layout: draft
title: IP命令基本使用
author: Nature丿灵然
tags: []
categories:
  - 运维
date: 2021-05-02 23:26:00
---
ip 命令是linux中常用的网络配置命令

<!--more-->

> ip命令是iproute2包中的命令

#### 安装

> 一般发行版再带ip命令

```shell
# macos
brew install iproute2mac

# ubuntu
apt install iproute2

# centos
yum install iproute2
```

#### 设备(device)

> 主要是配置OSI模型中的第二层数据链路层

##### 查看设备

```sehll
# 显示所有
ip link show

详细显示
ip -s  link show
```

##### 操作设备

```shell
# 开启网卡
ip link set ens33 up

# 关闭网卡
ip link set ens33 down

# 开启网卡的混合模式
ip link set ens33 promisc on

# 关闭网卡的混个模式
ip link set ens33 promisc offi

# 设置网卡队列长度
ip link set ens33 txqueuelen 1200

# 设置网卡最大传输单元
ip link set ens33 mtu 1400

# 修改名字
ip link set ens33 name eth0

# 修改网卡的MAC地址
ip link set ens33 address aa:aa:aa:aa:aa:aa
```

#### IP相关配置

##### 查看IP

```shell
# 显示所有IP地址
ip address
# 简写
ip addr 

# 显示指定网卡的IP
ip addr ens

# 详细显示指定网卡的IP
ip -s addr ens33

2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:d9:89:c8 brd ff:ff:ff:ff:ff:ff
    inet 192.168.32.132/24 brd 192.168.32.255 scope global noprefixroute ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fed9:89c8/64 scope link
       valid_lft forever preferred_lft forever
```

- broadcast：设定广播位址，如果设定值是 + 表示让系统自动计算；
- label：该设备的别名，例如eth0:0；
- scope：这个设备的领域，默认global，通常是以下几个大类：
- global：允许来自所有来源的连线；
  - site：仅支持IPv6 ，仅允许本主机的连接；
  - link：仅允许本设备自我连接；
  - host：仅允许本主机内部的连接；

##### 增加IP

```shell
# 设置ens33网卡IP地址192.168.1.1
ip addr add 192.168.1.1/24 dev ens33 
```

##### 删除IP

```shell
 # 删除ens33网卡IP地址
ip addr del 192.168.1.1/24 dev ens33
```

#### 路由相关配置

##### 查看路由

```shell
# 显示系统路由
ip route show

#简写
ip r

default via 192.168.32.2 dev ens33 proto static metric 100                      
169.254.0.0/16 dev ens33 scope link metric 1000                                 
172.16.1.0/24 dev docker0 proto kernel scope link src 172.16.1.1                
192.168.32.0/24 dev ens33 proto kernel scope link src 192.168.32.132 metric 100 
192.168.49.0/24 dev br-e6a94a27c143 proto kernel scope link src 192.168.49.1    
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 linkdown  

#显示vip这个路由表的路由
ip route show table vip

# 查看某个地址走那条路由
ip route get 114.114.114.114
```

- proto：此路由的路由协定，主要有redirect,kernel,boot,static,ra等，其中kernel是直接由核心判断自动设定。
- scope：路由的范围，主要是link，是与本设备有关的直接连接。

##### 增加/修改路由

```shell
# 设置192.168.1.0网段的网关为192.168.1.1数据走eth0接口
ip route add 192.168.1.0/24 via 192.168.1.1 dev eth0

# 设置默认网关为192.168.1.1
ip route add default via 192.168.1.1 dev eth0
```

##### 删除路由

```shell
# 删除192.168.1.0网段的网关
ip route del 192.168.1.0/24

# 删除默认路由
ip route del default

# 删除路由
ip route delete 192.168.1.0/24 dev eth0 
```

#### 网络命名空间

##### 查看

```shell
ip netns
ip netns show
```

##### 增加

```shell
# 增加一个叫test的网络命名空间
ip netns add test
```

##### 删除

```shell
# 删除一个叫test的网络命名空间
ip netns del test
```

#### 参考资料

<https://wangchujiang.com/linux-command/c/ip.html>
<https://www.jianshu.com/p/7466862382c4>
