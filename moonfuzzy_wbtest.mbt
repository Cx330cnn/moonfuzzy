///|
test "triangle membership boundaries" {
  let cold = match triangle("cold", 0.0, 10.0, 20.0) {
    Ok(value) => value
    Err(_) => abort("valid triangle rejected")
  }
  assert_eq(cold.membership(-1.0), 0.0)
  assert_eq(cold.membership(5.0), 0.5)
  assert_eq(cold.membership(10.0), 1.0)
  assert_eq(cold.membership(15.0), 0.5)
  assert_eq(cold.membership(21.0), 0.0)
}

///|
test "validation rejects reversed triangles and empty domains" {
  assert_true(triangle("bad", 2.0, 1.0, 3.0) is Err(InvalidShape))
  assert_true(variable("x", 10.0, 0.0, []) is Err(EmptyDomain))
  assert_true(
    rule(is_set("x", "low"), sugeno_constant("y", 3.0), 2.0)
    is Err(InvalidWeight),
  )
}

///|
test "sugeno inference combines weighted constant and linear rules" {
  let low = match triangle("low", 0.0, 0.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("low")
  }
  let high = match triangle("high", 0.0, 10.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("high")
  }
  let input = match variable("temperature", 0.0, 10.0, [low, high]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("fan", 0.0, 100.0, []) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let r1 = match
    rule(is_set("temperature", "low"), sugeno_linear("fan", 0.0, [2.0]), 1.0) {
    Ok(value) => value
    Err(_) => abort("r1")
  }
  let r2 = match
    rule(is_set("temperature", "high"), sugeno_constant("fan", 80.0), 1.0) {
    Ok(value) => value
    Err(_) => abort("r2")
  }
  let model = match
    system([input], [output], [r1, r2], product_probabilistic_connective()) {
    Ok(value) => value
    Err(_) => abort("system")
  }
  let result = model.infer_sugeno([5.0])
  assert_true(result is Ok([45.0]))
}

///|
test "mamdani centroid is stable for a symmetric consequent" {
  let input_set = match triangle("active", 0.0, 1.0, 2.0) {
    Ok(value) => value
    Err(_) => abort("input set")
  }
  let output_set = match triangle("center", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("output set")
  }
  let input = match variable("signal", 0.0, 2.0, [input_set]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("level", 0.0, 10.0, [output_set]) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let current_rule = match
    rule(is_set("signal", "active"), mamdani("level", "center"), 1.0) {
    Ok(value) => value
    Err(_) => abort("rule")
  }
  let model = match
    system([input], [output], [current_rule], min_max_connective()) {
    Ok(value) => value
    Err(_) => abort("system")
  }
  let result = model.infer_mamdani([1.0], 101)
  assert_true(
    match result {
      Ok(values) => values[0] > 4.99 && values[0] < 5.01
      Err(_) => false
    },
  )
}

///|
test "mamdani rejects no fired rules and too-coarse grids" {
  let cold = match triangle("cold", 0.0, 0.0, 5.0) {
    Ok(value) => value
    Err(_) => abort("cold")
  }
  let warm = match triangle("warm", 5.0, 10.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("warm")
  }
  let output_set = match triangle("out", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("out")
  }
  let input = match variable("x", 0.0, 10.0, [cold, warm]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("y", 0.0, 10.0, [output_set]) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let current_rule = match rule(is_set("x", "cold"), mamdani("y", "out"), 1.0) {
    Ok(value) => value
    Err(_) => abort("rule")
  }
  let model = match
    system([input], [output], [current_rule], min_max_connective()) {
    Ok(value) => value
    Err(_) => abort("system")
  }
  assert_true(model.infer_mamdani([9.0], 11) is Err(NoFiredRule("y")))
  assert_true(model.infer_mamdani([1.0], 1) is Err(InvalidResolution))
}

///|
test "gaussian and sigmoid membership are bounded and oriented" {
  let bell = match gaussian("bell", 2.0, 2.0) {
    Ok(value) => value
    Err(_) => abort("gaussian")
  }
  assert_eq(bell.membership(2.0), 1.0)
  assert_true(bell.membership(0.0) > 0.60 && bell.membership(0.0) < 0.61)
  let rising = match sigmoid("rising", 2.0, 0.0) {
    Ok(value) => value
    Err(_) => abort("sigmoid")
  }
  assert_eq(rising.membership(0.0), 0.5)
  assert_true(rising.membership(3.0) > rising.membership(-3.0))
  assert_true(gaussian("bad", 0.0, 0.0) is Err(InvalidShape))
  assert_true(sigmoid("bad", 0.0, 0.0) is Err(InvalidShape))
}

///|
test "shoulders and fuzzification preserve boundary grades" {
  let low = match left_shoulder("low", 2.0, 6.0) {
    Ok(value) => value
    Err(_) => abort("left")
  }
  let high = match right_shoulder("high", 4.0, 8.0) {
    Ok(value) => value
    Err(_) => abort("right")
  }
  assert_eq(low.membership(-10.0), 1.0)
  assert_eq(low.membership(6.0), 0.0)
  assert_eq(high.membership(4.0), 0.0)
  assert_eq(high.membership(10.0), 1.0)
  let input = match variable("load", 0.0, 10.0, [low, high]) {
    Ok(value) => value
    Err(_) => abort("variable")
  }
  assert_eq(input.fuzzify(4.0), [0.5, 0.0])
  assert_eq(input.maximizers(4.0), ["low"])
}

///|
test "rule activations retain both raw and weighted firing strengths" {
  let active = match triangle("active", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("set")
  }
  let input = match variable("x", 0.0, 10.0, [active]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("y", 0.0, 1.0, []) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let current_rule = match
    rule(is_set("x", "active"), sugeno_constant("y", 1.0), 0.4) {
    Ok(value) => value
    Err(_) => abort("rule")
  }
  let model = match
    system([input], [output], [current_rule], min_max_connective()) {
    Ok(value) => value
    Err(_) => abort("system")
  }
  match model.activations([5.0]) {
    Err(_) => abort("activation failed")
    Ok(items) => {
      assert_eq(items.length(), 1)
      assert_eq(items[0].rule_index, 0)
      assert_eq(items[0].antecedent_grade, 1.0)
      assert_eq(items[0].weighted_grade, 0.4)
    }
  }
  assert_true(model.activations([]) is Err(InputCount(1, 0)))
}

///|
test "sample defuzzifiers distinguish centroid bisector and maximum" {
  let axis = [0.0, 1.0, 2.0, 3.0]
  let grades = [0.0, 1.0, 1.0, 0.0]
  assert_true(defuzzify(axis, grades, SampledCentroid) is Ok(1.5))
  assert_true(defuzzify(axis, grades, Bisector) is Ok(1.5))
  assert_true(defuzzify(axis, grades, MeanOfMaximum) is Ok(1.5))
  assert_true(defuzzify([0.0], [1.0], SampledCentroid) is Err(TooFewSamples))
  assert_true(
    defuzzify([0.0, 1.0], [0.0, 0.0], SampledCentroid) is Err(ZeroArea),
  )
  assert_true(
    defuzzify([0.0, 0.0], [0.0, 1.0], SampledCentroid) is Err(NonIncreasingAxis),
  )
  assert_true(
    defuzzify([0.0, 1.0], [0.0, 1.1], SampledCentroid) is Err(GradeOutOfRange),
  )
}

///|
test "system construction validates names and every rule reference" {
  let set = match triangle("active", 0.0, 1.0, 2.0) {
    Ok(value) => value
    Err(_) => abort("set")
  }
  let input = match variable("x", 0.0, 2.0, [set]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("y", 0.0, 1.0, []) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let bad_input = match
    rule(is_set("missing", "active"), sugeno_constant("y", 1.0), 1.0) {
    Ok(value) => value
    Err(_) => abort("rule")
  }
  assert_true(
    system([input], [output], [bad_input], min_max_connective())
    is Err(MissingInput("missing")),
  )
  let duplicate_variable = match variable("x", 0.0, 2.0, [set]) {
    Ok(value) => value
    Err(_) => abort("duplicate variable")
  }
  let valid = match
    rule(is_set("x", "active"), sugeno_constant("y", 1.0), 1.0) {
    Ok(value) => value
    Err(_) => abort("valid rule")
  }
  assert_true(
    system([input, duplicate_variable], [output], [valid], min_max_connective())
    is Err(DuplicateVariable("x")),
  )
}

///|
test "system construction rejects duplicate labels and bad Sugeno dimensions" {
  let first = match singleton("same", 1.0) {
    Ok(value) => value
    Err(_) => abort("first")
  }
  let second = match singleton("same", 2.0) {
    Ok(value) => value
    Err(_) => abort("second")
  }
  let input = match variable("x", 0.0, 2.0, [first, second]) {
    Ok(value) => value
    Err(_) => abort("input")
  }
  let output = match variable("y", 0.0, 1.0, []) {
    Ok(value) => value
    Err(_) => abort("output")
  }
  let rule_with_bad_coefficients = match
    rule(is_set("x", "same"), sugeno_linear("y", 0.0, []), 1.0) {
    Ok(value) => value
    Err(_) => abort("rule")
  }
  assert_true(
    system(
      [input],
      [output],
      [rule_with_bad_coefficients],
      min_max_connective(),
    )
    is Err(DuplicateSet("x", "same")),
  )
  let distinct = match singleton("only", 1.0) {
    Ok(value) => value
    Err(_) => abort("distinct")
  }
  let valid_input = match variable("x", 0.0, 2.0, [distinct]) {
    Ok(value) => value
    Err(_) => abort("valid input")
  }
  let bad_dimensions = match
    rule(is_set("x", "only"), sugeno_linear("y", 0.0, []), 1.0) {
    Ok(value) => value
    Err(_) => abort("bad dimensions rule")
  }
  assert_true(
    system([valid_input], [output], [bad_dimensions], min_max_connective())
    is Err(CoefficientCount("y")),
  )
}

///|
test "sampled curves expose area and alpha cuts" {
  let triangle = match triangle("mid", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("triangle")
  }
  let curve = match sample_set(triangle, 0.0, 10.0, 11) {
    Ok(value) => value
    Err(_) => abort("sample")
  }
  assert_true(
    match curve.area() {
      Ok(value) => value > 4.999 && value < 5.001
      Err(_) => false
    },
  )
  assert_true(curve.alpha_cut(0.5) is Ok(Some((3.0, 7.0))))
  assert_true(curve.alpha_cut(1.0) is Ok(Some((5.0, 5.0))))
  assert_true(curve.alpha_cut(1.1) is Err(GradeOutOfRange))
  assert_true(
    { axis: [0.0], grades: [1.0, 0.0], }.area() is Err(SampleCountMismatch),
  )
}

///|
test "sampled fuzzy Jaccard compares identical and disjoint labels" {
  let first = match triangle("first", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("first")
  }
  let identical = match triangle("copy", 0.0, 5.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("copy")
  }
  let far = match triangle("far", 20.0, 25.0, 30.0) {
    Ok(value) => value
    Err(_) => abort("far")
  }
  assert_true(fuzzy_jaccard(first, identical, 0.0, 10.0, 101) is Ok(1.0))
  assert_true(fuzzy_jaccard(first, far, 0.0, 30.0, 101) is Ok(0.0))
  assert_true(fuzzy_jaccard(first, far, 0.0, 30.0, 1) is Err(InvalidResolution))
}
