layout: draft
title: containerd源码-启动容器
author: Nature丿灵然
tags:
  - containerd
  - k8s
categories:
  - 开发
date: 2023-11-02 19:26:00
---
<简介，将显示在首页>

<!--more-->

> 说明，模版文件不要发布出来

#### 总结

```mermaid
sequenceDiagram
    autonumber
    participant client as 客户端
    participant container as container-service
    participant task as task-service
    #participant content as content-service
    #participant snapshotter as snapshotter-service
    #participant image as image-service
    
    client->>container:创建容器
    client->>task:创建task
    client->>task:启动task
```

#### 参考资料

<http://blog.naturelr.cc>
