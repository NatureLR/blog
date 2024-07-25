title: kubectl格式化输出
author: Nature丿灵然
tags:
  - k8s
date: 2020-07-21 14:16:00
---
有时候需要输出一些k8s的资源信息为一个表格比如统计资源你的数量
<!--more-->
将下面你的模板保存为template.txt

```shell
cat << EOF >> template.txt
命名空间              名字           保留内存              保留cpu        最大内存  最大cpu
metadata.namespace   metadata.name spec.containers[*].resources.requests.memory  spec.containers[*].resources.requests.memory   spec.containers[*].resources.limits.memory  spec.containers[*].resources.limits.cpu
EOF
```

然后执行

```shell
kubectl get deployment  -o custom-columns-file=template.txt
```

除了用模板文件还可以用

```shell
kubectl get deployment  -o custom-columns=名字:.metadata.name,数量:.spec.replicas
```
