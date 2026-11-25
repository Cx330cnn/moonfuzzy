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
