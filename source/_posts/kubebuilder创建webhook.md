---
title: kubebuilder创建webhook
author: Nature丿灵然
tags:
  - k8s
  - kubebuilder
date: 2025-05-03 12:58:00
---
kubebuilder可以快速的为k8s创建一个webhook脚手架

<!--more-->

#### 1.初始化项目

- 初始化kubebuilder

```shell
kubebuilder init --repo github.com/naturelr/lxcfs-admission-webhook --domain github.com
```

#### 2.创建webhook

> 注意 mutating webhook和validating webhook确定之后是不能修改的

- mutating webhook

```shell
kubebuilder create webhook --group core --version v1 --kind Pod --defaulting 
```

- validating webhook

```shell
kubebuilder create webhook --group core --version v1 --kind Pod --programmatic-validation
```

- mutating webhook和validating webhook

```shell
kubebuilder create webhook --group core --version v1 --kind Pod --programmatic-validation --defaulting
```

- 在`config/default/kustomization.yaml`删除下面的注释来支持certmanager

```yaml
resources:
# [CERTMANAGER] To enable cert-manager, uncomment all sections with 'CERTMANAGER'. 'WEBHOOK' components are required.
- ../certmanager
```

- 在`config/default/kustomization.yaml`删除下面的注释的来支持webhook

```yaml
replacements:
- source: # Uncomment the following block if you have any webhook
    kind: Service
    version: v1
    name: webhook-service
    fieldPath: .metadata.name # Name of the service
  targets:
    - select:
        kind: Certificate
        group: cert-manager.io
        version: v1
        name: serving-cert
      fieldPaths:
        - .spec.dnsNames.0
        - .spec.dnsNames.1
      options:
        delimiter: '.'
        index: 0
        create: true
- source:
    kind: Service
    version: v1
    name: webhook-service
    fieldPath: .metadata.namespace # Namespace of the service
  targets:
    - select:
        kind: Certificate
        group: cert-manager.io
        version: v1
        name: serving-cert
      fieldPaths:
        - .spec.dnsNames.0
        - .spec.dnsNames.1
      options:
        delimiter: '.'
        index: 1
        create: true
```

- 如果是mutating webhook(--defaulting)就删除下面的注释

```yaml
replacements:
- source: # Uncomment the following block if you have a DefaultingWebhook (--defaulting )
    kind: Certificate
    group: cert-manager.io
    version: v1
    name: serving-cert
    fieldPath: .metadata.namespace # Namespace of the certificate CR
  targets:
    - select:
        kind: MutatingWebhookConfiguration
      fieldPaths:
        - .metadata.annotations.[cert-manager.io/inject-ca-from]
      options:
        delimiter: '/'
        index: 0
        create: true
- source:
    kind: Certificate
    group: cert-manager.io
    version: v1
    name: serving-cert
    fieldPath: .metadata.name
  targets:
    - select:
        kind: MutatingWebhookConfiguration
      fieldPaths:
        - .metadata.annotations.[cert-manager.io/inject-ca-from]
      options:
        delimiter: '/'
        index: 1
        create: true
```

- 如果是validating webhook则将下面注释开头的内容注释删除

```yaml
# - source: # Uncomment the following block if you have a ValidatingWebhook (--programmatic-validation)
```

##### 为webhook添加ns选择器

- 将下面的yaml的补丁放到`config/default/webhook_webhook_patch.yaml`中

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: mutating-webhook-configuration
webhooks:
  - name: mpod-v1.kb.io
    namespaceSelector:
      matchLabels:
         lxcfs-injection: enabled
```

- 同时在`config/default/kustomization.yaml`中的`patches`字段添加下面的内容

```yaml
patches:
- path: webhook_webhook_patch.yaml
  target:
    kind: MutatingWebhookConfiguration
    name: mutating-webhook-configuration
```

#### 3.编写webhook代码

- 在`internal/webhook/v1/pod_webhook.go`中写逻辑，其中`+kubebuilder`开头的注释为代码生成器

- 修改`+kubebuilder`需要执行下面的命令来生成一些代码

```shell
make manifests
```

#### 4.编译镜像

- 设置镜像仓库地址，在makefile中第一行设置docker镜像地址

```makefile
# makefile
IMG ?= controller:latest
```

- 编译docker镜像

```shell
make docker-build 
make docker-push
```

- 多架构镜像,这会直接上传到镜像仓库，在makefiel中的`PLATFORMS`变量可以调整需要的平台

```shell
make docker-buildx
```

- 如果没有cr的话没有api目录导致编译报错注释掉dockefile中这句话就可以了

```shell
#COPY api/ api/
```

#### 5.部署测试

- 部署到集群中

```shell
make deploy
```

- 从集群中卸载

```shell
make undeploy
```

- 生成部署的yaml,如果是webhook需要添加`--force`

```shell
make build-installer IMG=naturelr/lxcfs-admission-webhook:latest --force
```

- 生成helm文件,

```shell
kubebuilder edit --plugins=helm/v1-alpha
```

#### 参考资料

<https://book.kubebuilder.io>
