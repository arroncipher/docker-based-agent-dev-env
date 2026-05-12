# 架构设计

## 总体模型

```text
Host macOS
├── CODING_AGENT_WORK_DIR/                 # 全部 ticket/repo 根目录
│   ├── dev_env/
│   └── <ticket-or-repo>/
├── .coding_agents/<account>/              # 本地账号长期状态，不能删除
├── scripts/ssh/authorized_keys            # 本地 SSH 公钥文件，git 忽略
├── scripts/sing-box/config.json           # sing-box 运行配置，无凭据时可跟踪
├── scripts/proxy.env                      # 宿主机与容器网络环境适配
└── Docker / OrbStack
    ├── sing_box_gateway                   # sing-box TUN gateway
    └── coding_agent                       # coding-agent 账号容器
```

容器内：

```text
/data/work_dir                             # bind mount: CODING_AGENT_WORK_DIR
/home/arron/.ssh/authorized_keys           # readonly bind mount: CODING_AGENT_SSH_AUTHORIZED_KEYS
/etc/sing-box                              # bind mount: CODING_AGENT_SING_BOX_CONFIG_DIR
```

## 核心决策

| 决策 | 当前设计 |
|---|---|
| 基础镜像 | `coding-agent-base:debian-bookworm` |
| Compose 入口 | `compose/coding-agent/docker-compose.sing-box.yml` |
| Compose 配置 | `compose/coding-agent/coding-agent.env` |
| 容器用户 | `arron:staff`，UID/GID `501:20`，`HOME=/home/arron`，免密 sudo |
| 需求代码 | 宿主机 `CODING_AGENT_WORK_DIR`，容器 `/data/work_dir` |
| 账号状态 | 宿主机 `.coding_agents/<account>`，不挂载进容器 |
| SSH 公钥 | 宿主机 `CODING_AGENT_SSH_AUTHORIZED_KEYS`，容器 `/home/arron/.ssh/authorized_keys` |
| sing-box 配置 | 宿主机 `CODING_AGENT_SING_BOX_CONFIG_DIR`，容器 `/etc/sing-box` |
| 容器代理 | 跟随容器网络，由 `sing_box_gateway` 的 sing-box TUN 处理 |
| 宿主机 shim 代理 | `scripts/proxy.env` 根据是否存在 `sing-box` 选择 TUN 环境变量或 HTTP proxy |

## Compose 结构

`sing_box_gateway` 负责 TUN、DNS、代理路由和 SSH 端口发布。`coding_agent` 通过 `network_mode: service:sing_box_gateway` 共享 gateway 网络命名空间，因此 SSH 端口必须发布在 gateway 服务上。

`CODING_AGENT_WORK_DIR`、`CODING_AGENT_SSH_AUTHORIZED_KEYS`、`CODING_AGENT_SING_BOX_CONFIG_DIR`、`CODING_AGENT_SSH_PORT` 必须在 `coding-agent.env` 中配置。`CODING_AGENT_IMAGE` 和 `CODING_AGENT_SING_BOX_IMAGE` 可按需覆盖。

## Base Image 边界

base image 提供基础系统工具、SSH、Docker CLI、网络诊断工具、中文 UTF-8 locale、新加坡时区、Node.js 22，以及 Claude Code、OpenAI Codex CLI、Gemini CLI。Go、Rust、Python 项目依赖、clangd、gopls、pyright、mise 等项目工具链不放入 base image，由具体项目初始化流程安装。

## 安全边界

认证状态、OAuth token、SSH key 和本地生成状态不得进入 git-tracked 文件。`scripts/proxy.env` 是宿主机与 Docker/OrbStack 网络环境适配，不应包含账号 token 或私密认证信息。项目依赖和项目配置应写入项目目录或项目约定位置，不应写入账号状态目录。

`.coding_agents/` 下的每个子目录都是本地账号长期状态。项目维护时不得删除既有账号目录；切换当前运行账号只能通过修改 `CODING_AGENT_SSH_AUTHORIZED_KEYS` 和 `CODING_AGENT_SING_BOX_CONFIG_DIR` 指向，或复制状态到新的目标目录完成。
