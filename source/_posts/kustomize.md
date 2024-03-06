layout: draft
title: kustomize
author: Nature丿灵然
tags:
  - k8s
date: 2021-07-21 18:46:00
---
kustomize是k8s-sig开发的一个用来渲染一些k8s资源文件的工具

<!--more-->

> 主要场景就是多集群环境，一个服务在每个集群的配置不一样很容易造成混乱

#### 安装

macos

```shell
brew install kustomize
```

二进制手动安装

```shell
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
```

kubectl

> kubectl 已经集成了kustomize

```shell
kubectl kustomize
kubectl apply -k
```

#### 动手尝试

##### 1.创建kustomize描述文件

创建一个名为`base`的文件夹并在文件夹里一个文件名为`kustomization.yaml`且写入如下内容

```yaml
# 设置ns
namespace: test
resources:
  - deployment.yaml
# 生成config
configMapGenerator:
- name: example-configmap-1
  envs:
  - env.conf
  literals:
  - FOO=Bar
# 生成secrets
secretGenerator:
- name: example-secret-2
  literals:
  - username=admin
  # 通过文件生成secret
  files: 
  - passwd.conf
generatorOptions: # 只对生成的资源有效
  disableNameSuffixHash: true # 关闭生成的资源文件的hash值
  labels: # 所有生产的资源都会有下面的标签
    type: generated
  annotations: # 所有生产的资源都会有下面的注解
    note: generated
# 镜像替换
images:
  - name: nginx
    newName: nginx
    newTag: alpine
```

##### 2.创建依引用资源文件

创建kustomization.yaml中引用的文件

```shell
# 创建deployment.yaml 此文件为为模板文件
cat <<EOF >base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
spec:
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: test
        image: nginx
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
        volumeMount:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: example-configmap-1
EOF

# 创建配置文件
cat <<EOF >base/env.conf
key=abcdef
debug=true
EOF

# 创建secrets文件
cat <<EOF >base/passwd.conf
user=root
passwd=123456
EOF

```

最终文件结构如下：
base
├── deployment.yaml
├── env.conf
├── kustomization.yaml
└── passwd.conf

##### 3.编译

执行`kubectl kustomize base`或者`kustomize build base`

这时候我们发现生成的内容当中自动从.conf文件自动转换为k8s资源文件，且镜像被替换了生成的文件都有我们指定的标签

#### 基准覆盖

上面我们创建的只是一个基本k8s资源文件，在实际中一个服务在各个环境会有细微的区别那么我们可以通过kustomize在基本上进行一些修改

假如上面的服务我们要部署到测试环境中，在测试环境中ns需要加上一些dev等字段，且还有一些节点亲和等操作

##### 1.创建测试环境的kustomize文件

- 在base同级目录中创建一个叫`overlays`的目录,且在里面在创建个目录叫dev

```shell
mkdir -p overlays/dev
```

- 写入`kustomization.yaml`

```yaml
# 引用基准资源
resources:
  - ../../base
# 设置ns名字前缀
namePrefix: dev-
# 设置ns名字后缀
nameSuffix: "-a"
# 设置公共标签
commonLabels:
  env: dev
# 设置公共注解
commonAnnotations:
  owner: foo
images:
  - name: nginx
    newName: nginx
    newTag: alpine
# 合并补丁
patchesStrategicMerge:
  - nodeAffinity.yaml
```

##### 2.创建测试环境的引用文件

```shell
cat <<EOF >overlays/dev/nodeAffinity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
  spec:
    template:
      spec:
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
              - matchExpressions:
                - key: kubernetes.io/os
                  operator: Exists
EOF
```

此时文件结构如下
.
├── base
│   ├── deployment.yaml
│   ├── env.conf
│   ├── kustomization.yaml
│   └── passwd.conf
└── overlays
    └── dev
        ├── kustomization.yaml
        ├── nodeAffinity.yaml

##### 3.编译测试环境

```shell
kustomize build overlays/dev
```

其他环境如法炮制，这样就可以优雅的管理服务在各个资源的描述，在结合argcd的情况下会更加的舒服！

#### kubectl使用

> kubectl中只需要在后面加上-k即可对应命令如下

```shell
kubectl apply -k
kubectl apply --kustomize

kubectl get -k
kubectl diff -k
kubectl describe -k
```

#### 参考资料

- <https://kubernetes.io/zh/docs/tasks/manage-kubernetes-objects/kustomization>

- <https://kustomize.io>
