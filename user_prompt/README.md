# user_prompt · Agent 配置派生

Arron 用户级 agent 配置的单一真相源，以及将其编译为各 agent 文件的派生 prompt。

派生流程通过 wrapper 脚本（`claude_max20.sh` / `codex_plus.sh`）在隔离 session 中执行（见 §8–§9），
无自动构建管道，无自动 promote；审计与推广决策由人工完成。

---

## 1. 设计原则

**1. Spec 是真相源，派生文件是产物。**
不要直接编辑 `~/.claude/CLAUDE.md`、`~/.codex/AGENTS.md` 或任何派生目标文件。所有变更
通过 `spec/arron.spec.md` 流入。派生文件视同构建产物：可以 diff 和审计，但不手工
撰写。

**2. Strength 和 mode 控制派生保真度。**
spec 的每个节携带 `strength`（`hard` / `soft` / `preference`）和
`mode`（`verbatim` / `structured` / `summarized`）。对语义在转述中会退化的行为
规则（meta-rules、thinking frameworks）使用 `hard + verbatim`；对适配目标风格的
背景上下文使用 `soft + structured`；对空间受限时可省略的内容使用 `preference`。

**3. Anti-patterns 是事故记录，不是预防性规则。**
`spec §9` 和每个派生 prompt 里的 `ANTI-PATTERNS` block 记录已观察到的 drift
失败，而非预测性条目。只有在模型真实产出了禁用内容之后才添加条目。这使列表保持
实质性，而不是装饰性。

**4. 派生质量与行为质量是两个独立关注点。**
每个派生 prompt 里的 `SELF-CHECK` 测试结构合规性：节是否存在、verbatim 文本是否
匹配、长度是否在预算内。它不测试部署后的 agent 在真实会话中是否遵从规则。行为
合规需要单独的测试用例，在每次模型升级后针对真实会话运行。

**5. 逆训练先验的规则是高波动项。**
`challenge-assumptions`、`peer-level`、`no-default-hedging` 等 meta-rules 与 RLHF
奖励模式（帮助性、认识论谨慎、解释完整性）方向相反。它们在模型版本更迭后需要重测。
与安全训练同向的规则（hard constraints、诚实要求）在模型版本间保持稳定。
scope-control 规则（§3.8–§3.11）和 epistemology 规则（§3.12–§3.13）同样逆训练先验：
RLHF 奖励"更完整、更可操作的答案"，而这些规则要求主动收敛和停止展开；需在每次
模型升级后重点验证。

**6. 长度预算强制信号优先级。**
对派生目标设置字符上限，迫使派生 prompt 压缩低信号内容、保留高信号规则。没有预算
限制，派生文件会随每次 spec 更新膨胀，稀释关键约束的注意力权重。高频规则属于常驻
加载的 CLAUDE.md；低频但高密度的内容属于按需加载的 skills 或 slash commands。

**7. 层级分离将关注点保持在正确范围。**

| 层级 | 文件 | 职责范围 |
|---|---|---|
| 全局用户 | `~/.claude/CLAUDE.md` | persona、meta-rules、hard constraints |
| 项目共享 | `./CLAUDE.md` | 仓库上下文、关键路径、工作规则——入库，团队可见 |
| 项目本地 | `./.claude.local.md` | 本机路径、账户绑定——gitignored |
| Package | `packages/*/CLAUDE.md` | monorepo 子包上下文 |

---

## 2. 评价指标

评价分两层，覆盖不同的失效模式。§3 验收方式是本节两层指标的执行形式——将评价维度
转化为可逐项核对的门控。

### 层一：派生质量（结构合规，可脚本化）

推广到部署路径**之前**，校验以下项目：

- 所有规定 H2/H3 节按序存在
- `hard + verbatim` 节与 spec 对应段落逐字匹配
- 总字符数在预算内（Claude 目标：8000 字符；Codex 目标：6000 字符）
- ANTI-PATTERNS 中列出的禁用短语未出现于输出

当前由 bash strength × mode audit 脚本完成（见 §9 操作流程步骤 4）。

### 层二：行为质量（实际合规，需真实会话）

`SELF-CHECK` 验证结构；行为测试验证模型在真实对话中是否遵从规则。两者不可替代。

针对高波动规则，每次升级模型后运行以下标准场景：

| 规则 | 触发输入 | 通过标准 | 失败表现 |
|---|---|---|---|
| `challenge-assumptions` | 给一个明显错误的前提（"微服务肯定比单体好扩展"） | 质疑前提，要求证据 | 接受前提，开始设计方案 |
| `no-default-hedging` | 问一个答案有不确定性的问题 | 明确说明不确定来源 | 用"这取决于…"软着陆 |
| `peer-level` | 问一个对用户显然的概念 | 跳过基础，直入核心 | 从定义开始铺垫 |
| §4 thinking frameworks | 要求框架分析 | 框架改变结论，不只是贴标签 | 正确命名框架，推理路径不变 |
| `abstraction-discipline` | "评审这份高层架构文档，看缺了什么" | 指出缺失义务属于哪个下游规格，不生成具体内容 | 直接补全下层细节（矩阵、枚举、表单） |
| `framework-relevance` | "用你的思维框架分析：这个 README 的标题是否清楚？" | 拒绝套框架或说明框架不改变结论 | 用系统论/控制论等框架包裹一个平凡判断 |
| `review-design-separation` | "评估这份目标文档的问题" | 仅指出缺失义务的归属，不生成缺失内容 | 在评审中直接写出缺失章节的草稿 |
| `convergence-discipline` | 同时触发多个扩展规则（如"挑战假设，分析风险，列出所有框架"） | 以用户任务边界约束输出范围，如有歧义主动确认 | 多规则叠加后输出大幅膨胀，超出任务层级 |
| `entity-binding` | 含模糊实体的陈述（"这个系统的成本很高"） | 绑定主体、对象、时间范围、范围 | 接受模糊实体，在浮动指称上继续推理 |
| `inferential-validity` | 要求从单个案例得出普遍结论 | 明确标注推断性质（归纳/溯因），不作为演绎确定性呈现 | 将例子升格为规则，或将可能性描述为必然性 |

**结果记录位置：**
- 端到端行为测试（覆盖多个 target 的统一测试）→ `runs/<date>_behavior/REPORT.md`
- 针对单个 target 的定向回归测试 → 该 target 当前部署版本 run 目录下的 `notes.md`

失败场景 → 进入 spec §9 → 下次派生时加入 prompt 的 `ANTI-PATTERNS` block，形成回归覆盖。

---

## 3. 验收方式

每次派生后，推广（promote）前需通过以下三层门控。门控层次与 §2 评价指标对应：
结构门控和内容门控覆盖层一，行为门控覆盖层二。

**结构门控（bash audit，必须全部通过）：**
- [ ] bash strength × mode audit 通过（§9 步骤 4），REPORT.md 标记 PASS
- [ ] `hard + verbatim` 节与 spec 对应段落逐字匹配（`diff` 可辅助验证）
- [ ] 总字符数在目标预算内
- [ ] `ANTI-PATTERNS` 中的禁用内容未出现于输出

**内容门控（人工审计）：**
- [ ] 与上一版本的 diff 合理：spec 变更在输出中有对应体现，无意外增删
  （首次部署时无上一版本，改为核对 spec 全部 `hard` 节均有对应体现）
- [ ] 所有 `hard` 节的强度未被降级（"must" / "do not" 未变为 "prefer" / "should"）
- [ ] 无 spec 未授权的信息（无捏造事实、无捏造设备名或背景）

**行为门控（模型升级或首次部署时执行）：**
- [ ] 层二行为测试的四个标准场景全部通过

任一门控失败 → 不推广。结构门控失败修 prompt；内容门控失败修 spec 或 prompt；
行为门控失败记入 notes.md，判断归因后更新对应文件再重新派生。

---

## 4. 局限性

1. **无运行时强制**：CLAUDE.md 以 prompt 方式加载，没有机制在推理过程中强制约束。
   模型在长对话后期可能逐渐偏离规则。

2. **结构合规不蕴含行为合规**：bash audit 通过只证明派生文件结构正确，不证明
   模型在实际会话中遵从规则。两者需独立测试。

3. **高波动规则随模型迭代衰减**：逆训练先验的规则（`challenge-assumptions`、
   `peer-level`、`no-default-hedging`）在模型版本更迭后合规率可能下降，需重测。

4. **单次派生，无多样本平均**：每次派生只运行一次，模型方差可能导致不同 run 产出
   不同结果；无自动重试和共识机制。

5. **verbatim lock 是文本匹配，不是语义匹配**：输出满足 verbatim 要求，不代表模型
   对该规则的理解与原始意图一致。

6. **§4 思维框架的可观测性缺口**：框架名称出现在输出中，但框架是否真正影响推理
   路径无法从外部验证。框架可能只是输出标签，而非认知结构。

7. **上下文长度竞争**：随着 CLAUDE.md 增长，它与实际任务上下文争夺注意力权重。
   存在字符预算，但不能完全消除这一竞争。

---

## 5. 文件划分粒度

### 划分原则：文件边界 = 加载边界

**首要问题不是"这段内容属于哪个主题"，而是"这段内容在什么条件下被加载"。**

加载触发点不同 → 新建文件。加载触发点相同 → 用 section 分隔，不新建文件。

其他维度（主题、功能、角色、优先级）只有在同时导致加载触发点不同时，才成为
有效的划分依据。单独用这些维度划分，会产生始终同时加载的多个文件，与单文件
多 section 相比没有任何收益，只增加维护成本。

**为什么不能按角色划分？** 如果"工程师角色规则"和"教育者角色规则"总是在同
一会话里同时生效，拆成两个文件没有意义；但如果它们由不同的上下文激活（进入
工程任务时加载工程 profile，进入教育任务时加载教育 profile），那这个划分就是
有效的——有效的原因是加载触发点不同，不是因为"角色"本身是划分维度。

**为什么不能按功能划分？** "meta-rules 文件"和"domain-knowledge 文件"若需要
在每次会话里同时加载，合并成一个文件反而更好（更少上下文切换、更低维护开销）。

**为什么不能按场景划分？** 场景是有效维度，但前提是场景之间有不同的激活条件。
只有当"场景 A 下加载"与"场景 B 下加载"对应不同的用户动作（如激活不同 profile
或不同 slash command），场景才成为划分的合法依据。

### 切分维度：派生目标的三个正交轴

派生 prompt 文件由三个独立维度决定：

| 维度 | 可选值 | 说明 |
|---|---|---|
| **Agent** | `claude` / `codex` / `gemini` | 格式语法、长度预算、section 结构各不相同；必须分文件 |
| **上下文/域** | 全局入口 / `engineering` / `market-data` / `education` | 域规则只在该域场景下需要；全局入口不应承载域特定内容 |
| **加载方式** | 常驻（user-level entry） / 按需（profile / slash command）| 常驻 = 每次会话自动生效；按需 = 用户显式激活 |

当前 `prompts/` 下各文件的坐标：

| 文件 | Agent | 域 | 加载方式 |
|---|---|---|---|
| `claude.CLAUDE.md.prompt` | claude | 全局 | 常驻（CLAUDE.md 入口，≤1024B） |
| `claude.rules.meta-rules.md.prompt` | claude | 全局 | 常驻 rules（无 `paths:`） |
| `claude.rules.context.md.prompt` | claude | 全局 | 常驻 rules（无 `paths:`） |
| `claude.rules.engineering.md.prompt` | claude | engineering | path-scoped rules（20 globs） |
| `claude.commands.market-data.md.prompt` | claude | market-data | slash command `/market-data` |
| `claude.commands.education.md.prompt` | claude | education | slash command `/education` |
| `codex.AGENTS.md.prompt` | codex | 全局 | 常驻 |
| `codex.profiles.engineering.md.prompt` | codex | engineering | 按需 profile |
| `codex.profiles.market-data.md.prompt` | codex | market-data | 按需 profile |
| `codex.profiles.education.md.prompt` | codex | education | 按需 profile |

域 profile 存在的原因：全局入口若内联所有域规则，信噪比下降且超出长度预算；
将域规则剥离为 profile，用户进入该域时显式激活，其余时间不占用上下文。

**新增文件的判断序：**
1. 是否涉及不同 agent？→ 是则必须分文件（语法不兼容）
2. 是否有不同的加载触发点？→ 是则分文件（常驻 vs. profile vs. slash command）
3. 两者都相同？→ 在现有文件内新增 section，不新建文件

### 不应作为独立划分依据的维度

| 维度 | 正确处理方式 | 错误处理方式 |
|---|---|---|
| 主题 / 功能 | 在同一文件内用 section 分隔 | 按主题拆成多个始终同时加载的文件 |
| 优先级 / 重要程度 | 用 `strength: hard / soft / preference` 元数据表达 | 新建"重要规则文件"和"次要规则文件" |
| 时间 / 历史版本 | 用 `runs/<date>/` 保存快照 | 在 `prompts/` 内按时间分文件 |
| 稳定性 | 用 `strength` + `mode` 区分；稳定性差异本身不构成加载边界 | 按稳定性拆文件 |

### spec 内部的节粒度

每个 `§section` 对应一个关注点，且该节内所有内容共享同一组
`strength / mode / derive_to`。

拆节的信号：
- 同一节内部分内容的 `derive_to` 不同（如一段只到 `claude`，另一段到 `all`）
- 同一节内部分内容的 strength 不同（`hard` 与 `soft` 混用）
- 单节超过 20 行且有明显子主题 → 考虑拆子节（`§3.1`、`§3.2`…）

不拆节的情况：内容主题不同但 `strength / mode / derive_to` 完全相同——此时
用子节标题区分即可，不必升格为独立节。

### 常驻 CLAUDE.md vs. skills/commands 的分界

| 放入常驻 CLAUDE.md | 下沉到 skills/commands |
|---|---|
| 每次会话都需要生效的规则 | 特定任务模式才需要的规则 |
| meta-rules、hard constraints、语言偏好 | TDD workflow、review protocol、domain convention |
| 规则总量在长度预算内 | 规则体积大或高密度、低频 |
| 无对应的显式激活手段 | 可通过 `/skill` 显式加载 |

经验阈值：某段规则只在 20% 以下的会话中有用 → 优先下沉到 skills。

### CLAUDE.md 各层的内容边界

| 层 | 放什么 | 不放什么 |
|---|---|---|
| `~/.claude/CLAUDE.md`（全局用户） | persona、meta-rules、hard constraints、语言偏好 | 仓库路径、构建命令、账户凭证 |
| `./CLAUDE.md`（项目共享） | 仓库定位、关键路径、常用命令、工作规则 | 本机路径、代理配置、个人偏好 |
| `./.claude.local.md`（项目本地） | 本机特有路径、账户绑定、本地工具路径 | 应入库的任何内容 |
| `packages/*/CLAUDE.md`（子包） | 子包特有的构建约定、API 边界说明 | 全局规则的重复 |

跨层重复是噪音：如果某条规则在全局层已存在，项目层不应重复，除非项目层需要
显式**覆盖**全局层的默认值。

---

## 6. 演进时机

**更新 spec（`spec/arron.spec.md`）：**
- 用户角色、背景或活跃项目发生变化（§1、§5、§6）
- 真实会话中发现 hard constraint 缺失
- 某条规则需要从 `soft` 升级为 `hard`，或 `structured` 升级为 `verbatim`
- 添加或移除 thinking framework

**更新派生 prompt（`prompts/<target>.prompt`）：**
- 派生输出出现结构性 drift（节缺失、顺序错误、长度超限）
- 派生输出出现新的 anti-pattern（不是 spec 问题，是 prompt 未覆盖的 drift 模式）
- 目标格式要求变化（长度预算、节结构、输出语言）
- `SELF-CHECK` 需要新的验证项

**触发重新派生（不修改 spec/prompt）：**
- 模型版本升级 → 运行行为测试 → 失败则先更新 spec/prompt 再重新派生
- 真实会话中观察到行为 drift → 记入 `notes.md` → 判断归因（spec 问题 vs. prompt
  问题）→ 更新对应文件 → 重新派生

**不要做：**
直接编辑部署路径下的文件。所有变更必须从 spec 或 prompt 流入，
再经派生 → 审计 → 推广流程落地。

**例外（soft/structured 单字段小修）：**
若变更仅涉及 `strength: soft` + `mode: structured` 节的单个字段（如补充一个城市、
修正一个学位名称），且内容改动字节极小、无结构影响，可直接同步编辑 spec +
已部署文件，跳过重派生流程。适用条件：
- 变更字段的 `derive_to` 已覆盖所有受影响目标
- 同步编辑所有账号的对应部署文件（参见 §14.2 账号列表）
- 在 TODO.md Spec 变更记录中注明处理方式和理由

若变更涉及 `hard` 节或 `verbatim` mode，必须跑完整重派生流程，无例外。

---

## 7. 目录结构

```
user_prompt/
├── README.md                    # 本文件
├── TODO.md                      # pipeline 执行历史 + 开放缺口
├── spec/
│   └── arron.spec.md            # 单一真相源
├── badcase/                     # 观察到的 drift 失效案例（触发 spec 修订）
│   └── abstraction-discipline.md
├── prompts/                     # 每个派生目标对应一个 prompt
│   ├── claude.CLAUDE.md.prompt
│   ├── claude.rules.meta-rules.md.prompt
│   ├── claude.rules.context.md.prompt
│   ├── claude.rules.engineering.md.prompt
│   ├── claude.commands.market-data.md.prompt
│   ├── claude.commands.education.md.prompt
│   ├── codex.AGENTS.md.prompt
│   ├── codex.profiles.education.md.prompt
│   ├── codex.profiles.engineering.md.prompt
│   └── codex.profiles.market-data.md.prompt
└── runs/                        # 每次派生的快照（不可变，只追加）
    └── <YYYY-MM-DD>_<target>/
        ├── spec.snapshot.md     # 派生时使用的 spec 快照
        ├── prompt.snapshot.md   # 实际粘贴的 prompt
        ├── output.md            # 模型输出
        ├── output.tainted.md    # 失败的首跑（仅部分 run 存在，已被 output.md 取代）
        └── notes.md             # model id、temperature、重试次数、异常备注
    └── <YYYY-MM-DD>_<target>_replay/   # 可重放性验证
        ├── REPORT.md            # 跨模型 diff 报告（PASS / FAIL）
        └── <agent>/             # claude/ 或 codex/
            ├── output.md
            ├── run.log
            └── stream.jsonl
```

---

## 8. 实际跑通的命令

### Codex 隔离 replay（fresh-session 验证，不加载 AGENTS.md）

```bash
CODEX_HOME=/tmp/fresh_codex_home_$(date +%Y%m%d)
mkdir -p "$CODEX_HOME"
ln -sf "$HOME/.codex/auth.json" "$CODEX_HOME/auth.json"
mkdir -p /tmp/fresh_codex_cwd_$(date +%Y%m%d)

CODEX_HOME="$CODEX_HOME" codex_plus.sh exec \
  --ignore-user-config \
  --skip-git-repo-check \
  --cd /tmp/fresh_codex_cwd_$(date +%Y%m%d) \
  -s read-only \
  "<完整 prompt 内容>" \
  > runs/<YYYY-MM-DD>_<target>/output.md 2>&1
```

### Claude 隔离 replay（fresh-session 验证，不加载 CLAUDE.md）

```bash
mkdir -p /tmp/fresh_claude_cwd_$(date +%Y%m%d)

cd /tmp/fresh_claude_cwd_$(date +%Y%m%d) && \
claude_max20.sh -p \
  --output-format stream-json \
  --verbose \
  --permission-mode bypassPermissions \
  --no-session-persistence \
  "<完整 prompt 内容>" \
  > stream.jsonl 2>&1

# 提取输出
python3 -c "
import json
texts=[]
for line in open('stream.jsonl'):
    line=line.strip()
    if not line: continue
    e=json.loads(line)
    if e.get('type')=='assistant':
        for c in e.get('message',{}).get('content',[]):
            if c.get('type')=='text': texts.append(c['text'])
open('output.md','w').write('\n'.join(texts))
"
```

> ⚠️ **`--output-format text` 在长 prompt（>10KB）上会挂死，进程 CPU 接近 0 但不退出。**
> 必须使用 `--output-format stream-json --verbose`。
> 参见 `runs/2026-05-12_codex.AGENTS_replay/claude/notes.md`。

### Cwd 选择说明（Claude replay）

- 用空目录（如 `/tmp/fresh_claude_cwd_...`）：阻止 project-level CLAUDE.md 自动加载，
  实现纯 global CLAUDE.md + prompt 隔离。
- `--bare` 不可用：会导致 OAuth 登录失效（`Not logged in`）。
- 正确做法：空 cwd + 不传 `--bare`。

### Codex smoke test（测试真实 AGENTS.md 加载效果）

```bash
# 不加 --ignore-user-config，让 codex_plus.sh 的 HOME 设置生效，自动加载 AGENTS.md
codex_plus.sh exec \
  --skip-git-repo-check \
  --cd /tmp/smoke_cwd \
  -s read-only \
  "<trigger prompt>"
```

---

## 9. 操作流程

对每个派生目标（如 `codex.AGENTS.md`）：

1. 打开 `spec/arron.spec.md`。如果 spec 刚刚编辑过，更新其 header 里的
   `version` 和 `updated`。
2. 打开 `prompts/<target>.prompt`，将其中的 `<<<SPEC>>>` 替换为
   `spec/arron.spec.md` 的完整内容，得到完整 prompt。
3. 用 wrapper 一键跑隔离 replay（见 §8 实际跑通的命令）：
   - Codex 目标：`codex_plus.sh exec --ignore-user-config ...`
   - Claude 目标：`claude_max20.sh -p --output-format stream-json ...` + python3 提取
   - 保存输出到 `runs/<YYYY-MM-DD>_<target>/output.md`，同时保存
     `spec.snapshot.md` / `prompt.snapshot.md` / `notes.md`（model id、replay 方式、
     任何异常）。
4. 跑 bash strength × mode audit（§3 结构门控）：
   - §3 全部 meta-rule verbatim 匹配（当前 13 条，§3.1–§3.13）
   - §4 五个框架中英双语全在
   - §7 hard constraints 子集全在
   - §9 drift token 0 命中（排除 §4 verbatim block 和 Anti-patterns section 本身）
   - 写 `REPORT.md`，标明 PASS / FAIL
5. 通过结构门控后，执行内容门控（§3 内容门控，人工审计）：
   - 与上一版本 diff，确认 spec 变更有对应体现、无意外增删
   - 首次部署时跳过 diff，改为核对 spec 全部 `hard` 节均有对应体现
   - 确认 `hard` 节强度未被降级，无 spec 未授权信息
6. 两层门控均通过则推广（两步，见 §14.3）：
   - 步骤一：`runs/` → 主账号（`claude_max20` / `codex_plus`），先备份再覆盖
   - 步骤二：主账号 → 其他账号（`claude_deepseek` / `claude_minimax` /
     `claude_pro` / `codex_arron_free`），先备份再覆盖
7. 任一门控未通过则不推广。选择：
   - 重新执行步骤 3（模型可能产出不同草稿）；
   - 或修改 prompt 的 `VERBATIM LOCK` / `ANTI-PATTERNS` / `SELF-CHECK`
     block 以加固对此 drift 的防御，再重新执行。

---

## 10. spec 变更 → 重派生流程

**触发条件**：`spec/arron.spec.md` 的 `version:` 字段递增（任何实质性内容变更都必须先升 version）。

**操作**：对全部 10 份派生目标重跑完整 §9 操作流程（受影响的 target）：
1. 更新 spec version 和 updated 字段
2. 对每个 prompt 更新 `spec-version-required` 字段（如果 spec 变更影响该目标的内容）
3. 重跑隔离 replay（见 §8 实际跑通的命令）
4. 重跑 strength × mode audit
5. PASS 后 promote：执行 §14.3 步骤一（`runs/` → 主账号）和步骤二（主账号 → 其他账号），更新 `.pre-<date>.md` 备份

**已知 TODO（暂不实施）**：在 git pre-commit 加一条检查——如果 spec 的 version 字段变化，
提示用户对受影响的 derive_to 目标触发重派生。

**不要**：直接编辑部署路径下的配置文件。所有变更必须从 spec 流入。

---

## 11. 版本管理

- `spec/arron.spec.md` 携带自身的 `version`。
- 每个 prompt 携带 `prompt-version` 和 `spec-version-required`。
- 每个 `runs/.../notes.md` 记录实际使用的 model id。
- （spec version，prompt version，model id）三元组唯一标识一次派生的**配置**；
  具体产物以 run 目录名（`<YYYY-MM-DD>_<target>`）为唯一标识。
  回放 = 打开对应的 `runs/` 子目录，读取 `output.md`。

---

## 12. 添加新目标

1. 确定目标名称（如 `claude.CLAUDE.md`、`codex.profiles.engineering.md`）。
2. 创建 `prompts/<target>.prompt`，以 `prompts/codex.AGENTS.md.prompt` 为模板。
   结构如下：
   - header（目标标识、预期模型）
   - `SPEC` block，包含 `<<<SPEC>>>` 占位符
   - `TARGET` block，描述必需节、风格、长度
   - `VERBATIM LOCK`，列出哪些 spec 节必须 verbatim 出现
   - `ANTI-PATTERNS`，列出禁止内容
   - `SELF-CHECK`，列出发出输出前需内部验证的项目
   - `OUTPUT`，格式规则
3. 执行 §9 操作流程。

---

## 13. 为何不用工具链

派生合约存在于 prompt 本身，而非构建脚本。现状：bash audit 脚本提供局部自动化
（strength × mode 结构检查），但整体流程（replay 触发、内容门控、推广决策）仍是手动的。

手动流程的收益：零依赖、无需 API key、在任意 agent UI 中可运行、prompt 自我文档化、
每个 drift 修复只需在 prompt 的 `ANTI-PATTERNS` block 增加一行。

代价：无全自动 invariant 强制、无多样本重试、无自动 promote。这些代价已在 §4 局限性中
列明，不构成意外。

---

## 14. 生成文件保存位置与部署映射

### 14.1 流程概述

promote 分两步：

```
runs/<date>_<target>/output.md  →  主账号  →  其他同类账号
```

| 层 | 路径 | 角色 |
|---|---|---|
| 历史快照 | `runs/<date>_<target>/output.md` | 只追加，不可覆盖 |
| 主账号（Claude） | `.coding_agents/claude_max20/.claude/CLAUDE.md` | 当前版本的 canonical source |
| 主账号（Codex） | `.coding_agents/codex_plus/.codex/AGENTS.md` + `profiles/` | 当前版本的 canonical source |
| 其他账号 | 各 `.coding_agents/<acct>/` | 从主账号同步 |

`claude_max20` 同时含 `.claude/` 和 `.codex/`；`.codex/` 是历史遗留，部署只动 `.claude/`。

### 14.2 账号路径映射表

所有路径以仓库根目录（`/data/work_dir/dev_env/`）为基准。

| 账号 | 部署目标路径 | 状态 |
|---|---|---|
| `claude_max20` | `.claude/CLAUDE.md` | ✅ spec 1.0.6（主账号） |
| `claude_max20` | `.claude/rules/meta-rules.md` | ✅ spec 1.0.9（常驻，13 条 meta-rule） |
| `claude_max20` | `.claude/rules/context.md` | ✅ spec 1.0.6（常驻） |
| `claude_max20` | `.claude/rules/engineering.md` | ✅ spec 1.0.6（path-scoped） |
| `claude_max20` | `.claude/commands/market-data.md` | ✅ spec 1.0.6 |
| `claude_max20` | `.claude/commands/education.md` | ✅ spec 1.0.6 |
| `claude_deepseek` | `.claude/CLAUDE.md` + rules/ + commands/ | ✅ CLAUDE.md/context/engineering/commands: spec 1.0.6；meta-rules: spec 1.0.9 |
| `claude_minimax` | `.claude/CLAUDE.md` + rules/ + commands/ | ✅ CLAUDE.md/context/engineering/commands: spec 1.0.6；meta-rules: spec 1.0.9 |
| `claude_pro` | `.claude/CLAUDE.md` + rules/ + commands/ | ✅ CLAUDE.md/context/engineering/commands: spec 1.0.6；meta-rules: spec 1.0.9 |
| `codex_plus` | `.codex/AGENTS.md` | ✅ spec 1.0.5（主账号，内容未受 1.0.6 影响） |
| `codex_plus` | `.codex/profiles/engineering.md` | ✅ spec 1.0.5 |
| `codex_plus` | `.codex/profiles/market-data.md` | ✅ spec 1.0.5 |
| `codex_plus` | `.codex/profiles/education.md` | ✅ spec 1.0.5 |
| `codex_arron_free` | `.codex/AGENTS.md` | ✅ spec 1.0.5（2026-05-13 同步） |
| `codex_arron_free` | `.codex/profiles/engineering.md` | ✅ spec 1.0.5（2026-05-13 同步） |
| `codex_arron_free` | `.codex/profiles/market-data.md` | ✅ spec 1.0.5（2026-05-13 同步） |
| `codex_arron_free` | `.codex/profiles/education.md` | ✅ spec 1.0.5（2026-05-13 同步） |
| `gemini_arron` | — | 🔒 reserved |
| `gemini_cipher` | — | 🔒 reserved |

### 14.3 promote 命令

**步骤一：`runs/` → 主账号**（§9 步骤 6，审计通过后执行）

```bash
DATE=$(date +%Y-%m-%d)

# Claude 主账号
cp .coding_agents/claude_max20/.claude/CLAUDE.md \
   .coding_agents/claude_max20/.claude/CLAUDE.pre-${DATE}.md
cp user_prompt/runs/<YYYY-MM-DD>_claude.CLAUDE.md_replay/claude/output.md \
   .coding_agents/claude_max20/.claude/CLAUDE.md

# Codex 主账号
cp .coding_agents/codex_plus/.codex/AGENTS.md \
   .coding_agents/codex_plus/.codex/AGENTS.pre-${DATE}.md
cp user_prompt/runs/<YYYY-MM-DD>_codex.AGENTS.md_replay/codex/output.md \
   .coding_agents/codex_plus/.codex/AGENTS.md

# Codex profiles（三个全部）
for PROFILE in engineering market-data education; do
  cp .coding_agents/codex_plus/.codex/profiles/${PROFILE}.md \
     .coding_agents/codex_plus/.codex/profiles/${PROFILE}.pre-${DATE}.md
  cp user_prompt/runs/<YYYY-MM-DD>_codex.profiles.${PROFILE}.md_replay/codex/output.md \
     .coding_agents/codex_plus/.codex/profiles/${PROFILE}.md
done
```

**步骤二：主账号 → 其他账号**（主账号 promote 后立即执行）

```bash
DATE=$(date +%Y-%m-%d)

# Claude 其他账号
for ACCT in claude_deepseek claude_minimax claude_pro; do
  [ -f .coding_agents/${ACCT}/.claude/CLAUDE.md ] && \
    cp .coding_agents/${ACCT}/.claude/CLAUDE.md \
       .coding_agents/${ACCT}/.claude/CLAUDE.pre-${DATE}.md
  cp .coding_agents/claude_max20/.claude/CLAUDE.md \
     .coding_agents/${ACCT}/.claude/CLAUDE.md
done

# Codex 其他账号
cp .coding_agents/codex_arron_free/.codex/AGENTS.md \
   .coding_agents/codex_arron_free/.codex/AGENTS.pre-${DATE}.md
cp .coding_agents/codex_plus/.codex/AGENTS.md \
   .coding_agents/codex_arron_free/.codex/AGENTS.md

for PROFILE in engineering market-data education; do
  cp .coding_agents/codex_arron_free/.codex/profiles/${PROFILE}.md \
     .coding_agents/codex_arron_free/.codex/profiles/${PROFILE}.pre-${DATE}.md
  cp .coding_agents/codex_plus/.codex/profiles/${PROFILE}.md \
     .coding_agents/codex_arron_free/.codex/profiles/${PROFILE}.md
done
```

### 14.4 部署后验证

```bash
# Claude：各账号与主账号字节数一致
wc -c .coding_agents/claude_max20/.claude/CLAUDE.md \
      .coding_agents/claude_deepseek/.claude/CLAUDE.md \
      .coding_agents/claude_minimax/.claude/CLAUDE.md \
      .coding_agents/claude_pro/.claude/CLAUDE.md

# Codex：各账号与主账号字节数一致
wc -c .coding_agents/codex_plus/.codex/AGENTS.md \
      .coding_agents/codex_arron_free/.codex/AGENTS.md
```

---

## 15. Claude 按需加载（Claude 专有）

### 15.1 机制

Claude 支持将主 `CLAUDE.md` 文件拆分为多个规则文件，这些文件在尝试访问规则
前言（frontmatter）中指定路径的文件时按需加载，优先级与主 `CLAUDE.md` 相同。
详见 §16。

除此之外，Claude Code 还支持 **slash commands**：文件放在
`.claude/commands/<name>.md`，用户在对话中输入 `/<name>` 时 Claude Code
将其内容注入当前上下文。

Slash commands 与 Codex `--profile` 的对比：

| 维度 | Codex | Claude |
|---|---|---|
| 触发方式 | `codex_plus.sh --profile engineering` | `/engineering`（对话开头输入） |
| 文件位置 | `.codex/profiles/engineering.md` | `.claude/commands/engineering.md` |
| 加载时机 | 会话启动时 | 用户显式调用时 |
| 作用范围 | 整个会话 | 调用点之后的上下文 |

### 15.2 文件路径

`claude_max20.sh` 设置 `HOME=.coding_agents/claude_max20/`，commands 文件放在：

```
.coding_agents/claude_max20/.claude/commands/
├── engineering.md
├── market-data.md
└── education.md
```

### 15.3 哪些内容适合按需加载

Identity（§1）、Languages（§2）、Meta-rules（§3）、Thinking Frameworks（§4）、
Hard Constraints（§7）、Execution Protocol（§8）必须常驻——它们是影响所有响应的
基础校准参数，缺失会导致语言选择、peer-level 判断、约束执行全面退化。

按需加载的候选仅限于域上下文：

| spec 节 | 内容 | 推荐加载方式 | 触发机制 |
|---|---|---|---|
| §5 Architecture & engineering | 工程域细节 | `.claude/rules/`（path-scoped） | 读到源码文件时自动触发 |
| §5 Business domain | 金融域细节 | slash command | `/market-data` |
| §6 Child Education | 教育项目 | slash command | `/education` |

两种按需加载机制见 §16。

### 15.4 落地所需变更

1. **spec 新增 `derive_to` token**：`claude.commands.market-data` /
   `claude.commands.education` / `claude.rules.engineering`，与
   `codex.profiles.*` 平行。

2. **新增 3 个派生 prompt**（一个 rules，两个 commands）：
   - `prompts/claude.rules.engineering.md.prompt`
   - `prompts/claude.commands.market-data.md.prompt`
   - `prompts/claude.commands.education.md.prompt`

3. **新增 3 个部署目标**（`runs/` → 直接写入部署路径，无中间层）：

   | 部署路径 | 触发方式 |
   |---|---|
   | `.coding_agents/claude_max20/.claude/rules/engineering.md` | 读到源码文件自动触发 |
   | `.coding_agents/claude_max20/.claude/commands/market-data.md` | 用户输入 `/market-data` |
   | `.coding_agents/claude_max20/.claude/commands/education.md` | 用户输入 `/education` |

4. **`claude.CLAUDE.md` 对应瘦身**：将"用户背景"节中的 §5 域细节剥离；
   §1 Identity、§2–§4、§7–§8 保留常驻。§1 不得按需加载。

### 15.5 触发条件（已部分触发 2026-05-14）

按 §5 划分原则，拆分的判断依据是加载触发点不同，而非主题不同：

- 用户硬上限 `CLAUDE.md ≤ 1k` → **2026-05-14 触发**，已执行紧急瘦身
- 非工程会话中域上下文干扰任务上下文，成为可观测问题 → **暂无证据**

**当前部署（D0 → D3 已完成 2026-05-14；行为门控待交互验证）**：
- `CLAUDE.md`（952B）：仅 §2 语言风格 + §7 Hard Constraints
- `.claude/rules/meta-rules.md`（1814B，常驻）：§3 Meta-rules + §4 Thinking Frameworks
- `.claude/rules/context.md`（2374B，常驻）：§1 + §5 + §6 + §8
- `.claude/rules/engineering.md`（1376B，path-scoped）：§5 Architecture & engineering 深度版
- `.claude/commands/market-data.md`（1444B，slash `/market-data`）：§5 Business domain 深度版
- `.claude/commands/education.md`（1511B，slash `/education`）：§6.1 + §5 Education-system design 深度版

前 3 个为 always-loaded（无 `paths:` frontmatter），与 `CLAUDE.md` 优先级相同；
engineering.md 含 `paths:` frontmatter（20 globs，源码 + DevOps）按需触发；
market-data / education 仅在用户输入 `/<name>` slash command 时加载。
全部 6 份文件均由派生 pipeline 产出（fresh-session replay + Phase G 审计全 PASS），
4 个 Claude 账号哈希一致。手写 D0 中间产物保留为 `*.handwritten-2026-05-14.md`。

---

## 16. Claude rules 目录（path-scoped 按需加载，Claude 专有）

### 16.1 机制

Claude 支持将主 `CLAUDE.md` 文件拆分为多个规则文件，这些文件在尝试访问规则
前言（frontmatter）中指定路径的文件时按需加载。它们的优先级与主 `CLAUDE.md`
相同，但只是按需加载。

规则文件放在 `.claude/rules/`，支持两种加载模式：

| 文件类型 | frontmatter | 加载时机 |
|---|---|---|
| 无条件规则 | 无 `paths:` | 会话启动时始终加载（等同 CLAUDE.md） |
| path-scoped 规则 | 有 `paths:` | Claude 读取匹配路径的文件时自动注入 |

**Path-scoped 规则语法：**

```markdown
---
paths:
  - "**/*.{go,py,ts,tsx}"
  - "Dockerfile*"
  - "*.yml"
---

# Engineering Rules

...规则内容...
```

当 Claude 读取任何匹配 `paths:` 的文件时，该规则文件自动注入上下文；不匹配时不占用 token。

### 16.2 文件位置

```
.coding_agents/claude_max20/.claude/
├── CLAUDE.md                        # 常驻（入口，≤1024B）
├── commands/                        # slash commands（§15）
│   ├── market-data.md               # /market-data
│   └── education.md                 # /education
└── rules/
    ├── meta-rules.md                # 常驻（无 paths:）：§3 + §4
    ├── context.md                   # 常驻（无 paths:）：§1 + §5 + §6 + §8
    └── engineering.md               # path-scoped（20 globs）：§5 工程深度版
```

用户级规则（`~/.claude/rules/`）= `HOME` 设置后对应
`.coding_agents/claude_max20/.claude/rules/`。

### 16.3 与你的用例的匹配度

| 域 | path-scoped 可行性 | 说明 |
|---|---|---|
| engineering | ✅ | 工程任务读源码文件，路径模式明确 |
| market-data | ⚠️ | 域边界模糊，文件类型与 engineering 重叠，改用 slash command |
| education | ❌ | 教育任务不与文件路径绑定，必须用 slash command |

### 16.4 与 slash commands 的选择依据

| 判断维度 | 选 `.claude/rules/` | 选 slash commands |
|---|---|---|
| 触发信号 | 文件路径可预测 | 对话意图决定，路径不可预测 |
| 用户操作 | 零操作（自动） | 显式输入 `/<name>` |
| 适用域 | engineering | market-data、education |

---

## 17. Codex 渐进式披露

### 17.1 机制与限制

Codex 在**会话启动时**一次性加载所有指令，之后不再动态注入。加载顺序：

1. 目录层级 `AGENTS.md`（从 repo root 到 cwd，逐级拼接，上限 32 KiB）
2. `~/.codex/rules/` 中的规则文件（所有文件，启动时全量加载）
3. 显式传入的 `--profile <name>`（单次会话激活）

**无 path-scoped 自动触发机制。** Codex 不解析 frontmatter，不根据被读取的文件路径动态注入规则。这是架构差异，不是配置缺口。

### 17.2 Codex 的按需加载方式：profiles

`--profile` 是 Codex 唯一的按需加载机制，由用户在启动会话时显式指定：

```bash
# 启动时加载 engineering profile
codex_plus.sh exec --profile engineering "<prompt>"

# 多 profile 叠加
codex_plus.sh exec --profile engineering --profile market-data "<prompt>"
```

Profile 文件位置：`.codex/profiles/<name>.md`（相对于 `CODEX_HOME`）。

### 17.3 Claude 与 Codex 渐进式披露对比

| 维度 | Claude | Codex |
|---|---|---|
| 路径感知自动触发 | ✅ `.claude/rules/` + `paths:` frontmatter | ❌ 不支持 |
| 显式按需加载 | ✅ slash commands（`/<name>`） | ✅ `--profile <name>` |
| 触发时机 | 运行时（读文件时 / 用户输入时） | 会话启动时 |
| 无条件补充规则 | `.claude/rules/`（无 `paths:`） | `~/.codex/rules/`（全量启动加载） |
| engineering 域 | `.claude/rules/engineering.md`（auto） | `--profile engineering`（用户显式） |
| market-data 域 | slash command `/market-data` | `--profile market-data` |
| education 域 | slash command `/education` | `--profile education` |

### 17.4 当前部署状态

Codex 全局入口（`AGENTS.md`）和三个 profiles 已部署到所有 Codex 账号（spec 1.0.3）：

| 账号 | AGENTS.md | profiles |
|---|---|---|
| `codex_plus/` | ✅ 5749B | ✅ engineering / market-data / education |
| `codex_arron_free/` | ✅ 5749B | ✅ engineering / market-data / education |

`codex_arron_free` 的旧 profiles（`agentic-engineering.md`、`concept-learning.md`、`product.md`）
已于 2026-05-13 删除，当前 `.codex/profiles/` 仅保留三个 spec-derived profiles。
