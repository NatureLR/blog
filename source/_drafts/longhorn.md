title: 模版
author: Nature丿灵然
tags:
  - 模版
date: 2020-12-14 15:15:00
---
<简介，将显示在首页>

<!--more-->

> 说明，模版文件不要发布出来

#### 标题一

```shell
yum --setopt=tsflags=noscripts install iscsi-initiator-utils

echo "InitiatorName=$(/sbin/iscsi-iname)" > /etc/iscsi/initiatorname.iscsi
systemctl enable iscsid
systemctl start iscsid
modprobe iscsi_tcp

cat /boot/config-`uname -r`| grep CONFIG_NFS_V4_1
cat /boot/config-`uname -r`| grep CONFIG_NFS_V4_2

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml

kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

#### 参考资料

<https://longhorn.io/docs>
