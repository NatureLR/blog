title: 在k8s中部署calico
author: Nature丿灵然
tags:
  - 模版
categories:
  - 运维
date: 2023-05-10 16:41:00
---
calico是k8s中常见的网络插件

<!--more-->

> 说明，模版文件不要发布出来

#### 标题一

<内容>

#### 安装calicoctl

##### 用容器的方式运行calicoctl

```shell
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calicoctl.yaml -o calicoctl.yaml

kubectl apply -f calicoctl.yaml

echo alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
```

#### 开启ipv6支持

##### 修改cni配置文件

```shell
kubectl -n kube-system edit cm calico-config
```

```json
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "true"
    },
```

##### 修改DS环境变量

|环境变量|值|
|--|--------|
|IP6|autodetect|
|FELIX_IPV6SUPPORT|true|

```shell
# 修改环境变量
kubectl -n kube-system set env ds/calico-node -c calico-node IP6=autodetect
kubectl -n kube-system set env ds/calico-node -c calico-node FELIX_IPV6SUPPORT=true
```

#### 参考资料

<https://docs.tigera.io/calico/latest/about>
