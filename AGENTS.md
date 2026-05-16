# Repository Guidelines

本文档为 Codex 在此仓库中工作时提供最小必要指导。完整背景以 `docs/` 中的编号文档为准。

## 项目结构

本仓库由若干子项目组成（详见 `docs/00-projects.md`）：

- 子项目 1 「Docker 账户环境搭建」——`docs/00-problem-and-scope.md`
- 子项目 2 「用户提示词搭建」——`user_prompt/README.md`

未来子项目按需追加。下文「制品语域」「工作规则」为跨子项目共享约束；「仓库定位」「关键路径」「常用命令」「文档索引」默认描述子项目 1，子项目 2 工作流见其 README。

## 仓库定位

本仓库维护一套本地 coding-agent Docker 开发环境，不是业务应用仓库：

- 基础镜像：`coding-agent-base:debian-bookworm`
- Compose 入口：`compose/coding-agent/docker-compose.sing-box.yml`
- Compose 配置：`compose/coding-agent/coding-agent.env`
- 账号目录不整体挂载进容器；只按 `CODING_AGENT_SSH_AUTHORIZED_KEYS` 和 `CODING_AGENT_SING_BOX_CONFIG_DIR` 挂载具体文件/目录。
- 需求根目录：`CODING_AGENT_WORK_DIR` -> `/data/work_dir`
- 容器用户：`arron:staff`，UID/GID `501:20`，具备免密 sudo。

## 制品语域

本仓库 scope：coding-agent 开发环境建设——容器镜像与 Compose、`.coding_agents/<account>/` 多账号目录、statusline、用户级提示词、skills 等 harness 配置；不含业务域任务（marketdata、医疗、金融业务实现不在本仓）。

Agent 产出的制品（`docs/`、shell 脚本、Dockerfile/Compose、PR 描述、commit subject、章节标题、变量与配置键名）须按以下 register 着陆：

- **域 register**：harness 工程抽象——Docker / Compose / sing-box / wrapper / account directory / statusline / hook / skill / slash command / permission / `settings.json`。不得使用业务域词汇。
- **受众 register**：harness 运维者与 Agent 配置作者，非业务域终端用户。
- **Framework 词汇**：系统论 / 控制论 / 信息论 / 认识论 / 混沌系统作为 reasoning 工具可见于推理过程，不得出现在制品的用户可见命名/标题中（见 AGENTS.md meta-rules §3.15）。如需在 reasoning 中应用，最终命名须完成 framework → 工程抽象 的转换。

## 关键路径

| 用途 | 路径 |
|---|---|
| 基础镜像 | `images/coding-agent-base/debian-bookworm/Dockerfile` |
| 容器入口 | `images/coding-agent-base/debian-bookworm/entrypoint.sh` |
| Compose | `compose/coding-agent/docker-compose.sing-box.yml` |
| Compose env | `compose/coding-agent/coding-agent.env` |
| sing-box 模板 | `compose/coding-agent/sing-box.config.json` |
| 构建脚本 | `scripts/host-build-base-image.sh` |
| 环境默认值 | `scripts/host-env.sh` |

## 常用命令

```bash
scripts/host-build-base-image.sh
```

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  config
```

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  up -d
```

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash
```

## 工作规则

- 不让 Agent 自动 push、merge 主分支或自动解决并发冲突。
- 不把账号认证、SSH key、代理密钥写入项目仓库或 `.coding_agents/` 之外的位置。
- `.coding_agents/<account>` 下的目录是本地长期状态，不得清理或删除既有账号目录。
- 修改 Dockerfile、Compose、SSH、DNS、TUN、代理配置前，先确认影响范围和回滚方式。
- Shell 修改先运行 `bash -n`；Compose 修改先运行 `docker-compose ... config`；镜像修改运行 `scripts/host-build-base-image.sh`。

## 文档索引

- `docs/00-problem-and-scope.md` — 问题定义、范围和非目标
- `docs/01-architecture.md` — 当前架构、目录挂载和安全边界
- `docs/02-setup-and-operations.md` — 搭建、启动、停止、VS Code 接入
- `docs/03-network-and-proxy.md` — sing-box TUN、DNS 和代理验证
- `docs/04-agent-workflow.md` — Agent 工作流、代码风格、提交与 PR 规范
- `docs/05-verification.md` — 静态检查、镜像构建和运行时检查
