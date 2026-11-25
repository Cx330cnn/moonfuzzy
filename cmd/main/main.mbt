///|
/// Run a small fan-control model to demonstrate a real library workflow.
fn main {
  let low = match @fuzzy.triangle("low", 0.0, 0.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("could not construct low set")
  }
  let high = match @fuzzy.triangle("high", 0.0, 10.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("could not construct high set")
  }
  let temperature = match
    @fuzzy.variable("temperature", 0.0, 10.0, [low, high]) {
    Ok(value) => value
    Err(_) => abort("could not construct temperature input")
  }
  let fan = match @fuzzy.variable("fan", 0.0, 100.0, []) {
    Ok(value) => value
    Err(_) => abort("could not construct fan output")
  }
  let cool = match
    @fuzzy.rule(
      @fuzzy.is_set("temperature", "low"),
      @fuzzy.sugeno_constant("fan", 20.0),
      1.0,
    ) {
    Ok(value) => value
    Err(_) => abort("could not construct cool rule")
  }
  let warm = match
    @fuzzy.rule(
      @fuzzy.is_set("temperature", "high"),
      @fuzzy.sugeno_constant("fan", 80.0),
      1.0,
    ) {
    Ok(value) => value
    Err(_) => abort("could not construct warm rule")
  }
  let controller = match
    @fuzzy.system(
      [temperature],
      [fan],
      [cool, warm],
      @fuzzy.min_max_connective(),
    ) {
    Ok(value) => value
    Err(_) => abort("could not construct controller")
  }
  match controller.infer_sugeno([5.0]) {
    Err(_) => abort("inference failed")
    Ok(outputs) =>
      println("Fan command at temperature 5: " + outputs[0].to_string())
  }
}
