---
layout: draft
title: helm使用
author: Nature丿灵然
tags:
  - helm
  - k8s
date: 2021-07-07 16:46:00
---
helm是cncf基金会下的一个云原生管理程序

<!--more-->

> helm2和helm3有些区别，helm3去掉了服务端，本文主要是使用helm3

#### 安装

macos

```shell
brew install helm
```

脚本安装

```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

#### 应用

##### 搜索应用

在hub中搜索

```shell
helm search hub <应用>
```

在本地的repo中搜索

```shell
helm search repo <应用>
```

##### 安装应用

```shell
helm install <名字> <仓库>

# 指定ns下安装
helm install <名字> <仓库> --namespace <namespace>
```

- 指定ns并创建

```shell
 helm install <名字> <仓库>  --namespace <namespace> --create-namespace 
```

- 查看helm chart的values文件

```shell
helm show values <仓库> > values.yaml
```

- 通过values来设置参数

```shell
helm install <名字> <仓库> --namespace <namespace> --create-namespace -f values.yaml
```

- 通过命令行来设置参数,--set参数可以有多个用户指定多个参数，其指定的参数就是values里的

```shell
 helm install <名字> <仓库> --namespace <namespace> --create-namespace --set <key>:<value>
```

- --dry-run参数不执行安装可以将要安装yaml打印出来

```shell
helm install <名字> <仓库> --namespace <namespace>  --create-namespace --debug --dry-run > resource.yaml
```

##### 查看应用

显示当前ns下

```shell
helm list
```

显示当前ns下

```shell
helm list -n <namespace>
```

显示所有ns

```shell
helm list -A
```

##### 升级应用

获取安装时的设置值

```shell
helm get values <应用> > tmp.yaml
```

升级配置或者版本

```shell
helm upgrade <应用> <应用仓库> -f tmp.yaml
```

升级指定版本

```shell
helm upgrade <应用> <应用仓库> --version vx.y.z
```

例子

```shell
helm get values cilium > tmp.yaml
helm upgrade cilium cilium/cilium -f tmp.yaml
```

##### 回滚应用

```shell
helm rollback <应用>
```

##### 卸载应用

```shell
helm uninstall <名字>
```

##### 下载应用包

将在本地生成一个包里面是这个应用得chart文件

```shell
helm fetch <应用仓库>
```

#### 本地直接生成模版

- 常常用在离线安装或者本地开发当中

```shell
helm template <解压后chart包> -f <values文件>
```

#### 仓库操作

##### 添加仓库

```shell
helm repo add <仓库地址>
```

##### 查看仓库

```shell
helm repo list
```

##### 升级仓库

```shell
helm repo update
```

##### 删除仓库

```shell
helm remove <仓库名字>
```

#### 参考资料

<http://blog.naturelr.cc>
<https://helm.sh/docs>
