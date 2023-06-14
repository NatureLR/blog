layout: draft
title: 使用kubespray部署k8s集群
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2023-05-25 17:35:00
---
[kubespray](https://github.com/kubernetes-sigs/kubespray.git)是k8s兴趣小组开发的一个使用ansible的部署脚本,和kubeadm需要再每个节点上操作是去中心化的,这样会很麻烦

<!--more-->

而kubespray则sh你在kubeadm上是用ansible将部署自动化,kubeadm不关注除了k8s组件之外的东西，然而现实是我们在部署的时候需要安装一些组件以及一些设置比如关闭swap等

#### 部署集群

{% note warning %}
默认是在线模式,需要访问外网
{% endnote %}

- Python版本等问题很麻烦这里使用docker镜像

```shell
docker pull quay.io/kubespray/kubespray:v2.22.1
```

- 启动,这里将本地的inventory文件夹和key映射到容器中供kubespray使用

```shell
docker run --rm -it -v $(pwd)/inventory:/inventory -v "${HOME}"/.ssh/id_rsa:/root/.ssh/id_rsa quay.io/kubespray/kubespray:v2.22.1 bash
```

- 拷贝模本文件到自己的inventory下

```shell
cp -rfp inventory/sample /inventory/mycluster
```

- 通过脚本自动生成hosts文件,也可以自己写hosts文件,且配置集群

```shell
declare -a IPS=(10.7.19.47 10.7.170.8 10.7.36.194)
CONFIG_FILE=/inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

- 部署集群

```shell
ansible-playbook -i /inventory/mycluster/hosts.yaml --private-key /root/.ssh/id_rsa cluster.yml
```

- 稍等片可以就部署一个集群

#### 节点伸缩

##### 添加节点

- 在ansible清单中添加新节点相关信息，然后执行`scale.yml`指定新的节点名字

```shell
ansible-playbook -i /inventory/mycluster/hosts.yaml --private-key /root/.ssh/id_rsa scale.yml --limit $new_node
```

##### 删除节点

- 执行`remove-node.yml`这个ploybook,并且添加-e node变量来指定节点

```shell
ansible-playbook -i /inventory/mycluster/hosts.yaml --private-key /root/.ssh/id_rsa remove-node.yml -e node=$node 
```

- 节点不在线删除

```shell
ansible-playbook -i /inventory/mycluster/hosts.yaml --private-key /root/.ssh/id_rsa remove-node.yml -e node=$node -e reset_nodes=false -e allow_ungraceful_removal=true
```

- 最后在清单中删除已经清理的节点

#### 清理安装

```shell
ansible-playbook -i /inventory/mycluster/hosts.yaml --private-key /root/.ssh/id_rsa reset.yml --limit $node
```

#### 参考资料

<http://blog.naturelr.cc>
