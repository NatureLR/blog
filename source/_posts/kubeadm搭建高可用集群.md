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

> kubeadm，虽然是官方的是使用起来也不是很方便，他需要在每个节点上进行安装，在大规模的时候需要借助其他工具

#### 环境信息说明

- 4台2c2g虚拟机,官方要求最少2c4g但是我的机器没这么高配置，如果仅仅是学习的话够用了
- 系统为centos7
- lb方案为了方便使用hosts文件，生产环境请使用lvs,haproxy,nginx等方案
- 默认为最新版本

#### 节点初始化

> 所有节点无论master和node

##### 设置主机名字和PS1为主机IP

> 为了方便统一设置主机名为ip地址

```shell
echo 'export PS1="[\u@\H \W]\$ "' >> .bashrc

IP=$(ip addr show $(ip route |grep default |awk '{print$5}') |grep -w inet |awk -F '[ /]+' '{print $3}')
hostnamectl set-hostname $IP
```

##### 关闭swap交换分区

```shell
# 临时关闭
swapoff -a

# 永久关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

##### 关闭selinux

```shell
setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=disable/g' /etc/selinux/config
```

##### 关闭防火墙

```shell
systemctl stop firewalld && systemctl disable firewalld
```

##### 同步时间

```shell
ntpdate cn.pool.ntp.org
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
# 添加配置文件

cat <<EOF > /etc/docker/daemon.json 
{
    "oom-score-adjust": -1000,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "exec-opts": ["native.cgroupdriver=systemd"],
    "live-restore": true,
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "registry-mirrors": ["http://hub-mirror.c.163.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn"],
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF

# 安装docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 重启docker
systemctl restart docker && systemctl enable docker
```

##### 安装k8s组件

```shell
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

# ipvs模式推荐安装
yum install -y ipvsadm
```

#### 初始化master

```shell
# 执行master节点初始化
kubeadm init \
    --control-plane-endpoint "k8s-api:6443" \
    --upload-certs \
    --image-repository registry.aliyuncs.com/google_containers \
    --pod-network-cidr=172.16.1.0/16 \
    --v=6

# 初始化完成之后会打印出加入集群的命令

```

加入集群的命令可以使用kubeadm重新获取,参考后面kubeadm

##### 其他两个master节点

```shell
 kubeadm join k8s-api:6443 --token iq5o5t.8mtwj9117qhed25p \
        --discovery-token-ca-cert-hash sha256:95fda448e3cb56303efc3bccbc785e000c3124a9a045ff2ed33c854cb9ee3108 \
        --control-plane --certificate-key f075fe20e799440297bf9bd48942134da1c95f1c00ef94d7d208a2a66ce87bda
```

##### 节点上执行

```shell
kubeadm join k8s-api:6443 --token iq5o5t.8mtwj9117qhed25p \
        --discovery-token-ca-cert-hash sha256:95fda448e3cb56303efc3bccbc785e000c3124a9a045ff2ed33c854cb9ee3108
```

#### cni

> k8s支持很多cni，这里使用了最简单的flannel

```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

#### metrics-server

> metrics-server提供了最基础的metrics手机，使用`kubectl top`和hpa时需要他，当然也可以使用kube-prometheus代理

```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### ingress

> ingress官方只是定义了crd，具体实现由第三方实现，这里使用了常见的nginx-ingreses

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/baremetal/deploy.yaml

# 使用helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```

#### dashboard

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
```

##### 删除清理

> master要保持奇数！

- 驱逐节点上的pod

```shell
kubectl drain <节点> --delete-local-data --force --ignore-daemonsets
```

- 删除节点

```shell
kubectl delete <节点>
```

- 在要删除的节点上执行

```shell
kubeadm reset
```

- 清理iptables规则

```shell
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

- 如果使用了ipvs模式

```shell
ipvsadm -C
```

- 清理安装目录和文件

```shell
rm -rf ~/.kube
rm -rf /opt/cni
rm -rf /etc/cni
rm -rf /etc/kubernetes
rm -rf /var/etcd # master节点才有
```

- 卸载组件

```shell
yum remove kube*
```

- 重启

```shell
reboot
```

##### 升级版本

> k8s升级版本最大不能跨越两个次版本，其版本通过二进制的版本来确定要通过kubeadm去每个节点上执行

###### master节点

```shell
yum -y update kubeadm kubelet kubectl

# 验证版本
kubeadm version

# 查看升级计划
kubeadm upgrade plan

# 执行升级
sudo kubeadm upgrade apply v1.y.x

# 其他的master
sudo kubeadm upgrade node
```

###### 工作节点

- 驱逐节点上pod

```shell
kubectl drain <节点> --delete-local-data --force --ignore-daemonsets
```

- 升级节点

```shell
yum update -y kubelet

systemctl restart kubelet
```

- 恢复节点

```shell
kubectl uncordon <节点>
```

###### 其他

- 查看cni是不是需要根据版本升级
- dashboard等k8s应用升级

#### kubeadm常用命令

```shell
# 打印默认的初始化配置
kubeadm config print init-defaults > kubeadm-config.yaml

# 使用配置文件来初始化集群
kubeadm init --config kubeadm-config.yaml

# 查看所需要的镜像列表
kubeadm config images list

# 下载默认配置的镜像
kubeadm config images pull

# 由于国内无法访问gcr.io，可以指定仓库，这里使用了阿里的镜像
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers --kubernetes-version latest

# 获取key
kubeadm init phase upload-certs --upload-certs

# 获取加入节点的命令
kubeadm token create --print-join-command --ttl 0

# 将获取的key组合成添加master的命令
kubeadm join k8s-api:6443 
--token <token> \
--discovery-token-ca-cert-hash <cert>\
--control-plane \
--certificate-key <key> \
--v=6

# kubeadm init 和 kubeadm join 如果cpu配置太低可以使用下面的参数忽略
--ignore-preflight-errors=Mem,NumCPU

```

#### 参考资料

<https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/>
<https://kubernetes.io/zh/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/>
