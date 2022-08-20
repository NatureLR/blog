layout: draft
title: ipvs
author: Nature丿灵然
tags:
  - 网络
categories:
  - 运维
date: 2021-10-15 15:20:00
---
ipvs是个4层负载均衡器，常常用于服务的高可用

<!--more-->

> ipvs已经合并到linux内核当中，用户层面使用ipvsadm

#### 安装ipvsadm

```shell
yum install ipvsadm
```

#### 技术术语

|缩写|全写|说明|
|---|------------------|--------------|
|CIP|Client IP         |客户端ip
|VIP|Virtual IP        |虚拟ip
|DIP|Director Server IP|负载均衡ip
|RIP|Real Servier IP   |真正的后端服务ip
|DS |Director Server   |部署负载均衡的服务器
|RS |Real Server       |后端服务器

#### 三种模式

##### nat

- 本质是个dnat
- 流量出入都经过DR
- RS的默认网关指向DS
- 来回流量都从dr过dr会成为瓶颈

> 部署步骤

- 在DS设置规则，将在DS设置规则，将192.168.1.1:80轮询到10.23.218.86:80和10.23.39.137:80

```shell
ipvsadm -A -t 192.168.1.1:80 -s rr
ipvsadm -a -t 192.168.1.1:80 -r 10.9.78.125:80 -m
ipvsadm -a -t 192.168.1.1:80 -r 10.9.79.76:80 -m
```

- 查看规则

```shell
ipvsadm -L -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
   -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  192.168.1.1:80 rr
  -> 10.23.39.137:80              Masq    1      0          1
  -> 10.23.218.86:80              Masq    1      0          0
```

- 在RS上部署一个httpd用于判断访问到哪那台机器

```shell
yum -y install httpd && systemctl start httpd
echo "i am rs $HOSTNAME" > /var/www/html/index.html
```

此时在rs上curl`192.168.1.1`这个vip会轮询访问

```shell
[root@10-23-234-104 ~]# curl 192.168.1.1
i am rs 10-23-39-137
[root@10-23-234-104 ~]# curl 192.168.1.1
i am rs 10-23-218-86
```

ip r add 192.168.1.1/32 via 10.23.105.123 dev eth0
ip r add 192.168.1.1/32 via 10.23.234.104 dev eth0
ip link add ipvs  type dummy

##### DR

- rs和ds需要在一个二层中

- dr模式中客户端请求vip流量从ds通过修改mac地址来达到负载均衡

- 由于没有修改ip地址所以rs上需要添加vip到lo或者dummy类型的网口上，不然rs发现请求的ip不在本机就会被丢弃

- 由于rs的lo或者dummy的网卡上配置的有vip为了防止rs响应vip的请求，所以需要修改arp配置

- 不支持端口映射

###### 部署步骤(cip,vip,rs同网段)

|类型|IP|
|---|--------------|
|CIP|10.23.148.237 |
|VIP|10.23.20.112  |
|DS |10.23.20.111  |
|RS1|10.23.102.39  |
|RS2|10.23.133.111 |

- DS配置

```shell
ip link add vip  type dummy
ip addr add 10.23.20.112 dev vip

ipvsadm -A -t 10.23.20.112:80 -s rr
ipvsadm -a -t 10.23.20.112:80 -r 10.23.102.39:80  -g
ipvsadm -a -t 10.23.20.112:80 -r 10.23.133.111:80 -g
```

- 两个RS配置

```shell
# 部署http服务用于区分是否负载均衡
yum -y install httpd && systemctl start httpd
echo "i am rs $HOSTNAME" > /var/www/html/index.html

# 配置arp
echo 1 >/proc/sys/net/ipv4/conf/all/arp_ignore
echo 2 >/proc/sys/net/ipv4/conf/all/arp_announc

# 配置vip网卡(用dummy和lo都可以)
ip link add vip  type dummy
ip addr add 10.23.20.112 dev vip
```

- Client

```shell
# 添加路由
ip r add  10.23.20.112/32 via 10.23.20.111 dev eth0
```

- 测试

```shell
[root@10-23-148-237 ~]# curl 10.23.20.112
i am rs 10-23-102-39
[root@10-23-148-237 ~]# curl 10.23.20.112
i am rs 10-23-133-111
```

##### 隧道(IPIP)

```shell
ipvsadm -A -t 10.23.20.112:80 -s rr
ipvsadm -a -t 10.23.20.112:80 -r 10.23.102.39:80  -i
ipvsadm -a -t 10.23.20.112:80 -r 10.23.133.111:80 -i
```

#### 负载均衡算法

- rr（轮询）
- wrr（权重）
- lc（最后连接）
- wlc（权重）
- lblc（本地最后连接）
- lblcr（带复制的本地最后连接）
- dh（目的地址哈希）
- sh（源地址哈希）
- sed（最小期望延迟）
- nq（永不排队）

#### ipvsadm常用命令

```shell
# 查看规则
ipvsadm -L

# 查看指定规则
ipvsadm -L -t 10.0.0.1:80

# 查看链接
ipvsadm -l -c

# 清理所有规则
ipvsadm -c

# 清空计数器
ipvsadm -Z

# 添加一个虚拟服务器，算法为轮询
ipvsadm -A -t 10.0.0.1:80 -s rr

# 删除一个虚拟服务,同时删除RS
ipvsadm -D -t 10.0.0.1:80

# 修改一个服务，将算法修改为wlc
ipvsadm -E -t 10.0.0.1:80 -s wlc

# 添加一个RS,nat模式
ipvsadm -a -t 10.0.0.1:80 -r 192.168.32.129:80 -m

# 添加一个RS,路由模式,权重为3
ipvsadm -a -t 10.0.0.1:80 -r 192.168.32.129:80 -g -w 3

# 添加一个RS,ipip隧道模式
ipvsadm -a -t 10.0.0.1:80 -r 192.168.32.129:80 -i

# 修改rs 将此rs的模式改为ipip权重为2
ipvsadm -e -t 10.0.0.1:80 -r 192.168.32.129:80 -i -w 2

# 删除一个RS
ipvsadm -d -t 10.0.0.1:80 -r 192.168.32.129:80

# 查看转发情况
ipvsadm -L -n -c

# 保存配置
ipvsadm -S -n >ipvs.conf

# 读取配置
ipvsadm -R < ipvs.conf
```

#### 参考资料

<https://www.cnblogs.com/laolieren/p/lvs_explained.html>
<https://www.cnblogs.com/klb561/p/9215667.html>
