# MoonFuzzy 选题查重记录

检查日期：2026-11-25。账号/目标命名空间：Cx330cnn。当前状态：初步检索并预留；非完整语义审计，非唯一性结论。只读检索材料存放于 `C:/Users/42673/.codex/competition-deliverables/Cx330cnn/moonfuzzy/evidence/`。

## 需求和比较候选

| 领域 | 用户—输入—处理—结果闭环 | MoonBit 邻近 | 判断 |
| --- | --- | --- | --- |
| 模糊控制推理 | 控制开发者输入变量、语言集合和规则；引擎计算隶属度、激活规则、聚合及解模糊；得到可解释的连续控制量 | `moon search fuzzy --limit 100` 找到字符串匹配、fuzzy ranking/search；`Mamdani`、`Sugeno`、`defuzzify` 零结果；GitHub 查询 `fuzzy language:MoonBit` 命中字符串搜索类仓库 | 初步入选。语义方向不同；仍需对搜索结果候选实际源码/API进一步复核，并扩充检索和行为测试 |
| UCUM / 物理单位 | 数据集成方输入 UCUM 单位表达式；解析/归一化/量纲换算；得到一致数量 | `impart563/moonucum`（UCUM 2.2）及 `FrozenLemonTee/LunarUnits`；registry 已记录既有直接实现 | 淘汰：直接功能重叠，优先贡献上游 |
| 生存/可靠性分析 | 医疗/可靠性数据使用者输入删失时间/失效样本；拟合/生存估计；输出曲线和寿命指标 | `Lyl66655/moon-survival` 与 `wcx789ll/moon-reliability`；`moon search survival --limit 100` 已返回此类包 | 淘汰：成熟直接或高度相邻实现，独立重做价值不足 |

## 检索记录与设计基线

- 已运行比赛助手 `osc2026-guide` 的 Project Research Guide：本地 `moon search`，并查询 MoonCakes 与对应 GitHub 项目元数据。
- 模糊候选扩词：`fuzzy`、`Mamdani`、`Sugeno`、`fuzzylite`、`fuzzy logic`、`fuzzy control`、`membership`、`defuzzify`、`inference`；GitHub 查询覆盖 MoonBit fuzzy 和精确 Mamdani/Sugeno/fuzzylite。
- 其他候选查询：`UCUM`、`units`、`dimensional`、`survival`、`Kaplan`、`Weibull`。Moon 搜索结果存于上述 evidence 目录。
- 跨生态行为基线：scikit-fuzzy 提供 Python 模糊控制工作流参考；本实现仅采用通用数学概念，未复制代码/夹具。许可证和各上游实际源码文件尚未逐项审查；不将该依赖纳入构建。
- 已读永久项目注册表相关边界：MoonNormal 为正态概率分布/分位数/估计类库，与规则驱动模糊推理在输入模型和输出任务上不同；MoonSearch/fuzzy_match/fuzzyscore 处理文本检索排名，不实现集合隶属规则系统。

## 范围、矩阵和差异

本项目拟交付规则式模糊推理引擎，而非 fuzzy string matching、统计分布估计、单位解析、可靠性拟合。主要数据模型为有界语言变量、三角/梯形/单点集合、组合前件树与 Mamdani/Sugeno 后件。目标核心是规则解释、确定性数值结果和可复用库 API。

直接重叠：在已知 registry 指纹和上述有限索引结果中，未发现成熟的 MoonBit Mamdani/Sugeno 推理包。相邻但不同：模糊文本匹配（相似度/检索）；MoonNormal（概率分布）；通用数值/控制算法集合。该结论受搜索索引、分页和时间限制约束，不是对生态完整性的证明。

## 阶段性结论与缺口

选题可作为有界原型继续研究。仍需：读取模糊搜索相邻包的 README、源码、测试与接口；检查 MoonBit 官方/社区清单；对公开 API 名与核心行为反向检索；为 Mamdani 建立可信参考向量、边界/未触发规则测试；补足真实下游示例。未完成这些检查前不得将查重标为通过或发布。
