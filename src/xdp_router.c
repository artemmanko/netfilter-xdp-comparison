#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <linux/if_ether.h>
#include <linux/ip.h>

#define IP_192_168_1_0 0xc0a80100
#define IP_192_168_2_0 0xc0a80200

// MAC-адреса
static const unsigned char mac_enp0s8[] = {0x08,0x00,0x27,0x25,0x67,0x3e};
static const unsigned char mac_enp0s9[] = {0x08,0x00,0x27,0x42,0x8f,0xd0};
static const unsigned char mac_client_a[] = {0x08,0x00,0x27,0xde,0xdb,0xc5};
static const unsigned char mac_client_b[] = {0x08,0x00,0x27,0xa3,0x6d,0xdb};

// Индексы интерфейсов (получить через ip link)
#define IFINDEX_ENP0S8 3
#define IFINDEX_ENP0S9 4

SEC("xdp_router")
int xdp_router_func(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;

    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end) return XDP_PASS;
    if (eth->h_proto != bpf_htons(ETH_P_IP)) return XDP_PASS;

    struct iphdr *ip = (void *)(eth + 1);
    if ((void *)(ip + 1) > data_end) return XDP_PASS;

    __u32 dst = ip->daddr;
    __u32 src = ip->saddr;

    // Из сети 192.168.1.0/24 в сеть 192.168.2.0/24
    if ((dst & 0xffffff00) == bpf_htonl(IP_192_168_2_0) &&
        (src & 0xffffff00) == bpf_htonl(IP_192_168_1_0)) {
        __builtin_memcpy(eth->h_source, mac_enp0s9, ETH_ALEN);
        __builtin_memcpy(eth->h_dest, mac_client_b, ETH_ALEN);
        return bpf_redirect(IFINDEX_ENP0S9, 0);
    }

    // Из сети 192.168.2.0/24 в сеть 192.168.1.0/24
    if ((dst & 0xffffff00) == bpf_htonl(IP_192_168_1_0) &&
        (src & 0xffffff00) == bpf_htonl(IP_192_168_2_0)) {
        __builtin_memcpy(eth->h_source, mac_enp0s8, ETH_ALEN);
        __builtin_memcpy(eth->h_dest, mac_client_a, ETH_ALEN);
        return bpf_redirect(IFINDEX_ENP0S8, 0);
    }

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
