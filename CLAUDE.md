# CLAUDE.md

本文档为 Claude Code 在此仓库中工作时提供最小必要指导。完整背景以 `docs/` 中的编号文档为准。

## 仓库定位

本仓库维护一套本地 coding-agent Docker 开发环境：

- 基础镜像：`coding-agent-base:debian-bookworm`
- Compose 入口：`compose/coding-agent/docker-compose.sing-box.yml`
- Compose 配置：`compose/coding-agent/coding-agent.env`
- 账号目录不整体挂载进容器；Compose 只按 `CODING_AGENT_SSH_AUTHORIZED_KEYS` 和 `CODING_AGENT_SING_BOX_CONFIG_DIR` 挂载具体文件/目录。
- 需求根目录：`CODING_AGENT_WORK_DIR` -> `/data/work_dir`
- 容器用户：`arron:staff`，UID/GID `501:20`，具备免密 sudo。

非目标和已退役的旧机制（`docker-compose.dev.yml`、`AGENT_ACCOUNT_ID` 等）见 `docs/00-problem-and-scope.md`。

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

- 使用 VS Code `Dev Containers: Attach to Running Container...`，然后打开 `/data/work_dir/<ticket-or-repo>`。
- 不使用 `Reopen in Container` 或 `Rebuild Container` 管理此环境。
- 不把 `/data/work_dir` 当作日常大 workspace 打开。
- 不把账号认证、SSH key、代理配置写入项目仓库。
- 不让 Agent 自动 push、merge 主分支或自动解决并发冲突。
- 修改 Dockerfile、Compose、SSH、DNS、TUN、代理配置前，先确认影响范围和回滚方式。

## 文档索引

- `docs/00-problem-and-scope.md` — 问题定义、范围和非目标
- `docs/01-architecture.md` — 当前架构、目录挂载和边界
- `docs/02-setup-and-operations.md` — 搭建、启动、停止、VS Code 接入
- `docs/03-network-and-proxy.md` — sing-box TUN、DNS 和代理验证
- `docs/04-agent-workflow.md` — Agent 工作流、代码风格、提交与 PR 规范
- `docs/05-verification.md` — 静态检查、镜像构建和运行时检查
