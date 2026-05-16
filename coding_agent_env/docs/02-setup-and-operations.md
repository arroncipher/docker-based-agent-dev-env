# 搭建与日常操作

## 准备配置

确认 Docker 或 OrbStack 已运行，且 `docker-compose` 可用。编辑：

```text
compose/coding-agent/coding-agent.env
```

最小配置：

```env
CODING_AGENT_WORK_DIR=/Users/arron/work_dir
CODING_AGENT_SSH_AUTHORIZED_KEYS=/Users/arron/work_dir/dev_env/scripts/ssh/authorized_keys
CODING_AGENT_SING_BOX_CONFIG_DIR=/Users/arron/work_dir/dev_env/scripts/sing-box
CODING_AGENT_SSH_PORT=22001
CODING_AGENT_IMAGE=coding-agent-base:debian-bookworm
CODING_AGENT_SING_BOX_IMAGE=ghcr.io/sagernet/sing-box:latest
```

准备 SSH 公钥：

```text
$CODING_AGENT_SSH_AUTHORIZED_KEYS
```

`scripts/ssh/` 是本地运行密钥目录，已被 git 忽略；不要提交私钥。`.coding_agents/` 下已有账号目录也不得删除。

准备 sing-box 配置：

```bash
mkdir -p "$CODING_AGENT_SING_BOX_CONFIG_DIR"
cp compose/coding-agent/sing-box.config.json "$CODING_AGENT_SING_BOX_CONFIG_DIR/config.json"
```

## 构建基础镜像

```bash
scripts/host-build-base-image.sh
```

当 `coding_agent_env/images/coding-agent-base/debian-bookworm/Dockerfile` 或 `entrypoint.sh` 变化后，需要重新构建。

## 校验 Compose

```bash
docker-compose \
  --env-file coding_agent_env/compose/coding-agent/coding-agent.env \
  -f coding_agent_env/compose/coding-agent/docker-compose.sing-box.yml \
  config
```

## 启动与停止

启动：

```bash
docker-compose \
  --env-file coding_agent_env/compose/coding-agent/coding-agent.env \
  -f coding_agent_env/compose/coding-agent/docker-compose.sing-box.yml \
  up -d
```

查看：

```bash
docker-compose \
  --env-file coding_agent_env/compose/coding-agent/coding-agent.env \
  -f coding_agent_env/compose/coding-agent/docker-compose.sing-box.yml \
  ps
```

进入容器：

```bash
docker-compose \
  --env-file coding_agent_env/compose/coding-agent/coding-agent.env \
  -f coding_agent_env/compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash
```

停止：

```bash
docker-compose \
  --env-file coding_agent_env/compose/coding-agent/coding-agent.env \
  -f coding_agent_env/compose/coding-agent/docker-compose.sing-box.yml \
  down
```

## VS Code 接入

使用 `Dev Containers: Attach to Running Container...` 连接 `coding_agent` 容器。连接后执行 `File -> Open Folder...`，打开：

```text
/data/work_dir/<ticket-or-repo>
```

需要多个 repo 时使用 `File -> Add Folder to Workspace...`。不要用 `Reopen in Container` 或 `Rebuild Container` 管理此环境。

### CLI 扩展账号绑定

容器里的 `claude` / `codex` / `gemini` 都通过 `scripts/<account>.sh` wrapper 切账号（wrapper 在 `exec` 前改写 `HOME`）。但 **VS Code 扩展层面只有 Claude Code 能稳定绑定到 wrapper**，其他两个扩展无可用钩子，只能从集成终端起 wrapper。

| 扩展 | 扩展层切账号 | 原因 |
|---|---|---|
| `anthropic.claude-code` | ✅ 可配 wrapper 路径 | 暴露 `claudeCode.claudeProcessWrapper` setting，扩展会 spawn 该路径 |
| `openai.chatgpt`（Codex） | ❌ 不支持 | `chatgpt.cliExecutable` 标记 "DEVELOPMENT ONLY"，release build 忽略；扩展用绝对路径 spawn 自带 `bin/<arch>/codex`，不查 PATH；二进制不认 `CODEX_HOME` 之类 env |
| `google.gemini-cli-vscode-ide-companion` | ❌ 不适用 | 扩展只跑 IDE-side MCP/HTTP server，由 `gemini` CLI 主动连入，扩展本身不 spawn CLI |

**Claude Code 扩展（`anthropic.claude-code`）**

setting 键 `claudeCode.claudeProcessWrapper`，window scope，可写到 Machine / Workspace / User 任一层。容器内全 workspace 生效推荐写 Machine Settings：

文件：`/home/arron/.vscode-server/data/Machine/settings.json`

```json
{
  "claudeCode.claudeProcessWrapper": "/data/work_dir/dev_env/scripts/claude_max20.sh",
  "claudeCode.disableLoginPrompt": true
}
```

注意：

- 扩展进程的 `PATH` 不一定包含 `scripts/`，wrapper 路径写**绝对路径**，不要写裸文件名
- 不要叠加 `claudeCode.environmentVariables` 注入 `HOME` / `CLAUDE_CONFIG_DIR`，会与 wrapper 冲突
- 宿主机 User Settings 里的 `claudeCode.environmentVariables`（包括 `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_MODEL` 等）会**跨进 attached container 注入到 claude 子进程**，wrapper 不拦截 env，会覆盖账号本身的 API endpoint 和模型。要切账号前先把宿主机这些 setting 清掉
- 改 setting 后需在命令面板执行 `Developer: Reload Window`
- 切账号：把 wrapper 路径替换成另一个 `scripts/<account>.sh`
- 验证：发起一次会话后 `.coding_agents/<account>/.claude/projects/` 下应出现新文件

**Codex / Gemini**

扩展无可靠切账号钩子，**从集成终端起 wrapper**：

```bash
scripts/codex_plus.sh
scripts/gemini_arron.sh
# 或
scripts/gemini_cipher.sh
```

wrapper 改写 `HOME` 后 exec 真 CLI，状态读写都落到对应 `.coding_agents/<account>/`。Gemini CLI 启动后会自动与同窗口的 Companion 扩展握手。

如果开了 ChatGPT 扩展的 IDE 面板，它 spawn 的 `codex app-server` 用的是 `HOME=/home/arron`、绝对路径自带二进制，与终端里的 wrapper 不是同一份状态，**两条路并存会造成账号视图不一致**，注意只信终端那一份。

## 新需求开发

在宿主机 clone：

```bash
cd "$CODING_AGENT_WORK_DIR"
git clone <repo-url> <ticket-or-repo>
```

然后在 VS Code attached container 中打开 `/data/work_dir/<ticket-or-repo>`。项目依赖、语言工具链、测试和 lint 都按项目文档执行。

## 基础验证

容器内验证：

```bash
whoami
echo "$HOME"
echo "$TZ"
echo "$LANG"
echo "$LC_ALL"
locale -a | grep -E '^(en_US|zh_CN)\.utf8$'
ls /data/work_dir
git --version
curl --version
docker --version
```

预期：`whoami` 为 `arron`，主组为 `staff`，`HOME` 为 `/home/arron`，`TZ=Asia/Singapore`，`LANG/LC_ALL=zh_CN.UTF-8`，`LANGUAGE=zh_CN:zh:en_US:en`，且 `sudo -n true` 成功。账号目录不整体挂载进容器；SSH 公钥位于 `/home/arron/.ssh/authorized_keys`。`claude`、`codex`、`gemini` 和 `node` 应可直接执行。
