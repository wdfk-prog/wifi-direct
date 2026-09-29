# Ubuntu 24.04 作为 Container 的 userspace 基础环境。
# mac80211_hwsim 属于 Ubuntu Host 的 Linux kernel module，不在这个 Image 中加载。
FROM ubuntu:24.04

# 避免 apt 在 docker build 过程中弹出交互式配置界面。
ARG DEBIAN_FRONTEND=noninteractive

# Container 内统一使用 dev 作为开发用户。
# USER_UID / USER_GID 默认使用 1000；本地构建时由 compose.yaml 从 .env 传入 Host UID/GID，
# 这样 bind mount 到 /workspace 后，新建文件不会轻易变成 root:root。
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# 固定本系列学习和调试使用的 wpa_supplicant release。
ARG WPA_SUPPLICANT_VERSION=2.12
ARG WPA_SUPPLICANT_GIT_URL=https://git.w1.fi/hostap.git
ARG WPA_SUPPLICANT_COMMIT=831364bf02710ad09c2f27d3efa92abeeb5634c0

# 安装四类工具：
# 1. 编译工具：build-essential、pkg-config。
# 2. wpa_supplicant 构建依赖：libnl-3-dev、libnl-genl-3-dev、libssl-dev、libreadline-dev。
# 3. 无线/网络实验工具：iw、iproute2、iputils-ping、rfkill、tcpdump。
# 4. 源码阅读与调试工具：gdb、gdbserver、bear、git、less、vim、procps、sudo、curl、ca-certificates。
#
# apt-get update 只刷新软件包索引；apt-get install 才真正安装软件。
# --no-install-recommends 避免把非必需的推荐软件一起装入 Image。
# 最后删除 /var/lib/apt/lists，减少 Image layer 体积。
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-client \
        build-essential \
        pkg-config \
        libnl-3-dev \
        libnl-genl-3-dev \
        libssl-dev \
        libreadline-dev \
        iw \
        iproute2 \
        iputils-ping \
        rfkill \
        tcpdump \
        gdb \
        gdbserver \
        bear \
        git \
        less \
        vim \
        procps \
        sudo \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建或复用开发用户。
#
# 基础 Image 可能已经存在与 USER_UID / USER_GID 相同的用户或组，
# 因此这里先查询再复用，最终统一得到 dev:/home/dev。
RUN set -eux; \
    existing_user="$(getent passwd "${USER_UID}" | cut -d: -f1 || true)"; \
    existing_group="$(getent group "${USER_GID}" | cut -d: -f1 || true)"; \
    if [ -n "${existing_user}" ]; then \
        if [ "${existing_user}" != "${USERNAME}" ]; then \
            old_user="${existing_user}"; \
            old_home="$(getent passwd "${old_user}" | cut -d: -f6)"; \
            usermod --login "${USERNAME}" "${old_user}"; \
            if [ -d "${old_home}" ]; then \
                usermod --home "/home/${USERNAME}" --move-home "${USERNAME}"; \
            else \
                mkdir -p "/home/${USERNAME}"; \
                usermod --home "/home/${USERNAME}" "${USERNAME}"; \
            fi; \
            if [ "${existing_group}" = "${old_user}" ] && ! getent group "${USERNAME}" >/dev/null 2>&1; then \
                groupmod --new-name "${USERNAME}" "${existing_group}"; \
            fi; \
        fi; \
    else \
        if [ -z "${existing_group}" ]; then \
            groupadd --gid "${USER_GID}" "${USERNAME}"; \
        fi; \
        primary_group="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        useradd \
            --uid "${USER_UID}" \
            --gid "${primary_group}" \
            --create-home \
            --shell /bin/bash \
            "${USERNAME}"; \
    fi; \
    primary_group="$(getent group "${USER_GID}" | cut -d: -f1)"; \
    usermod --gid "${primary_group}" --shell /bin/bash "${USERNAME}"; \
    chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"

# 只给实验需要的程序配置免密码 sudo，不使用 NOPASSWD:ALL。
#
# wpa_supplicant-2.12：手工实验时需要 root 身份执行 nl80211 无线管理操作。
# wpa_cli-2.12：当前 control socket 由 root wpa_supplicant 创建，教程继续允许通过 sudo 访问。
# gdbserver：F5 时仅让 gdbserver 以 root 身份启动 wpa_supplicant；VS Code/GDB 本身仍以 dev 运行。
#
# 说明：root gdbserver 本身仍是高权限调试能力，这里只是把 sudoers 从 ALL 收窄到实验所需程序。
RUN printf '%s\n' \
    "${USERNAME} ALL=(root) NOPASSWD: /usr/local/bin/wpa_supplicant-2.12, /usr/local/bin/wpa_cli-2.12, /usr/bin/gdbserver" \
    > "/etc/sudoers.d/${USERNAME}-wifi-direct" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}-wifi-direct" && \
    visudo -cf "/etc/sudoers.d/${USERNAME}-wifi-direct"

# 从官方 hostap Git 仓库获取源码，并保留完整 Git 历史。
# 不使用浅克隆，确保 Container 内可以直接使用 git log / git blame / git show。
# checkout 固定到 2.12 release commit，避免远端分支后续移动改变教程基线。
RUN mkdir -p /opt/wifi-direct/src && \
    git clone "${WPA_SUPPLICANT_GIT_URL}" \
        "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}" && \
    cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}" && \
    git checkout --detach "${WPA_SUPPLICANT_COMMIT}" && \
    test "$(git rev-parse HEAD)" = "${WPA_SUPPLICANT_COMMIT}"

# 第一步先复制官方 defconfig 作为 wpa_supplicant 构建配置基础。
RUN cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}/wpa_supplicant" && \
    cp defconfig .config

# 明确启用本系列实验需要的能力：
# CONFIG_DRIVER_NL80211：Linux nl80211 driver backend。
# CONFIG_LIBNL32：libnl 3.x API。
# CONFIG_CTRL_IFACE：wpa_cli 使用的 UNIX control interface。
# CONFIG_WPS / CONFIG_P2P / CONFIG_AP：Wi-Fi Direct 所需能力。
# CONFIG_READLINE：改善 wpa_cli 交互式输入。
# CONFIG_DEBUG_FILE：保留调试日志输出能力。
RUN cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}/wpa_supplicant" && \
    for opt in \
        CONFIG_DRIVER_NL80211 \
        CONFIG_LIBNL32 \
        CONFIG_CTRL_IFACE \
        CONFIG_WPS \
        CONFIG_P2P \
        CONFIG_AP \
        CONFIG_READLINE \
        CONFIG_DEBUG_FILE; do \
            sed -i "s/^#${opt}=y$/${opt}=y/" .config; \
            grep -q "^${opt}=y$" .config || printf '%s=y\n' "${opt}" >> .config; \
        done

# 本实验使用 wpa_cli -> UNIX control socket -> wpa_supplicant ctrl_iface，
# 不使用 D-Bus control interface，因此关闭对应配置。
RUN cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}/wpa_supplicant" && \
    for opt in \
        CONFIG_CTRL_IFACE_DBUS \
        CONFIG_CTRL_IFACE_DBUS_NEW \
        CONFIG_CTRL_IFACE_DBUS_INTRO; do \
            sed -i "/^${opt}=/d" .config; \
        done && \
    ! grep -Eq '^CONFIG_CTRL_IFACE_DBUS(_NEW|_INTRO)?=y$' .config

# 本实验固定走 nl80211，不启用 MACsec、wired 或旧 WEXT backend。
RUN cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}/wpa_supplicant" && \
    for opt in \
        CONFIG_DRIVER_MACSEC_LINUX \
        CONFIG_DRIVER_WIRED \
        CONFIG_DRIVER_WEXT \
        CONFIG_MACSEC; do \
            sed -i "/^${opt}=/d" .config; \
        done && \
    ! grep -Eq '^(CONFIG_DRIVER_MACSEC_LINUX|CONFIG_DRIVER_WIRED|CONFIG_DRIVER_WEXT|CONFIG_MACSEC)=y$' .config

# 使用 Debug 友好的编译参数：
# -O0：关闭编译优化，减少单步调试时的代码重排。
# -g3：生成更完整的 DWARF 调试信息。
# -fno-omit-frame-pointer：保留 frame pointer，方便 GDB 回溯调用栈。
#
# bear -- make：在真实构建时记录编译命令并生成 compile_commands.json，
# 供 VS Code C/C++ 扩展进行 IntelliSense 和 F12 源码跳转。
RUN cd "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}/wpa_supplicant" && \
    printf '%s\n' \
        'CFLAGS += -O0 -g3 -fno-omit-frame-pointer' \
        >> .config && \
    bear -- make -j"$(nproc)" && \
    install -Dm755 wpa_supplicant /usr/local/bin/wpa_supplicant-2.12 && \
    install -Dm755 wpa_cli /usr/local/bin/wpa_cli-2.12 && \
    ln -s /usr/local/bin/wpa_supplicant-2.12 /usr/local/bin/wpa_supplicant-lab && \
    ln -s /usr/local/bin/wpa_cli-2.12 /usr/local/bin/wpa_cli-lab

# Docker build 阶段以 root clone/build；切换到 dev 前把源码树和 .git 交给开发用户。
# 这样进入 Dev Container 后可直接运行 git status/log/blame/show，不会触发 dubious ownership。
RUN chown -R "${USER_UID}:${USER_GID}" \
    "/opt/wifi-direct/src/wpa_supplicant-${WPA_SUPPLICANT_VERSION}"

# 把固定源码、commit、binary 和 CLI 路径暴露成环境变量。
ENV WPA_SUPPLICANT_SRC=/opt/wifi-direct/src/wpa_supplicant-2.12
ENV WPA_SUPPLICANT_COMMIT=${WPA_SUPPLICANT_COMMIT}
ENV WPA_SUPPLICANT_BIN=/usr/local/bin/wpa_supplicant-2.12
ENV WPA_CLI_BIN=/usr/local/bin/wpa_cli-2.12

# Dev Containers 会把 VS Code Server 安装到该目录。
RUN mkdir -p /home/${USERNAME}/.vscode-server && \
    chown -R "${USER_UID}:${USER_GID}" /home/${USERNAME}/.vscode-server

# 日常开发以普通用户 dev 运行。
USER ${USERNAME}
WORKDIR /workspace

# Container 只作为长期开发环境存在；真正的实验进程由教程或 F5 启动。
CMD ["sleep", "infinity"]
