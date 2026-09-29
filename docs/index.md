<meta name="referrer" content="no-referrer" />

# Wi-Fi Direct Source Lab

> 摘要：提供 Wi-Fi Direct Source Lab 的系列入口，覆盖 P2P 用户态机制、Linux Wireless 控制面与 Group 普通 IP 数据面。

[TOC]

本项目围绕 `wpa_supplicant 2.12`、`mac80211_hwsim` 与 Linux Wi-Fi Direct（P2P）建立可复现的源码阅读、实验和调试环境。

从 [源码系列索引](00-series-index.md) 开始，可以按顺序阅读从 `wpa_cli` 控制命令、P2P Discovery、GO Negotiation、Group Formation，到 Group Runtime、Teardown 与 Persistent Group；最后通过教程 14～15 补齐 Wi-Fi Direct 进入 Linux Wireless 后的管理帧控制路径，以及 Group 建立后普通 TCP/UDP 数据的 TX/RX 路径。

