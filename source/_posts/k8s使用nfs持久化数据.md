layout: draft
title: k8s使用nfs持久化数据
author: Nature丿灵然
tags:
  - k8s
  - 存储
date: 2022-07-16 22:45:00
---
nfs是们常用的远程存储，这里记录下k8s安装nfs

<!--more-->

#### 部署nfs服务器

安装nfs工具

```shell

yum -y install nfs-utils
systemctl start nfs && systemctl enable nfs
```

创建nfs的目录

```shell
mkdir -p /data/nfs/ && chmod -R 777 /data/nfs

# 设置共享目录
echo "/data/nfs *(rw,no_root_squash,sync)" >> /etc/exports
# 应用配置
exportfs -r
# 查看配置
exportfs
```

启动nfs服务

```shell
systemctl restart rpcbind && systemctl enable rpcbind
systemctl restart nfs && systemctl enable nfs

# 查看 RPC 服务的注册状况
rpcinfo -p localhost

# 测试一下
showmount -e 192.168.32.133
```

#### k8s安装nfs驱动

官方仓库<https://github.com/kubernetes-csi/csi-driver-nfs>

{% note warning %}
官方默认的镜像在国内是无法访问，需要转储到国内的仓库里，建议找台香港的机器或者科学上网
{% endnote %}

```shell
registry.k8s.io/sig-storage/csi-provisioner:v3.2.0
registry.k8s.io/sig-storage/livenessprobe:v2.7.0
registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.5.1
gcr.io/k8s-staging-sig-storage/nfsplugin:canary
```

##### 在线安装

```shell
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --
```

##### 本地安装

```shell
git clone https://github.com/kubernetes-csi/csi-driver-nfs.git
cd csi-driver-nfs
./deploy/install-driver.sh master local
```

等待所有pod running

```shell
kubectl -n kube-system get pod  |grep nfs
```

##### 部署存储类对象

```shell
cat <<EOF > nfs-cs.yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs
parameters:
  server: 192.168.32.133 # nfs服务器地址
  share: /data/nfs # nfs共享的目录
provisioner: nfs.csi.k8s.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

kubectl apply -f nfs-cs.yml
```

```shell
# 将nfs-csi 设置为默认存储类
kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### 测试部署

静态pv

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-csi
  mountOptions:
    - nfsvers=3
  csi:
    driver: nfs.csi.k8s.io
    readOnly: false
    volumeHandle: unique-volumeid  # make sure it's a unique id in the cluster
    volumeAttributes:
      server: 192.168.32.133
      share: /data/nfs
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nfs-static
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: pv-nfs
  storageClassName: nfs-csi
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: test
      mountPath: /data
  volumes:
  - name: test
    persistentVolumeClaim:
      claimName: pvc-nfs-static
```

#### 参考资料

<https://github.com/kubernetes-csi/csi-driver-nfs>
