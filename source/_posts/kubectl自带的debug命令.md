layout: draft
title: kubectl自带的debug命令
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2022-09-16 15:22:00
---
在使用k8s的时候需要调试的时候我们一般都是exec -it 命令登录上去执行一些调试命令，但是很多镜像为了体积和安全都不内置这些命令，导致我们需要手动安装调试麻烦

<!--more-->

kubectl在1.18之后新加了一个debug子命令将我们的调试容器放到需要调试的pod中方便调试

#### 支持情况

k8s 1.18以后,需要开启特性

#### 使用

##### 调试pod

- 将centos添加到pod进行调试

```shell
kubectl debug cdebug-64cd86798b-sjxrl -it --image=centos -- sh
```

- 将centos添加到pod进行调试的同时复制一个pod叫cdebug-debug且共享进程，--share-processes=true只有在`copy`是才生效

```shell
kubectl debug cdebug-64cd86798b-sjxrl -it --image=centos --share-processes --copy-to=cdebug-debug -- sh
```

##### 调试node

- 需要注意的node会挂载在/host下

```shell
kubectl debug node/10.69.202.146 -it --image=centos -- sh
chroot /host
```

此功能也可以通过[node_shell](https://github.com/kvaps/kubectl-node-shell)这个kubect插件来实现

#### 参考资料

<https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod>
