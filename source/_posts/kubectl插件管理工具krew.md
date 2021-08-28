layout: draft
title: kubectl插件管理工具krew
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2021-04-18 16:27:00
---
krew是一个kubectl的插件管理系统

<!--more-->

#### 安装

```shell
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)
```

> 添加环境变量

```shell
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

##### 常用命令

- kubectl krew install xxx 安装插件

- kubectl krew uninstall xxx 卸载插件

- kubectl krew list xxx 查看插件

- kubectl krew update xxx 升级插件

#### 参考资料

<https://krew.sigs.k8s.io>
