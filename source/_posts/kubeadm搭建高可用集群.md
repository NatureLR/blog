layout: draft
title: kubeadm搭建高可用集群
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2021-09-04 21:36:00
---
kubeadm是官方的一个用来管理k8s集群的工具

<!--more-->

> xxxx

#### 节点初始化

> 所有节点无论master和node

##### 关闭swap交换分区

```shell
# 临时关闭
swapoff -a

# 永久关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

##### 关闭selinux

```shell
setenforce 0 && sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
```

##### 关闭防火墙

```shell
systemctl stop firewalld && systemctl disable firewalld
```

##### yum源

默认源很慢，改为阿里云的

###### 修改centos7源为阿里云

```shell
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

###### 修改centos7 epel源为阿里云

```shell
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

###### 安装k8s源

官方的国内不可用，使用阿里云的

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

##### 安装docker

```shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

systemctl restart docker && systemctl enable docker
```

```shell
cat <<EOF > /etc/docker/daemon.json 
    "oom-score-adjust": -1000,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "exec-opts": ["native.cgroupdriver=systemd"],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "registry-mirrors": ["http://hub-mirror.c.163.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"],
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF
```

##### 安装k8s组件

```shell
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet
```

#### 初始化master

```shell
# 打印默认的初始化配置
kubeadm config print init-defaults > kubeadm-config.yaml

# 使用配置文件来初始化集群
kubeadm init --config kubeadm-config.yaml

# 查看所需要的镜像列表
kubeadm config images list

# 提前下载镜像
kubeadm config images pull

# 由于国内无法访问gcr.io，可以指定仓库，这里使用了阿里的镜像
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers --kubernetes-version latest
```

```shell
# 执行master节点初始化
kubeadm init \
    --control-plane-endpoint "k8s-api:6443" \
    --upload-certs \
    --image-repository registry.aliyuncs.com/google_containers \
    --pod-network-cidr=192.16.1.0/16 \
    --v=6

# 初始化完成之后会打印出加入集群的命令

# 获取key
kubeadm init phase upload-certs --upload-certs

# 获取加入节点的命令
kubeadm token create --print-join-command --ttl 0

# 将获取的key组合成添加master的命令
kubeadm join k8s-api:6443 
--token guke67.qbqotvs5pndd5vk3 
--discovery-token-ca-cert-hash sha256:b6d4d752543f1435751d4aad83c46571ac9fe21bdbd87c2b9b009f2dd2eef24b 
--control-plane 
--certificate-key a3a3eabf81b1463f984bad94b7b6852acd01535784d83b06ae0178d770d5a3b3 
--v=6
```

#### cni

> k8s支持很多cni，这里使用了最简单的flannel

```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

#### metrics-server

#### ingress

#### dashboard

#### 参考资料

<http://blog.naturelr.cc>
