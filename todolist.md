# 项目进展与待办

## 已完成

- 重组 `docs/` 文档体系，按开发流程保留 5 份文档：
  - `docs/00-problem-and-scope.md`
  - `docs/01-architecture.md`
  - `docs/02-setup-and-operations.md`
  - `docs/03-network-and-proxy.md`
  - `docs/04-agent-workflow.md`
- 删除旧 SRS、旧多账号方案、旧 VS Code 指南、旧 sing-box 调试日志等重复/过时文档。
- 删除 `compose/coding-agent/docker-compose.dev.yml`。
- 将 Compose 收敛到 `compose/coding-agent/docker-compose.sing-box.yml`。
- 移除 `AGENT_ACCOUNT_ID`、`AGENT_HOME`、`COMPOSE_PROJECT_NAME`。
- 使用 `CODING_AGENT_WORK_DIR`、`CODING_AGENT_SSH_AUTHORIZED_KEYS`、`CODING_AGENT_SING_BOX_CONFIG_DIR`、`CODING_AGENT_SSH_PORT` 作为当前 Compose 配置边界。
- 更新 `entrypoint.sh`，SSH 公钥固定使用 `/home/arron/.ssh/authorized_keys`。
- 已验证 `docker-compose --env-file compose/coding-agent/coding-agent.env -f compose/coding-agent/docker-compose.sing-box.yml config` 通过。
- 已将 `compose/coding-agent/coding-agent.env` 指向真实账号状态下的 SSH 公钥文件和 sing-box 配置目录。
- 已新增 `compose/coding-agent/sing-box.config.json` 作为可跟踪的 sing-box 配置模板，并在 docs 中说明复制到 `$CODING_AGENT_SING_BOX_CONFIG_DIR/config.json`。
- 已清理 `scripts/host-env.sh` 中旧的 `CODING_AGENT_ACCOUNT_ROOT`、account/ticket helper，仅保留 `DEV_ENV_ROOT`、镜像构建默认值和 PATH 配置。
- 已恢复本地 Agent executable shim：`claude_deepseek.sh`、`claude_max20.sh`、`claude_minimax.sh`、`codex_arron_free.sh`、`codex_plus.sh`、`gemini_arron.sh`、`gemini_cipher.sh`。
- 已恢复 `scripts/proxy.env`。该文件用于解决宿主机与 Docker/OrbStack 的网络环境差异，由本地 shim 加载，不存放账号 token。
- 已精简 `CLAUDE.md`，只保留当前事实、常用命令、工作规则和新 docs 索引。
- 已将仓库模板 `compose/coding-agent/sing-box.config.json` 同步到运行配置目录 `scripts/sing-box/config.json`。
- 已完成静态验证：
  - 旧变量/旧文件引用扫描通过（仅保留 todolist/CLAUDE 中的废弃说明）。
  - `bash -n` 校验脚本通过。
  - `jq empty compose/coding-agent/sing-box.config.json` 通过。
  - `docker-compose --env-file compose/coding-agent/coding-agent.env -f compose/coding-agent/docker-compose.sing-box.yml config` 通过。
- 已通过 OrbStack Docker daemon 构建基础镜像 `coding-agent-base:debian-bookworm`。
- 为绕过 Docker Hub 匿名限流，已从 `public.ecr.aws/docker/library/debian:bookworm-slim` 拉取 Debian 官方镜像缓存，并本地 tag 为 `debian:bookworm-slim`。
- 已启动 `docker-compose.sing-box.yml`：
  - `coding-agent-sing_box_gateway-1` 运行中。
  - `coding-agent-coding_agent-1` 运行中。
  - SSH 端口发布为 `127.0.0.1:22001->22/tcp`。
- 已生成本地测试 SSH key，并追加到 `.coding_agents/claude_minimax/ssh/authorized_keys`。
- 已验证 SSH 登录成功：
  ```bash
  ssh -i .coding_agents/claude_minimax/ssh/id_ed25519 -p 22001 arron@127.0.0.1
  ```
- 已验证容器基础环境：
  - `whoami -> arron`
  - `id -> uid=501(arron) gid=20(staff)`
  - `HOME=/home/arron`
  - `sudo -n true` 成功
  - `LANG=en_US.UTF-8`
  - `LC_ALL=en_US.UTF-8`
  - `locale -a` 包含 `en_US.utf8` 和 `zh_CN.utf8`
  - `/home/arron/.ssh/authorized_keys` 已通过只读文件挂载提供。
- 已验证 DNS：
  - `/etc/resolv.conf` 指向 `172.19.0.1`
  - `dig @172.19.0.1 www.google.com A` 返回 `NOERROR`
- 已验证外网 HTTPS：
  - `curl https://github.com` 返回 `HTTP:200`
  - `curl https://www.google.com` 返回 `HTTP:302`
- 已验证 TUN：
  - `tun0` 存在，MTU 为 `1280`
  - sing-box 日志显示 `dns-in`、`tun-in` 和 `outbound/http[http-proxy]` 正常工作。
- 已将容器镜像 `WORKDIR` 和 Compose `working_dir` 改为 `/home/arron`，SSH 与 `docker-compose exec` 默认进入 `/home/arron`。
- 已移除 `coding_agent` 对账号目录的整体挂载；当前只挂载 `/data/work_dir` 和只读 SSH 公钥文件。
- 已移除 Compose 对 `CODING_AGENT_ACCOUNT_DIR` 的依赖，改为显式文件/目录变量。
- 已将 `CODING_AGENT_WORK_DIR` 从仓库目录 `/Users/arron/work_dir/dev_env` 调整为工作根目录 `/Users/arron/work_dir`，避免把 `dev_env` 仓库名写成需求根。
- 已将 `CODING_AGENT_SSH_AUTHORIZED_KEYS` 和 `CODING_AGENT_SING_BOX_CONFIG_DIR` 指向 `scripts/ssh` 与 `scripts/sing-box`；`scripts/ssh/` git 忽略，`scripts/sing-box/config.json` 可跟踪。
- 已重启 Compose 验证新挂载：容器内 `/data/work_dir/dev_env` 可见，entrypoint 可访问 `/data/work_dir/dev_env/scripts/setup-shell-env.sh`。
- 已复测 SSH、`nslookup`、`dig +time=6`、GitHub/Google HTTPS 和 `tun0` 正常。
- 已将容器运行用户模型调整为 `arron:staff`，UID/GID 对齐宿主机 `501:20`，并保留免密 sudo。
- 已在基础镜像中加入 Node.js 22、Claude Code、OpenAI Codex CLI 和 Gemini CLI。
- 已将容器默认时区改为 `Asia/Singapore`，默认语言环境改为 `zh_CN.UTF-8`，并保留 `en_US.UTF-8` locale。
- 已修复登录 shell PATH，`claude`、`codex`、`gemini` 同时通过 `/home/arron/.npm-global/bin` 和 `/usr/local/bin` 可执行。
- 已验证 SSH 远程命令可直接执行 Claude Code、OpenAI Codex CLI 和 Gemini CLI。
- 已梳理 `docs/00-problem-and-scope.md` 中账号相关术语，区分工具登录账号、容器用户、本地工具状态目录和运行配置目录。
- 已执行完整运行时检查：
  - Compose 展开符合 `arron:staff`、`/home/arron`、中文 locale、新加坡时区和显式挂载模型。
  - 容器内用户、sudo、locale、工作根目录、CLI、sing-box 配置挂载均通过。
  - SSH 登录 `arron@127.0.0.1:22001` 成功，远程命令可直接执行 `claude`、`codex`、`gemini`。
  - DNS、GitHub/Google HTTPS 和 `tun0` 检查通过。
- 已新增 `docs/05-verification.md`，沉淀静态检查、镜像构建、运行时检查、SSH、网络和 VS Code GUI 检查方案。
- 已验证容器内不存在 `/home/arron/.coding_agents`，`mount` 仅显示 `/data/work_dir` 和 `/home/arron/.ssh/authorized_keys` 两个 coding_agent 相关挂载。
- 已基于新挂载模型重建镜像、重启 Compose，并复测 SSH、DNS、HTTPS 和 TUN 正常。
- 已确认 `.coding_agents/` 下既有账号目录全部保留，并将“不得删除账号目录”的约定写入 `AGENTS.md`、`docs/01-architecture.md` 和 `docs/02-setup-and-operations.md`。

## 待补齐

- 使用 VS Code Attach 打开 `/data/work_dir/<ticket-or-repo>` 仍需人工 GUI 验证。

## 风险点

- sing-box Compose 已就绪，`config.json` 目前采用仓库模板复制到 `scripts/sing-box` 的维护方式；后续如需账号差异化，可再引入生成脚本。
- 当前环境使用独立 `docker-compose`，不是 `docker compose` 插件；文档和命令应继续保持一致。
- Docker Hub 匿名限流仍可能影响未来全新环境；当前本机已通过 public ECR 缓存绕过。
- 账号状态目录中新增了本地测试私钥 `.coding_agents/claude_minimax/ssh/id_ed25519`，该目录被 `.gitignore` 排除，不应提交。

## 下一步验证

- 构建基础镜像：
  ```bash
  scripts/host-build-base-image.sh
  ```
  当前状态：已完成。
- 校验 Compose：
  ```bash
  docker-compose --env-file compose/coding-agent/coding-agent.env -f compose/coding-agent/docker-compose.sing-box.yml config
  ```
- 启动容器：
  ```bash
  docker-compose --env-file compose/coding-agent/coding-agent.env -f compose/coding-agent/docker-compose.sing-box.yml up -d
  ```
  当前状态：已完成。
- 使用 VS Code Attach 打开 `/data/work_dir/<ticket-or-repo>`。
  当前状态：待人工 GUI 验证。
