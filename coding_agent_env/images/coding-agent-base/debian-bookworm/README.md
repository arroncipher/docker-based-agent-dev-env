# coding-agent-base:debian-bookworm

Lightweight base image for coding-agent containers. The default user is
`arron:staff` with UID/GID `501:20` and passwordless sudo.

Build:

```bash
scripts/host-build-base-image.sh
```

This image includes Node.js 22 plus Claude Code, OpenAI Codex CLI, and Gemini CLI. Project language toolchains such as Go, Rust, clangd, gopls, pyright, and mise are not installed by default.
