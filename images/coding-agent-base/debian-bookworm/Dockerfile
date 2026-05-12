# Coding Agent Base Image
# Lightweight runtime base for local coding agents.

FROM debian:bookworm-slim

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dnsutils \
    docker.io \
    git \
    gnupg \
    htop \
    iproute2 \
    iputils-ping \
    jq \
    locales \
    lsof \
    net-tools \
    netcat-openbsd \
    openssh-server \
    ripgrep \
    sudo \
    strace \
    tzdata \
    tmux \
    unzip \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Disable IPv6 at image level so glibc/name resolution won't return IPv6
# addresses even if DNS returns them. This avoids OrbStack fake IPv6 (2001::1)
# causing connection failures through IPv4-only upstream proxies.
RUN printf 'net.ipv6.conf.all.disable_ipv6=1\nnet.ipv6.conf.default.disable_ipv6=1\n' > /etc/sysctl.d/99-disable-ipv6.conf

ARG CODING_AGENT_USER=arron
ARG CODING_AGENT_UID=501
ARG CODING_AGENT_GROUP=staff
ARG CODING_AGENT_GID=20

RUN set -eux; \
    if getent group "$CODING_AGENT_GROUP" >/dev/null; then \
      existing_gid="$(getent group "$CODING_AGENT_GROUP" | cut -d: -f3)"; \
      if [ "$existing_gid" != "$CODING_AGENT_GID" ]; then groupmod -n "${CODING_AGENT_GROUP}-base" "$CODING_AGENT_GROUP"; fi; \
    fi; \
    if getent group "$CODING_AGENT_GID" >/dev/null; then \
      groupmod -n "$CODING_AGENT_GROUP" "$(getent group "$CODING_AGENT_GID" | cut -d: -f1)"; \
    else \
      groupadd -g "$CODING_AGENT_GID" "$CODING_AGENT_GROUP"; \
    fi; \
    useradd -m -u "$CODING_AGENT_UID" -g "$CODING_AGENT_GID" -s /bin/bash "$CODING_AGENT_USER"; \
    usermod -aG sudo "$CODING_AGENT_USER"; \
    if getent group docker >/dev/null; then usermod -aG docker "$CODING_AGENT_USER"; fi; \
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$CODING_AGENT_USER" > "/etc/sudoers.d/$CODING_AGENT_USER"; \
    chmod 0440 "/etc/sudoers.d/$CODING_AGENT_USER"; \
    mkdir -p "/home/$CODING_AGENT_USER/.ssh" /data/work_dir /run/sshd; \
    chmod 700 "/home/$CODING_AGENT_USER" "/home/$CODING_AGENT_USER/.ssh"; \
    chown -R "$CODING_AGENT_USER:$CODING_AGENT_GROUP" "/home/$CODING_AGENT_USER"

ENV HOME="/home/arron"
ENV TZ="Asia/Singapore"
ENV LANG="zh_CN.UTF-8"
ENV LC_ALL="zh_CN.UTF-8"
ENV LANGUAGE="zh_CN:zh:en_US:en"
ENV NPM_CONFIG_PREFIX="/home/arron/.npm-global"
ENV PATH="/home/arron/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 zh_CN.UTF-8 \
    && update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN:zh:en_US:en

RUN sed -i 's/^#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

RUN printf 'set -g default-terminal "xterm-256color"\nset -ga terminal-overrides ",xterm-256color:Tc"\n' \
    | tee /etc/tmux.conf > /dev/null

RUN printf 'export HOME="%s"\nexport TZ="%s"\nexport LANG="%s"\nexport LC_ALL="%s"\nexport LANGUAGE="%s"\nexport NPM_CONFIG_PREFIX="%s"\nexport PATH="%s/bin:$PATH"\n' \
      "$HOME" "$TZ" "$LANG" "$LC_ALL" "$LANGUAGE" "$NPM_CONFIG_PREFIX" "$NPM_CONFIG_PREFIX" \
    | tee /etc/profile.d/coding-agent-home.sh > /dev/null

RUN sed -ri 's/^#?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -ri 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -ri 's@^#?AuthorizedKeysFile .*@AuthorizedKeysFile /home/arron/.ssh/authorized_keys@' /etc/ssh/sshd_config

RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    printf 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main\n' \
      > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p /home/arron/.npm-global; \
    chown -R arron:staff /home/arron/.npm-global

USER arron
RUN npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli

COPY entrypoint.sh /usr/local/bin/coding-agent-entrypoint
USER root
RUN chmod +x /usr/local/bin/coding-agent-entrypoint \
    && ln -sf /home/arron/.npm-global/bin/claude /usr/local/bin/claude \
    && ln -sf /home/arron/.npm-global/bin/codex /usr/local/bin/codex \
    && ln -sf /home/arron/.npm-global/bin/gemini /usr/local/bin/gemini

USER arron
WORKDIR /home/arron

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/coding-agent-entrypoint"]
CMD ["bash"]
