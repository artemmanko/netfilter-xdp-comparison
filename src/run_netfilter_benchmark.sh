#!/bin/bash
# run_netfilter_benchmark.sh
# Использование: ./run_netfilter_benchmark.sh [tcp|udp]

TEST_TYPE=${1:-tcp}
DURATION=30
UDP_BW="100M"

RESULT_DIR="/root/netfilter_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"

echo "=== Netfilter бенчмарк ($TEST_TYPE) ==="
echo "Результаты будут сохранены в: $RESULT_DIR"

# 1. Запуск сервера iperf3 на клиенте B (192.168.2.2)
echo "[1/4] Запуск iperf3 сервера на 192.168.2.2..."
ssh root@192.168.2.2 "iperf3 -s -p 5201 -1 -J" > "$RESULT_DIR/server_${TEST_TYPE}.json" &
SERVER_PID=$!
sleep 2

# 2. Сбор метрик на роутере
echo "[2/4] Сбор метрик CPU/сети на роутере..."
/root/collect_netfilter.sh $((DURATION + 5)) &
COLLECT_PID=$!

# 3. Запуск клиента iperf3 на клиенте A (192.168.1.2)
echo "[3/4] Запуск iperf3 клиента на 192.168.1.2..."
if [ "$TEST_TYPE" = "tcp" ]; then
    ssh root@192.168.1.2 "iperf3 -c 192.168.2.2 -p 5201 -t $DURATION -J" > "$RESULT_DIR/client_${TEST_TYPE}.json"
else
    ssh root@192.168.1.2 "iperf3 -c 192.168.2.2 -p 5201 -u -b $UDP_BW -t $DURATION -J" > "$RESULT_DIR/client_${TEST_TYPE}.json"
fi

wait $COLLECT_PID
wait $SERVER_PID

# 4. Дополнительно: замер ping (только TCP)
if [ "$TEST_TYPE" = "tcp" ]; then
    echo "Замер ping между клиентами..."
    ssh root@192.168.1.2 "ping 192.168.2.2 -c 50 -i 0.2" > "$RESULT_DIR/ping.txt"
fi

echo "=== Бенчмарк завершён ==="
echo "Результаты находятся в: $RESULT_DIR"
ls -la "$RESULT_DIR"
