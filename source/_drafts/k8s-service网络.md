layout: draft
title: k8s-service网络
author: Nature丿灵然
tags:
  - k8s
categories:
  - 运维
date: 2021-06-11 15:05:00
---

k8s service是对一组pod进行抽象的方法

<!--more-->

> pod并不是永久的随时可以销毁的，那么他ip也会变的，这样的话就需要一种方法来作为pod的”前端“来转发到pod上去

#### 实现方式

service的vip是虚拟的他的具体实现程序是`kube-proxy`

![upload successful](/images/pasted-24.png)

如图，流量被service给负载到后端当中，对于用户来说只要访问service即可

kub-proxy有目前主要有三种

- 用户空间: 所有策略都在用户空间效率比较差
- iptables: iptables在内核空间，由于iptables是一个一个匹配所有规则多时效果延迟比较大
- ipvs: 和iptables类似只不过使用了ipvs
- ebpf: 最新的技术速度快效率高，但对内核版本要求比较高

目前默认使用iptables，所以主要说iptables

![upload successful](/images/pasted-26.png)

##### kube-proxy

#### 使用

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
```

#### 参考资料

<https://kubernetes.io/zh/docs/concepts/services-networking/service/>
