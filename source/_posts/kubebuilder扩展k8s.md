layout: draft
title: kubebuilder扩展k8s
author: Nature丿灵然
tags:
  - k8s
  - go
date: 2021-11-02 11:39:00
---
kubebuilder是个专门用于开发k8s的框架

<!--more-->

> k8s有很多资源如deployment,cronjob等资源，这些资源的行为则由位于controller-manager中的各个资源控制器来实现逻辑,

#### 安装

在<https://github.com/kubernetes-sigs/kubebuilder/releases>下载合适的二进制文件并放入path中

#### 术语

- GV: Api Group和Version
  - API Group 是相关API功能的集合，
  - 每个 Group 拥有一或多个Versions
- GVK: Group Version Kind
  - 每个GV都包含很多个api 类型，称之为Kinds,不同Version同一个Kinds可能不同
- GVR: Group Version Rsource
  - Resource 是 Kind 的对象标识，一般来Kind和Resource 是1:1 的,但是有时候存在 1:n 的关系，不过对于Operator来说都是 1:1 的关系

```yaml
apiVersion: apps/v1 # 这个是 GV，G 是 apps，V 是 v1
kind: Deployment    # 这个就是 Kind
sepc:               # 加上下放的 spec 就是 Resource了
```

根据GVK K8s就能找到你到底要创建什么类型的资源，根据你定义的Spec创建好资源之后就成为了Resource，也就是GVR。GVK/GVR就是K8s资源的坐标，是我们创建/删除/修改/读取资源的基础

类似这样的关系/group/version/kind

#### 示例

##### 项目初始化

完整代码:<https://github.com/NatureLR/code-example/tree/master/operator>

##### 需求背景

> 我们在部署服务的时候经常需要同时部署deployment和svc这样很复杂，于是自定义一个资源叫appx，让appx来创建svc和deployment

##### 初始化文件夹

在项目文件夹下执行

```shell
kubebuilder init --repo github.com/naturelr/code-example/operator --domain naturelr.cc --skip-go-version-check
```

这个时候目录下会产生一些文件

```text.
├── Dockerfile # 编译docker镜像
├── Makefile # 编译部署相关的脚本，常用功能都在里面
├── PROJECT # 项目说明
├── config # 这个目录都是一些需要安装到集群的文件
│   ├── default # 默认配置
│   ├── manager # crd文件
│   ├── prometheus # 监控相关的如ServiceMonitor
│   └── rbac # rbac文件
├── go.mod
├── go.sum
├── hack
│   └── boilerplate.go.txt
└── main.go

6 directories, 24 files
```

##### 创建api模板

执行下面的命令，创建api，期间会问你是不是需要创建Resource和Controller，这里我们都选y

```shell
kubebuilder create api --group appx --version v1 --kind Appx
```

完成之后多了一些目录

```text
.
├── Dockerfile
├── Makefile
├── PROJECT
├── api
│   └── v1 # 我们自定义的api
├── bin
│   └── controller-gen # 生成文件的程序
├── config
├── controllers
│   ├── appx_controller.go # 控制逻辑写在这
│   └── suite_test.go # 测试用例
├── go.mod
├── go.sum
├── hack
│   └── boilerplate.go.txt
└── main.go

12 directories, 10 files
```

##### 实现

##### 定义字段

在`api/v1/application_types.go`中的AppxSpec写上需要的字段

```go
 type AppxSpec struct {
  // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
  // Important: Run "make" to regenerate code after modifying this file
 
  // Foo is an example field of Appx. Edit appx_types.go to remove/update
  Image string `json:"image,omitempty"`
  Port  int    `json:"port,omitempty"`
 }
```

然后执行`make manifests generate`命令生成crd文件

生成的crd文件在`config/crd/bases/`中

##### 实现控制器

> 有crd只能在k8s中定义cr但是k8s并不知道如何处理这些cr，所以我们要实现控制器来处理这些逻辑

我们需要实现的控制器逻辑在`controllers/application_controller.go`中的`Reconcile`函数中

逻辑改完之后就需要上测试了，执行`make install`安装crd到集群，注意他会安装到`~/.kube/config`这个配置文件中的集群

然后执行`make run`运行控制器，他会打印很多日志

- 获取cd，拿到cr中定义的镜像和端口号

```go
 appx := &appxv1.Appx{}
 if err := r.Get(ctx, req.NamespacedName, appx); err != nil {
  return ctrl.Result{}, err
 }
```

- 拿到信息之后需要创建对应的deployment对象和service对象，需要特别注意的是要管理创建的资源，不然删除的不会删除创建的子资源

```go
svc := &apiv1.Service{}
if err := r.Get(ctx, req.NamespacedName, svc); err != nil {
  if client.IgnoreNotFound(err) != nil { 
    return ctrl.Result{}, err// 如果有错误且不是没找到的话就直接返回错误
  }
  // 没找到就创建资源
  if svc.Name == "" {
    l.Info("创建service:", "名字", appx.Name)
    svc = &apiv1.Service{
      ObjectMeta: metav1.ObjectMeta{
        Name:      req.Name,
        Namespace: req.Namespace,
      },
        Spec: apiv1.ServiceSpec{
        Selector: map[string]string{"app": req.Name},
        Ports: []apiv1.ServicePort{{
          Port:       int32(appx.Spec.Port),
          TargetPort: intstr.FromInt(appx.Spec.Port),
        },
        },
      },
    }
    // 关联 appx和deployment
    if err := controllerutil.SetOwnerReference(appx, svc, r.Scheme); err != nil {
       return ctrl.Result{}, err
    }
    if err := r.Create(ctx, svc); err != nil {
       return ctrl.Result{}, err
    }
    l.Info("创建service成功")
  }
}
```

- 如果已经有此资源,那么可能就需要更新资源了

```go
// svc
svc.Spec.Ports = []apiv1.ServicePort{{Port: int32(appx.Spec.Port)}}
l.Info("更新service", "port", appx.Spec.Image)
if err := r.Update(ctx, svc); err != nil {
   return ctrl.Result{}, err
}
l.Info("service更新完成")
```

到此一个简单的crd的控制逻辑就完成了

##### status

> 上面创建的cr当查看的时候并不会显示status

- 在`api/v1/appx_types.go`中找到`AppxStatus`,添加上合适的字段

```go
// AppxStatus defines the observed state of Appx
type AppxStatus struct {
  // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
  // Important: Run "make" to regenerate code after modifying this file
  // 必须要有json tag
  Workload int32  `json:"workload"`
  Svc      string `json:"svc"`
}
```

- 在`controllers/application_controller.go`中更新status字段

```go
appx.Status.Workload = *deploy.Spec.Replicas
appx.Status.Svc = fmt.Sprintf("%d", svc.Spec.Ports[0].Port)
r.Status().Update(ctx, appx)
```

- 上面自会显示在get xx -o yaml当中,当我们想显示在 get xxx -o wide中时需要在`api/v1/appx_types.go`中添加注释，具体参考<https://book.kubebuilder.io/reference/generating-crd.html>

```text
// 注意type要对应上字段！！！
//+kubebuilder:printcolumn:JSONPath=".status.workload",name=Workload,type=integer
//+kubebuilder:printcolumn:JSONPath=".status.svc",name=Svc,type=string
```

- 同样需要重新生成crd并且要安装

##### event事件

> evnet事件，有的时候告诉我们一些重要的信息

- 在`controllers/application_controller.go`中增加字段

```go
// AppxReconciler reconciles a Appx object
type AppxReconciler struct {
  client.Client
  Scheme   *runtime.Scheme
  Recorder record.EventRecorder//增加事件结构体
}

```

- 调用

```go
r.Recorder.Event(appx, apiv1.EventTypeNormal, "找到cr", appx.Name)
```

- 在`main.go`中加上Recorder的初始化逻辑

```go
if err = (&controllers.AppxReconciler{
  Client:   mgr.GetClient(),
  Scheme:   mgr.GetScheme(),
  Recorder: mgr.GetEventRecorderFor("Appx"), //+
}).SetupWithManager(mgr); err != nil {
  setupLog.Error(err, "unable to create controller", "controller", "Appx")
  os.Exit(1)
}
```

```shell
$ kubectl get event
LAST SEEN   TYPE     REASON   OBJECT     MESSAGE
2m55s       Normal   找到cr     appx       
4s          Normal   找到cr     appx/foo   foo  
```

#### 常用命令

```shell
# 初始化
kubebuilder init --repo github.com/naturelr/code-example/operator --domain naturelr.cc --skip-go-version-check

# 创建 api
kubebuilder create api --group appx --version v1 --kind Appx

# 创建webhook
kubebuilder create webhook --group nodes --version v1 --kind Appx --defaulting --programmatic-validation

# 生成文件
make manifests generate

# 安装crd等文件
make install

# 本地调试运行
make run
```

#### 参考资料

<https://book.kubebuilder.io/introduction.html>
<https://lailin.xyz/post/operator-03-kubebuilder-tutorial.html>
