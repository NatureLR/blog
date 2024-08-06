---
layout: draft
title: 初试kubevirt
author: Nature丿灵然
tags:
  - 虚拟化
  - k8s
date: 2022-07-17 16:26:00
---
kubevirt是一个可以在k8s上管理虚拟机的应用

<!--more-->

> 可以通过cr的方式创建虚拟机，是k8s具备提供虚拟化服务

## 安装

> 安装资源发布在官方[仓库](https://github.com/kubevirt/kubevirt/releases),这里提供快捷安装方法

### kubevirt

> 更新也是一样的

```sehll
# 定义版本
export RELEASE=v0.51.0

# 部署operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$RELEASE/kubevirt-operator.yaml

# 部署kubevirt的cr
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$RELEASE/kubevirt-cr.yaml

# 查看状态
kubectl -n kubevirt wait kv kubevirt --for condition=Available
```

下面的yaml增加了热迁移特性且调整副本数为1

```shell
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  certificateRotateStrategy: {}
  configuration:
    developerConfiguration:
      featureGates: 
      - LiveMigration # 热迁移特性
  customizeComponents: {}
  imagePullPolicy: IfNotPresent
  infra:
    replicas: 1 # api副本数调整为1，使用默认的2
  workloadUpdateStrategy: {}
EOF
```

> 如果是在虚拟机中需要打开嵌套虚拟化,如果没法打开就使用软件仿真

```shlle
kubectl create configmap kubevirt-config -n kubevirt --from-literal debug.useEmulation=true
```

### kubectl插件

```shell
kubectl krew install virt
```

### virtctl命令行工具

```shell
export VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
export ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/') || windows-amd64.exe
echo ${ARCH}

curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl
sudo install virtctl /usr/local/bin
```

### 卸载

{% note warning %}
卸载有顺序先删除自动以资源,再删除oper，强制删除ns会导致ns处于Terminating状态
{% endnote %}

```shell
export RELEASE=v0.54.0
kubectl delete -n kubevirt kubevirt kubevirt --wait=true # --wait=true should anyway be default
kubectl delete apiservices v1alpha3.subresources.kubevirt.io # this needs to be deleted to avoid stuck terminating namespaces
kubectl delete mutatingwebhookconfigurations virt-api-mutator # not blocking but would be left over
kubectl delete validatingwebhookconfigurations virt-api-validator # not blocking but would be left over
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml --wait=false
```

### 管理虚拟机

- 创建虚拟机

```shell
kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml
```

- 查看虚拟机状态

```shell
k get vms                                                  
# NAME     AGE   STATUS    READY
# testvm   7s    Stopped   False

k get vmi
#NAME     AGE     PHASE     IP            NODENAME         READY
#testvm   6h16m   Running   10.244.1.44   192.168.32.133   True
```

- 启动虚拟机

```shell
virtctl start testvm
```

- 停止虚拟机

```shell
virtctl stop testvm
```

- 登录虚拟机

```shell
virtctl console testvm
```

- 删除虚拟机

```shell
kubectl delete vm testvm
```

## cdi

> 导入镜像创建虚拟机，使用pvc提供虚拟机磁盘

CDI 支持 qemu 支持的raw和qcow2 ISO 可以使用gz或xz格式压缩图像

### 安装cdi

```shell
export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

### 创建磁盘持久卷(dv)

dv datavolumes缩写，实际上是经过cdi处理之后的放在pvc的.img文件

- pvc自动获取，从连接下载自动解压到指定的pvc中
- 手动上传，使用`virtctl`工具上传到pvc中

#### pvc自动拉取

```shell
cat <<EOF > pvc_fedora.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "fedora"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://download.fedoraproject.org/pub/fedora/linux/releases/33/Cloud/x86_64/images/Fedora-Cloud-Base-33-1.2.x86_64.raw.xz" # 这个国内很慢建议且有时候会404,建议手动下载下来放到本地web服务上
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

kubectl apply -f pvc_fedora.yaml
```

这个时候会有创建导入到pvc的pod

#### 手动上传镜像

{% note warning %}
192.168.32.132:31937替换为实际的nodeport地址
{% endnote %}

##### 访问cdi-uploadproxy

这里使用nodeport

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: cdi-uploadproxy-nodeport
  namespace: cdi
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    cdi.kubevirt.io: cdi-uploadproxy
  sessionAffinity: None
  type: NodePort
EOF
```

##### 上传

由于证书的问题会导致上传失败，有2种方法来解决证书问题

###### 使用hosts

- 获取信任域名

```shell
echo | openssl s_client -showcerts -connect  192.168.32.132:31937 2>/dev/null \
     | openssl x509 -inform pem -noout -text \
     | sed -n -e '/Subject.*CN/p' -e '/Subject Alternative/{N;p}'
```

输出

```text
        Subject: CN=cdi-uploadproxy
            X509v3 Subject Alternative Name:
                DNS:cdi-uploadproxy, DNS:cdi-uploadproxy.cdi, DNS:cdi-uploadproxy.cdi.svc
```

其中`Subject`就是讲作为认证的域名

- 组合成hosts条目

```shell
echo "192.168.32.132  cdi-uploadproxy" >> /etc/hosts
```

- 上传

```shell
virtctl image-upload dv dv-test
    --size=5Gi \
    --image-path=./Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
    --uploadproxy-url=https://cdi-uploadproxy:31937 \
    --insecure # 忽略证书错误
```

###### 信任证书

- 导出证书

```shell
kubectl get secret -n cdi cdi-uploadproxy-server-cert \
  -o jsonpath="{.data['tls\.crt']}" \
  | base64 -d > cdi-uploadproxy-server-cert.crt
```

- 安装证书

```shell
# 安装证书
sudo cp cdi-uploadproxy-server-cert.crt /etc/pki/ca-trust/source/anchors

# 刷新证书
sudo update-ca-trust
```

- 上传

```shell
virtctl image-upload dv dv-test
    --size=5Gi \
    --image-path=./Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
    --uploadproxy-url=https://cdi-uploadproxy:31937 
    #--insecure # 不需要此参数
```

#### 设置默认上传地址

```shell
kubectl patch cdi cdi \
  --type merge \
  --patch '{"spec":{"config":{"uploadProxyURLOverride":"https://cdi-uploadproxy:31937"}}}'
```

上传的时候就不需要带`--uploadproxy-url`参数了

### 使用pvc的作为vm系统盘

```shell
cat <<EOF > vm1.yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  generation: 1
  labels:
    kubevirt.io/os: linux
  name: vm1
spec:
  running: true
  template:
      labels:
        kubevirt.io/domain: vm1
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
          - cdrom:
              bus: sata
              readonly: true
            name: cloudinitdisk
        machine:
          type: q35
        resources:
          requests:
            memory: 512M
      volumes:
      - name: disk0
        persistentVolumeClaim:
          claimName: fedora
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            hostname: vm1
            ssh_pwauth: True
            disable_root: false
            ssh_authorized_keys:
            - ssh-rsa <公钥> 
        name: cloudinitdisk
EOF

kubectl apply -f vm1.yaml
```

- 直接创建vmi

```shell
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  name: dv-test
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: dvdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: dvdisk
    dataVolume:
      name: dv-test
status: {}
EOF
```

- 使用vm

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/os: linux
  name: dv-test
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: dv-test
    spec:
      domain:
        cpu:
          cores: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
        machine:
          type: q35
        resources:
          requests:
            memory: 512M
      volumes:
      - name: disk0
        dataVolume:
          name: dv-test
```

#### 参考资料

<https://kubevirt.io/user-guide/>
