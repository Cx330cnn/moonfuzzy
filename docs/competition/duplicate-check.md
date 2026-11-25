# MoonFuzzy 选题查重记录

检查日期：2026-11-25。账号/目标命名空间：Cx330cnn。状态：范围受限的语义审查，尚未取得完整唯一性结论，也不代表赛事官方裁决。

## 候选比较

| 领域 | 用户—输入—处理—结果闭环 | MoonBit 邻近 | 判断 |
| --- | --- | --- | --- |
| 模糊控制推理 | 控制/仿真开发者定义连续变量、语言集合和规则；执行隶属度计算、规则激活/聚合与解模糊；返回连续控制量和解释信息 | MoonCakes 中 fuzzy_match 提供字符串 Query、匹配索引/评分/搜索；fuzzyscore.mbt 实现 VS Code 风格的子序列匹配评分与高亮。输入为字符串、输出为文本匹配与排序，不是语言变量/模糊规则推理 | 继续实现，但继续查重与发布前复核仍是门禁 |
| UCUM / 物理单位 | 集成开发者解析单位表达式并归一化、换算 | `impart563/moonucum`（UCUM）及 `FrozenLemonTee/LunarUnits` | 淘汰：有直接/高度重叠项目，优先参与上游 |
| 生存/可靠性分析 | 医疗/可靠性使用者提供删失/失效观测，估计生存或寿命指标 | `Lyl66655/moon-survival` 与 `wcx789ll/moon-reliability` | 淘汰：直接/高度相邻实现使另起炉灶依据不足 |

## MoonFuzzy 邻近项目检查

- `moonbit-community/fuzzy_match` 的 MoonCakes 文档（检查日在线版本 0.2.6）列出 `Query::matching_indices`、`score`、`search`、`split_by_matching_sections`、`is_match` 等接口；文档说明其上游为 Jane Street `fuzzy_match`。文档源码清单包含实现和对应 `_wtest.mbt` 文件。README 与公开接口都将任务限定在字符串匹配/搜索。
- `moonbit-community/fuzzyscore.mbt` 的仓库 README 将其定位为 VS Code fuzzyScore 的 MoonBit 移植，提供子序列匹配、分数和字符位置。不是模糊集合/模糊逻辑推理。
- MoonBit 官方社区 awesome-moonbit 的 Libraries 清单也将 `fuzzy_match` 放在文本、数据和解析类目，并称其用于 fuzzy string matching/searching。
- 上述项目的实际文档/API和测试清单被用于区分任务语义；没有将仓库星数、下载量或标题作为唯一判据。当前复核仍未对其所有源码逐行审计，也未穷尽所有可能的私人/新建项目。

## 搜索范围和限制

- 查重词覆盖 `fuzzy`、`Mamdani`、`Sugeno`、`fuzzy logic`、`fuzzy control`、`membership`、`defuzzify`、`inference`、`UCUM`、`units`、`survival`、`Kaplan`、`Weibull`，并查询 MoonCakes、GitHub 和 awesome-moonbit。
- 使用比赛助手 `Milky2018/osc2026-guide` 的 Project Research Guide 作为检索指导；它不是权威重复判定。
- 结果链接：
  - https://mooncakes.io/docs/moonbit-community/fuzzy_match
  - https://github.com/moonbit-community/fuzzyscore.mbt
  - https://github.com/moonbitlang/awesome-moonbit
  - https://github.com/Milky2018/osc2026-guide
- 许可证/上游源码边界仍需在依赖或复制代码前逐项核查。本项目当前没有依赖上述 fuzzy 项目，也没有复制其代码或夹具。采用的是 Mamdani/Sugeno 公开数学概念，后续应补可追溯的教材/论文/参考实现出处。

## 语义矩阵

| 项目 | 主要用户任务 | 输入 | 核心行为 | 输出 | 与 MoonFuzzy 关系 |
| --- | --- | --- | --- | --- | --- |
| fuzzy_match | 文本搜索/候选排序 | 查询字符串、字符串项 | 字符级匹配、分数、匹配索引/片段 | 文本命中/排序 | 同为 fuzzy 一词；问题域和数学模型不同 |
| fuzzyscore.mbt | 编辑器/命令面板模糊检索 | pattern 与 word | 动态规划子序列评分、高亮位置 | 分数与字符位置 | 文本检索工具，不实现控制推理 |
| MoonFuzzy（本项目） | 连续控制/仿真规则推理 | 数值、语言集合、规则 | 隶属函数、t/s 范数、前件树、Mamdani/Sugeno | 连续数值及规则激活解释 | 规则驱动模糊推理 |

## 有界范围与结论

目标是可嵌入 MoonBit 控制/仿真的规则式推理引擎，而非字符串匹配、概率分布拟合、单位解析、可靠性估计或自动规则学习。当前实现是原型：已有 Mamdani 采样质心、Sugeno 加权平均、常见隶属形状、规则激活诊断和独立采样解模糊策略；还未达完整交付门槛。

截至本记录覆盖的已知索引和相邻项目，没有发现成熟的 MoonBit Mamdani/Sugeno 推理实现。该有限结论不等于绝对唯一，也不足以单独放行发布。发布前还须反向检索核心 API/行为、重查 MoonCakes 与 GitHub 新近项目、完整核对上游设计依据，并更新本记录。
