layout: draft
title: cdi
author: Nature丿灵然
tags:
  - docker
  - k8s
  - gpu
date: 2024-07-10 02:04:00
---

CDI(container device interface)是一个容器运行时支持第三方设备的一个规范，类似CNI一样对添加设备进行抽象

<!--more-->

现有的情况下添加如gpu的一些设备则需要使用nvidia的runtime来替代默认的runtime，这样只能支持nvidia的gpu方法不通用

设备由完全限定名称唯一指定，该名称由供应商 ID、设备类别以及每个供应商 ID-设备类别对唯一的名称构成

```shell
vendor.com/class=unique_name
```

cdi的目录在`/etc/cdi`和`/var/run/cdi`

#### nvidia

- nvidia的ctk

```shell
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

#### containerd

```toml
[plugins."io.containerd.grpc.v1.cri"]
  enable_cdi = true
  cdi_spec_dirs = ["/etc/cdi", "/var/run/cdi"]
```

#### docker

- `/etc/docker/daemon.json`中配置开启cdi,随后重启

```json
{
  "features": {
    "cdi": true
  }
}
```

#### 参考资料

<https://github.com/cncf-tags/container-device-interface>
<https://developer.aliyun.com/article/1180698>
