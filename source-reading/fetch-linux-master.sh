#!/bin/sh
set -eu

# Wi-Fi Direct 14/15 only need a small Linux Wireless source subset.
# Default: fetch the latest upstream master when this script is executed.
# Reproduce the article snapshot with:
#   LINUX_REF=72d3fcf802c45d00b300f25b848a93c3a2bd7c7e ./fetch-linux-master.sh

REPO_URL=${LINUX_REPO_URL:-https://github.com/torvalds/linux.git}
REF=${LINUX_REF:-master}
OUT=${LINUX_OUT:-linux-wireless-source}

if [ -e "$OUT" ]; then
    echo "error: output path already exists: $OUT" >&2
    exit 1
fi

mkdir -p "$OUT"
cd "$OUT"
git init -q
git remote add origin "$REPO_URL"
git sparse-checkout init --no-cone
cat > .git/info/sparse-checkout <<'PATTERNS'
/COPYING
/include/uapi/linux/nl80211.h
/include/net/cfg80211.h
/include/net/mac80211.h
/net/wireless/nl80211.c
/net/wireless/mlme.c
/net/wireless/rdev-ops.h
/net/mac80211/cfg.c
/net/mac80211/offchannel.c
/net/mac80211/tx.c
/net/mac80211/rx.c
/net/mac80211/iface.c
/net/mac80211/driver-ops.h
/drivers/net/wireless/virtual/mac80211_hwsim_main.c
/drivers/net/wireless/virtual/mac80211_hwsim.h
/drivers/net/wireless/virtual/mac80211_hwsim_i.h
PATTERNS

echo "Fetching Linux ref: $REF"
git fetch --depth 1 origin "$REF"
git checkout -q --detach FETCH_HEAD

printf '\nFetched commit:\n'
git log -1 --format='%H%n%cd%n%s' --date=iso-strict
printf '\nSource root: %s\n' "$(pwd)"
