layout: draft
title: Kvm
author: Nature丿灵然
tags:
  - kvm
  - 虚拟化
categories:
  - 运维
date: 2021-04-18 00:00:00
---
kvm基于linux内核的虚拟化

<!--more-->

> kvm是基于硬件的完全虚拟化，集成在内核中，qemu主要外部设备的虚拟化两者各发挥所长

#### 检查硬件是否支持

```shell
cpu-checker
kvm-ok
```

#### 安装

```shell
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
```

#### 参考资料

<https://www.iplayio.cn/post/92661051>