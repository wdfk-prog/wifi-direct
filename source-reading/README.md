# Wi-Fi Direct 14/15 源码阅读包

这个目录配套教程 14、15。

- `hostap-2.12-relevant/`：从本项目使用的 hostap 2.12 源码快照中提取的相关原文件，可直接离线阅读。
- `fetch-linux-master.sh`：从 `torvalds/linux` sparse-checkout 教程需要的 Linux Wireless 文件。
- `SOURCE-INDEX.md`：按文章执行路径列出应阅读的文件和关键符号。

Linux `master` 是移动分支。文章本次校对固定在：

```text
72d3fcf802c45d00b300f25b848a93c3a2bd7c7e  Linux 7.3-rc5
```

复现文章：

```bash
cd source-reading
LINUX_REF=72d3fcf802c45d00b300f25b848a93c3a2bd7c7e ./fetch-linux-master.sh
```

获取以后最新的 `master`：

```bash
cd source-reading
./fetch-linux-master.sh
```

脚本只下载文章实际使用的源码路径，不编译 kernel，也不会修改系统内核。
