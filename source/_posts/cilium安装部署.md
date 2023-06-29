layout: draft
title: cilium安装部署
author: Nature丿灵然
tags:
  - cni
  - 网络
  - k8s
categories:
  - 运维
date: 2023-06-21 17:01:00
---
clium是一个使用ebpf实现的cni

<!--more-->

#### 安装

{% note warning %}
ebpf需要高版本内核支持,建议5.0以上
{% endnote %}

- 下载二进制文件

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

- 安装cilium

```shell
cilium install

cilium status

cilium hubble enable
```

- 开启hubble可观测性界面

```shell
# 下载二进制文件
wget https://github.com/cilium/hubble/releases/download/v0.10.0/hubble-linux-amd64.tar.gz

# 开启hubble界面
cilium hubble enable --ui

# 打开hubble界面
cilium hubble ui
```

#### 参考资料

<https://docs.cilium.io/en/stable/>
