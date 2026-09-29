# Wi-Fi Direct 14/15 源码阅读索引

文章中的 userspace 继续使用 hostap/wpa_supplicant 2.12；Linux Wireless 部分改为 upstream Linux `master`。

文章校对时使用的 Linux `master` 快照：

```text
commit: 72d3fcf802c45d00b300f25b848a93c3a2bd7c7e
subject: Linux 7.3-rc5
date: 2026-09-27
```

`master` 会继续变化。需要完全复现文章中的函数签名和目录结构时，执行：

```bash
LINUX_REF=72d3fcf802c45d00b300f25b848a93c3a2bd7c7e ./fetch-linux-master.sh
```

需要直接阅读运行脚本当天的最新 `master`：

```bash
./fetch-linux-master.sh
```

## 教程 14：控制面进入内核

建议按以下顺序打开：

| 阶段 | 源码文件 | 关键符号 |
|---|---|---|
| P2P Listen | [`p2p_supplicant.c`](hostap-2.12-relevant/wpa_supplicant/p2p_supplicant.c) | `wpas_start_listen()`、`wpas_start_listen_cb()` |
| driver wrapper | [`driver_i.h`](hostap-2.12-relevant/wpa_supplicant/driver_i.h) | `wpa_drv_remain_on_channel()` |
| nl80211 backend | [`driver_nl80211.c`](hostap-2.12-relevant/src/drivers/driver_nl80211.c) | `wpa_driver_nl80211_remain_on_channel()`、`wpa_driver_nl80211_send_action()` |
| kernel nl80211 | [`nl80211.c`](linux-wireless-source/net/wireless/nl80211.c) | `nl80211_remain_on_channel()`、`nl80211_tx_mgmt()` |
| cfg80211 dispatch | [`rdev-ops.h`](linux-wireless-source/net/wireless/rdev-ops.h)、[`mlme.c`](linux-wireless-source/net/wireless/mlme.c) | `rdev_remain_on_channel()`、`cfg80211_mlme_mgmt_tx()` |
| mac80211 ROC/TX | [`offchannel.c`](linux-wireless-source/net/mac80211/offchannel.c) | `ieee80211_remain_on_channel()`、`ieee80211_mgmt_tx()` |
| cfg80211 ops binding | [`cfg.c`](linux-wireless-source/net/mac80211/cfg.c) | `mac80211_config_ops` |
| hwsim radio | [`mac80211_hwsim_main.c`](linux-wireless-source/drivers/net/wireless/virtual/mac80211_hwsim_main.c) | `mac80211_hwsim_roc()`、`mac80211_hwsim_tx_frame_no_nl()`、`mac80211_hwsim_rx()` |
| event return | [`driver_nl80211_event.c`](hostap-2.12-relevant/src/drivers/driver_nl80211_event.c) | `mlme_event_remain_on_channel()`、`mlme_event_mgmt_tx_status()` |

## 教程 15：Group 数据面 TX/RX

| 阶段 | 源码文件 | 关键符号 |
|---|---|---|
| Group netdev TX | [`tx.c`](linux-wireless-source/net/mac80211/tx.c) | `ieee80211_subif_start_xmit()` |
| 802.11 TX handlers | [`tx.c`](linux-wireless-source/net/mac80211/tx.c) | `ieee80211_tx_h_select_key()`、`ieee80211_tx_h_encrypt()` |
| 提交 driver | [`tx.c`](linux-wireless-source/net/mac80211/tx.c)、[`driver-ops.h`](linux-wireless-source/net/mac80211/driver-ops.h) | `__ieee80211_tx()`、`drv_tx()` |
| hwsim virtual medium | [`mac80211_hwsim_main.c`](linux-wireless-source/drivers/net/wireless/virtual/mac80211_hwsim_main.c) | `mac80211_hwsim_tx_frame_no_nl()`、`mac80211_hwsim_rx()` |
| mac80211 RX | [`rx.c`](linux-wireless-source/net/mac80211/rx.c) | RX handlers、`ieee80211_deliver_skb()` |
| 返回 Linux network stack | [`rx.c`](linux-wireless-source/net/mac80211/rx.c) | `ieee80211_deliver_skb_to_local_stack()`、`netif_receive_skb()` |

## 为什么不下载整个 Linux Kernel

教程 14/15 只用于理解 Wi-Fi Direct 穿过 Linux Wireless Stack 后的控制面与数据面，不需要把内核驱动学习扩展到 rate control、A-MPDU、DMA、firmware 或 PHY。因此脚本只 sparse-checkout 与文章调用链直接相关的文件，保存后更适合在 VS Code 中搜索和跳转。
