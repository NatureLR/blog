title: kubectl多集群管理
author: Nature丿灵然
tags: 
  - k8s
categories:
  - 运维
date: 2020-09-14 19:56:00
---
大部分情况我们不只一个k8s集群，这个时候我们需要快速的在各个集群之间进行切换。且省去每次都要申明namespace
<!--more-->
#### 使用kubectx

kubectx是个可以快速的切换集群且能设置namespace的官方[地址](https://github.com/ahmetb/kubectx)

##### 安装

	brew install kubectx

为了能够使用模糊推查找荐安装[fzf](https://github.com/junegunn/fzf)

##### 使用

- kubectx 可以看到所有环境，通过模糊查找可快速选择集群
- kubens 可以看到当前环境所有的namespace，可以快速选择NS，选择NS之后执行的命令就是在当前NS中执行了，比如执行kubectl get pods 显示的就是当前NS所有的pod，不需要加上-n xxxx

#### 多集群的管理

kubectx 所有解决了多个环境和命名空间的问题，但是没能解决快速添加集群
利用kubectl的环境变量拿到所有的环境然后通过`kubectl config view --raw`合并成为一个config文件，脚本如下：

```sh
#! /bin/bash
# 合并$HOME/.kube/configs目录下的文件到$HOME/.kube/config
# 配合kubectx工具进行环境切换

CONFIGPATH=$HOME/.kube/configs

FILEPATH=

for C in `ls $CONFIGPATH/*yaml`;do
    echo "找到配置文件:"$C
    FILEPATH=$FILEPATH$C:
done

export KUBECONFIG=$FILEPATH

kubectl config view --raw > $HOME/.kube/config

unset KUBECONFIG
```

添加集群就只需要把集群的config文件保存到`$HOME/.kube/configs`下，名字为xxx.yaml，然后执行脚本，删除同理只需要将该集群的yaml文件从`$HOME/.kube/configs`中移除在执行脚本

```go
package main

import (
        "github.com/NatureLingRan/go-project/cmd"
)

func main() {
        cmd.Execute()
}
```