layout: draft
title: 使用kubespray部署k8s集群
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2023-05-25 17:35:00
---
<简介，将显示在首页>

<!--more-->

> 说明，模版文件不要发布出来

#### 标题一

```shell
git clone https://github.com/kubernetes-sigs/kubespray.git
```

```shell
cp -rfp inventory/sample /inventory/mycluster

declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}


docker run --rm -it --mount type=bind,source="$(pwd)"/inventory/sample,dst=/inventory \
  --mount type=bind,source="${HOME}"/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
  quay.io/kubespray/kubespray:v2.22.0 bash

ansible-playbook -i /inventory/inventory.ini --private-key /root/.ssh/id_rsa cluster.yml
```


##### 标题一子标题

<内容>

#### 参考资料

<http://blog.naturelr.cc>