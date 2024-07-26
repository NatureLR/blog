title: coredns
author: Nature丿灵然
tags:
  - 网络
  - dns
  - k8s
date: 2024-07-14 15:15:00
---
coredns是coreos开发的一个dns，是k8s的默认dns

<!--more-->

> 说明，模版文件不要发布出来

#### 标题一

```yaml
apiVersion: v1
data:
  Corefile: |
    foo.com:53 {
        template ANY AAAA {
          rcode NOERROR
        }
        log
        errors
        cache 30
        forward . 100.90.90.90 100.90.90.100
     }
    .:53 {
        log
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        hosts {
           192.168.65.254 host.minikube.internal
           fallthrough
        }
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
```

#### 自定义hosts

#### 轮训

#### 参考资料

<http://blog.naturelr.cc>

动态dns <https://github.com/cunnie/sslip.io>
