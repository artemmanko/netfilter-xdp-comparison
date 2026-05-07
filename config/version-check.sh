#!/bin/bash
echo "=== Версии ПО для воспроизведения ==="
echo "ОС: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
echo "Ядро: $(uname -r)"
echo "VirtualBox: $(VBoxManage --version 2>/dev/null || echo 'не установлен')"
echo "clang: $(clang --version | head -1)"
echo "libbpf: $(pkg-config --modversion libbpf 2>/dev/null || echo 'не найден')"
echo "iperf3: $(iperf3 --version | head -1)"
echo "bpftool: $(bpftool --version | head -1)"
