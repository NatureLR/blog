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

#### ipvsadm命令

##### 负载均衡算法

###### rr

轮训算法，每个后端ip轮着处理请求

###### wlc

最小加权连接数

##### 三种模式

###### nat

###### dr

###### 隧道

#### 参考资料

<https://www.cnblogs.com/laolieren/p/lvs_explained.html>
