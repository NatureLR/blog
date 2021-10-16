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
|-----------|----------|--------------|
|CIP|Client IP         |客户端ip
|vip|Virtual IP        |虚拟ip
|DIP|Director Server IP|负载均衡ip
|RIP|Real Servier IP   |真正的后端服务ip
|DS |Director Server   |部署负载均衡的服务器
|RS |Real Server       |后端服务器

##### 三种模式

###### nat

- 流量出入都经过DR
- RS的默认网关指向DS

###### dr

###### 隧道

##### 负载均衡算法

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

#### ipvsadm命令

```shell
# 查看规则
ipvsadm -L

# 查看指定规则
ipvsadm -L -t 192.168.32.250:80

# 查看链接
ipvsadm -l -c

# 清理所有规则
ipvsadm -c

# 清空计数器
ipvsadm -Z

# 添加一个虚拟服务器，算法为轮询
ipvsadm -A -t 192.168.32.250:80 -s rr

# 删除一个虚拟服务,同时删除RS
ipvsadm -D -t 192.168.32.250:80

# 修改一个服务，将算法修改为wlc
ipvsadm -E -t 192.168.32.250:80 -s wlc

# 添加一个RS,nat模式
ipvsadm -a -t 192.168.32.250:80 -r 192.168.32.134:80 -m

# 添加一个RS,路由模式,权重为3
ipvsadm -a -t 192.168.32.250:80 -r 192.168.32.134:80 -g -w 3

# 添加一个RS,ipip隧道模式
ipvsadm -a -t 192.168.32.250:80 -r 192.168.32.134:80 -i

# 修改rs 将此rs的模式改为ipip权重为2
ipvsadm -e -t 192.168.32.250:80 -r 192.168.32.129:80 -i -w 2

# 删除一个RS
ipvsadm -d -t 192.168.32.250:80 -r 192.168.32.129:80
```

#### 参考资料

<https://www.cnblogs.com/laolieren/p/lvs_explained.html>
