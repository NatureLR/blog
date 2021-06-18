title: 部署Rancher
author: Nature丿灵然
tags:
  - k8s
  - rancher
categories:
  - 运维
date: 2020-11-02 14:20:00
---
rancer是一个多k8s集群管理工具

<!--more-->

##### 在k8s集群里安装

>直接部署在k8s中具备高可用 \
>中文官方<https://www.rancher.cn>英文官网<https://rancher.com>

###### rancher需要cert-manager

```shell
# 添加helm仓库
helm repo add jetstack https://charts.jetstack.io

# 更新仓库
helm repo update

# 创建cert-manager的namespace
kubectl create namespace cert-manager

# 使用helm安装cert-manager
helm install \
 cert-manager jetstack/cert-manager \
 --namespace cert-manager \
 --set installCRDs=true
```

###### 使用helm安装rancher

```shell
# 添加rancher的repo仓库，这里是用latest，生产环境推荐使用stable，尝鲜使用alpha
helm repo add rancher-latest http://rancher-mirror.oss-cn-beijing.aliyuncs.com/server-charts/latest

# 为rancher创建namespace
kubectl create namespace cattle-system

# 安装rancher
helm install rancher rancher-latest/rancher \
 --namespace cattle-system \
 --set hostname=<域名>
```

##### 单节点安装

> 作为一个单独的程序管理其他的集群

```shell
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  -v /data/rancher:/var/lib/rancher/ \
  -v /data/rancher/log/auditlog:/var/log/auditlog \
  -e CATTLE_SYSTEM_CATALOG=bundled \
  -e AUDIT_LEVEL=3 \
 rancher/rancher:stable --no-cacerts
 ```
