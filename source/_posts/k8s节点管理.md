title: k8s节点管理
tags:
  - k8s
date: 2020-01-17 15:31:00
---
节点管理
<!--more-->

###### 查看节点

```shell
#查看节点基本信息
kubectl get nodes

#查看节点详细信息
kubectl get nodes <节点名字> -o wide
kubectl describe nodes <节点名字>
```

###### 节点调度

```shell
#停止向此节点调度
kubectl cordon <节点名字>

#将此节点上的所有容器驱逐到其他节点
kubectl drain <节点名字>

#恢复向此节点调度pod
kubectl uncordon <节点名字>
```

###### 标签

```shell
#打标签
kubectl label nodes <节点名字> <标签key>=<标签val>  

#删除节点标签
kubectl label nodes <节点名字> <标签key>- 
```

###### 删除节点

```shell
# 驱逐节点上的pod
kubectl drain <节点> --delete-local-data --force --ignore-daemonsets

# 删除节点
kubectl delete nodes <节点>
```
