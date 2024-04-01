title: karmada安装和基本使用
author: Nature丿灵然
tags:
  - k8s
  - 多集群
  - karmada
date: 2024-04-01 18:48:00
---
karmada是k8s的一个多集群实现方案

<!--more-->

![alt text](../images/karmada-1.png)

#### 安装

- 下载二进制客户端文件<https://github.com/karmada-io/karmada/releases>

```shell
wget https://github.com/karmada-io/karmada/releases/download/v1.9.0/karmadactl-linux-amd64.tgz
```

- 也可以安装 kubectl的插件

```shell
kubectl krew install karmada
```

- 安装karmadactl到集群中

```shell
karmadactl init 
```

- 安装完成之后默认会在目录`/etc/karmada/`添加这个虚拟集群的相关文件

#### 多集群成员

##### push模式添加成员

- 添加集群push模式，--kubeconfig决定要加入的集群

```shell
karmadactl --kubeconfig /etc/karmada/karmada-apiserver.config join cluster1  --cluster-kubeconfig=$HOME/.kube/config
```

##### 查看集群

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config get clusters
```

##### pull模式添加成员

- 获取注册命令和凭据

```shell
karmadactl  token create --print-register-command --kubeconfig /etc/karmada/karmada-apiserver.config
# karmadactl register 10.7.143.254:32443 --cluster-name cluster2 --token po8les.a05eqne2hqwy8gly --discovery-token-ca-cert-hash sha256:3bfb29c846092b61af5bb51a47a88bd52ed834d8468158a7fb341180d5a3bc74
```

##### 删除集群

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config delete cluster cluster2
```

#### 应用分发

- 首先查看下有那些集群

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config get clusters
# NAME         VERSION    MODE   READY   AGE
# cluster1     v1.24.12   Push   True    10d
# kubernetes   v1.24.12   Pull   True    9d
```

- 部署分发策略

```yaml
# propagationpolicy.yaml
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: example-policy # The default namespace is `default`.
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: nginx # If no namespace is specified, the namespace is inherited from the parent object scope.
  placement:
    clusterAffinity:
      clusterNames:
        - cluster1
        - kubernetes
```

- 部署上面的分发策略

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config apply -f propagationpolicy.yaml
```

- 其中一个集群中部署一个测试的nginx

```shell
kubectl create deployment nginx --image nginx
```

- 在karmada中也创建一个测试的

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config create deployment nginx --image nginx
```

- 在第二个集群中可以看到同步过来了，此时同步完成

```shell
kubectl --kubeconfig=./2.yaml get po
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-8f458dc5b-w526c   1/1     Running   0          5m43s
```

- 当我们删除karmada中的nginx

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config delete deploy
# deployment.apps "nginx" deleted

# 集群1的资源还在
kubectl get po
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-8f458dc5b-t6z4k   1/1     Running   0          7m35s

# 集群2的资源不在了
kubectl --kubeconfig=./2.yaml get po
# No resources found in default namespace.
```

- 将集群1的测试资源也删除

```shell
kubectl delete deploy nginx
# deployment.apps "nginx" deleted
```

- 我们只在karmada中部署nginx测试

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config create deployment nginx --image nginx
#deployment.apps/nginx created

# 可以看到 ready是2/1 因为2个集群都同步了
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config get deploy  
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   2/1     2            2           15s

# 使用karmadactl查看
karmadactl --kubeconfig=/etc/karmada/karmada-apiserver.config  get po
# NAME                     CLUSTER      READY   STATUS    RESTARTS   AGE
# nginx-74f96fcc5c-zphtd   cluster1     1/1     Running   0          6m6s
# nginx-8f458dc5b-mkpx9    kubernetes   1/1     Running   0          11m
```

- 从上面的现象可以看到同步的时候karmada集群中必须有需要同步资源,当成员集群已经有了该资源则在删除的时候不会删除

#### 覆盖应用

> 覆盖主要用于重写一些属性

- 保存下面的覆盖策略为overridepolicy.yaml

```shell
# overridepolicy.yaml
apiVersion: policy.karmada.io/v1alpha1
kind: OverridePolicy
metadata:
  name: example
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: nginx
      labelSelector:
        matchLabels:
          app: nginx
  overrideRules:
    - targetCluster:
        clusterNames:
          - cluster1
      overriders:
        imageOverrider:
          - component: Tag
            operator: replace
            value: '1.20'
```

- apply这个策略到karmada集群

```shell
kubectl --kubeconfig /etc/karmada/karmada-apiserver.config apply -f overridepolicy.yaml
```

- 查看集群1的nginx已经被改为1.20版本了

```shell
kubectl  get deploy -o wide 
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
# nginx   1/1     1            1           6m12s   nginx        nginx:1.20   app=nginx
```

#### 参考资料

<https://karmada.io/zh/docs>
