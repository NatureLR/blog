---
layout: draft
title: flannel
author: Nature丿灵然
tags:
  - k8s
  - cni
  - 网络
date: 2023-05-15 08:10:00
---
flannel是k8s一个常见的cni

<!--more-->

#### 部署

```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

#### vxlan模式

> vxlan模式是flannel的默认模式

- 节点和pod环境说明：有2个节点3个pod其中有2个pod在同一个节点

```shell
kubectl get po -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
# ubuntu-664c5f866b-2z472   1/1     Running   0          43m   10.244.0.4   10-7-160-190   <none>           <none>
# ubuntu-664c5f866b-865jb   1/1     Running   0          47h   10.244.1.2   10-7-111-92    <none>           <none>
# ubuntu-664c5f866b-ngdrj   1/1     Running   0          47h   10.244.1.3   10-7-111-92    <none>           <none>
kubectl get no
# NAME           STATUS   ROLES           AGE   VERSION
# 10-7-111-92    Ready    <none>          47h   v1.28.2
# 10-7-160-190   Ready    control-plane   47h   v1.28.2
```

- 选一个pod连续ping和他同节点的ip

```shell
k exec -it ubuntu-664c5f866b-865jb -- ping 10.244.1.3
# PING 10.244.1.3 (10.244.1.3) 56(84) bytes of data.
# 64 bytes from 10.244.1.3: icmp_seq=1 ttl=64 time=0.105 ms
# 64 bytes from 10.244.1.3: icmp_seq=2 ttl=64 time=0.082 ms
# 64 bytes from 10.244.1.3: icmp_seq=3 ttl=64 time=0.102 ms
# 64 bytes from 10.244.1.3: icmp_seq=4 ttl=64 time=0.095 ms
```

- 查看网桥可以看到cni0这个网桥上有2个veth

```shell
brctl show
# bridge name     bridge id               STP enabled     interfaces
# cni0            8000.2ef30b426c49       no              veth4891a1c9
#                                                         vethc408576a
```

- 通过转包可以看到同节点直接通过网桥转发

```shell
tcpdump -i cni0
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on cni0, link-type EN10MB (Ethernet), capture size 262144 bytes
# 18:07:04.005795 IP 10.244.1.2 > 10.244.1.3: ICMP echo request, id 17509, seq 164, length 64
# 18:07:04.005867 IP 10.244.1.3 > 10.244.1.2: ICMP echo reply, id 17509, seq 164, length 64
# 18:07:05.029763 IP 10.244.1.2 > 10.244.1.3: ICMP echo request, id 17509, seq 165, length 64
# 18:07:05.029814 IP 10.244.1.3 > 10.244.1.2: ICMP echo reply, id 17509, seq 165, length 64
```

- 此时抓包flannel.1是没有流量的

```shell
tcpdump -i flannel.1
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on flannel.1, link-type EN10MB (Ethernet), capture size 262144 bytes
```

- 通过查看cni0可以看到详细信息

```shell
ip -d link show cni0
# 6: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1402 qdisc noqueue state UP mode DEFAULT group default qlen 1000
#     link/ether 2e:f3:0b:42:6c:49 brd ff:ff:ff:ff:ff:ff promiscuity 0
#     bridge forward_delay 1500 hello_time 200 max_age 2000 ageing_time 30000 stp_state 0 priority 32768 vlan_filtering 0 vlan_protocol 802.1Q bridge_id 8000.2e:f3:b:42:6c:49 designated_root 8000.2e:f3:b:42:6c:49 root_port 0 root_path_cost 0 topology_change 0 topology_change_detected 0 hello_timer    0.00 tcn_timer    0.00 topology_change_timer    0.00 gc_timer  291.45 vlan_default_pvid 1 vlan_stats_enabled 0 group_fwd_mask 0 group_address 01:80:c2:00:00:00 mcast_snooping 1 mcast_router 1 mcast_query_use_ifaddr 0 mcast_querier 0 mcast_hash_elasticity 4 mcast_hash_max 512 mcast_last_member_count 2 mcast_startup_query_count 2 mcast_last_member_interval 100 mcast_membership_interval 26000 mcast_querier_interval 25500 mcast_query_interval 12500 mcast_query_response_interval 1000 mcast_startup_query_interval 3125 mcast_stats_enabled 0 mcast_igmp_version 2 mcast_mld_version 1 nf_call_iptables 0 nf_call_ip6tables 0 nf_call_arptables 0 addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535
```

- 查看flannel.1网卡详细信息可以看到他是个vxlan网卡

```shell
 ip -d link show flannel.1
# 5: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1402 qdisc noqueue state UNKNOWN mode DEFAULT group default
#     link/ether 06:74:ad:94:9f:06 brd ff:ff:ff:ff:ff:ff promiscuity 0
#     vxlan id 1 local 10.7.111.92 dev eth0 srcport 0 0 dstport 8472 nolearning ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535
```

- 我们改为ping不在同节点的pod

```shell
k exec -it ubuntu-664c5f866b-865jb -- ping 10.244.0.4
# PING 10.244.0.4 (10.244.0.4) 56(84) bytes of data.
# 64 bytes from 10.244.0.4: icmp_seq=1 ttl=62 time=2.14 ms
# 64 bytes from 10.244.0.4: icmp_seq=2 ttl=62 time=0.363 ms
# 64 bytes from 10.244.0.4: icmp_seq=3 ttl=62 time=0.322 ms
# 64 bytes from 10.244.0.4: icmp_seq=4 ttl=62 time=0.362 ms
# 64 bytes from 10.244.0.4: icmp_seq=5 ttl=62 time=0.307 ms
```

- 抓eth0包可以看到Icmp协议

```shell
tcpdump -i cni0
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on cni0, link-type EN10MB (Ethernet), capture size 262144 bytes
# 18:18:14.085771 IP 10.244.1.2 > 10.244.0.4: ICMP echo request, id 17562, seq 354, length 64
# 18:18:14.086116 IP 10.244.0.4 > 10.244.1.2: ICMP echo reply, id 17562, seq 354, length 64
# 18:18:15.109806 IP 10.244.1.2 > 10.244.0.4: ICMP echo request, id 17562, seq 355, length 64
```

- 可以看到flannel.1上可以看到流量

```shell
tcpdump -i flannel.1
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on flannel.1, link-type EN10MB (Ethernet), capture size 262144 bytes
# 18:13:43.749812 IP 10.244.1.2 > 10.244.0.4: ICMP echo request, id 17562, seq 90, length 64
# 18:13:43.750086 IP 10.244.0.4 > 10.244.1.2: ICMP echo reply, id 17562, seq 90, length 64
# 18:13:44.773764 IP 10.244.1.2 > 10.244.0.4: ICMP echo request, id 17562, seq 91, length 64
```

- 抓eth0上的vxlan包可以看到有记录，外面是vxlan的信息里面才是icmp

```shell
tcpdump 'udp[39]=1' -nv -i eth0
# tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
# 18:16:21.445817 IP (tos 0x0, ttl 64, id 55345, offset 0, flags [none], proto UDP (17), length 134)
#     10.7.111.92.28167 > 10.7.160.190.otv: OTV, flags [I] (0x08), overlay 0, instance 1
# IP (tos 0x0, ttl 63, id 33261, offset 0, flags [DF], proto ICMP (1), length 84)
#     10.244.1.2 > 10.244.0.4: ICMP echo request, id 17562, seq 244, length 64
# 18:16:21.446069 IP (tos 0x0, ttl 63, id 23398, offset 0, flags [none], proto UDP (17), length 134)
#     10.7.160.190.59128 > 10.7.111.92.otv: OTV, flags [I] (0x08), overlay 0, instance 1
# IP (tos 0x0, ttl 63, id 24980, offset 0, flags [none], proto ICMP (1), length 84)
#     10.244.0.4 > 10.244.1.2: ICMP echo reply, id 17562, seq 244, length 64
```

```shell
ip r
# default via 10.7.0.1 dev eth0
# 10.7.0.0/16 dev eth0 proto kernel scope link src 10.7.111.92
# 10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
# 10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1
# 169.254.0.0/16 dev eth0 scope link metric 1002
```

##### vxlan小结

#### host-gw模式

#### 参考资料

<https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md>
