layout: draft
title: loki
author: Nature丿灵然
tags:
  - 日志
  - k8s
date: 2024-07-15 11:08:00
---
loki是grafana开发的一个日志系统，相较于elk比较轻量,查询语法使用类似Prometheus的语法称为`LogQL`

<!--more-->

#### 架构

![alt text](../images/loki-1.png)

- agent/promtail负责采集日志，部署在各个节点上
- grafana负责展示和查询日志
- loki负责存储日志

#### 安装

- 添加helm仓库

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

##### 使用loki stack部署

{% note warning %}
loki-stack没有持久化相关设置,所以数据没有持久化
{% endnote %}

```shell
helm install loki-stack grafana/loki-stack \
    --set grafana.enabled=true \
    --namespace loki \
    --create-namespace
```

- 端口转发或将该svc改为lb或nodeport类型

```shell
kubectl port-forward svc/loki-grafana 3000:80
```

#### 参考资料

<http://blog.naturelr.cc>
