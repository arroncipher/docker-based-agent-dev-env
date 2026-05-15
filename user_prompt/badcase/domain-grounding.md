为什么 agent 在 domain artifact 的命名/标签中使用 framework 词汇（如"不变量"、"系统接口"、"闭环"），而非业务域词汇（如"行情"、"复权"、"停牌"、"合规边界"）？

---
一、直接原因（在 reasoning 行为里）

framework-vocabulary bias 的直接表现：

- 对 marketdata 制品做分析时，reasoning 过程中调用系统论/控制论词汇（系统边界、不变量、反馈回路），这些词汇随后渗透进 artifact 的命名层
- 最终输出中出现 "行情数据治理不变量"、"market-data 系统接口契约" 等混合命名——framework 词汇停在 output，未完成向 domain 词汇的转换
- 用户的期望命名是 domain-native 的：行情合规追溯、停牌数据一致性、复权计算边界

---
二、提示词归因

不是单一提示词，是四条规则联合作用 + 一条缺位的合成。

致因 1：thinking-frameworks 是显式要求

  meta-rules.md 末尾要求：
  ▎ "Apply these frameworks where relevant. 系统论 / 控制论 / 信息论 / 认识论 / 混沌系统"
  ▎ "Each framework must appear in derived targets with both its Chinese and English form"

  效果：模型在 reasoning 时主动调用这些框架的 vocabulary（系统边界、不变量、形式化、闭环），这些 vocabulary 自然渗透到 output 的命名层。框架是 reasoning tool，但 output 命名时未被显式驱赶回 domain vocabulary。

致因 2：concept-clarity 偏好 well-defined existing terms

  ▎ "Every key term in the agent's output must be precisely defined with clear intension and extension"

  效果：使用 framework 词汇（"不变量"、"系统接口"）有 formal-methods / systems-theory 教科书定义可援引；使用 marketdata domain 自创术语（"行情数据治理与追溯保证"）需要自己定义。concept-clarity 实际偏向有教科书源的 framework 词汇，对 domain coining 不友好。

致因 3：precision 偏好 well-established 术语

  ▎ "Prefer exact, well-defined terms over readable but ambiguous phrasing"

  效果：framework 术语"精确"——"invariant" 是 Hoare 1969 formal definition；"system boundary" 是 systems theory 标准术语。Business terms "行情数据治理" 在 marketdata 工程社区有共识但没有正式定义。precision 推向 framework 术语。

致因 4：peer-level 默认 engineer 视角

  ▎ "Do not explain concepts the user is likely to know. Engage at peer level."

  用户画像（context.md）："独立技术顾问、面向生产的软件架构师、AI-native 工程从业者"。

  效果：peer-level 解读为 engineer-to-engineer，模型默认用 software engineer vocabulary（架构、不变量、接口），不是 marketdata domain expert vocabulary（行情、复权、停牌、合规边界）。

缺位：domain-vocabulary 规则

  meta-rules.md 没有规则说："当 artifact 服务特定业务域时，最终命名/标签应使用该业务域 vocabulary，不是 reasoning 用的 framework vocabulary。"

---
三、共同模式

与 abstraction-discipline（纵向层错位）同构的横向 register 错位：

  ┌──────────────────────────────────────┬────────────────────────────────────────────────────────────────────┐
  │ 维度                                 │ 错位                                                               │
  ├──────────────────────────────────────┼────────────────────────────────────────────────────────────────────┤
  │ 纵向（abstraction-discipline §3.8）  │ reasoning 用 framework → output 下沉到 mechanism（应停在 goal）    │
  │ 横向（domain-grounding §3.14）       │ reasoning 用 framework → output 停在 framework vocab（应转到 domain）│
  └──────────────────────────────────────┴────────────────────────────────────────────────────────────────────┘

两次都是"reasoning 工具 ≠ output destination"这一前置假设的缺失。

---
四、修复

spec v1.0.12 新增 §3.14 domain-grounding（claude.rules.meta-rules.md.prompt v1.0.5）：

  思维框架（系统论、控制论、信息论、认识论、混沌系统）以及软件工程抽象（架构、不变量、系统边界、契约）是推理工具，不是命名终点。当制品服务于特定业务域（如 marketdata、医疗）时，最终命名/标签必须使用该业务域的词汇，而非推理过程中使用的分析框架词汇。完成转换：framework → 工程抽象 → domain 词汇。通过制品的主要受众与用途识别语域：面向特定业务域的团队内部文档使用业务域词汇；跨域参考模板使用工程抽象词汇；纯分析性写作框架词汇可接受。框架在推理链中保持可见（遵循现有规则），但不得出现在制品的用户可见命名/标题中，除非受众明确要求使用框架语域。

---
五、一句话结论

直接成因是 thinking-frameworks 显式要求 + concept-clarity/precision 对有教科书定义的术语的系统性偏好，联合驱动 framework vocabulary 渗透进 domain artifact 命名层；结构成因是 meta-rules.md 缺 domain-grounding 规则；与 abstraction-discipline 缺位的深层结构相同：reasoning 工具被误用为 output destination。
