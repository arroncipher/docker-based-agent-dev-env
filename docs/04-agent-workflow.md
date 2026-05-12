# Agent 工作流

## 工作入口

每个需求从宿主机 `CODING_AGENT_WORK_DIR` 下的一个目录开始：

```text
$CODING_AGENT_WORK_DIR/<ticket-or-repo>
```

容器内对应：

```text
/data/work_dir/<ticket-or-repo>
```

VS Code attach 到 `coding_agent` 后，只打开当前任务需要的 folder。打开的 workspace folder 是任务边界。

## 账号与认证

账号认证在账号容器内完成，状态写入：

```text
/home/arron
```

对应宿主机侧真实账号目录：

```text
.coding_agents/<account>
```

认证状态不得写入需求 repo，也不得进入 git-tracked 文件。

## 多 Agent 协作原则

当前实现不提供自动调度器、自动上下文同步或自动冲突仲裁。多 Agent 协作依赖人工流程控制：

- 明确每个 Agent 的任务边界。
- 明确文件 ownership。
- 完成后审查 diff。
- 合并前检查重叠修改、删除、重命名和生成文件冲突。
- 高风险修改需要人工确认后再执行。

## 验证闭环

每个 Agent 交付前应在当前 workspace folder 内运行项目自己的验证命令，例如：

```bash
npm test
pnpm lint
pytest
go test ./...
cargo test
```

实际命令以目标项目文档为准。本环境不提供跨项目统一测试命令，也不拦截 git commit。

## 禁止行为

Agent 不应：

- 自动 push 或 merge 主分支。
- 在未授权情况下删除大量文件。
- 修改账号状态、SSH、代理或 compose 配置。
- 把 `/data/work_dir` 当作一个大 workspace 批量编辑。
- 把认证信息写入项目目录。

## 代码风格与命名约定

- Shell 脚本使用 Bash；可执行流程优先使用 `set -euo pipefail`，变量必须加引号。
- 宿主机侧 helper 放在 `scripts/`，文件名使用小写 kebab-case，例如 `host-build-base-image.sh`。
- Docker 与 Compose 修改应保留当前 `arron:staff` 用户、`/data/work_dir` 挂载、以及账号目录只按用途挂载的模型；改变这些边界必须同步更新 `docs/01-architecture.md`。

## 提交与 Pull Request 规范

- Commit 主题使用简洁、可读的祈使句，例如 `Update base image SSH setup` 或 `Document sing-box compose flow`。避免历史中出现过的纯数字或单字摘要。
- PR 应说明影响范围、列出验证命令、关联相关 issue 或设计文档。
- 对账号状态、挂载路径、网络、SSH 或代理配置的行为变化必须在 PR 中显式标注。
- 手动容器验证后，把使用的命令和结果一并写进 PR 描述。

## 后续可扩展项

仍可在未来补充：

- session 日志与审计 schema。
- 文件 ownership 检查脚本。
- 冲突检测和人工仲裁提示。
- 项目验证结果的结构化反馈。
