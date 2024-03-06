layout: draft
title: ipset
author: Nature丿灵然
tags:
  - 网络
date: 2021-07-28 13:56:00
---
ipset是iptables的一个扩展，可以动态的修改规则的地址

<!--more-->

> 主要用户存储网络，端口号，ip地址以及mac地址，然后在iptables中调用此模块,有点像是存储网络信息的数据库

#### 安装

```shell
yum install ipset
```

#### 基本操作

ipset的操作比较简单

##### 显示集合

```shell
ipset list <集合名字>
```

##### 增加集合

```shell
ipset create <集合名字> <集合类型>
```

##### 删除集合

```shell
# 删除指定集合
ipset destroy <集合名字>

# 删除所有
ipset destroy
```

##### 增加条目

```shell
ipset add <集合名字> <条目>
```

##### 删除条目

```shell
ipset del <集合名字> <条目>
```

##### 保存规则

```shell
ipset save > ipset.bak
```

##### 还原规则

```shell
ipset restore < ipset.bak
```

#### 参考资料

<https://ipset.netfilter.org>
