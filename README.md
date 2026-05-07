# netfilter-xdp-comparison
# Сравнительный анализ маршрутизации пакетов: Netfilter vs eBPF/XDP
Данный репозиторий содержит исходные коды и скрипты для воспроизведения эксперимента, описанного в статье «Сравнительный анализ маршрутизации пакетов: модуль на базе Netfilter против реализации на eBPF/XDP».

## Авторы
Манько Артем Владимирович
Евсеев Алексей Евгеньевич
Студенты РГУ нефти и газа (НИУ) имени И.М. Губкина

## Лицензия
GPL-2.0 (код XDP-программы и скрипты).

## Версии ПО (условия воспроизведения)
Тестирование проводилось на следующей конфигурации:

| Компонент               | Версия                          | Команда для получения             |
|-------------------------|---------------------------------|-----------------------------------|
| ОС                      | ALT Linux Workstation 11.1      | cat /etc/os-release               |
| Ядро Linux              | 6.12.74-alt1                    | uname -r                          |
| Гипервизор              | VirtualBox 7.0.12               | VBoxManage --version              |
| Сетевой адаптер         | virtio-net (драйвер virtio_net) | lsmod | grep virtio               |
| Компилятор eBPF         | clang 17.0.6, LLVM 17.0.6       | clang --version                   |
| Библиотека libbpf       | 1.3.0                           | pkg-config --modversion libbpf    |
| Инструмент тестирования | iperf3 3.16                     | iperf3 --version                  |
| Обработка JSON          | jq 1.6 (опционально)            | jq --version                      |

## Требования к оборудованию
- Три виртуальные машины (роутер, клиент A, клиент B).
- На роутере два внутренних сетевых интерфейса: enp0s8 (подсеть 192.168.1.0/24) и enp0s9 (подсеть 192.168.2.0/24).
- Клиенты подключены к соответствующим интерфейсам роутера.
- На всех машинах установлены iperf3, ssh, clang, bpftool.

## Настройка перед запуском
1. Скопируйте SSH-ключи с роутера на клиентов:
   ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
   ssh-copy-id root@192.168.1.2
   ssh-copy-id root@192.168.2.2

2. Убедитесь, что интерфейсы имеют правильные MAC-адреса и ifindex (при необходимости отредактируйте xdp_router.c). Получить ifindex:
   ip link show | grep -E 'enp0s8|enp0s9'

3. Установите компилятор и инструменты eBPF:
   apt-get install clang llvm libbpf-dev bpftool linux-tools-common

## Запуск бенчмарка Netfilter
chmod +x collect_netfilter.sh run_netfilter_benchmark.sh
./run_netfilter_benchmark.sh tcp   # TCP-тест
./run_netfilter_benchmark.sh udp   # UDP-тест

## Запуск бенчмарка XDP
Перед запуском скомпилируйте XDP-программу:
clang -O2 -target bpf -c xdp_router.c -o xdp_router.o
Затем выполните:
chmod +x run_xdp_benchmark.sh
./run_xdp_benchmark.sh tcp   # TCP-тест
./run_xdp_benchmark.sh udp   # UDP-тест
После завершения теста XDP-программа автоматически выгружается, настройки Netfilter восстанавливаются.

## Структура выходных данных
- netfilter_results_<timestamp>/ – результаты Netfilter (JSON-файлы iperf3, CSV метрик CPU, ping.txt)
- xdp_results_<timestamp>/ – аналогично для XDP
## Примечания
- Тестирование проводилось в режиме Generic XDP (XDP_SKB) из-за ограничений VirtualBox. Для high performance (10+ Гбит/с) используйте native XDP на физическом сервере с драйверами i40e/ixgbe.
- UDP-тест с ограничением скорости 100 Мбит/с используется только для оценки джиттера, не для сравнения пропускной способности.
———————————————————————————————————————
