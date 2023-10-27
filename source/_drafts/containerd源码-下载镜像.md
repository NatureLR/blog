title: containerd源码-下载镜像
author: Nature丿灵然
tags:
  - k8s
  - containerd
categories:
  - 开发
date: 2023-10-26 15:15:00
---

前面介绍了插件注册以及启动,本次介绍下载镜像的过程

<!--more-->

#### 下载镜过程

```mermaid
sequenceDiagram
    autonumber
    participant hub as 仓库
    participant client as 客户端
    participant diff as diff-service
    participant content as content-service
    participant snapshotter as snapshotter-service
    participant image as image-service

    client->>hub:获取镜像index
    client->>content:存储index信息
    client->>hub:获取manifests
    client->>content:存储manifests信息

    loop 保存所有的layers
    client->>hub:下载镜像
    client->>content:保存layer
    end

    loop 解压layer压缩包到snap
    client->>snapshotter:创建snap
    client->>diff:apply layer
    diff->>diff:解压
    diff->>client:层信息
    client->>snapshotter:提交快照
    end
    client->>image:创建镜像
```

```mermaid
flowchart LR
  kubectl(kubctl)<-->api-server(api-server)

  subgraph master
  api-server(api-server)<-->etcd[(etcd)]
  api-server(api-server)<-->scheduler(scheduler)
  api-server(api-server)<-->controller-manage(controller-manage)
  end

  api-server(api-server)<-->kubelet(kubelet)
  kubelet(kubelet)<--"grpc"-->containerd(containerd)

  subgraph containerd组件
  containerd(containerd)<--"exec"-->containerd-shim-runc(containerd-shim-runc)
  containerd-shim-runc(containerd-shim-runc)<--"exec"-->runc(runc)
  runc(runc)<--"exec"-->containers(containers)
  end

  api-server(api-server)<-->kube-proxy(kube-proxy)
  kube-proxy(kube-proxy)<-->ipt(iptables/ipvs)
```

##### chanid怎么得出来的

sha256(sha256 + sha256)

#### 参考

<https://blog.csdn.net/alex_yangchuansheng/article/details/111829103>
<https://www.myway5.com/index.php/2021/05/24/containerd-storage>
<https://www.myway5.com/index.php/2021/05/18/container-image>
<https://www.myway5.com/index.php/2021/05/24/containerd-storage/>
<https://github.com/containerd/containerd/blob/main/docs/content-flow.md>
<https://blog.csdn.net/weixin_40864891/article/details/107330218>
