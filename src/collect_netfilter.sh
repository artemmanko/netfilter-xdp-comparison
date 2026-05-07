#!/bin/bash
# collect_netfilter.sh - сбор метрик CPU и сетевых интерфейсов
DURATION=${1:-35}
OUTFILE="/root/netfilter_metrics_$(date +%Y%m%d_%H%M%S).csv"

echo "timestamp,iface,rx_bytes,tx_bytes,cpu_user,cpu_sys,cpu_idle" > "$OUTFILE"

prev_usr=$(awk '/^cpu / {print $2}' /proc/stat)
prev_sys=$(awk '/^cpu / {print $4}' /proc/stat)
prev_idle=$(awk '/^cpu / {print $5}' /proc/stat)

for ((i=0; i<DURATION; i++)); do
    sleep 1

    cur_usr=$(awk '/^cpu / {print $2}' /proc/stat)
    cur_sys=$(awk '/^cpu / {print $4}' /proc/stat)
    cur_idle=$(awk '/^cpu / {print $5}' /proc/stat)

    d_usr=$((cur_usr - prev_usr))
    d_sys=$((cur_sys - prev_sys))
    d_idle=$((cur_idle - prev_idle))
    total=$((d_usr + d_sys + d_idle))

    if [ $total -gt 0 ]; then
        p_usr=$((100 * d_usr / total))
        p_sys=$((100 * d_sys / total))
        p_idle=$((100 * d_idle / total))
    else
        p_usr=0; p_sys=0; p_idle=100
    fi

    prev_usr=$cur_usr; prev_sys=$cur_sys; prev_idle=$cur_idle

    rx8=$(cat /sys/class/net/enp0s8/statistics/rx_bytes 2>/dev/null || echo 0)
    tx8=$(cat /sys/class/net/enp0s8/statistics/tx_bytes 2>/dev/null || echo 0)
    rx9=$(cat /sys/class/net/enp0s9/statistics/rx_bytes 2>/dev/null || echo 0)
    tx9=$(cat /sys/class/net/enp0s9/statistics/tx_bytes 2>/dev/null || echo 0)

    ts=$(date +%H:%M:%S)
    echo "$ts,enp0s8,$rx8,$tx8,$p_usr,$p_sys,$p_idle" >> "$OUTFILE"
    echo "$ts,enp0s9,$rx9,$tx9,$p_usr,$p_sys,$p_idle" >> "$OUTFILE"
done

echo "Метрики сохранены в $OUTFILE"
