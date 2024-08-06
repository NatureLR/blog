---
layout: draft
title: argocd
author: Nature丿灵然
tags:
  - gitops
date: 2022-03-04 10:46:00
---
argocd 是个有可视化界面的git-ops工具

<!--more-->

> argocd是一个gitops工具，可以将git上的文件同步到k8s集群，且支持多集群，这样我只需要修改git上的内容就可以完成发布

#### 安装

> 单节点安装

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.2.5/manifests/install.yaml
```

> 高可用安装

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.2.5/manifests/ha/install.yaml
```

#### 登录界面

argocd默认安装没有用nodePort，我们需要手动将`argocd-server`改为nodePort

```shell
kubectl patch svc argocd-server -p '{"spec":{"type":"NodePort"}}'
```

这样就可以通过NodePort来访问了，账号为admin

获取初始密码

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

接下来就可以在界面上点点点了

#### 参考资料

<https://argo-cd.readthedocs.io/en/stable/>
