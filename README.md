# MoonFuzzy

MoonFuzzy 是面向 MoonBit 的模糊推理库原型：把连续数值、语言变量、隶属集合与 IF–THEN 规则组合起来，计算 Mamdani 或 Sugeno 输出。它处理的是模糊逻辑控制，不是 fuzzy string matching（文本模糊搜索）。

> **交付状态（2026-11-26）：**GitHub 公开仓库已建立，主分支提交 `ed111c4e947a844fc9139c8771d778365a27bc2c` 的 MoonBit CI 已通过（检查、WASM 测试与下游示例）。GitHub Release 和 MoonCakes 首发版本仍待发布，因此当前还不能安装公开包。

## 适用场景与用户

- 控制/仿真开发者：将温度、误差、负载等传感器值映射为“低/中/高”，再用规则推导连续控制量。
- MoonBit 应用开发者：在业务代码中内嵌小型、确定性的规则推理，而不是为几条规则自己维护一套隶属度、聚合及加权平均逻辑。
- 教学与算法验证：逐条检查前件激活强度，观察输入扰动和规则权重对结果的影响。

这些是根据库功能界定的目标使用者，不是已经完成访谈或生产部署的用户证据。

## 当前功能

- 三角形、梯形、单点、Gaussian、Sigmoid、左肩形和右肩形隶属函数；形状参数进行基本校验。
- 有界语言变量、批量 fuzzify、并列最大标签查询、归一化 Gini 模糊分类歧义度，以及网格化语言分区缺口扫描/域归一化。
- `AND`、`OR`、`NOT` 前件树；minimum-AND/maximum-OR、product-AND/probabilistic-sum-OR，以及明确标注为非标准 max-max 的连接策略。
- 加权规则；建模时检查变量/集合重名、规则前件/后件引用与 Sugeno 系数维度；按规则索引返回原始与加权激活值，并可对调用方提供的输入样本集计算经验覆盖率；Sugeno API 可逐条报告激活度、后件值及加权项；Mamdani trace API 可导出每条规则的采样蕴涵曲线、聚合曲线与清晰值；同一模型支持输入域校验和批量推理。
- Mamdani：默认采样输出域、最小蕴涵/最大聚合与离散质心；扩展 API 可选择积蕴涵、概率和聚合及多种解模糊策略。
- Sugeno：零阶常数与一阶线性后件的加权平均。
- 采样曲线提供面积、离散 alpha-cut、线性插值及质心/面积平分近似/最大隶属度均值；模糊集合还支持解析 alpha-cut 和采样 fuzzy-Jaccard 比较。

`defuzzify` 是采样数组工具；当前 Mamdani system API 固定采用质心。解模糊工具中的 Bisector 通过离散梯形段面积累计，并在线性坐标比例上近似段内位置，不声称解析精确。

## 本地运行

需要 MoonBit 工具链；已验证 MoonBit 工具链 `0.1.20261119`。在本地仓库根目录运行：

```sh
moon info
moon fmt
moon check --target wasm --deny-warn
moon test --target wasm --deny-warn
moon run --target wasm cmd/main
```

示例构造一个温度到风扇命令的 Sugeno 控制器；输入 `5.0` 时，两条规则等强激活，输出 `50`。示例源代码位于 [`cmd/main/main.mbt`](cmd/main/main.mbt)。当前 31 项白盒测试覆盖形状边界与采样不变量、参数错误、模型引用完整性、Mamdani/Sugeno 数值结果、批量等价性、规则覆盖诊断、分类歧义、alpha-cut 及采样曲线工具。

## 下游接入（发布后使用）

模块名为 `Cx330cnn/moonfuzzy`，拟发布版本为 `0.1.0`。**Release 和 MoonCakes 发布与消费者验证完成前不可安装。**发布后可运行 `moon add Cx330cnn/moonfuzzy@0.1.0`，或在消费者的 `moon.mod` 中固定版本：

```moonbit
import {
  "Cx330cnn/moonfuzzy@0.1.0"
}
```

在使用库的包（例如 `cmd/main/moon.pkg`）导入：

```moonbit
import {
  "Cx330cnn/moonfuzzy" @fuzzy,
}
```

最小建模流程（省略包级导入，完整文件可直接参考下方示例）：

```moonbit
fn main {
  let low = match @fuzzy.triangle("low", 0.0, 0.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("could not construct low set")
  }
  let high = match @fuzzy.triangle("high", 0.0, 10.0, 10.0) {
    Ok(value) => value
    Err(_) => abort("could not construct high set")
  }
  let temperature = match @fuzzy.variable("temperature", 0.0, 10.0, [low, high]) {
    Ok(value) => value
    Err(_) => abort("could not construct input")
  }
  let fan = match @fuzzy.variable("fan", 0.0, 100.0, []) {
    Ok(value) => value
    Err(_) => abort("could not construct output")
  }
  let cool = match @fuzzy.rule(@fuzzy.is_set("temperature", "low"), @fuzzy.sugeno_constant("fan", 20.0), 1.0) {
    Ok(value) => value
    Err(_) => abort("could not construct rule")
  }
  let warm = match @fuzzy.rule(@fuzzy.is_set("temperature", "high"), @fuzzy.sugeno_constant("fan", 80.0), 1.0) {
    Ok(value) => value
    Err(_) => abort("could not construct rule")
  }
  let controller = match @fuzzy.system([temperature], [fan], [cool, warm], @fuzzy.min_max_connective()) {
    Ok(value) => value
    Err(_) => abort("could not construct controller")
  }
  match controller.infer_sugeno([5.0]) {
    Err(_) => abort("inference failed")
    Ok(outputs) => println(outputs[0].to_string())
  }
}
```

它输出 `50`。完整源代码（含包配置）位于 [`cmd/main/main.mbt`](cmd/main/main.mbt) 与 [`cmd/main/moon.pkg`](cmd/main/moon.pkg)。该示例会在 CI 中通过 `moon run --target wasm cmd/main` 执行。

## 限制与非目标

- 不支持 FCL / IEC 61131-7 文件导入导出、持久化模型格式、规则学习/优化、统计不确定性或自动校准。
- 目前没有实时性、数值稳定性或嵌入式内存用量保证；Mamdani 运行成本随规则数、输出变量数和分辨率增长。
- 尚未建立 native、JS、wasm-gc 等完整目标矩阵，也没有真实云端 CI。
- 当前示例是集成路径演示，不是硬件控制器或工业安全验证。

## 许可、设计来源与 AI 使用

项目代码使用 Apache-2.0，见 [`LICENSE`](LICENSE)。实现按公开的 Mamdani/Sugeno 模糊推理概念编写；没有复制 `fuzzy_match` 或 `fuzzyscore.mbt` 的代码。数学设计参考 Mamdani 与 Assilian 的模糊逻辑控制实验（[DOI](https://doi.org/10.1016/S0020-7373(75)80002-2)），以及 Takagi 与 Sugeno 的系统辨识模型（[DOI](https://doi.org/10.1109/TSMC.1985.6313399)）；这些是算法背景来源，不是复制代码的许可。项目不依赖 scikit-fuzzy 或 MoonBit fuzzy string-matching 包，也未移植其实现。AI 辅助参与了原型实现、测试和文档编写；代码仍需独立维护审阅。

有限查重范围、相邻项目比较和未完成事项见 [`docs/competition/duplicate-check.md`](docs/competition/duplicate-check.md)。
