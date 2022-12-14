title: minikube安装使用
author: Nature丿灵然
tags:
  - minikube
categories:
  - 开发
date: 2020-09-14 19:28:00
---
在做k8s开发的时候受限于本地的性能以及复杂度不能搭建一个完整的k8s集群，这个时候需要minikube来搭建k8s开发环境
<!--more-->

#### 下载安装

- 阿里云版本[地址](https://github.com/AliyunContainerService/minikube),官方版本[地址](https://github.com/kubernetes/minikube),推荐阿里云版本

##### 下载阿里云版本二进制文件

###### Macos

```shell
curl -Lo minikube https://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/releases/v1.13.0/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

###### Linux

```shell
curl -Lo minikube https://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/releases/v1.14.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

##### 验证安装

执行`minikube version`验证安装

#### 启动Minikube

```shell
minikube start --driver=docker --image-mirror-country cn
```

这样就启动一个使用docker作为驱动的minikube，稍等一会就会启动成功，并且将`kubectl`设置为minikube
再次启动是只需要执行`minikube start`即可

#### 多节点

- 添加

```shell
minikube node add
```

- 查看

```shell
minikube node list
```

- 删除

```shell
minikube delete <名字>
```

#### 常用命令

- minikube start 启动集群

- minikube stop 停止集群

- minikube delete 删除集群

- minikube dashboard 打开k8s报表

- minikube status 查看minikube状态

- minikube ssh 登录到minikube节点上
