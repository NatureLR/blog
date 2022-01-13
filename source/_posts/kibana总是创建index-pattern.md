title: kibana总是创建index-pattern
author: Nature丿灵然
tags:
  - kibana
categories:
  - 运维
date: 2022-01-13 18:59:00
---

在kibana界面点击创建index pattern失败一直让创建index pattern

<!--more-->

> 今天在做升级修复log4j时升级之后打开kibana界面创建index pattern总是创建不出来，将es删除重建也不行，看日志也没发现一些错误，于是就想是不是kibana的问题，于是重启kibana和删除es中一些kibana的索引解决了

#### 1.删除es索引

```shell
# 先查看所有索引
curl 127.0.0.1:9200/_cat/indices?v
```

可能还有其他类似.kibana_1之类的我也删除了

```shell
#删除kibana的索引
curl -XDELETE 127.0.0.1:9200/.kibana?pretty
```

#### 2.重启kibana容器

```shell
kubectl rollout restart deployment kibana
```
