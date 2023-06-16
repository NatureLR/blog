layout: draft
title: 使用multus-cni为pod创建多个网卡
author: Nature丿灵然
tags:
  - cni
  - 网络
categories:
  - 运维
date: 2023-06-16 19:00:00
---
k8s的cni一般只创建一个网卡，有些时候我需要多个网卡，`multus-cni`

<!--more-->

#### 安装

```shell
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

- 可能会出现oom,官方默认给的内存太小根据需要可以大点

#### 配置

- 编写cni配置文件，根据实际情况编写

```shell
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.58.0/24",
        "rangeStart": "192.168.58.100",
        "rangeEnd": "192.168.58.200",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.58.1"
      }
    }'
EOF
```

- 在pod的注解上添加上面创建的cm的名字

```yaml
annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
```

- 进入pod会发现多一个网卡

- 如果多个则用逗号隔开,类似

```yaml
annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf,macvlan-conf
```

```shell
# k exec -it cdebug-79585bd577-ptltw -- ip addr
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#     inet 127.0.0.1/8 scope host lo
#        valid_lft forever preferred_lft forever
# 2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
#     link/ipip 0.0.0.0 brd 0.0.0.0
# 3: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN group default qlen 1000
#     link/tunnel6 :: brd :: permaddr bec6:214:eb31::
# 5: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65515 qdisc noqueue state UP group default 
#     link/ether 9a:8c:bd:86:e4:11 brd ff:ff:ff:ff:ff:ff link-netnsid 0
#     inet 10.244.120.104/32 scope global eth0
#        valid_lft forever preferred_lft forever
# 6: net1@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default  第二个网卡
#     link/ether 8a:9d:50:21:27:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
#     inet 192.168.58.103/24 brd 192.168.58.255 scope global net1
#        valid_lft forever preferred_lft forever
```

#### 参考资料

<https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/thick-plugin.md>
