///|
/// A normalized shape used to turn a crisp input into a membership grade.
pub enum MembershipShape {
  Triangle(Double, Double, Double)
  Trapezoid(Double, Double, Double, Double)
  Singleton(Double)
  Gaussian(Double, Double)
  Sigmoid(Double, Double)
  LeftShoulder(Double, Double)
  RightShoulder(Double, Double)
}

///|
/// A named fuzzy set over one input or output domain.
pub struct FuzzySet {
  name : String
  shape : MembershipShape
}

///|
/// Errors returned when a model or evaluation request is malformed.
pub enum FuzzyError {
  EmptyName
  InvalidShape
  EmptyDomain
  MissingInput(String)
  MissingSet(String, String)
  InputCount(Int32, Int32)
  MissingConsequent(String, String)
  NoFiredRule(String)
  CoefficientCount(String)
  EmptyRuleBase
  InvalidResolution
  InvalidWeight
  DuplicateVariable(String)
  DuplicateSet(String, String)
  MissingOutput(String)
  NoMembershipArea
}

///|
/// A linguistic variable groups fuzzy sets over a bounded crisp domain.
pub struct LinguisticVariable {
  name : String
  minimum : Double
  maximum : Double
  sets : Array[FuzzySet]
}

///|
/// Create a validated triangular membership function.
pub fn triangle(
  name : String,
  left : Double,
  peak : Double,
  right : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if left > peak || peak > right || left == right {
    return Err(InvalidShape)
  }
  Ok({ name, shape: Triangle(left, peak, right), })
}

///|
/// Create a validated trapezoidal membership function.
pub fn trapezoid(
  name : String,
  left : Double,
  shoulder_left : Double,
  shoulder_right : Double,
  right : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if left > shoulder_left ||
    shoulder_left > shoulder_right ||
    shoulder_right > right ||
    left == right {
    return Err(InvalidShape)
  }
  Ok({ name, shape: Trapezoid(left, shoulder_left, shoulder_right, right), })
}

///|
/// Create a singleton set, useful for discrete domains.
pub fn singleton(name : String, value : Double) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  Ok({ name, shape: Singleton(value), })
}

///|
/// Return the degree to which a crisp value belongs to a set, in [0, 1].
pub fn FuzzySet::membership(self : FuzzySet, value : Double) -> Double {
  match self.shape {
    Triangle(a, b, c) =>
      if value < a || value > c {
        0.0
      } else if value == b {
        1.0
      } else if value < b {
        (value - a) / (b - a)
      } else {
        (c - value) / (c - b)
      }
    Trapezoid(a, b, c, d) =>
      if value < a || value > d {
        0.0
      } else if value >= b && value <= c {
        1.0
      } else if value < b {
        (value - a) / (b - a)
      } else {
        (d - value) / (d - c)
      }
    Singleton(x) => if value == x { 1.0 } else { 0.0 }
    Gaussian(center, spread) => {
      let z = (value - center) / spread
      @math.exp(-0.5 * z * z)
    }
    Sigmoid(slope, center) => 1.0 / (1.0 + @math.exp(-slope * (value - center)))
    LeftShoulder(plateau_end, zero_start) =>
      if value <= plateau_end {
        1.0
      } else if value >= zero_start {
        0.0
      } else {
        (zero_start - value) / (zero_start - plateau_end)
      }
    RightShoulder(zero_end, plateau_start) =>
      if value <= zero_end {
        0.0
      } else if value >= plateau_start {
        1.0
      } else {
        (value - zero_end) / (plateau_start - zero_end)
      }
  }
}

///|
/// Create a variable with a checked, non-empty domain.
pub fn variable(
  name : String,
  minimum : Double,
  maximum : Double,
  sets : Array[FuzzySet],
) -> Result[LinguisticVariable, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if minimum >= maximum {
    return Err(EmptyDomain)
  }
  Ok({ name, minimum, maximum, sets, })
}

///|
/// Combine antecedent grades using the minimum t-norm.
pub fn and_min(left : Double, right : Double) -> Double {
  if left < right {
    left
  } else {
    right
  }
}

///|
/// Combine antecedent grades using the product t-norm.
pub fn and_product(left : Double, right : Double) -> Double {
  left * right
}

///|
/// Combine alternative antecedent grades using the maximum s-norm.
pub fn or_max(left : Double, right : Double) -> Double {
  if left > right {
    left
  } else {
    right
  }
}

///|
/// Combine alternative antecedent grades using the probabilistic sum.
pub fn or_probabilistic(left : Double, right : Double) -> Double {
  left + right - left * right
}

///|
/// Logical operator used to combine rule antecedents.
pub enum Connective {
  Minimum
  Product
  Maximum
  ProbabilisticSum
}

///|
/// A fuzzy proposition selects a named set on a named variable.
pub enum Antecedent {
  Is(String, String)
  And(Antecedent, Antecedent)
  Or(Antecedent, Antecedent)
  Not(Antecedent)
}

///|
/// A zero-order Sugeno consequent is a constant crisp output.
pub enum Consequent {
  Mamdani(String, String)
  SugenoConstant(String, Double)
  SugenoLinear(String, Double, Array[Double])
}

///|
/// A weighted fuzzy production rule.
pub struct Rule {
  antecedent : Antecedent
  consequent : Consequent
  weight : Double
}

///|
/// A reusable rule base with explicit input and output variables.
pub struct System {
  inputs : Array[LinguisticVariable]
  outputs : Array[LinguisticVariable]
  rules : Array[Rule]
  connective : Connective
}

///|
/// Create a weighted rule. Weight must lie in the closed unit interval.
pub fn rule(
  antecedent : Antecedent,
  consequent : Consequent,
  weight : Double,
) -> Result[Rule, FuzzyError] {
  if weight < 0.0 || weight > 1.0 {
    return Err(InvalidWeight)
  }
  Ok({ antecedent, consequent, weight, })
}

///|
/// Build a system after checking that its rule base is non-empty.
pub fn system(
  inputs : Array[LinguisticVariable],
  outputs : Array[LinguisticVariable],
  rules : Array[Rule],
  connective : Connective,
) -> Result[System, FuzzyError] {
  if rules.length() == 0 {
    return Err(EmptyRuleBase)
  }
  match validate_variable_names(inputs) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_variable_names(outputs) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_rules(inputs, outputs, rules) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({ inputs, outputs, rules, connective, })
}

///|
/// Resolve a variable by name, returning its position for compact rule evaluation.
fn find_variable(
  variables : Array[LinguisticVariable],
  name : String,
) -> Int32? {
  let mut index = 0
  while index < variables.length() {
    if variables[index].name == name {
      return Some(index)
    }
    index = index + 1
  }
  None
}

///|
/// Resolve a fuzzy set inside a variable by name.
fn find_set(variable : LinguisticVariable, name : String) -> FuzzySet? {
  let mut index = 0
  while index < variable.sets.length() {
    if variable.sets[index].name == name {
      return Some(variable.sets[index])
    }
    index = index + 1
  }
  None
}

///|
/// Evaluate one proposition tree against an ordered input vector.
fn evaluate_antecedent(
  node : Antecedent,
  variables : Array[LinguisticVariable],
  values : Array[Double],
  connective : Connective,
) -> Result[Double, FuzzyError] {
  match node {
    Is(variable_name, set_name) =>
      match find_variable(variables, variable_name) {
        None => Err(MissingInput(variable_name))
        Some(index) =>
          match find_set(variables[index], set_name) {
            None => Err(MissingSet(variable_name, set_name))
            Some(set) => Ok(set.membership(values[index]))
          }
      }
    Not(child) =>
      match evaluate_antecedent(child, variables, values, connective) {
        Err(error) => Err(error)
        Ok(grade) => Ok(1.0 - grade)
      }
    And(left, right) =>
      combine_children(left, right, variables, values, connective, true)
    Or(left, right) =>
      combine_children(left, right, variables, values, connective, false)
  }
}

///|
/// Evaluate both branches and apply the configured t-norm/s-norm.
fn combine_children(
  left : Antecedent,
  right : Antecedent,
  variables : Array[LinguisticVariable],
  values : Array[Double],
  connective : Connective,
  is_and : Bool,
) -> Result[Double, FuzzyError] {
  match evaluate_antecedent(left, variables, values, connective) {
    Err(error) => Err(error)
    Ok(a) =>
      match evaluate_antecedent(right, variables, values, connective) {
        Err(error) => Err(error)
        Ok(b) => Ok(combine_grade(a, b, connective, is_and))
      }
  }
}

///|
/// Apply a fuzzy t-norm or s-norm to a pair of grades.
fn combine_grade(
  a : Double,
  b : Double,
  connective : Connective,
  is_and : Bool,
) -> Double {
  match connective {
    Minimum => if is_and { and_min(a, b) } else { or_max(a, b) }
    Product => if is_and { and_product(a, b) } else { or_probabilistic(a, b) }
    Maximum => if is_and { and_min(a, b) } else { or_max(a, b) }
    ProbabilisticSum =>
      if is_and {
        and_product(a, b)
      } else {
        or_probabilistic(a, b)
      }
  }
}

///|
/// Evaluate with conventional minimum implication, maximum aggregation,
/// and sampled-centroid defuzzification defaults.
pub fn System::infer_mamdani(
  self : System,
  values : Array[Double],
  resolution : Int32,
) -> Result[Array[Double], FuzzyError] {
  self.infer_mamdani_with(
    values,
    resolution,
    MinimumImplication,
    MaximumAggregation,
    SampledCentroid,
  )
}

///|
/// Evaluate Mamdani rules with explicit implication, aggregation, and defuzzifier.
pub fn System::infer_mamdani_with(
  self : System,
  values : Array[Double],
  resolution : Int32,
  implication : Implication,
  aggregation : Aggregation,
  defuzzification : Defuzzification,
) -> Result[Array[Double], FuzzyError] {
  if values.length() != self.inputs.length() {
    return Err(InputCount(self.inputs.length(), values.length()))
  }
  if resolution < 2 {
    return Err(InvalidResolution)
  }
  let results = Array()
  for output in self.outputs {
    let axis = Array()
    let grades = Array()
    let step = (output.maximum - output.minimum) / (resolution - 1).to_double()
    let mut point = 0
    while point < resolution {
      let x = output.minimum + point.to_double() * step
      axis.push(x)
      let mut aggregate = 0.0
      for current_rule in self.rules {
        match current_rule.consequent {
          Mamdani(output_name, set_name) if output_name == output.name => {
            let firing = match
              evaluate_antecedent(
                current_rule.antecedent,
                self.inputs,
                values,
                self.connective,
              ) {
              Err(error) => return Err(error)
              Ok(grade) => grade * current_rule.weight
            }
            match find_set(output, set_name) {
              None => return Err(MissingConsequent(output.name, set_name))
              Some(set) => {
                let membership = set.membership(x)
                let implied = match implication {
                  MinimumImplication => and_min(firing, membership)
                  ProductImplication => firing * membership
                }
                aggregate = match aggregation {
                  MaximumAggregation => or_max(aggregate, implied)
                  ProbabilisticAggregation =>
                    or_probabilistic(aggregate, implied)
                }
              }
            }
          }
          _ => ()
        }
      }
      grades.push(aggregate)
      point = point + 1
    }
    match defuzzify(axis, grades, defuzzification) {
      Err(_) => return Err(NoFiredRule(output.name))
      Ok(value) => results.push(value)
    }
  }
  Ok(results)
}

///|
/// Evaluate a first-order Sugeno system with weighted-average aggregation.
pub fn System::infer_sugeno(
  self : System,
  values : Array[Double],
) -> Result[Array[Double], FuzzyError] {
  if values.length() != self.inputs.length() {
    return Err(InputCount(self.inputs.length(), values.length()))
  }
  let result = Array()
  for output in self.outputs {
    let mut numerator = 0.0
    let mut denominator = 0.0
    for current_rule in self.rules {
      match current_rule.consequent {
        SugenoConstant(name, constant) if name == output.name => {
          let firing = match
            evaluate_antecedent(
              current_rule.antecedent,
              self.inputs,
              values,
              self.connective,
            ) {
            Err(error) => return Err(error)
            Ok(grade) => grade * current_rule.weight
          }
          numerator = numerator + firing * constant
          denominator = denominator + firing
        }
        SugenoLinear(name, constant, coefficients) if name == output.name => {
          if coefficients.length() != values.length() {
            return Err(CoefficientCount(output.name))
          }
          let firing = match
            evaluate_antecedent(
              current_rule.antecedent,
              self.inputs,
              values,
              self.connective,
            ) {
            Err(error) => return Err(error)
            Ok(grade) => grade * current_rule.weight
          }
          let mut consequent_value = constant
          let mut index = 0
          while index < values.length() {
            consequent_value = consequent_value +
              coefficients[index] * values[index]
            index = index + 1
          }
          numerator = numerator + firing * consequent_value
          denominator = denominator + firing
        }
        _ => ()
      }
    }
    if denominator == 0.0 {
      return Err(NoFiredRule(output.name))
    }
    result.push(numerator / denominator)
  }
  Ok(result)
}

///|
/// Build an atomic antecedent, matching a named set on a named input.
pub fn is_set(variable_name : String, set_name : String) -> Antecedent {
  Is(variable_name, set_name)
}

///|
/// Build a conjunction of two fuzzy propositions.
pub fn both(left : Antecedent, right : Antecedent) -> Antecedent {
  And(left, right)
}

///|
/// Build a disjunction of two fuzzy propositions.
pub fn either(left : Antecedent, right : Antecedent) -> Antecedent {
  Or(left, right)
}

///|
/// Negate a fuzzy proposition using the standard complement.
pub fn negate(value : Antecedent) -> Antecedent {
  Not(value)
}

///|
/// Construct a Mamdani fuzzy-set consequent.
pub fn mamdani(output_name : String, set_name : String) -> Consequent {
  Mamdani(output_name, set_name)
}

///|
/// Construct a zero-order Sugeno constant consequent.
pub fn sugeno_constant(output_name : String, value : Double) -> Consequent {
  SugenoConstant(output_name, value)
}

///|
/// Construct a first-order Sugeno linear consequent.
pub fn sugeno_linear(
  output_name : String,
  bias : Double,
  coefficients : Array[Double],
) -> Consequent {
  SugenoLinear(output_name, bias, coefficients)
}

///|
/// Select minimum-AND with maximum-OR.
pub fn min_max_connective() -> Connective {
  Minimum
}

///|
/// Select product-AND with probabilistic-sum OR.
pub fn product_probabilistic_connective() -> Connective {
  Product
}

///|
/// Select maximum-AND with maximum-OR.
pub fn max_connective() -> Connective {
  Maximum
}

///|
/// Select product-AND with probabilistic-sum OR.
pub fn probabilistic_connective() -> Connective {
  ProbabilisticSum
}

///|
/// Create a symmetric Gaussian set with a positive standard-deviation scale.
pub fn gaussian(
  name : String,
  center : Double,
  spread : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if spread <= 0.0 {
    return Err(InvalidShape)
  }
  Ok({ name, shape: Gaussian(center, spread), })
}

///|
/// Create a logistic S-curve. Positive slope is increasing; negative slope is decreasing.
pub fn sigmoid(
  name : String,
  slope : Double,
  center : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if slope == 0.0 {
    return Err(InvalidShape)
  }
  Ok({ name, shape: Sigmoid(slope, center), })
}

///|
/// Create a left-shoulder set that remains fully active below its domain.
pub fn left_shoulder(
  name : String,
  plateau_end : Double,
  zero_start : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if plateau_end >= zero_start {
    return Err(InvalidShape)
  }
  Ok({ name, shape: LeftShoulder(plateau_end, zero_start), })
}

///|
/// Create a right-shoulder set that remains fully active above its domain.
pub fn right_shoulder(
  name : String,
  zero_end : Double,
  plateau_start : Double,
) -> Result[FuzzySet, FuzzyError] {
  if name == "" {
    return Err(EmptyName)
  }
  if zero_end >= plateau_start {
    return Err(InvalidShape)
  }
  Ok({ name, shape: RightShoulder(zero_end, plateau_start), })
}

///|
/// Fuzzify one crisp value into a vector ordered like the variable's set list.
pub fn LinguisticVariable::fuzzify(
  self : LinguisticVariable,
  value : Double,
) -> Array[Double] {
  let grades = Array()
  for set in self.sets {
    grades.push(set.membership(value))
  }
  grades
}

///|
/// Find the strongest linguistic labels for an input value, preserving ties.
pub fn LinguisticVariable::maximizers(
  self : LinguisticVariable,
  value : Double,
) -> Array[String] {
  let mut best = -1.0
  let labels = Array()
  for set in self.sets {
    let grade = set.membership(value)
    if grade > best {
      best = grade
      labels.clear()
      labels.push(set.name)
    } else if grade == best {
      labels.push(set.name)
    }
  }
  labels
}

///|
/// Explain how strongly each rule fires for one ordered input vector.
pub struct RuleActivation {
  rule_index : Int32
  antecedent_grade : Double
  weighted_grade : Double
}

///|
/// Evaluate every rule antecedent and return its unweighted and weighted strength.
/// This is useful for debugging rule bases and explaining Mamdani or Sugeno results.
pub fn System::activations(
  self : System,
  values : Array[Double],
) -> Result[Array[RuleActivation], FuzzyError] {
  if values.length() != self.inputs.length() {
    return Err(InputCount(self.inputs.length(), values.length()))
  }
  let result = Array()
  let mut index = 0
  while index < self.rules.length() {
    let current_rule = self.rules[index]
    match
      evaluate_antecedent(
        current_rule.antecedent,
        self.inputs,
        values,
        self.connective,
      ) {
      Err(error) => return Err(error)
      Ok(grade) =>
        result.push({
          rule_index: index,
          antecedent_grade: grade,
          weighted_grade: grade * current_rule.weight,
        })
    }
    index = index + 1
  }
  Ok(result)
}

///|
/// Strategy for converting a sampled fuzzy output into one crisp value.
pub enum Defuzzification {
  SampledCentroid
  Bisector
  MeanOfMaximum
}

///|
/// Errors specific to sampled-output defuzzification.
pub enum SampleError {
  SampleCountMismatch
  TooFewSamples
  NonIncreasingAxis
  GradeOutOfRange
  ZeroArea
}

///|
/// Defuzzify grades sampled at strictly increasing axis coordinates.
/// Centroid and bisector use trapezoidal segment areas; mean-of-maximum
/// averages coordinates that attain the maximum sampled grade.
pub fn defuzzify(
  axis : Array[Double],
  grades : Array[Double],
  strategy : Defuzzification,
) -> Result[Double, SampleError] {
  if axis.length() != grades.length() {
    return Err(SampleCountMismatch)
  }
  if axis.length() < 2 {
    return Err(TooFewSamples)
  }
  let mut i = 0
  while i < axis.length() {
    if grades[i] < 0.0 || grades[i] > 1.0 {
      return Err(GradeOutOfRange)
    }
    if i > 0 && axis[i] <= axis[i - 1] {
      return Err(NonIncreasingAxis)
    }
    i = i + 1
  }
  match strategy {
    MeanOfMaximum => {
      let mut maximum = grades[0]
      for grade in grades {
        if grade > maximum {
          maximum = grade
        }
      }
      if maximum == 0.0 {
        return Err(ZeroArea)
      }
      let mut sum = 0.0
      let mut count = 0
      let mut j = 0
      while j < grades.length() {
        if grades[j] == maximum {
          sum = sum + axis[j]
          count = count + 1
        }
        j = j + 1
      }
      Ok(sum / count.to_double())
    }
    SampledCentroid | Bisector => {
      let mut total_area = 0.0
      let mut moment = 0.0
      let mut j = 1
      while j < axis.length() {
        let width = axis[j] - axis[j - 1]
        let area = width * (grades[j - 1] + grades[j]) / 2.0
        total_area = total_area + area
        moment = moment + area * (axis[j - 1] + axis[j]) / 2.0
        j = j + 1
      }
      if total_area == 0.0 {
        return Err(ZeroArea)
      }
      match strategy {
        SampledCentroid => Ok(moment / total_area)
        Bisector => {
          let target = total_area / 2.0
          let mut accumulated = 0.0
          let mut k = 1
          while k < axis.length() {
            let width = axis[k] - axis[k - 1]
            let area = width * (grades[k - 1] + grades[k]) / 2.0
            if accumulated + area >= target {
              let fraction = (target - accumulated) / area
              return Ok(axis[k - 1] + fraction * width)
            }
            accumulated = accumulated + area
            k = k + 1
          }
          Ok(axis[axis.length() - 1])
        }
        MeanOfMaximum => Err(ZeroArea)
      }
    }
  }
}

///|
/// Convenience wrapper for sampled centroid defuzzification.
pub fn defuzzify_centroid(
  axis : Array[Double],
  grades : Array[Double],
) -> Result[Double, SampleError] {
  defuzzify(axis, grades, SampledCentroid)
}

///|
/// Convenience wrapper for bisector defuzzification.
pub fn defuzzify_bisector(
  axis : Array[Double],
  grades : Array[Double],
) -> Result[Double, SampleError] {
  defuzzify(axis, grades, Bisector)
}

///|
/// Convenience wrapper for mean-of-maximum defuzzification.
pub fn defuzzify_mean_of_maximum(
  axis : Array[Double],
  grades : Array[Double],
) -> Result[Double, SampleError] {
  defuzzify(axis, grades, MeanOfMaximum)
}

///|
/// Check that all names within a group of variables are unique.
fn validate_variable_names(
  variables : Array[LinguisticVariable],
) -> Result[Unit, FuzzyError] {
  let mut i = 0
  while i < variables.length() {
    let mut j = i + 1
    while j < variables.length() {
      if variables[i].name == variables[j].name {
        return Err(DuplicateVariable(variables[i].name))
      }
      j = j + 1
    }
    let mut a = 0
    while a < variables[i].sets.length() {
      let mut b = a + 1
      while b < variables[i].sets.length() {
        if variables[i].sets[a].name == variables[i].sets[b].name {
          return Err(DuplicateSet(variables[i].name, variables[i].sets[a].name))
        }
        b = b + 1
      }
      a = a + 1
    }
    i = i + 1
  }
  Ok(())
}

///|
/// Validate every named proposition before evaluation begins.
fn validate_proposition(
  node : Antecedent,
  inputs : Array[LinguisticVariable],
) -> Result[Unit, FuzzyError] {
  match node {
    Is(variable_name, set_name) =>
      match find_variable(inputs, variable_name) {
        None => Err(MissingInput(variable_name))
        Some(index) =>
          match find_set(inputs[index], set_name) {
            None => Err(MissingSet(variable_name, set_name))
            Some(_) => Ok(())
          }
      }
    Not(child) => validate_proposition(child, inputs)
    And(left, right) =>
      match validate_proposition(left, inputs) {
        Err(error) => Err(error)
        Ok(_) => validate_proposition(right, inputs)
      }
    Or(left, right) =>
      match validate_proposition(left, inputs) {
        Err(error) => Err(error)
        Ok(_) => validate_proposition(right, inputs)
      }
  }
}

///|
/// Validate rule references and consequent dimensions for a proposed system.
fn validate_rules(
  inputs : Array[LinguisticVariable],
  outputs : Array[LinguisticVariable],
  rules : Array[Rule],
) -> Result[Unit, FuzzyError] {
  for current_rule in rules {
    match validate_proposition(current_rule.antecedent, inputs) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match current_rule.consequent {
      Mamdani(output_name, set_name) =>
        match find_variable(outputs, output_name) {
          None => return Err(MissingOutput(output_name))
          Some(index) =>
            match find_set(outputs[index], set_name) {
              None => return Err(MissingConsequent(output_name, set_name))
              Some(_) => ()
            }
        }
      SugenoConstant(output_name, _) =>
        if find_variable(outputs, output_name) is None {
          return Err(MissingOutput(output_name))
        }
      SugenoLinear(output_name, _, coefficients) => {
        if find_variable(outputs, output_name) is None {
          return Err(MissingOutput(output_name))
        }
        if coefficients.length() != inputs.length() {
          return Err(CoefficientCount(output_name))
        }
      }
    }
  }
  Ok(())
}

///|
/// A finite grid representation of a fuzzy set over a requested interval.
pub struct SampledCurve {
  axis : Array[Double]
  grades : Array[Double]
}

///|
/// Sample one fuzzy set over an inclusive interval using a uniform grid.
pub fn sample_set(
  set : FuzzySet,
  minimum : Double,
  maximum : Double,
  resolution : Int32,
) -> Result[SampledCurve, FuzzyError] {
  if minimum >= maximum {
    return Err(EmptyDomain)
  }
  if resolution < 2 {
    return Err(InvalidResolution)
  }
  let axis = Array()
  let grades = Array()
  let step = (maximum - minimum) / (resolution - 1).to_double()
  let mut index = 0
  while index < resolution {
    let x = minimum + index.to_double() * step
    axis.push(x)
    grades.push(set.membership(x))
    index = index + 1
  }
  Ok({ axis, grades, })
}

///|
/// Return the sampled area under a validated membership curve.
pub fn SampledCurve::area(self : SampledCurve) -> Result[Double, SampleError] {
  if self.axis.length() != self.grades.length() {
    return Err(SampleCountMismatch)
  }
  if self.axis.length() < 2 {
    return Err(TooFewSamples)
  }
  let mut total = 0.0
  let mut index = 1
  while index < self.axis.length() {
    if self.axis[index] <= self.axis[index - 1] {
      return Err(NonIncreasingAxis)
    }
    if self.grades[index - 1] < 0.0 ||
      self.grades[index - 1] > 1.0 ||
      self.grades[index] < 0.0 ||
      self.grades[index] > 1.0 {
      return Err(GradeOutOfRange)
    }
    total = total +
      (self.axis[index] - self.axis[index - 1]) *
      (self.grades[index - 1] + self.grades[index]) /
      2.0
    index = index + 1
  }
  Ok(total)
}

///|
/// Find the closed interval spanning sampled points at or above alpha.
pub fn SampledCurve::alpha_cut(
  self : SampledCurve,
  alpha : Double,
) -> Result[(Double, Double)?, SampleError] {
  if alpha < 0.0 || alpha > 1.0 {
    return Err(GradeOutOfRange)
  }
  if self.axis.length() != self.grades.length() {
    return Err(SampleCountMismatch)
  }
  if self.axis.length() < 2 {
    return Err(TooFewSamples)
  }
  let mut first = -1
  let mut last = -1
  let mut i = 0
  while i < self.axis.length() {
    if i > 0 && self.axis[i] <= self.axis[i - 1] {
      return Err(NonIncreasingAxis)
    }
    if self.grades[i] < 0.0 || self.grades[i] > 1.0 {
      return Err(GradeOutOfRange)
    }
    if self.grades[i] >= alpha {
      if first < 0 {
        first = i
      }
      last = i
    }
    i = i + 1
  }
  if first < 0 {
    Ok(None)
  } else {
    Ok(Some((self.axis[first], self.axis[last])))
  }
}

///|
/// Compute a sampled Jaccard-style similarity between two fuzzy sets.
pub fn fuzzy_jaccard(
  left : FuzzySet,
  right : FuzzySet,
  minimum : Double,
  maximum : Double,
  resolution : Int32,
) -> Result[Double, FuzzyError] {
  match sample_set(left, minimum, maximum, resolution) {
    Err(error) => Err(error)
    Ok(left_curve) =>
      match sample_set(right, minimum, maximum, resolution) {
        Err(error) => Err(error)
        Ok(right_curve) => {
          let mut intersection = 0.0
          let mut union = 0.0
          let mut index = 1
          while index < resolution {
            let width = left_curve.axis[index] - left_curve.axis[index - 1]
            let left_low = left_curve.grades[index - 1]
            let left_high = left_curve.grades[index]
            let right_low = right_curve.grades[index - 1]
            let right_high = right_curve.grades[index]
            intersection = intersection +
              width *
              (and_min(left_low, right_low) + and_min(left_high, right_high)) /
              2.0
            union = union +
              width *
              (or_max(left_low, right_low) + or_max(left_high, right_high)) /
              2.0
            index = index + 1
          }
          if union == 0.0 {
            Err(NoMembershipArea)
          } else {
            Ok(intersection / union)
          }
        }
      }
  }
}

///|
/// How each Mamdani rule firing strength modifies its consequent set.
pub enum Implication {
  MinimumImplication
  ProductImplication
}

///|
/// How clipped rule consequents are combined into one output set.
pub enum Aggregation {
  MaximumAggregation
  ProbabilisticAggregation
}

///|
/// Select minimum t-norm Mamdani implication.
pub fn minimum_implication() -> Implication {
  MinimumImplication
}

///|
/// Select product Mamdani implication.
pub fn product_implication() -> Implication {
  ProductImplication
}

///|
/// Select maximum-s-norm consequent aggregation.
pub fn maximum_aggregation() -> Aggregation {
  MaximumAggregation
}

///|
/// Select probabilistic-sum consequent aggregation.
pub fn probabilistic_aggregation() -> Aggregation {
  ProbabilisticAggregation
}

///|
/// Summary of empirical rule-base coverage over caller-supplied samples.
pub struct CoverageReport {
  sample_count : Int32
  covered_samples : Int32
  uncovered_indices : Array[Int32]
  weakest_strength : Double
  average_strength : Double
}

///|
/// Errors produced when a coverage request is not meaningful.
pub enum CoverageError {
  EmptySamples
  InvalidCoverageThreshold
  CoverageEvaluation(FuzzyError)
}

///|
/// Measure how often at least one rule reaches the requested weighted strength.
pub fn System::coverage(
  self : System,
  samples : Array[Array[Double]],
  threshold : Double,
) -> Result[CoverageReport, CoverageError] {
  if samples.length() == 0 {
    return Err(EmptySamples)
  }
  if threshold < 0.0 || threshold > 1.0 {
    return Err(InvalidCoverageThreshold)
  }
  let uncovered = Array()
  let mut covered = 0
  let mut weakest = 1.0
  let mut total = 0.0
  let mut sample_index = 0
  while sample_index < samples.length() {
    let activations = match self.activations(samples[sample_index]) {
      Err(error) => return Err(CoverageEvaluation(error))
      Ok(items) => items
    }
    let mut strongest = 0.0
    for activation in activations {
      if activation.weighted_grade > strongest {
        strongest = activation.weighted_grade
      }
    }
    total = total + strongest
    if strongest >= threshold {
      covered = covered + 1
    } else {
      uncovered.push(sample_index)
    }
    if strongest < weakest {
      weakest = strongest
    }
    sample_index = sample_index + 1
  }
  Ok({
    sample_count: samples.length(),
    covered_samples: covered,
    uncovered_indices: uncovered,
    weakest_strength: weakest,
    average_strength: total / samples.length().to_double(),
  })
}

///|
/// One rule's weighted contribution to a Sugeno output.
pub struct SugenoContribution {
  rule_index : Int32
  firing_strength : Double
  consequent_value : Double
  weighted_value : Double
}

///|
/// Explain each rule's contribution to one named Sugeno output.
pub fn System::sugeno_contributions(
  self : System,
  output_name : String,
  values : Array[Double],
) -> Result[Array[SugenoContribution], FuzzyError] {
  if values.length() != self.inputs.length() {
    return Err(InputCount(self.inputs.length(), values.length()))
  }
  if find_variable(self.outputs, output_name) is None {
    return Err(MissingOutput(output_name))
  }
  let contributions = Array()
  let mut index = 0
  while index < self.rules.length() {
    let current_rule = self.rules[index]
    match current_rule.consequent {
      SugenoConstant(name, value) if name == output_name => {
        let grade = match
          evaluate_antecedent(
            current_rule.antecedent,
            self.inputs,
            values,
            self.connective,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value * current_rule.weight
        }
        contributions.push({
          rule_index: index,
          firing_strength: grade,
          consequent_value: value,
          weighted_value: grade * value,
        })
      }
      SugenoLinear(name, bias, coefficients) if name == output_name => {
        if coefficients.length() != values.length() {
          return Err(CoefficientCount(output_name))
        }
        let mut output = bias
        let mut input_index = 0
        while input_index < values.length() {
          output = output + coefficients[input_index] * values[input_index]
          input_index = input_index + 1
        }
        let grade = match
          evaluate_antecedent(
            current_rule.antecedent,
            self.inputs,
            values,
            self.connective,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value * current_rule.weight
        }
        contributions.push({
          rule_index: index,
          firing_strength: grade,
          consequent_value: output,
          weighted_value: grade * output,
        })
      }
      _ => ()
    }
    index = index + 1
  }
  Ok(contributions)
}
