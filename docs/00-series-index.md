<meta name="referrer" content="no-referrer" />

# Wi-Fi Direct 源码系列索引：hostap / wpa_supplicant 2.12

> 摘要：按真实运行顺序索引 01～13 篇，从实验环境、启动初始化、control path、Device Discovery 到 Group 生命周期。

[TOC]

本索引只承担系列导航。各编号文章保持单一主线，不在前篇提前展开后篇机制。源码统一采用 hostap 2.12 `hostap_2_12`。[S1](#source-s1)

## 系列导航

| 编号 | 主题 | 入口 | 停止点 |
|---|---|---|---|
| 01 | [实验与调试环境](01-wifi-direct-lab.md) | Ubuntu / Docker / hwsim | 双 wpa_supplicant 2.12 实例 |
| 02 | [wpa_cli client control path](02-wpa-cli-to-p2p-find.md) | `wpa_cli main()` | `wpa_ctrl_request()` 同步回复 |
| 03 | [wpa_supplicant 启动与 driver](03-wpa-supplicant-startup-driver.md) | `wpa_supplicant main()` | `nl80211` backend 就绪 |
| 04 | [Interface 协议子系统初始化](04-interface-protocol-init.md) | `wpa_supplicant_init_iface()` 后半段 | WPA/WPS/P2P 等上下文就绪 |
| 05 | [control socket 与 eloop](05-ctrl-iface-eloop.md) | `wpas_ctrl_iface_open_sock()` | `P2P_FIND` 进入 command parser |
| 06 | [P2P_FIND 进入 P2P Core](06-p2p-find-to-core.md) | `p2p_ctrl_find()` | Core 请求第一轮 scan |
| 07 | [第一次 P2P Scan](07-p2p-first-scan.md) | `wpas_p2p_scan()` | scan request 提交给 kernel/driver |
| 08 | [Scan Result 到 P2P Peer](08-scan-result-to-peer.md) | `NL80211_CMD_NEW_SCAN_RESULTS` | `P2P-DEVICE-FOUND` + Find 回环 |
| 09 | [P2P_CONNECT 与 GO Negotiation](09-p2p-connect-go-negotiation.md) | CLI `p2p_connect` | `wpas_go_neg_completed()` / `P2P-GO-NEG-SUCCESS` |
| 10 | [Group Formation 与安全建立](10-group-formation-security.md) | GO Negotiation result | WPS / 4-Way → `P2P-GROUP-STARTED` |
| 11 | [Group Runtime / Data Path](11-group-runtime.md) | `P2P-GROUP-STARTED` | IP/route ready |
| 12 | [Group Teardown](12-group-teardown.md) | `P2P_GROUP_REMOVE` | active Group teardown 完成 |
| 13 | [Persistent Group / Invitation](13-persistent-group.md) | `P2P_INVITE persistent=<id>` | reinvocation 回到 Group Started |

## 按关键符号索引

- 启动/driver：[`wpa_supplicant_init()`](03-wpa-supplicant-startup-driver.md#idx-init) · [`wpa_supplicant_init_iface()`](03-wpa-supplicant-startup-driver.md#idx-init-iface)
- 协议初始化：[`wpas_p2p_init()`](04-interface-protocol-init.md#idx-p2p-init)
- Control server：[`wpa_supplicant_ctrl_iface_receive()`](05-ctrl-iface-eloop.md#idx-receive)
- Find/Core：[`p2p_find()`](06-p2p-find-to-core.md#idx-p2p-find) · [`p2p_scan_type`](06-p2p-find-to-core.md#idx-scan-type)
- Scan request：[`radio_add_work()`](07-p2p-first-scan.md#idx-radio-work)
- Scan completion / Peer：[`_wpa_supplicant_event_scan_results()`](08-scan-result-to-peer.md#idx-scan-event) · [`p2p_add_device()`](08-scan-result-to-peer.md#idx-add-device)
- GO Negotiation：[`p2p_connect()`](09-p2p-connect-go-negotiation.md#idx-p2p-connect) · [`p2p_go_det()`](09-p2p-connect-go-negotiation.md#idx-go-intent) · [`p2p_handle_go_neg_conf()`](09-p2p-connect-go-negotiation.md#idx-rx)
- Group Formation：[`wpas_go_neg_completed()`](10-group-formation-security.md#idx-role) · [`wpas_start_wps_enrollee()`](10-group-formation-security.md#idx-client)
- Group Started：[`wpas_p2p_completed()`](10-group-formation-security.md#idx-completed) · [`wpas_p2p_group_started()`](10-group-formation-security.md#idx-group-started)
- Runtime：[Group Interface](11-group-runtime.md#idx-group-iface)
- Teardown：[`wpas_p2p_group_remove()`](12-group-teardown.md#idx-remove)
- Persistent Group：[`wpas_p2p_store_persistent_group()`](13-persistent-group.md#idx-store)

## 资料来源

<a id="source-s1"></a>
### [S1] hostap 2.12 release Git tag
- 版本：[`hostap_2_12` / `831364bf02710ad09c2f27d3efa92abeeb5634c0`](https://chromium.googlesource.com/chromiumos/third_party/hostap/+/refs/tags/hostap_2_12)
- 来源：[canonical hostap.git](https://git.w1.fi/hostap.git)
- 使用位置：系列导航与源码基线
- 支撑内容：01～13 全系列采用统一 hostap/wpa_supplicant 2.12 source baseline。
