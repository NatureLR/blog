---
layout: draft
title: 用k8s资源方式创建k8s-clusterapi
author: Nature丿灵然
tags:
  - 部署
  - k8s
date: 2022-12-19 14:08:00
---
cluster-api是k8s的一个子项目隶属于SIG Cluster Lifecycle,主要使用类似k8s风格的资源对象来管理k8s集群的生命周期

<!--more-->

k8s的部署比较复杂，且每个发行版本稍微有些不应，cluster api则致力于通过k8s得资源对象来创建，管理k8s集群

#### 安装

- clustar api的命令工具为`clusterctl`

```shell
# m1 macos
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.3.1/clusterctl-darwin-arm64 -o clusterctl
```

#### 初始化管理集群服务端

- infrastructure参数指定基础架构供应商

```shell
clusterctl init --infrastructure vcluster
```

#### 使用clusterctl部署集群

```shell
export HELM_VALUES="service:\n  type: NodePort"

kubectl create namespace ${CLUSTER_NAMESPACE}

# 生成cluster-api的cr并应用
clusterctl generate cluster ${CLUSTER_NAME} \
    --infrastructure vcluster \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --target-namespace ${CLUSTER_NAMESPACE} | kubectl apply -f -
```

- 查看集群发现已经部署好了

```shell
❯ vcluster list        
 NAME        NAMESPACE         STATUS    CONNECTED   CREATED                         AGE     CONTEXT   
 capi-test   clusterapi-test   Running               2022-12-19 15:40:46 +0800 CST   3m22s   minikube  
```

- 查看集群详情

```shell
clusterctl describe cluster  capi-test
```

- 获取创建的集群的kube-config

```shell
clusterctl get kubeconfig capi-test
```

- 删除管理集群

```shell
# 删除 供应商 创建的命名空间和crd
clusterctl delete --infrastructure aws --include-namespace --include-crd

# 删除所有
clusterctl delete --all
```

#### 命令补全

- zsh

```shell
# 已经有了此配置可以忽略
echo "autoload -U compinit; compinit" >> ~/.zshrc

clusterctl completion zsh > "${fpath[1]}/_clusterctl"
```

#### 参考资料

<https://cluster-api.sigs.k8s.io/introduction.html>
