# MoonFuzzy

MoonFuzzy 是一个以 MoonBit 编写的模糊推理库原型，当前代码覆盖三角形/梯形/单点隶属函数、AND/OR/NOT 前件树、加权规则、Mamdani 采样质心和 Sugeno 常数/线性后件。

> 当前为未发布原型：还没有公开仓库、MoonCakes 版本、稳定 CLI/安装示例或多目标 CI。请不要将当前预留状态视为赛事交付完成。

## 适用任务

控制器与仿真代码可以把温度、负载、误差等连续输入映射到可解释的语言变量（例如“低/中/高”），再用规则得到输出。与模糊字符串匹配不同，本项目的核心是隶属度、规则激活、聚合及解模糊。

预期复用方包括控制/嵌入式程序、仿真和教学工具、以及需要可解释规则映射的 MoonBit 服务。以上是目标用户类别，不代表已完成用户访谈或生产环境验证。

## 当前实现

- 通过 `triangle`、`trapezoid`、`singleton` 构造集合；非法顺序、空名称与退化域会返回错误。
- 用 `LinguisticVariable` 组织域与集合；规则前件支持命名集合、最小/积 t-范数、最大/概率和 s-范数、补集、AND/OR。
- `infer_mamdani` 用有界采样聚合输出并计算离散质心。
- `infer_sugeno` 支持常数及一阶线性后件的加权平均。
- 当前暂不提供 FCL/IEC 61131-7 导入导出、持久化格式、自动规则学习、不确定性统计、定时实时性保证或专用嵌入式后端。

## 检查

使用 MoonBit 0.1.20260920 工具链时：

```sh
moon info
moon fmt
moon check --target wasm --deny-warn
moon test --target wasm --deny-warn
```

目前五项白盒测试覆盖三角隶属边界、输入构造错误以及 Sugeno 混合后件。Mamdani 推理路径仍需独立的黄金向量与边界测试；目前只完成类型检查，不能据此宣称该路径已验证。

## 快速示意

```moonbit
let hot = triangle("hot", 0.0, 10.0, 20.0)
let grade = hot.membership(15.0) // 0.5
```

完整、可复制的客户端示例、精确安装版本、CLI 工作流和 wasm/js/native CI 尚未交付，故本原型不承诺跨项目安装或跨后端可用性。

## 许可与来源

本仓库使用 Apache-2.0。实现以 Mamdani/Sugeno 模糊推理的公开数学定义为设计基线；没有复制 scikit-fuzzy 源代码或测试数据。MoonBit fuzzy-match 等项目属于字符串相似检索，不是本项目的推理模型。AI 辅助用于原型代码、测试与文档；代码需由维护者继续复核。

