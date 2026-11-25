# MoonFuzzy

MoonFuzzy 是面向 MoonBit 的模糊推理库原型：把连续数值、语言变量、隶属集合与 IF–THEN 规则组合起来，计算 Mamdani 或 Sugeno 输出。它处理的是模糊逻辑控制，不是 fuzzy string matching（文本模糊搜索）。

> **交付状态（2026-11-25）：**项目尚未发布；没有可安装的公开版本、GitHub CI 结果、GitHub Release 或 MoonCakes 版本。`Cx330cnn/moonfuzzy` 是预期命名空间，不表示仓库已创建。当前本地工具链已通过 WASM 目标检查/测试与示例运行。

## 适用场景与用户

- 控制/仿真开发者：将温度、误差、负载等传感器值映射为“低/中/高”，再用规则推导连续控制量。
- MoonBit 应用开发者：在业务代码中内嵌小型、确定性的规则推理，而不是为几条规则自己维护一套隶属度、聚合及加权平均逻辑。
- 教学与算法验证：逐条检查前件激活强度，观察输入扰动和规则权重对结果的影响。

这些是根据库功能界定的目标使用者，不是已经完成访谈或生产部署的用户证据。

## 当前功能

- 三角形、梯形、单点、Gaussian、Sigmoid、左肩形和右肩形隶属函数；形状参数进行基本校验。
- 有界语言变量、批量 fuzzify 与并列最大标签查询。
- `AND`、`OR`、`NOT` 前件树；minimum/product/max/probabilistic-sum 连接策略。
- 加权规则；按规则索引返回原始与加权激活值，便于调试解释。
- Mamdani：采样输出域、最小蕴涵/最大聚合、离散质心解模糊。
- Sugeno：零阶常数与一阶线性后件的加权平均。
- 对外部采样曲线提供梯形积分意义下的质心、面积平分近似和最大隶属度均值解模糊函数。

`defuzzify` 是采样数组工具；当前 Mamdani system API 固定采用质心。解模糊工具中的 Bisector 通过离散梯形段面积累计，并在线性坐标比例上近似段内位置，不声称解析精确。

## 本地运行

需要 MoonBit 工具链；已验证版本 `0.1.20260920`。当前无公开模块版本，请在本地仓库根目录运行：

```sh
moon info
moon fmt
moon check --target wasm --deny-warn
moon test --target wasm --deny-warn
moon run --target wasm cmd/main
```

示例构造一个温度到风扇命令的 Sugeno 控制器；输入 `5.0` 时，两条规则等强激活，输出 `50`。示例源代码位于 [`cmd/main/main.mbt`](cmd/main/main.mbt)。当前测试集包括隶属函数边界/方向、参数错误、Mamdani 对称质心、Sugeno 混合后件、规则激活诊断及采样解模糊边界。

## 下游接入（尚未发布）

包名计划为 `Cx330cnn/moonfuzzy`，清单版本目前为 `0.1.0`，但该版本**尚未发布**，不应在新消费者中尝试安装。发布门槛满足后，本节将更新为精确安装命令并在干净、无凭据消费者环境中验证。

## 限制与非目标

- 不支持 FCL / IEC 61131-7 文件导入导出、持久化模型格式、规则学习/优化、统计不确定性或自动校准。
- 目前没有实时性、数值稳定性或嵌入式内存用量保证；Mamdani 运行成本随规则数、输出变量数和分辨率增长。
- 尚未建立 native、JS、wasm-gc 等完整目标矩阵，也没有真实云端 CI。
- 当前示例是集成路径演示，不是硬件控制器或工业安全验证。

## 许可、设计来源与 AI 使用

项目代码使用 Apache-2.0，见 [`LICENSE`](LICENSE)。实现按公开的 Mamdani/Sugeno 模糊推理概念编写；没有复制 `fuzzy_match` 或 `fuzzyscore.mbt` 的代码。正式发布前会补足可追溯的数学参考资料及上游许可证审查。AI 辅助参与了原型实现、测试和文档编写；代码仍需独立维护审阅。

有限查重范围、相邻项目比较和未完成事项见 [`docs/competition/duplicate-check.md`](docs/competition/duplicate-check.md)。
