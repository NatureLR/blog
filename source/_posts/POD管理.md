---
title: POD管理
date: 2020-01-17 15:33:12
tags: k8s
categories: 
- k8s
---

## 一键删除pod状态为Terminating的POD

    kubectl get pods |grep Terminating |awk -F " " '{print$1}'|xargs -n 1 kubectl delete pods --force --grace-period 0

## 横向扩容

<!--more-->

### 手动库容

    kubectl scale <资源类型> <资源名字> --replicas <副本数量> 将pod的副本书保持到指定数量

    例子：kubectl scale deployment webhook --replicas 2 将test的副本数扩容到2  

### 自动横向扩容（HPA）

#### 命令行

    kubectl autoscale <资源类型> <资源名字> --min=<最小副本> --max=<最大副本> --cpu-percent=<CPU阈值> -n <namespace>

    kubectl get hpa

    kubectl describe hpa <hpa名字>

    kubectl deleted hpa <hpa名字>  删除hpa

#### 配置文件形式

```yaml

apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: productpage-v1 # hpa名字
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1beta1
    kind: Deployment
    name: productpage-v1
  minReplicas: 1
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: memory
      targetAverageUtilization: 50
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 50
```
