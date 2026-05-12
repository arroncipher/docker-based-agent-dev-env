# 验证方案

本文档记录本仓库的静态检查和运行时检查。修改 Dockerfile、Compose、entrypoint、网络、SSH、用户、locale 或 Agent CLI 后，应至少执行对应部分。

## 静态检查

检查 Shell 语法：

```bash
bash -n images/coding-agent-base/debian-bookworm/entrypoint.sh
bash -n scripts/*.sh
```

检查 Compose 展开：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  config
```

重点确认：

- `coding_agent.user` 为 `arron`。
- `working_dir` 和 `HOME` 为 `/home/arron`。
- `TZ=Asia/Singapore`。
- `LANG/LC_ALL=zh_CN.UTF-8`，`LANGUAGE=zh_CN:zh:en_US:en`。
- `/Users/arron/work_dir` 挂载到 `/data/work_dir`。
- `scripts/ssh/authorized_keys` 只读挂载到 `/home/arron/.ssh/authorized_keys`。
- `scripts/sing-box` 挂载到 `/etc/sing-box`。

检查敏感文件边界：

```bash
git status --short scripts/ssh scripts/sing-box .gitignore
```

预期：`scripts/ssh/` 不出现；`scripts/sing-box/config.json` 可作为无凭据运行配置跟踪。

## 镜像构建检查

```bash
scripts/host-build-base-image.sh
```

预期：成功构建 `coding-agent-base:debian-bookworm`。该步骤会安装 Node.js、Claude Code、OpenAI Codex CLI 和 Gemini CLI，需要可访问 Debian、NodeSource 和 npm registry。

## 启动检查

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
  ps
```

预期：`coding_agent` 和 `sing_box_gateway` 均为 `Up`，SSH 端口发布为 `127.0.0.1:22001->22/tcp`。

## 容器运行时检查

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
pwd
whoami
id
echo "$HOME"
echo "$TZ"
echo "$LANG"
echo "$LC_ALL"
echo "$LANGUAGE"
date
sudo -n true && echo sudo:ok
locale -a | grep -E "^(en_US|zh_CN)\.utf8$"
test -d /data/work_dir/dev_env && echo dev_env_visible:ok
test ! -e /home/arron/.coding_agents && echo no_coding_agents_mount:ok
mount | grep -E "(/data/work_dir|authorized_keys)"
'
```

预期：用户为 `arron`，UID/GID 为 `501:20`，主组为 `staff`，具备免密 sudo；`/data/work_dir/dev_env` 可见；`/home/arron/.coding_agents` 不存在。

## Agent CLI 检查

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
node --version
npm --version
claude --version
codex --version
gemini --version
'
```

预期：四类命令均输出版本号。

## SSH 检查

```bash
ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -i scripts/ssh/id_ed25519 \
  -p 22001 \
  arron@127.0.0.1 \
  'pwd; whoami; id; command -v claude; command -v codex; command -v gemini; echo LANG=$LANG; echo TZ=$TZ'
```

预期：登录用户为 `arron`，工作目录为 `/home/arron`，`claude`、`codex`、`gemini` 可从 `/usr/local/bin` 找到。

## 网络检查

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
dig @172.19.0.1 github.com A +time=8 +tries=2 >/dev/null && echo dns_github:ok
dig @172.19.0.1 www.google.com A +time=8 +tries=2 >/dev/null && echo dns_google:ok
curl -sS --max-time 15 https://github.com -o /dev/null -w "github:%{http_code} time:%{time_total}\n"
curl -sS --max-time 15 https://www.google.com -o /dev/null -w "google:%{http_code} time:%{time_total}\n"
ip addr show tun0 | sed -n "1,3p"
'
```

预期：DNS 返回 `ok`，GitHub 返回 `200`，Google 返回 `302`，`tun0` 存在。上游代理偶发 EOF 时可以重试一次；连续失败需查看 sing-box 日志：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  logs --no-color --tail=120 sing_box_gateway
```

## sing-box / DNS 深入验证

上面的网络检查是冒烟测试。当怀疑 TUN、DNS 劫持、直连分流或代理出口有问题时，按本节逐项排查。

### sing-box 进程与配置重载

修改 `scripts/sing-box/config.json` 后，**无需重启容器**，向 sing-box 发送 SIGHUP 即可让它重载配置（coding_agent 不断网）：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  kill -s HUP sing_box_gateway
```

如果重载后行为没变化，看日志确认 sing-box 是否真的 reload 了：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  logs --no-color --tail=40 sing_box_gateway
```

### TUN 接口与 auto_route

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
ip -4 addr show tun0
echo "---"
ip route | grep -E "tun0|default" | head -20
'
```

预期：

- `tun0` 存在，地址 `172.19.0.1/30`，`POINTOPOINT,UP`。
- 路由表里默认/大段网段经 `dev tun0`。
- `route_exclude_address` 中列出的私有段保留经 `eth0`（或宿主桥接口）。

### DNS 劫持是否真的生效

当前 `tun-in` 未开启 `sniff`，因此 `protocol: dns` 规则**不会**捕获指向任意 IP 的 53 端口流量。生效的劫持路径是：**应用通过 `/etc/resolv.conf` 的默认 nameserver（已被 sing-box 改写为 `172.19.0.1`）发送查询 → dns-in 入站规则 hijack**。

判据：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
cat /etc/resolv.conf | grep nameserver
dig +short +time=4 +tries=1 github.com
dig @172.19.0.1 +short +time=4 +tries=1 github.com
'
```

预期：

- `resolv.conf` 的 nameserver 为 `172.19.0.1`（sing-box 改写的，不是 compose 的 `dns:` 字段）。
- 两条 dig 都返回 GitHub IP。

不要用 `dig @8.8.8.8 github.com` 作劫持判据——这种包确实经 tun0，但 sing-box 不识别 UDP 包内容为 DNS，会按普通 UDP 交给 HTTP 代理，代理不支持 UDP，最终超时。这不代表 sing-box 坏了，只代表 sniffer 没开。如果**确实**需要拦截"硬编码外部 DNS"的应用，需要在 `tun-in` 加 `"sniff": true`。

### DNS 直连分流（dns.rules）

`scripts/sing-box/config.json` 的 `dns.rules` 把 `myhexin.com` / `qq.com` 的解析改走 `direct-doh`（不经上游代理）。验证两类域名延迟差异：

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
for d in www.qq.com github.com www.google.com; do
  echo -n "$d "
  /usr/bin/time -f "%e s" dig +short +time=4 +tries=1 "$d" >/dev/null
done 2>&1
'
```

预期：`qq.com` 解析时间显著低于 `github.com` / `google.com`（前者经宿主直连 1.1.1.1，后者绕代理）。

### 流量出口与代理生效

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
curl -sS --max-time 8 https://api.ipify.org && echo
curl -sS --max-time 8 https://www.qq.com    -o /dev/null -w "qq:%{http_code} ip=%{remote_ip} t=%{time_total}\n"
curl -sS --max-time 8 https://github.com    -o /dev/null -w "github:%{http_code} ip=%{remote_ip} t=%{time_total}\n"
'
```

预期：

- `api.ipify.org` 返回**上游代理的公网出口 IP**（应与宿主机直连看到的 IP 不同）。
- `qq.com` 的 `remote_ip` 是国内 CDN 节点，`time_total` 较低（直连）。
- `github.com` 的 `remote_ip` 是 GitHub 全球节点（经代理）。

### 宿主侧观察容器到代理的连接

在**宿主机**上确认上游代理 `0.250.250.254:7897` 接到了来自容器的连接：

```bash
ss -tnp 2>/dev/null | grep 7897
# 或
lsof -iTCP:7897 -sTCP:ESTABLISHED -n -P 2>/dev/null | head
```

预期：能看到本机进程或 Docker 网络上的连接。

### host.docker.internal 映射

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent getent hosts host.docker.internal
```

预期：返回宿主在 Docker 桥/orbstack 上的 IP。此条由 `extra_hosts` 写进 gateway 的 `/etc/hosts`，并通过 `network_mode: service:` 共享给 coding_agent。

### dns-in 监听端口（旁路验证）

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent sh -c 'awk "NR==1 || \$2 ~ /:0035\$/" /proc/net/udp'
```

预期：表头之外至少有一行，本地地址列对应 `172.19.0.1:53`（十六进制 `010013AC:0035`，按 little-endian 解码：`AC.13.00.01` = `172.19.0.1`，端口 `0x0035` = 53）。此端口仅监听 UDP。

### policy routing 验证

`auto_route` 不依赖修改 main 路由表（main 表的默认路由仍是 eth0）。它通过 `ip rule` 把命中条件的流量送到自定义路由表 `2022`，表里再指向 `dev tun0`。

```bash
docker-compose \
  --env-file compose/coding-agent/coding-agent.env \
  -f compose/coding-agent/docker-compose.sing-box.yml \
  exec coding_agent bash -lc '
ip rule
echo "---"
ip route get 8.8.8.8
'
```

预期：

- `ip rule` 中有若干 9000-9003 优先级的规则指向 `lookup 2022`。
- `ip route get 8.8.8.8` 返回 `via 172.19.0.2 dev tun0 table 2022`。

注意：compose YAML 里 `sing_box_gateway.dns: [1.1.1.1, 8.8.8.8]` **不进入运行时 resolv.conf**——sing-box `stack: system + auto_route: true` 会覆盖之。compose 的 `dns:` 字段在当前配置下是死代码，但保留它对当前运行不造成影响。

## VS Code 检查

使用 `Dev Containers: Attach to Running Container...` 连接 `coding_agent`，再打开：

```text
/data/work_dir/<ticket-or-repo>
```

预期：VS Code Server 能安装在 `/home/arron` 下，终端用户为 `arron`，项目目录可读写。此项需要 GUI 人工确认。
