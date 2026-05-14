# TODO · Agent 配置派生 pipeline

单文件进度追踪，涵盖从 prompt 可重放性验证到生产 promote 再到治理的完整执行历史，
以及当前开放缺口。

---

## Phase 0 · codex.AGENTS.md prompt 可重放性验证 ✅ 2026-05-13

**目标**：验证 `prompts/codex.AGENTS.md.prompt` 在 fresh session 中重放，输出与
`runs/2026-05-12_codex.AGENTS/output.md` 实质等价（L3 语义等价）。

- [x] 1. 在 fresh session（codex-cli + claude-code 两族）重放 prompt
      → 实际用 `codex_plus.sh exec --ignore-user-config` + `claude_max20.sh -p --output-format stream-json`
        替代手动粘贴；结果存 `runs/2026-05-12_codex.AGENTS_replay/`
- [x] 2. 保存模型输出，去掉对话前后语
- [x] 3. 记录 notes.md（model id、replay 方式、异常）
- [x] 4. strength × mode audit（bash，7 条 meta-rule verbatim、5 框架中英、§7 constraints、§9 drift=0）
- [x] 5. REPORT.md 写明 PASS → baseline 替换为 fresh replay（`output.tainted.md` 归档旧版本）

**后续**：
- [x] 构建余下 4 份 prompt（见 Phase A）
- [x] 长度预算：TARGET block 和 SELF-CHECK block 均已更新至 6000 字符

---

## Phase A · 余下 4 份 prompt 全跑通 ✅ 2026-05-13

每个节点完整流程：写 prompt → fresh-session replay → strength × mode audit → REPORT.md。

### A1. ~~codex.profiles.engineering.md prompt~~ ✅ PASS 2026-05-13

**验收目标**
- `prompts/codex.profiles.engineering.md.prompt` 存在，四段结构（VERBATIM LOCK /
  ANTI-PATTERNS / SELF-CHECK / OUTPUT）齐全，spec-version-required 标注一致。
- `runs/2026-05-13_codex.profiles.engineering_replay/codex/output.md` 存在；audit：
  - §3 七条 meta-rule verbatim ✓、§4 五框架中英双语 ✓、§7 engineering 子集 ✓、§9 drift=0 ✓
- REPORT.md 标明 PASS。

---

### A2. ~~codex.profiles.market-data.md prompt~~ ✅ PASS 2026-05-13

**验收目标**：同 A1 结构；output 覆盖 §3、§4、§5 business domain 子集、§7。PASS。

---

### A3. ~~codex.profiles.education.md prompt~~ ✅ PASS 2026-05-13

**验收目标**：同 A1 结构；§6.1 child-education 以 mode=summarized 派生，三条规则保留
（developmental-stage / transferable exercises / challenge-pedagogy）。PASS。

---

### A4. ~~claude.CLAUDE.md prompt~~ ✅ PASS (soft: §3 line-wrap) 2026-05-13

**验收目标**：target-file 标 `~/.claude/CLAUDE.md`；replay 用 `claude_max20.sh -p
--output-format stream-json`（**禁 `--output-format text`，会挂死**）；§1–§9 全集覆盖。
PASS，软偏差：§3 rule body 单行化（内容 byte-identical，markdown 渲染一致）。

---

## Phase B · Promotion ✅ 2026-05-13

### B1. ~~替换 codex.AGENTS baseline 为 fresh replay~~ ✅ DONE 2026-05-13

`runs/2026-05-12_codex.AGENTS/output.md` 替换为 claude fresh replay（5579B）；
旧版本归档为 `output.tainted.md`（5475B）；notes.md 追加 changelog。

---

### B2. ~~Promote 5 份验证通过的 output 到生产位置~~ ✅ DONE 2026-05-13

| 目标 | 大小 | 备份 |
|---|---|---|
| `.coding_agents/codex_plus/.codex/AGENTS.md` | 5579B | `AGENTS.pre-2026-05-13.md` |
| `.coding_agents/codex_plus/.codex/profiles/engineering.md` | 4582B | `.pre-2026-05-13.md` |
| `.coding_agents/codex_plus/.codex/profiles/market-data.md` | 3269B | `.pre-2026-05-13.md` |
| `.coding_agents/codex_plus/.codex/profiles/education.md` | 4109B | `.pre-2026-05-13.md` |
| `.coding_agents/claude_max20/.claude/CLAUDE.md` | 5223B | `.pre-2026-05-13.md` |

---

### B3. ~~清理废弃 profiles~~ ✅ DONE 2026-05-13

`agentic-engineering.md` / `product.md` / `concept-learning.md` 移入
`.codex/profiles/.archive_2026-05-13/`；AGENTS.md Optional Profiles 与剩余三个文件一一对应。

---

### B4. ~~End-to-end 烟测~~ ✅ PASS 2026-05-13

结果存 `runs/2026-05-13_smoke/`。两边各跑一条市场数据延迟分析 trigger prompt：

| 检查项 | codex (gpt-5.5) | claude (sonnet-4-6) |
|---|---|---|
| 5 框架中英双语 | ✓ (1074 中文字符) | ✓ (621 中文字符) |
| §9 drift token | 0 | 0 |
| structure-first | ✓ | ✓ |
| challenge-assumptions | ✓ | ✓ |

已知局限：单 prompt 样本、无 promote 前后基线对比。
行为门控四场景完整测试见 `runs/2026-05-13_behavior/REPORT.md`（缺口 B）。

---

## Phase C · 治理

### C1. ~~`.gitignore` 拆细~~ ✅ DONE 2026-05-13

`user_prompt/runs/` 和 `user_prompt/out/` 继续忽略；`spec/` `prompts/` `README.md`
`TODO*.md` 入库（不再整行忽略 `user_prompt`）。

---

### C2. ~~README 补 working flag sets~~ ✅ DONE 2026-05-13

README §8 新增 codex/claude 隔离 replay 完整命令、`--output-format text` 挂死警告、
cwd 选择说明；§9 操作流程改为 wrapper 一键跑 + bash audit 自动化。

---

### C3. ~~TODO/workflow 刷新 + spec 变更流程~~ ✅ DONE 2026-05-13

README §10 新增 spec 变更 → 重派生流程（触发条件 / 操作步骤 / 已知 TODO）。

---

### C4. ~~README 改中文~~ ✅ DONE 2026-05-13

README 已重构为带编号中文章节（§1–§13），技术术语保留英文形式，
代码块内 bash 为英文（预期）。全部标题和叙述文本为中文，验收目标满足。

---

## 开放缺口（已全部关闭）

### ~~缺口 1~~ ✅ DONE 2026-05-13

`prompts/codex.AGENTS.md.prompt` SELF-CHECK block 第 152 行 `4000` → `6000`，与
TARGET block 一致。

### ~~缺口 2~~ ✅ DONE 2026-05-13

选 option b：删除 README §9 步骤 6 中 `out/` 复制描述（`out/` 为 gitignored 中间层，
无实质价值）；promote 直写部署路径，`out/` 保留 `.gitkeep` 供后续需要时启用。
同步修正 README §2 层一和 §6 中的两处残留 `out/<target>` 引用。

### ~~缺口 A~~ ✅ DONE 2026-05-13

README §2 层一（`out/<target>` → `部署路径`）和 §6（删除 `out/<target>` 引用）两处修正。
缺口 2 的修复现在完整。

### ~~缺口 B~~ ✅ DONE 2026-05-13

首次部署行为门控四场景全部执行并通过（claude + codex 两边）：
- challenge-assumptions ✓（B4 smoke 已覆盖）
- no-default-hedging ✓（"10 万 req/s 能撑住吗"触发，两边均明确说明不确定来源，零软着陆）
- peer-level ✓（"CAP 定理意味着什么"触发，两边均直接挑战框架有效性，无定义铺垫）
- §4 frameworks 改变结论 ✓（"微服务越细越好吗"触发，两边均从各框架导出不同具体推论）

结果存 `runs/2026-05-13_behavior/REPORT.md`。

### ~~缺口 C~~ ✅ DONE 2026-05-13

README §2 层二结果记录位置说明更新：端到端行为测试 → `runs/<date>_behavior/REPORT.md`；
单 target 定向回归测试 → 该 target run notes。
AGENTS.md 和 CLAUDE.md 的 run notes 中加入行为测试结果指针。

---

## Spec 变更记录

### v1.0.9 · 2026-05-14 · 新增 §3.12–§3.13 epistemology 规则

**触发**：认识论 (epistemology) 框架下识别出两个独立的推理约束缺口，由用户主动分析提出。

**变更**：
- spec §3 新增 §3.12 `entity-binding`（每个关系型实体引用须绑定可验证维度；
  触发条件用替换测试，维度列表为例示非规范）
- spec §3 新增 §3.13 `inferential-validity`（结论须有前提/证据支撑；非演绎推理须
  显式标注；禁止 6 类无效跃迁含 part→whole）
- spec §9 追加 4 条对应 anti-patterns

**处理方式**：spec v1.0.9 + `claude.rules.meta-rules.md.prompt` v1.0.3 →
fresh-session replay + Phase G audit PASS (4122 chars / 4200 budget) →
4 个 Claude 账号 promote（`de70d927…`，4162B 均一致）。

**Budget 扩容（2026-05-14）**：prompt length budget 已从 4200 → 5000，
`claude.rules.meta-rules.md.prompt` v1.0.3（两处：TARGET block + SELF-CHECK block）。

---

### v1.0.8 · 2026-05-14 · 新增 §3.9–§3.11 scope-control 规则

**触发**：同一 badcase（abstraction-discipline.md）的同构分析，识别出三类
边界缺口：框架应用门控、review/design 混同、扩展规则叠加效应。

**变更**：
- spec §3 新增 3 条 meta-rule（strength: hard, mode: verbatim）：
  - §3.9 `framework-relevance`：框架仅在改变结论/区分/问题时应用；不自动授权下沉至机制层
  - §3.10 `review-design-separation`：review 任务不得升级为 design 任务
  - §3.11 `convergence-discipline`：扩展规则叠加时以任务类型/制品边界/决策层约束；否定边界不推正向范围
- spec §9 anti-patterns 追加 4 条（§3.9–§3.11 对应失效模式）
- spec §9 sub-rule range 更新至 §3.1–§3.11

**处理方式**：spec v1.0.8 + `claude.rules.meta-rules.md.prompt` v1.0.2 →
fresh-session replay + Phase G audit PASS (3258 chars / 4200 budget) →
4 个 Claude 账号 promote（`3c3f266f…`，3296B 均一致）。

**行为门控**：3 个场景全部 PASS（claude-sonnet-4-6, claude_max20 wrapper），见
`runs/2026-05-14_behavior_meta-rules_v1.0.8/REPORT.md`。

**暂缓**：`example-boundary`、`minimal-sufficient-answer`、
`structure-first` 假设优先级；Codex prompts 下次模型升级重派生时自动覆盖。

---

### v1.0.7 · 2026-05-14 · 新增 §3.8 abstraction-discipline

**触发**：badcase `user_prompt/badcase/abstraction-discipline.md` — 评估制品时跨层
枚举下层机制细节，根因为 meta-rules.md 缺乏作用域收敛规则。

**变更**：
- spec §3 新增 §3.8 `abstraction-discipline`（strength: hard, mode: verbatim）
- derive_to 与 §3.1–§3.7 相同（`codex + claude.rules.meta-rules`）
- spec §9 anti-patterns 更新："Omitting any sub-rule of §3." →
  "Omitting any sub-rule of §3 (§3.1 through §3.8)."

**处理方式**：spec + prompt 同步更新（`claude.rules.meta-rules.md.prompt` v1.0.1）→
fresh-session replay + Phase G audit PASS (2142 chars) →
4 个 Claude 账号 promote（`e86db899…`，2178B 均一致）。

**注意**：codex prompts（§3 同属目标）在下次模型升级重派生时自动覆盖。

---

### v1.0.6 · 2026-05-14 · 新增 3 个 Claude 域拆分 token

**变更**：spec token glossary 与 §5/§6 derive_to 同步扩展：
- 新增 token：`claude.rules.engineering`（path-scoped rule）
- 新增 token：`claude.commands.market-data`（slash command `/market-data`）
- 新增 token：`claude.commands.education`（slash command `/education`）
- §5 derive_to 加入 `claude.rules.engineering` + `claude.commands.market-data`
- §6 derive_to 加入 `claude.commands.education`
- §5 段首加入文字说明：同一段在不同目标渲染不同子集（summary vs 深度）

**处理方式**：spec 编辑 + 3 个新派生 prompt（v1.0.0，spec-version-required: 1.0.6）+
3 次 fresh-session replay + Phase G audit 全 PASS + 4 个账号同步部署。

**部署成果**：
- `.claude/rules/engineering.md` 1376B / `.claude/commands/market-data.md` 1444B /
  `.claude/commands/education.md` 1511B（4 账号 hash 一致）

---

### v1.0.5 · 2026-05-14 · CLAUDE.md 1k 硬上限 + 拆分到常驻 rules

**变更**：用户要求 `CLAUDE.md ≤ 1k`，触发紧急架构变更：
- `CLAUDE.md` 缩至 928B（仅 §2 + §7）
- §3/§4 拆出到 `.claude/rules/meta-rules.md`（常驻）
- §1/§5/§6/§8 拆出到 `.claude/rules/context.md`（常驻）

**spec 变更**（D1 已完成）：
- 新增 token：`claude.rules.meta-rules` / `claude.rules.context`
- `all` token 语义收紧为"entry-point 文件集合"（不含 `claude.rules.*`）
- §1/§5/§6/§8 的 claude 目标重映射至 `claude.rules.context`
- §3/§4 的 claude 目标重映射至 `claude.rules.meta-rules`
- §2/§7 保留 claude（CLAUDE.md），§7 额外注释为不可外移

**处理方式**：rules 文件最初手写部署，随后 D2（同日 2026-05-14）用派生
prompt 走完整 fresh-replay → audit → promote 流程，输出覆盖手写版本。
spec → 派生 → 部署单向链路恢复。手写中间产物归档为 `*.handwritten-2026-05-14.md`。

---

### v1.0.4 · 2026-05-14 · Working contexts 顺序更正

**变更**：`§1 Working contexts` 列表顺序调整，United States 移至首位（主基地）；
原顺序首位为 Singapore，导致模型推断"新加坡（主基地）"，不符合实际。

**处理方式**：直接编辑 spec + 6 个已部署文件（4× CLAUDE.md、2× AGENTS.md）。
§1 是 soft/structured，无需跑完整重派生流程。

---

### v1.0.3 · 2026-05-13 · 学历更正（二次）+ 技术背景补充

**变更**：
- `§1 Education`：MSc 更正为计算机硕士（密码学方向），而非密码学硕士
- `§5 Architecture & engineering`：补入早期技术背景（嵌入式开发、图像处理算法优化）

**处理方式**：同 v1.0.1/1.0.2，直接编辑 spec + AGENTS.md + CLAUDE.md。

---

### v1.0.2 · 2026-05-13 · 学历更正

**变更**：`spec §1 Education` 更正为数学理学士 + 密码学理学硕士（均帝国理工学院，密码学属计算机系）。

**处理方式**：直接编辑 spec + AGENTS.md + CLAUDE.md，同 v1.0.1 处理逻辑。

---

### v1.0.1 · 2026-05-13 · 补充 Germany

**变更**：`spec §1 Working contexts` 加入 Germany（原列表漏写）。

**受影响节**：§1 `derive_to: [all]`, `strength: soft`, `mode: structured`。

**处理方式**：直接编辑 spec + 两个已部署文件（AGENTS.md / CLAUDE.md）。
§1 是 soft/structured，单字段补充无需跑完整重派生流程；三份文件已同步。

profiles（engineering / market-data / education）的 §1 片段不含 Working contexts
字段（各 profile 只派生业务域相关背景，不含完整 identity），无需更新。

---

## Phase E · 部署流程完善

### E1. ~~codex_arron_free 旧 profiles 删除~~ ✅ DONE 2026-05-13

`agentic-engineering.md` / `concept-learning.md` / `product.md` 已直接删除；
`.codex/profiles/` 现仅含 spec-derived 三个 profiles。

### ~~E2. spec 变更同步扩展到所有账号~~ ✅ DONE 2026-05-13

README §9 步骤 6 已明确列出两步 promote（runs/ → 主账号；主账号 → 其他账号），
并逐一枚举全部目标账号（claude_deepseek / claude_minimax / claude_pro /
codex_arron_free）；§10 步骤 5 同步引用 §14.3 步骤一和步骤二。
意图已实现，不需要额外操作。（TODO 中的 §14.5 引用为草稿期笔误，实际对应 §14.3）

### ~~E3. `out/` 填充~~ ✅ 取消 2026-05-13

`out/` 目录已删除。canonical source 由主账号（`claude_max20` / `codex_plus`）承担；
promote 流程改为两步：`runs/` → 主账号 → 其他账号（见 README §14.3）。

---

## Phase D · Claude CLAUDE.md 拆分

Claude 支持将主 `CLAUDE.md` 文件拆分为多个规则文件，这些文件在尝试访问规则
前言（frontmatter）中指定路径的文件时按需加载，优先级与主 `CLAUDE.md` 相同，
但只是按需加载。无 `paths:` frontmatter 的 rules 文件等同于常驻加载
（与 `CLAUDE.md` 优先级一致）。

### D0. 紧急瘦身（1k 硬上限）✅ DONE 2026-05-14

**触发**：用户要求 "claude.md最大不超过1k"，强制立即执行拆分。

**实施**：
- `CLAUDE.md` 缩至 928B（< 1024 上限），仅保留 §2 语言风格 + §7 Hard Constraints
- §3 Meta-rules + §4 Thinking Frameworks → `.claude/rules/meta-rules.md`（1815B，常驻）
- §1 Identity + §5 Domains + §6 Active Projects + §8 Execution Protocol →
  `.claude/rules/context.md`（2221B，常驻）
- 4 个 Claude 账号（max20 / deepseek / minimax / pro）已全部同步：
  - 旧 5270B 单文件 → 928B 入口 + 4036B 常驻 rules 文件
  - 原始备份保留为 `CLAUDE.pre-2026-05-14.md` / `CLAUDE.pre-2026-05-14-thin.md`

**差异**：本次为 always-loaded rules 拆分（紧急瘦身），未实施原计划的
path-scoped + slash-command 域拆分（见 D1–D3，留作后续优化）。

### ~~D1. spec 扩展~~ ✅ DONE 2026-05-14

- [x] 新增 `derive_to` token：`claude.rules.meta-rules` / `claude.rules.context`
      （对应 D0 实际部署的常驻 rules 文件）
- [x] 受影响节标注重映射：§1/§5/§6/§8 → `claude.rules.context`；
      §3/§4 → `claude.rules.meta-rules`；§2/§7 保留 `claude`（CLAUDE.md）
- [x] `all` token 语义收紧为"entry-point 文件集合"（不含 `claude.rules.*`）；
      §2 §7 仍用 `all`，含义为 codex family + claude CLAUDE.md
- [x] spec version 升至 1.0.5（2026-05-14）
- [x] `claude.rules.engineering` / `claude.commands.market-data` /
      `claude.commands.education` token 已加入（spec v1.0.6 2026-05-14）
- [x] §5 derive_to 扩展为 `[codex, codex.profiles.engineering, codex.profiles.market-data, claude.rules.context, claude.rules.engineering, claude.commands.market-data]`
- [x] §6 derive_to 扩展为 `[claude.rules.context, claude.commands.education, codex.profiles.education]`

### ~~D2. 新增派生 prompt~~ ✅ DONE 2026-05-14

- [x] `prompts/claude.CLAUDE.md.prompt` 升至 2.0.0，输出 ≤1024B thin entry
      （仅 §2 + §7）；spec-version-required: 1.0.5
- [x] `prompts/claude.rules.meta-rules.md.prompt` 1.0.0（§3 + §4，常驻 rule）
- [x] `prompts/claude.rules.context.md.prompt` 1.0.0（§1 + §5 + §6 + §8，常驻 rule）
- [x] `prompts/claude.rules.engineering.md.prompt` 1.0.0
      （§5 Architecture & engineering，path-scoped，20 globs 覆盖常见源码与 DevOps 文件）
- [x] `prompts/claude.commands.market-data.md.prompt` 1.0.0
      （§5 Business domain，slash command `/market-data`）
- [x] `prompts/claude.commands.education.md.prompt` 1.0.0
      （§6.1 + §5 Education-system design，slash command `/education`）
- [x] 6 个 prompt 各跑一次 fresh-session replay + structural audit
      - `runs/2026-05-14_claude.rules.meta-rules_G/` — PASS (1814B)
      - `runs/2026-05-14_claude.rules.context_G/` — PASS (1506 chars / 2374B)
      - `runs/2026-05-14_claude.CLAUDE.md_thin_G/` — PASS (842 chars / 952B)
      - `runs/2026-05-14_claude.rules.engineering_G/` — PASS (1000 chars / 1376B)
      - `runs/2026-05-14_claude.commands.market-data_G/` — PASS (733 chars / 1444B)
      - `runs/2026-05-14_claude.commands.education_G/` — PASS (749 chars / 1511B)

### ~~D3. 部署~~ ✅ 文件部署完成 2026-05-14（行为门控待交互验证）

- [x] meta-rules / context / CLAUDE.md(thin) 走派生 pipeline 重出，覆盖 D0
      手写版本 ✅ 2026-05-14
- [x] engineering / market-data / education 派生产物部署到 4 个账号 ✅ 2026-05-14
      - `.claude/rules/engineering.md` 1376B（4 账号 hash 一致 `2e33e590…`）
      - `.claude/commands/market-data.md` 1444B（hash `60e16d84…`）
      - `.claude/commands/education.md` 1511B（hash `83ea5a05…`）
- [ ] 行为门控（需交互式验证，非自动化）：
      - 触发：在 4 个账号分别打开匹配源码（如 `*.go` 文件），观察 agent
        是否激活 engineering 上下文；输入 `/market-data` / `/education`
        观察 slash command 是否加载并表现出对应工作模式
      - 不干扰：在非工程对话与非教育会话中确认未自动注入域上下文

---

## Phase F · Derivation Prompt 中文化 ✅ DONE 2026-05-14

将全部 5 份 `.prompt` 文件的指令文本转为中文，同时修复
`claude.CLAUDE.md.prompt` 中内联 spec v1.0.0 的历史遗留问题。

### F1. ~~codex.AGENTS.md.prompt~~ ✅ 转换完成

### F2. ~~codex.profiles.engineering.md.prompt~~ ✅ 转换完成

### F3. ~~codex.profiles.market-data.md.prompt~~ ✅ 转换完成

### F4. ~~codex.profiles.education.md.prompt~~ ✅ 转换完成

### F5. ~~claude.CLAUDE.md.prompt~~ ✅ 转换完成 + 修复内联 spec

- 原文件将 spec v1.0.0 完整内联（lines 29–273），且为英文指令。
- 修复：内联 spec → `<<<SPEC>>>` 占位符；`prompt-version: 1.0.1`；
  `spec-version-required: 1.0.3`；所有指令文本转为中文。
- 英文保留范围：输出节标题、VERBATIM LOCK 内容、ANTI-PATTERNS 检测串、
  framework 名称、代码块内容。

**后续**：中文化后需对每份 prompt 做一次 fresh-session replay +
strength × mode 结构 audit（不需要完整行为门控）；见 Phase G。

---

## Phase G · Prompt 中文化后回归验证 ✅ DONE 2026-05-14

**背景**：prompt 指令语言从英文改为中文，模型对指令的解析可能存在细微差异，
需对每份 prompt 做最小化验证（结构 audit，不需要完整行为门控）。

**验收标准**（每个 target）：
- fresh-session replay 成功生成输出（非空，无报错）
- §3 七条 meta-rule verbatim 一致性 ✓
- §4 五框架中英双语顺序 ✓
- §7 六条 Hard Constraints 全部出现 ✓
- §9 drift token = 0（实质内容节；education 的 Anti-patterns 节除外）

### ~~G1. claude.CLAUDE.md.prompt~~ ✅ PASS 2026-05-14

模型在 bypassPermissions 模式下读取并修改了已部署的 CLAUDE.md（用文件工具代替
stdout 输出）。内容正确，仅修正 2 处格式问题（首行多余注释 + 末尾空行）。
已向 claude.CLAUDE.md.prompt 新增 ANTI-PATTERNS #9（禁止使用文件工具）和
SELF-CHECK 对应项，防止下次重现。见 `runs/2026-05-14_claude.CLAUDE.md_G/`。

### ~~G2. codex.AGENTS.md.prompt~~ ✅ PASS 2026-05-14

5832 chars / 6000 budget。见 `runs/2026-05-14_codex.AGENTS.md_G/`。

### ~~G3. codex.profiles.engineering.md.prompt~~ ✅ PASS 2026-05-14

4614 chars / 6000 budget。首次运行遇 TLS 错误，重跑通过。
见 `runs/2026-05-14_codex.profiles.engineering_G/`。

### ~~G4. codex.profiles.market-data.md.prompt~~ ✅ PASS 2026-05-14

3311 chars / 6000 budget。见 `runs/2026-05-14_codex.profiles.market-data_G/`。

### ~~G5. codex.profiles.education.md.prompt~~ ✅ PASS 2026-05-14

4036 chars / 5000 budget。Drift audit 误报（'2014'、'MacBook Pro M5' 等
仅出现于 `## Anti-patterns` 必须输出节，非实质内容节）。
见 `runs/2026-05-14_codex.profiles.education_G/`。

---

## 不在本计划内的事

- 不做 prompt 模板抽象（`prompts/_shared.md`）——5 份 prompt 抽象成本高于复制成本。
- 不做 §9 anti-patterns 自动累积机制——手动维护成本可控。
- 不写 derivation 自动化脚本——wrapper + audit 已够；脚本是 premature automation。
- 不动 git 提交流程——任何 push / commit 由用户决定。
