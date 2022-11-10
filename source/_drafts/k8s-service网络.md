layout: draft
title: k8s-service网络
author: Nature丿灵然
tags:
  - k8s
  - 网络
categories:
  - 运维
date: 2021-06-11 15:05:00
---
k8s service是对一组pod进行抽象的方法

<!--more-->

> pod并不是永久的随时可以销毁的，那么他ip也会变的，这样的话就需要一种方法来作为pod的”前端“来转发到pod上去

#### 实现方式

service的ip是虚拟的他的具体实现程序是`kube-proxy`

![svc](../images/kube-svc-1.png)

如图，流量被service给负载到后端当中，对于用户来说只要访问service即可

kub-proxy有目前主要有四种

- 用户空间: 早期的方案，所有策略都在用户空间效率比较差
- iptables: iptables在内核空间，主要通过nat实现，由于iptables是一个一个匹配所有规则多时效果延迟比较大
- ipvs: 和iptables类似只不过使用了ipvs
- ebpf: 最新的技术速度快效率高，但对内核版本要求比较高

目前主流使用iptables和ipvs，所以主要说iptables和ipvs

![svc](../images/kube-svc-1.png)

##### kube-proxy

#### 使用

```yaml
apiVersion: v1
kind: Service
metadata:
  name: foo
spec:
  selector: # 选择需要负载到pod
    app: foo
  ports:
  - port: 80 # 服务的端口
    targetPort: 80 # pod的端口
  type: ClusterIP # 类型，默认ClusterIP
```

将上面的保存为foo.yaml然后执行`kubectl apply -f foo.yaml`即可创建一个svc

#### 类型

k8s的服务类型拥有很多种，根据实际情况选择

##### ClusterIP

默认的类型,创建一个虚拟的ip并将选择器选择的pod的ip作为这个虚拟ip的后端

##### NodePort

和ClusterIP基本一致，但是会将端口映射到所有集群中所有的节点上,端口范围默认是3000以上

```yaml
apiVersion: v1
kind: Service
metadata:
  name: foo
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: foo
  type: NodePort
```

##### Headless

和ClusterIP基本一致，只是没有虚拟ip同时失去了lb的功能,`kube-proxy`不会处理此svc且dns返回对应ep的所有地址，常用于`服务发现`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: foo
spec:
  selector: 
    app: foo
  clusterIP: None # 指定为none
  ports:
  - port: 80 
    targetPort: 80 
  type: ClusterIP
```

##### LoadBalancer

这个类型一般只有云服务商只能使用，创建这个服务的同时在云服务商的lb服务商上创建了一个实例

```yaml
apiVersion: v1
kind: Service
metadata:
  name: foo-loadbalancer
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: http
    nodePort: 80
    port: 80
    protocol: TCP
    targetPort: 800
  selector:
    app: foo
  sessionAffinity: None
  type: LoadBalancer
```

##### ExternalName

类似外部的一个服务对内部的一个别名，比如mysql的地址是192.168.1.1，则在集群中可以使用mysq来访问192.168.1.1

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  externalName: 192.168.1.1
  ports:
  - name: tcp
    port: 3306
    protocol: TCP
    targetPort: 3306
  sessionAffinity: None
  type: ExternalName
```

#### 流量策略

流量策略主要解决在拥有众多ep的服务在转发流量时有些pod距离访问的node比较远导致延迟增大

目前拥有2种策略，`cluster`和`local`

- cluster(默认):会将流量转发到所有节点的pod当中,但有可能pod在其他节点或者其他地域上会导致延迟

- local: 只会将流量转发本地的pod上，不会转发到其他node上的pod,拥有较好的性能

![kube-svc](../images/kube-svc-3.png)

##### internalTrafficPolicy

- 主要针对pod访问svc的策略

##### externalTrafficPolicy

- 针对外面通过node port访问集群的svc

#### 实现

##### iptables

##### 南北流量

```shell
#! /bin/bash
set -e

log(){
  printf "\n"
  echo -e '\e[92m'$1链$2表'\e[0m'
}

log PREROUTING raw
iptables -nvL PREROUTING -t raw
log PREROUTING mangle
iptables -nvL PREROUTING -t mangle
log PREROUTING nat
iptables -nvL PREROUTING -t nat


log INUT mangle
iptables -nvL INPUT -t mangle
log INUT nat
iptables -nvL INPUT -t nat
log INUT filter
iptables -nvL INPUT -t filter


log INUT filter
iptables -nvL FORWARD -t mangle
log INUT filter
iptables -nvL FORWARD -t filter

log OUTPUT raw
iptables -nvL OUTPUT -t raw
log OUTPUT mangle
iptables -nvL OUTPUT -t mangle
log OUTPUT nat
iptables -nvL OUTPUT -t nat
log OUTPUT filter
iptables -nvL OUTPUT -t filter

log POSTROUTING mangle
iptables -nvL POSTROUTING -t mangle
log POSTROUTING nat
iptables -nvL POSTROUTING -t nat
```

```shell
root@minikube:~# iptables -nvL PREROUTING -t nat
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    4   276 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
    1    96 DOCKER_OUTPUT  all  --  *      *       0.0.0.0/0            192.168.65.2        
    6   360 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
root@minikube:~# 



```

##### 东西流量

##### ipvs

#### 参考资料

<https://kubernetes.io/zh/docs/concepts/services-networking/service/>
<https://draveness.me/kubernetes-service/>
