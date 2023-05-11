title: 在k8s中部署calico
author: Nature丿灵然
tags:
  - k8s
  - cni
  - 网络
categories:
  - 运维
date: 2023-05-10 16:41:00
---
calico是k8s中常见的网络插件,支持ipip，vxlan隧道和bgp路由,以及ebpf

<!--more-->

#### 部署calico cni

```shell
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O

kubectl apply -f calico.yaml
```

#### 安装calicoctl

- calicoctl使用calic的命令行客户端攻击可以用来查看一些信息，有三种安装方法选一种即可

##### 用容器的方式运行calicoctl

```shell
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calicoctl.yaml -o calicoctl.yaml

kubectl apply -f calicoctl.yaml

echo alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"
```

使用方法:`calicoctl version`

##### 二进制文件使用

```shell
curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o calicoctl

chmod +x calicoctl
mv calicoctl /usr/local/bin/
```

使用方法:`calicoctl version`

##### kubectl插件使用

```shell
curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o kubectl-calico
chmod +x kubectl-calico
mv kubectl-calico /usr/local/bin/
```

使用方法: `kubectl calico version`

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
