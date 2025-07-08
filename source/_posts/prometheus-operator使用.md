---
layout: draft
title: prometheus-operator使用
author: Nature丿灵然
tags:
  - 监控
  - k8s
date: 2025-01-22 19:06:00
---
prometheus operator可以是cr的形式在k8s部署Prometheus

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

#### ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: demo
  name: demo
spec:
  endpoints:
  - port: "http" # metrics端口
    path: /metrics # metrics的路径
    metricRelabelings:
    - action: replace
      sourceLabels: [__name__]
      regex: .*
      targetLabel: model_id # 自定义标签key
      replacement: xxxxxxxx # 自定义标签value
  jobLabel: jobLabel
  namespaceSelector: # namespace选择
    matchNames:
    - default
  selector:  # svc选择
    matchLabels:
      app: demo
```

#### 参考资料

<https://prometheus.io/docs/introduction/overview/>

grafana好看的报表：16098，13105
