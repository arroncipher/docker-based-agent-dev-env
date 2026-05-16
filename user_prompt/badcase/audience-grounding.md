为什么 agent 在面向团队的制品中强制暴露 thinking framework 词汇（如"系统论分析"、"认识论视角"），而非面向制品实际受众使用工程语言？

---
一、直接原因（在 reasoning 行为里）

audience-register mismatch 的直接表现：

- 制品受众是特定团队（marketdata 工程师、医疗数据团队），但 agent 用 prompt-giver 的智识风格（framework 分析语域）写制品内容
- 最终输出中出现"系统论视角下的行情数据治理"、"认识论框架对复权计算的约束分析"等表述——框架词汇不是在 reasoning 链中辅助推理，而是作为制品结构标签出现
- 制品实际受众需要的是操作性工程语言：数据可追溯性要求、复权精度保证、停牌窗口一致性

---
二、提示词归因

不是单一提示词，是三条规则联合作用 + 一条缺位的合成。

致因 1（主因）：Thinking Frameworks 的 "must appear in derived targets" 要求

  meta-rules.md §4 末尾：
  ▎ "每个框架在派生目标中必须以中英双语形式出现，与上方列出的完全一致。"

  效果：这条规则要求框架必须出现在"派生目标"（derived targets）中。agent 将"派生目标"等同于"制品"，因此把框架名称强制写入所有输出——包括面向团队的内部文档、domain-specific 的命名/标签。框架从 reasoning tool 变成了 output obligation。

致因 2：peer-level 默认映射到 prompt-giver 的知识层次，而非制品受众

  ▎ "不解释用户可能已知的概念。以同行视角参与交流。"
  用户画像（context.md）："独立技术顾问、面向生产的软件架构师、AI-native 工程从业者"。

  效果：peer-level 解读为"与 prompt-giver 同层"——prompt-giver 是架构师/工程顾问，使用 framework 分析语域是合理的。但制品受众是团队成员，读 framework 词汇是认知负担，不是 peer 沟通。peer-level 没有区分"与 prompt-giver 同层"和"与制品受众同层"。

致因 3：concept-clarity 偏向有教科书定义的 framework 术语

  ▎ "the agent 输出中的每个关键术语必须具备精确的内涵与外延，不得依赖模糊共识。"

  效果：framework 术语有明确出处（Bertalanffy 系统论、Shannon 信息论）；操作性工程术语（"复权窗口一致性"、"行情追溯截止点"）缺乏教科书级定义，concept-clarity 对此不友好。同 domain-grounding §3.14 的致因 2。

缺位：audience-grounding 规则

  meta-rules.md 没有规则说："制品的 register 应匹配制品的实际受众，而非 prompt-giver 的分析语域；框架词汇仅合法出现在 prompt-giver 明确要求 framework 分析的输出中。"

---
三、共同模式

与 abstraction-discipline（纵向层）、domain-grounding（横向域）同构的第三维 register 错位：

  ┌──────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────┐
  │ 维度                                     │ 错位                                                                               │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ 纵向（abstraction-discipline §3.8）      │ reasoning 用 framework → output 下沉到 mechanism（应停在 goal）                    │
  │ 横向域（domain-grounding §3.14）         │ reasoning 用 framework → output 停在 framework vocab（应转到 domain）              │
  │ 横向受众（audience-grounding，缺位）     │ reasoning 对应 prompt-giver 语域 → output 停在 prompt-giver 语域（应转到制品受众语域）│
  └──────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────┘

三次都是同一个深层缺位：reasoning 使用的工具（框架、分析语域）不等于 output 应当着陆的 register。"reasoning 工具 ≠ output destination"这一前置假设始终缺位。

---
四、修复

spec v1.0.13 做两处改动（claude.rules.meta-rules.md.prompt v1.0.6）：

Option A 实施——修改 §4 Thinking Frameworks closing clause：
  将"每个框架在派生目标中必须以中英双语形式出现"改为明确"派生目标"指配置文件（meta-rules.md、AGENTS.md），不适用于 agent 工作中产出的制品；并显式声明框架不得出现在 agent 产出的输出单元的用户可见命名/标题中（引用 §3.15）。

Option B 实施——新增 §3.15 output-register-discipline：
  在产出任何将被实际消费者使用的输出单元时——包括文档、代码、变量名/注释、命名实体（API 端点、metric 名称、配置键名、章节标题等）——识别三个维度并使 output 着陆于匹配的 register：抽象层（goal / structure / mechanism / implementation，匹配输出类型不得漂移，见 §3.8）；域 register（framework / 工程抽象 / domain-specific，当输出服务特定业务域时完成向 domain 词汇的转换，见 §3.14）；受众 register（prompt-giver / 团队 / 公众，匹配输出的实际受众，不得默认映射到 prompt-giver 的分析语域）。思维框架与工程抽象是推理工具，不是 output destination；output 应着陆于输出类型 + 域 + 受众共同决定的 register，而非 reasoning 方便的 register。豁免：若实际受众就是当前 prompt-giver（如对话中 prompt-giver 明确要求 framework 级分析），此规则不触发，framework 词汇合法。任一维度不明确且输出单元非平凡时，须先提问再产出。

Option C（项目级，domain-specific CLAUDE.md 覆盖）：待用户在各具体项目中决定是否实施；属项目级配置，不在 spec 范围内。

---
五、一句话结论

主因是 Thinking Frameworks 的 "must appear in derived targets" 条款将框架从 reasoning tool 变成 output obligation，联合 peer-level 默认映射到 prompt-giver 语域（而非制品受众）和 concept-clarity 对 framework 术语的系统性偏向；结构成因是 meta-rules.md 缺 audience-grounding 规则；与 abstraction-discipline / domain-grounding 共享同一深层缺位：reasoning 工具被误用为 output destination。
