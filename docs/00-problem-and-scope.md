# 问题定义与范围

## 目标

本仓库提供一套本地 coding-agent Docker 开发环境，用于让 Claude、Codex、Gemini 等工具在稳定、可复现、可审查的容器环境中处理多个 ticket/repo。

核心问题不是“为每个项目生成一个 devcontainer”，而是隔离工具登录状态、统一需求代码入口、保证 VS Code 接入路径清晰，并通过人工审批和 diff 审查控制多 Agent 修改风险。

## 术语

- 工具登录账号：Claude、Codex、Gemini 等工具自己的登录身份和认证状态。
- 容器用户：容器内 Linux 用户，当前为 `arron:staff`，用于运行 shell、SSH 和开发工具。
- 本地工具状态目录：宿主机 `.coding_agents/<tool-profile>`，保存工具登录状态、缓存和本地生成状态，不整体挂载进容器。
- 运行配置目录：宿主机 `scripts/ssh/` 和 `scripts/sing-box/`，分别向容器提供 SSH 公钥和 sing-box 配置。

## 当前范围

当前实现覆盖：

- 构建共享基础镜像 `coding-agent-base:debian-bookworm`。
- 通过 `compose/coding-agent/docker-compose.sing-box.yml` 启动 coding-agent 容器和 sing-box gateway。
- 将宿主机需求根目录 `CODING_AGENT_WORK_DIR` 挂载到容器 `/data/work_dir`。
- 本地工具状态目录不整体挂载进容器；容器只通过 `CODING_AGENT_SSH_AUTHORIZED_KEYS` 和 `CODING_AGENT_SING_BOX_CONFIG_DIR` 使用运行所需的 SSH 公钥和 sing-box 配置。
- 使用 VS Code `Attach to Running Container` 后打开具体 `/data/work_dir/<ticket-or-repo>`。
- 通过 sing-box TUN 模式让容器外网流量走代理，局域网和宿主机地址直连。

## 非目标

当前方案不追求：

- 每个 ticket 自动创建一个 Dev Container。
- 同一份 compose 并行管理多个工具登录账号实例。
- 使用 `WORKSPACE` 环境变量切换当前需求。
- 在 base image 中预装所有语言工具链。
- 把工具登录认证状态复制进需求仓库。
- 让 Agent 自动 push、merge 主分支或自动解决并发修改冲突。

## 主要边界

工具登录状态属于本地工具状态目录，不属于项目；需求代码属于 `$CODING_AGENT_WORK_DIR/<ticket-or-repo>`，不应写入 `.coding_agents/`。任务边界由 VS Code 当前打开的 folder/workspace 决定，`/data/work_dir` 只是根目录，不应作为日常大 workspace 打开。

## 风险与控制

高风险操作包括修改 Dockerfile、Compose、工具登录状态、生产配置、网络代理、SSH、TUN 配置、大量删除文件或运行未知脚本。这类操作需要先明确影响范围，再执行可回滚的最小变更。
