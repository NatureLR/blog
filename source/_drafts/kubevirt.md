layout: draft
title: kubevirt
author: Nature丿灵然
tags:
  - 虚拟化
categories:
  - 运维
date: 2022-03-11 16:26:00
---
kubevirt是一个可以在k8s上管理虚拟机的程序

<!--more-->

> 可以通过cr的方式创建虚拟机，是k8s具备提供虚拟化服务

#### 安装

> 安装资源发布在官方[仓库](https://github.com/kubevirt/kubevirt/releases),这里提供快捷安装方法

#### kubevirt

> 更新也是一样的

```sehll
# 定义版本
export RELEASE=v0.51.0

# 部署operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$RELEASE/kubevirt-operator.yaml

# 部署kubevirt的cr
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$RELEASE/kubevirt-cr.yaml

# 查看状态
kubectl -n kubevirt wait kv kubevirt --for condition=Available
```

> 如果是在虚拟机中需要打开嵌套虚拟化,如果没法打开就使用软件仿真

```shlle
kubectl create configmap kubevirt-config -n kubevirt --from-literal debug.useEmulation=true
```

#### kubectl插件

```shell
kubectl krew install virt
```

#### virtctl命令行工具

```shell
export VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
export ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/') || windows-amd64.exe
echo ${ARCH}

curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl
sudo install virtctl /usr/local/bin
```

#### cdi

> 导入镜像创建虚拟机，使用pvc提供虚拟机磁盘

```shell
export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

### 管理虚拟机

```shell
kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml
```

查看虚拟机状态

```shell
k get vms                                                  
# NAME     AGE   STATUS    READY
# testvm   7s    Stopped   False
```

启动虚拟机

```shell
virtctl start testvm
```

停止虚拟机

```shell
virtctl stop testvm
```

登录虚拟机

```shell
virtctl console testvm
```

删除虚拟机

```shell
kubectl delete vm testvm
```

#### 参考资料

<https://kubevirt.io/user-guide/>
