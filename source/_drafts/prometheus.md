layout: draft
title: prometheus
author: Nature丿灵然
tags:
  - 监控
  - k8s
date: 2024-07-15 19:06:00
---
prometheus是一个监控系统，是k8s中最常用的监控，prometheus比较灵活通过各种export采集metrics然后再prometheus中处理数据并在grafana中展示

<!--more-->

#### 架构

![alt text](../images/prometheus-1.svg)

##### prometheus operator自定义资源

- Prometheus 定义Prometheus
- PrometheusAgent，定义Prometheus不过只负责抓取数据，告警等功能不可用
- Alertmanager 定义了alertmanager
- ThanosRuler thanos规则
- ServiceMonitor 定义需要监控的svc
- PodMonitor 定义监控pod
- Probe 拨测配置
- ScrapeConfig Prometheus抓取metrics的配置主要用于外部的资源
- PrometheusRule 定义Prometheus的告警规则
- AlertmanagerConfig 定义alertmanager的配置

#### 部署

- 直接部署kube-prometnheus stack

```shell
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
kubectl apply --server-side -f manifests/setup
kubectl apply -f manifests/
```

- 使用helm部署,helm部署的和上面相比缺少一些组件

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

```shell
helm install prometheus  prometheus-community/kube-prometheus-stack
```

- 默认的一些监控规则说明 <https://runbooks.prometheus-operator.dev/runbooks>

#### 参考资料

<https://prometheus.io/docs/introduction/overview/>

比较好看的报表：16098，13105
