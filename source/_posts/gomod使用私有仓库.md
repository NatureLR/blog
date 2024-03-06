layout: draft
title: gomod使用私有仓库
author: Nature丿灵然
tags:
  - gomod
date: 2023-04-11 17:50:00
---
在工作中我们有些mod是放在gitlab中的且一般是有认证的这里记录下解决办法

<!--more-->

### 私有仓库设置

> 都可以通过`,`来设置多个

- 告诉go那些仓库是私有仓库

```shell
go env -w GOPRIVATE="git@git.example.com"
```

- 告诉go私有仓库不走goproxy代理

```shell
go env -w GONOPROXY="git.example.com"
```

- 告诉go这个仓库的不用验证CA

```shell
go env -w GOINSECURE="git.example.com"
```

- 设置不做校验的仓库

```shell
go env -w GONOSUMDB="git.example.com"
```

#### 使用gitlab token认证

- 原理其实就是替换下git的链接将普通的链接替换成可以认证的链接

- token在gitlab的项目-->设置-->访问令牌，添加一个只读的即可

```shell
# 将go默认访问的替换成通过token认证的链接以达到认证的目的
git config --global url."https://oauth2:$TOKEN@git.example.com/lib/utils.git".insteadOf "https://git.example.com/lib/utils.git"
```

#### 使用gitlab ssh认证

- 这里将https的请求换成ssh请求，需要注意的是本地的公钥需要提前加入到gitalb中

```shell
git config --global url."git@git.example.com:lib/utils.git".insteadOf "https://git.example.com/lib/utils.git"

# 另一种写法
git config --global url."ssh://git@git.example.com:lib/utils.git".insteadOf "https://git.example.com/lib/utils.git"
```
