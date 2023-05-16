title: 在k8s中部署calico
author: Nature丿灵然
tags:
  - k8s
  - cni
  - 网络
categories:
  - 运维
date: 2023-05-10 16:41:00
---
[calico](https://github.com/projectcalico/calico)是k8s中常见的网络插件,支持ipip,vxlan隧道bgp路由以及ebpf

<!--more-->

#### 部署calico cni

```shell
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O

kubectl apply -f calico.yaml
```

#### 安装calicoctl

- calicoctl使用calic的命令行客户端攻击可以用来查看一些信息，有三种安装方法选一种即可

##### 用容器的方式运行calicoctl

```shell
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calicoctl.yaml -o calicoctl.yaml

kubectl apply -f calicoctl.yaml

echo alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
```

使用方法:`calicoctl version`

##### 二进制文件使用

```shell
curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o calicoctl

chmod +x calicoctl
mv calicoctl /usr/local/bin/
```

使用方法:`calicoctl version`

##### kubectl插件使用

```shell
curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o kubectl-calico
chmod +x kubectl-calico
mv kubectl-calico /usr/local/bin/
```

使用方法: `kubectl calico version`

#### IPIP模式

calico的网络模式`默认`是IPIP模式

- 通过calicoctl查看ippool的`IPIPMODE`字段，如下

```shell
calicoctl get ippool -o wide
# NAME                  CIDR               NAT     IPIPMODE   VXLANMODE   DISABLED   DISABLEBGPEXPORT   SELECTOR
# default-ipv4-ippool   10.244.0.0/16      true    Always      Never       false      false              all()
```

##### ipip分析

- 部署一个nginx

```shell
k get po -l app=nginx -o wide          
# NAME                     READY   STATUS    RESTARTS   AGE     IP               NODE           NOMINATED NODE   READINESS GATES
# nginx-7fc57c59f7-4nxhh   1/1     Running   0          6m30s   10.244.120.68    minikube       <none>           <none>
# nginx-7fc57c59f7-hf2g6   1/1     Running   0          6m43s   10.244.205.195   minikube-m02   <none>           <none>
# nginx-7fc57c59f7-rcdtw   1/1     Running   0          6m30s   10.244.205.196   minikube-m02   <none>           <none>
```

- 进入一个nginx的pod去ping另一个容器

```shell
kubectl exec -it nginx-7fc57c59f7-4nxhh -- ping 10.244.205.195
```

###### pod到node

- 查看容器的网卡和路由信息

```shell
kubectl exec -it nginx-7fc57c59f7-4nxhh -- sh -c "ip addr;ip r"
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#     inet 127.0.0.1/8 scope host lo
#        valid_lft forever preferred_lft forever
# 2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN qlen 1000
#     link/ipip 0.0.0.0 brd 0.0.0.0
# 3: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN qlen 1000
#     link/tunnel6 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00 brd 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
# 5: eth0@if10: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 65515 qdisc noqueue state UP 
#     link/ether fe:bb:51:af:03:a8 brd ff:ff:ff:ff:ff:ff
#     inet 10.244.120.68/32 scope global eth0
#        valid_lft forever preferred_lft forever

# default via 169.254.1.1 dev eth0 
# 169.254.1.1 dev eth0 scope link 
```

> 从上面的信息比较难以理解的是路由的网关是169.254.1.1，169.254.0.0/16为保留地址一般用于dhcp获取，而calico则将容器的默认路由设置为此,当容器发现目标地址不是本ip段时，会将流量发送给网关，这时需要知道网关的mac地址
> 这里calico将网关设置为169.254.1.1而没有任何一个网卡是169.254.1.1,其实是因为开了arp_proxy代答,具体使用了pod的veth的外面的网卡,这样流量就通过二层到达主机

```shell
tcpdump -i cali1143a22bb0c host 10.244.120.68 -ennnvv
# ...
# 09:21:15.764922 fe:bb:51:af:03:a8 > ee:ee:ee:ee:ee:ee, ethertype ARP (0x0806), length 42: Ethernet (len 6), IPv4 (len 4), Request who-has 169.254.1.1 tell 10.244.120.68, length 28
# 09:21:15.764944 ee:ee:ee:ee:ee:ee > fe:bb:51:af:03:a8, ethertype ARP (0x0806), length 42: Ethernet (len 6), IPv4 (len 4), Reply 169.254.1.1 is-at ee:ee:ee:ee:ee:ee, length 28
# ...

cat /proc/sys/net/ipv4/conf/cali1143a22bb0c/proxy_arp
# 1
```

- veth抓包

```shell
 tcpdump -i cali1143a22bb0c  host 10.244.120.68 -ennnvv
# tcpdump: listening on cali1143a22bb0c, link-type EN10MB (Ethernet), capture size 262144 bytes
# 09:39:53.417261 fe:bb:51:af:03:a8 > ee:ee:ee:ee:ee:ee, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 37455, offset 0, flags [DF], proto ICMP (1), length 84)
#     10.244.120.68 > 10.244.205.195: ICMP echo request, id 15617, seq 12, length 64
# 09:39:53.417585 ee:ee:ee:ee:ee:ee > fe:bb:51:af:03:a8, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 62, id 24660, offset 0, flags [none], proto ICMP (1), length 84)
#     10.244.205.195 > 10.244.120.68: ICMP echo reply, id 15617, seq 12, length 64
# 09:39:54.417872 fe:bb:51:af:03:a8 > ee:ee:ee:ee:ee:ee, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 38148, offset 0, flags [DF], proto ICMP (1), length 84)
#     10.244.120.68 > 10.244.205.195: ICMP echo request, id 15617, seq 13, length 64
# 09:39:54.418089 ee:ee:ee:ee:ee:ee > fe:bb:51:af:03:a8, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 62, id 24786, offset 0, flags [none], proto ICMP (1), length 84)
#     10.244.205.195 > 10.244.120.68: ICMP echo reply, id 15617, seq 13, length 64
# ...
```

###### node到node

- 查看minikube上的路由

```shell
ip r
# default via 192.168.49.1 dev eth0 
# blackhole 10.244.120.64/26 proto bird 
# 10.244.120.65 dev califc4f8273134 scope link 
# 10.244.120.66 dev cali54e305c20b5 scope link 
# 10.244.120.67 dev cali00c313c8253 scope link 
# 10.244.120.68 dev cali1143a22bb0c scope link  # 这个就是我们进行ping的pod的路由
# 10.244.205.192/26 via 192.168.49.3 dev tunl0 proto bird onlink  # 这个是minikube-m02这个节点上的路由，如果要访问minikube-m02上的pod则经过本路由
# 172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
# 192.168.49.0/24 dev eth0 proto kernel scope link src 192.168.49.2 
```

- 隧道抓包

```shell
tcpdump -i tunl0 host 10.244.120.68 -ennnvv
# tcpdump: listening on tunl0, link-type RAW (Raw IP), capture size 262144 bytes
# 09:40:55.459832 ip: (tos 0x0, ttl 63, id 114, offset 0, flags [DF], proto ICMP (1), length 84) 10.244.120.68 > 10.244.205.195: ICMP echo request, id 15617, seq 74, length 64
# 09:40:55.460009 ip: (tos 0x0, ttl 63, id 58352, offset 0, flags [none], proto ICMP (1), length 84) 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 15617, seq 74, length 64
# 09:40:56.460530 ip: (tos 0x0, ttl 63, id 495, offset 0, flags [DF], proto ICMP (1), length 84) 10.244.120.68 > 10.244.205.195: ICMP echo request, id 15617, seq 75, length 64
# 09:40:56.460780 ip: (tos 0x0, ttl 63, id 59235, offset 0, flags [none], proto ICMP (1), length 84) 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 15617, seq 75, length 64
# 09:40:57.461367 ip: (tos 0x0, ttl 63, id 979, offset 0, flags [DF], proto ICMP (1), length 84) 10.244.120.68 > 10.244.205.195: ICMP echo request, id 15617, seq 76, length 64
# 09:40:57.461510 ip: (tos 0x0, ttl 63, id 59858, offset 0, flags [none], proto ICMP (1), length 84) 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 15617, seq 76, length 64
```

- 到此pod的流量通过ipip封装发送到目标pod所在的node上,目标node将ipip包解封包，然后查找路由表发送到目标pod的veth网卡中

- 登录另一个node

```shell
minikube ssh --node="minikube-m02"
# Last login: Tue May 16 10:37:54 2023 from 192.168.49.1
# docker@minikube-m02:~$ 
sudo su
```

- 通过ip找到对应的网卡

```shell
ip r |grep 10.244.205.195
# 10.244.205.195 dev cali614e1c7b24e scope link 
```

- 抓包对应的网卡

```shell
tcpdump -i cali614e1c7b24e 
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on cali614e1c7b24e, link-type EN10MB (Ethernet), capture size 262144 bytes
# 10:50:48.678597 IP 10.244.120.68 > 10.244.205.195: ICMP echo request, id 21761, seq 88, length 64
# 10:50:48.678615 IP 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 21761, seq 88, length 64
# 10:50:49.678987 IP 10.244.120.68 > 10.244.205.195: ICMP echo request, id 21761, seq 89, length 64
# 10:50:49.679010 IP 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 21761, seq 89, length 64
# 10:50:50.680533 IP 10.244.120.68 > 10.244.205.195: ICMP echo request, id 21761, seq 90, length 64
# 10:50:50.680595 IP 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 21761, seq 90, length 64
```

- 抓包ipip隧道网卡

```shell
tcpdump -i tunl0 
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on tunl0, link-type RAW (Raw IP), capture size 262144 bytes
# 10:51:06.694392 IP 10.244.120.68 > 10.244.205.195: ICMP echo request, id 21761, seq 106, length 64
# 10:51:06.694504 IP 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 21761, seq 106, length 64
# 10:51:07.695538 IP 10.244.120.68 > 10.244.205.195: ICMP echo request, id 21761, seq 107, length 64
# 10:51:07.695667 IP 10.244.205.195 > 10.244.120.68: ICMP echo reply, id 21761, seq 107, length 64
```

- 通过以上抓包可以确定流量的路径

###### 2个pod在同一个node上

- 当目标pod和源pod在同一个node上执行通过node上的路由到对应的veth网卡,不经过隧道

- 这次ping一个在相同node上的pod的ip

```shell
kubectl get po whoami-7c88bd4c6f-7tc5b -o wide                   
# NAME                      READY   STATUS    RESTARTS   AGE     IP              NODE       NOMINATED NODE   READINESS GATES
# whoami-7c88bd4c6f-7tc5b   1/1     Running   0          3h18m   10.244.120.67   minikube   <none>           <none>

kubectl exec -it nginx-7fc57c59f7-4nxhh -- ping 10.244.120.67
# PING 10.244.120.67 (10.244.120.67): 56 data bytes
# PING 10.244.120.67 (10.244.120.67): 56 data bytes
# 64 bytes from 10.244.120.67: seq=0 ttl=63 time=1.777 ms
# 64 bytes from 10.244.120.67: seq=1 ttl=63 time=0.542 ms
# 64 bytes from 10.244.120.67: seq=2 ttl=63 time=0.132 ms
# ...
```

- 直接抓包隧道发现没有流量

```shell
minikube ssh 
# Last login: Tue May 16 10:41:40 2023 from 192.168.49.1
sudo su
tcpdump -i tunl0
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on tunl0, link-type RAW (Raw IP), capture size 262144 bytes
```

- 通过路由表找到对应的网卡

```shell
ip r |grep 10.244.120.67
10.244.120.67 dev cali00c313c8253 scope link 
```

- 抓包目标的网卡

```shell
tcpdump -i cali00c313c8253
# tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
# listening on cali00c313c8253, link-type EN10MB (Ethernet), capture size 262144 bytes
# 10:47:39.884507 IP 10.244.120.68 > 10.244.120.67: ICMP echo request, id 19969, seq 141, length 64
# 10:47:39.884649 IP 10.244.120.67 > 10.244.120.68: ICMP echo reply, id 19969, seq 141, length 64
# 10:47:40.885829 IP 10.244.120.68 > 10.244.120.67: ICMP echo request, id 19969, seq 142, length 64
# 10:47:40.885965 IP 10.244.120.67 > 10.244.120.68: ICMP echo reply, id 19969, seq 142, length 64
```

- 通过以上抓包可以发现并没有经过隧道，而是直接路由到了目标的网卡

###### 总结

![calico-ipip](../images/calico-1.png)

#### VXLAN模式

#### BGP模式

#### EBPF模式

#### 开启ipv6支持

##### 修改cni配置文件

```shell
kubectl -n kube-system edit cm calico-config
```

```json
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "true"
    },
```

##### 修改DS环境变量

|环境变量          |值        |
|-----------------|----------|
|IP6              |autodetect|
|FELIX_IPV6SUPPORT|true      |

```shell
# 修改环境变量
kubectl -n kube-system set env ds/calico-node -c calico-node IP6=autodetect
kubectl -n kube-system set env ds/calico-node -c calico-node FELIX_IPV6SUPPORT=true
```

#### 参考资料

<https://docs.tigera.io/calico/latest/about>
