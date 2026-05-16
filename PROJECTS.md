# 项目结构

本仓库由若干子项目组成，每个子项目独立维护 scope、非目标、完成判据。

## 子项目列表

| 编号 | 子项目 | scope 文档 | 状态 |
|---|---|---|---|
| 1 | Docker 账户环境搭建 | `coding_agent_env/docs/00-problem-and-scope.md`（详 `coding_agent_env/docs/01`–`05`） | ongoing |
| 2 | 用户提示词搭建 | `user_prompt/README.md`（spec `user_prompt/spec/`、TODO `user_prompt/TODO.md`） | ongoing |

未来子项目按需追加。新子项目在本表登记后，独立放置 scope 文档（推荐 `<subproject>/README.md` 或 `<subproject>/docs/00-problem-and-scope.md`），并在文档骨架中预留 `## 完成判据` 节。

`scripts/` 在仓库根部，跨子项目共享（wrapper、host helper、plugin、statusline、ccusage 等），不归属任何单一子项目。新子项目如需共享脚本，应直接复用根级 `scripts/`；子项目专属脚本放在子项目目录内。

## 跨子项目共享的约束

由仓库 entry 文件（`CLAUDE.md` / `AGENTS.md`）声明，适用于所有子项目：

- 制品语域：harness 工程抽象作为 domain register，harness 运维者作为受众 register，framework 词汇禁入制品命名（见 entry 文件「制品语域」节）。
- Agent 工作规则：不自动 push/merge/解冲突；不把认证写入项目仓库；高风险操作前确认影响与回滚（见 entry 文件「工作规则」节）。

子项目特定约束在自身 scope 文档中声明。

## 子项目划分原则

- **加载边界 = 子项目边界**：子项目应是可独立维护、独立部署、独立验收的单元。
- **共享 spec 或共享代码不构成子项目**：仅当一组制品有独立生命周期、独立 scope 与非目标时才单立子项目。
- **新子项目入仓前**：先在本文件登记并写出 scope 文档骨架（含 `## 完成判据`，可为 TBD），再开始 commit 内容。
