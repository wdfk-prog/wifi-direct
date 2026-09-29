# 阶段 1：向下进入 driver_nl80211 → nl80211 → cfg80211

## 目标

此时才开始正式读 Linux 内核无线控制路径。

## 阅读原则

只沿已经亲自实验过的调用下钻。

第一条建议：

```text
remain_on_channel
```

第二条建议：

```text
management frame TX
```

## 用户态

重点：

```text
src/drivers/driver_nl80211*.c
```

找到对应：

```text
NL80211_CMD_*
```

## Kernel

再进入：

```text
include/uapi/linux/nl80211.h
net/wireless/nl80211.c
include/net/cfg80211.h
net/wireless/*
```

## 必须理解

形成：

```text
P2P state machine
        ↓
wpa_driver_ops
        ↓
driver_nl80211
        ↓
Generic Netlink
        ↓
nl80211
        ↓
cfg80211
        ↓
mac80211 / driver callback
```

## 不要求

- 读完整 `nl80211.c`；
- 读完整 cfg80211；
- 读完整 mac80211。

## 验收

能够任选一个真实 P2P 动作，从 userspace 找到 kernel 对应入口。

---

# 阶段 2：阅读 upstream tests/hwsim

## 目标

在已经手工理解全部核心流程后，再看 upstream 如何自动化验证 P2P。

## 阅读方式

搜索：

```text
P2P
p2p_find
p2p_connect
GROUP-STARTED
GO-NEG
```

重点学习：

- test setup；
- event wait；
- timeout；
- cleanup；
- failure injection；
- repeatability。

## 价值

这一步相当于从：

```text
自己手工实验
```

升级到：

```text
上游维护者如何验证 P2P
```

## 验收

能够选一个 P2P hwsim test，完整解释：

```text
setup
→ action
→ expected event
→ assertion
→ cleanup
```

---
