#!/bin/bash
# run_xdp_benchmark.sh
# Использование: ./run_xdp_benchmark.sh [tcp|udp]

TEST_TYPE=${1:-tcp}
DURATION=30
UDP_BW="100M"
XDP_OBJ="/root/xdp_router.o"

RESULT_DIR="/root/xdp_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"

echo "=== XDP бенчмарк ($TEST_TYPE) ==="
echo "Результаты в: $RESULT_DIR"

# 1. Отключение Netfilter и загрузка XDP
echo "[1/5] Отключение IP forward и загрузка XDP..."
sysctl -w net.ipv4.ip_forward=0
iptables -P FORWARD DROP

bpftool net detach xdpdrv dev enp0s8 2>/dev/null
bpftool net detach xdpdrv dev enp0s9 2>/dev/null
bpftool net attach xdpdrv object $XDP_OBJ dev enp0s8
bpftool net attach xdpdrv object $XDP_OBJ dev enp0s9

# 2. Запуск iperf3 сервера на клиенте B
echo "[2/5] Запуск iperf3 сервера на 192.168.2.2..."
ssh root@192.168.2.2 "iperf3 -s -p 5201 -1 -J" > "$RESULT_DIR/server_${TEST_TYPE}.json" &
SERVER_PID=$!
sleep 2

# 3. Сбор метрик на роутере
echo "[3/5] Сбор метрик CPU/сети..."
/root/collect_netfilter.sh $((DURATION + 5)) &
COLLECT_PID=$!

# 4. Запуск iperf3 клиента на клиенте A
echo "[4/5] Запуск iperf3 клиента на 192.168.1.2..."
if [ "$TEST_TYPE" = "tcp" ]; then
    ssh root@192.168.1.2 "iperf3 -c 192.168.2.2 -p 5201 -t $DURATION -J" > "$RESULT_DIR/client_${TEST_TYPE}.json"
else
    ssh root@192.168.1.2 "iperf3 -c 192.168.2.2 -p 5201 -u -b $UDP_BW -t $DURATION -J" > "$RESULT_DIR/client_${TEST_TYPE}.json"
fi

wait $COLLECT_PID
wait $SERVER_PID

# 5. Замер ping (только TCP)
if [ "$TEST_TYPE" = "tcp" ]; then
    echo "Замер ping..."
    ssh root@192.168.1.2 "ping 192.168.2.2 -c 50 -i 0.2" > "$RESULT_DIR/ping.txt"
fi

# 6. Выгрузка XDP и восстановление Netfilter
echo "[5/5] Выгрузка XDP и восстановление настроек..."
bpftool net detach xdpdrv dev enp0s8
bpftool net detach xdpdrv dev enp0s9
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT

echo "=== Бенчмарк завершён ==="
ls -la "$RESULT_DIR"
