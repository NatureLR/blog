---
layout: draft
title: 使用docker-registry部署docker加速仓库
author: Nature丿灵然
tags:
  - docker
  - 镜像仓库
date: 2024-06-26 00:42:00
---
最近个国内各大docker镜像仓库都无法访问，我们可以在海外自己部署一个镜像仓库

<!--more-->

#### 部署加速仓库

- 部署文件，`docekr compose up -d`

```yaml
version: '3.8'
services:
  docker-registry:
    image: registry:latest
    container_name: docker-registry
    restart: always
    volumes:
      - ./data/docker-registry/config:/etc/docker/registry/
      - ./data/docker-registry/lib:/var/lib/registry
    ports:
      - 80:5000
```

- 将下面的配置文件保存到`./data/docker-registry/config/config.yml`

```yaml
---
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  #tag:
  #  concurrencylimit: 8
  #delete: #配置删除权限,默认安装的Registry不支持删除
  #  enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
#auth:
#  htpasswd:
#    realm: basic-realm
#    path: /etc/docker/registry/htpasswd
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
    remoteurl: https://registry-1.docker.io
```

#### docker配置

```json
{
  "registry-mirrors": ["http://<ip:port>"],
  "insecure-registries": ["http://<ip:port>"]
}
```

- 重启docker

```shell
systemctl restart docker
```

##### 认证

- 生成密码

```shell
docker run --rm --entrypoint htpasswd httpd:2 -Bbn <账号密码> <密码> > htpasswd
```

- 将生成的文件放在上面配置的路径

#### 参考资料

<https://distribution.github.io/distribution/>
<https://docs.docker.com/docker-hub/mirror/#configure-the-cache>
