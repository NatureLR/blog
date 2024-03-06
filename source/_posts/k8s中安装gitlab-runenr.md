title: k8s中安装gitlab-runner
author: Nature丿灵然
tags:
  - cicd
date: 2021-12-17 14:05:00
---

记录下在k8s中安装gitlab-runner

<!--more-->

#### 获取注册token

- 全局runner：管理员界面->概览—>runner->左上角(/admin/runners)

- 组runner：组界面->设置->CI/CD->展开runner(/groups/<组名>/-/settings/ci_cd)

- 项目runner：项目界面->设置->CI/CD->展开runner(<组名>/<项目名>/-/settings/ci_cd)

#### 添加helmc仓库

```shell
helm repo add gitlab https://charts.gitlab.io
```

#### 解压chart包

> 解压他的包为了得到完整的values.yaml，这个文件里面说的很详细的一些配置

```shell
helm pull gitlab/gitlab-runner
tar -xvf gitlab-runner-0.35.3.tgz
```

#### 修改参数

- 修改`gitlabUrl`的地址为你的gitlab地址

- 配置`runnerRegistrationToken`为你的token

- 配置`tags`字段，可以在在选择性

- 增加权限，这里直接给所有权限

```yaml
rbac:
  create: true
  rules: 
   - resources: ["*"]
     verbs: ["*"]
   - apiGroups: [""]
     resources: ["*"]
     verbs: ["*"]
```

#### 安装gitlab

```shell
helm install --namespace gitlab gitlab-runner -f values.yaml gitlab/gitlab-runner 
```

```sehll
helm upgrade --namespace gitlab -f values.yaml gitlab-runner gitlab/gitlab-runner
```

#### 参考资料

<https://docs.gitlab.com/runner/install/kubernetes.html>
