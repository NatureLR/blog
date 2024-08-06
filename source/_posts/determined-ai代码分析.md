---
layout: draft
title: determined-ai代码分析
author: Nature丿灵然
tags:
  - ai
  - go
date: 2024-06-28 17:54:00
---
[determined-ai](https://github.com/determined-ai/determined)是一个ai训练平台

<!--more-->

#### 启动流程

- 入口,使用了cobra作为命令行框架

```go
// master/cmd/determined-master/main.go
func main() {
  logger.SetLogrus(*logger.DefaultConfig())

  if err := rootCmd.Execute(); err != nil {
    log.WithError(err).Fatal("fatal error running Determined master")
  }
}

```

- 命令行处理,全局变量rootCmd由`newRootCmd()`实现,`RUN`下开始真正的执行,runRoot

```go
// master/cmd/determined-master/root.go

var rootCmd = newRootCmd()

func newRootCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "determined-master",
    Run: func(cmd *cobra.Command, args []string) {
      if err := runRoot(); err != nil {
        log.Error(fmt.Sprintf("%+v", err))
        os.Exit(1)
      }
    },
  }
}
```

- 处理日志和初始化配置文件以及必要的路径，做完这些准备之后就开始调用`internal.New()`初始化一个`master`

- 然后执行run

```go
// master/cmd/determined-master/root.go
func runRoot() error {
  logStore := logger.NewLogBuffer(logStoreSize)
  log.AddHook(logStore)

  err := initializeConfig()
  config := config.GetMasterConfig()
  printableConfig, err := config.Printable()
  err = os.MkdirAll(config.Cache.CacheDir, 0o700)
  m := internal.New(logStore, config)
  return m.Run(context.TODO(), nil)
}
```

- RUN这里是整个程序的主体结构

```go
// master/internal/core.go

func (m *Master) Run(ctx context.Context, gRPCLogInitDone chan struct{}) error {
    // 判断是否是新集群以创建密码，略过
 
    // 设置数据库
    m.db, err = db.Setup(&m.config.DB, newClustersRequirePasswords)

    // 设置webbhook
    webhookManager, err := webhooks.New(ctx)
    webhooks.SetDefault(webhookManager)

    l, err := logpattern.New(ctx)
    logpattern.SetDefault(l)


    // 根据配置文件的资源管理
    for _, r := range m.config.ResourceManagers() {
      err = m.checkIfRMDefaultsAreUnbound(r.ResourceManager)
    }

    // 初始化用户服务
    user.InitService(m.db, &m.config.InternalConfig.ExternalSessions)
    userService := user.GetService()

    // 初始化代理
    proxy.InitProxy(processProxyAuthentication)
    portregistry.InitPortRegistry(config.GetMasterConfig().ReservedPorts)

    // 初始化http服务
    m.echo = echo.New()
    
    // 中间有些路由和中间件注册

    // 初始化资源管理
    if m.rm, err = buildRM(m.db, m.echo, m.config.ResourceManagers(),
    &m.config.TaskContainerDefaults,
    &aproto.MasterSetAgentOptions{
      MasterInfo:     m.Info(),
      LoggingOptions: m.config.Logging,
    },
    cert,
    )
    // 设置jobservice
    jobservice.SetDefaultService(m.rm)

    // 命令服务初始化
    cs, err := command.NewService(m.db, m.rm)
    command.SetDefaultService(cs)

    // 一些文档之类的路由注册

    // 最后进入启动环节
    return m.startServers(ctx, cert, gRPCLogInitDone)
}
```

- 启动服务，这里需要注意使用cmux实现了一个监听接口同时可以http和grpc，且将grpc的一些api注册到http中 可以参考<https://golang2.eddycjy.com/posts/ch3/06-grpc-http-support/>

```go
    // master/internal/core.go

    // baseListener是最终使用的不过在此之前先获取systemd的，如果没有用systemd则使用配置文件
    var baseListener net.Listener
    systemdListener, err := m.getSystemdListener()
    switch {
    case err != nil:
    case systemdListener != nil:
        baseListener = systemdListener
        port, pErr := m.findListeningPort(systemdListener)
        m.config.Port = int(port)
    default:
        baseListener, err = net.Listen("tcp", fmt.Sprintf(":%d", m.config.Port))
    }

    // 配置tls证书
    if cert != nil {
        // ...
        baseListener = tls.NewListener(baseListener, &tls.Config{
            Certificates:             []tls.Certificate{*cert},
            MinVersion:               tls.VersionTLS12,
            PreferServerCipherSuites: true,
            ClientCAs:                clientCAs,
            ClientAuth:               clientAuthMode,
        })
    }


    // grpc服务创建，其中 apiServer实现了`proto.DeterminedServer`中所有的接口

    // This must be before grpcutil.RegisterHTTPProxy is called since it may use stuff set up by the
    // gRPC server (logger initialization, maybe more). Found by --race.
    gRPCServer := grpcutil.NewGRPCServer(m.db, &apiServer{m: m},
        m.config.Observability.EnablePrometheus,
        &m.config.InternalConfig.ExternalSessions,
        m.logs,
    )

    // 将grpc的中的接口注册到http中
    err = grpcutil.RegisterHTTPProxy(ctx, m.echo, m.config.Port, cert)

    // 这里使用cumx多路服务器，来实现一个端口就时可以使用http和grpc服务
    // Initialize listeners and multiplexing.
    mux := cmux.New(baseListener)
    // 设置cmux匹配grp的条件
    grpcListener := mux.MatchWithWriters(
        cmux.HTTP2MatchHeaderFieldSendSettings("content-type", "application/grpc"),
    )
    defer closeWithErrCheck("grpc", grpcListener)

    // 设置http 匹配协议
    httpListener := mux.Match(cmux.HTTP1(), cmux.HTTP2())
    defer closeWithErrCheck("http", httpListener)

    // 启动服务并通过携程来传递错误
    // Start all servers and return the first error. This leaks a channel, but the complexity of
    // perfectly handling cleanup and all the error cases doesn't seem worth it for a function that is
    // called exactly once and causes the whole process to exit immediately when it returns.
    errs := make(chan error)
    start := func(name string, run func() error) {
        go func() {
            errs <- errors.Wrap(run(), name+" failed")
        }()
    }
    start("gRPC server", func() error {
        // We should defer srv.Stop() here, but cmux does not unblock accept calls when underlying
        // listeners close and grpc-go depends on cmux unblocking and closing, Stop() blocks
        // indefinitely when using cmux.
        // To be fixed by https://github.com/soheilhy/cmux/pull/69 which makes cmux an io.Closer.
        return gRPCServer.Serve(grpcListener)
    })
    defer gRPCServer.Stop()

    start("HTTP server", func() error {
        m.echo.Listener = httpListener
        m.echo.HidePort = true
        m.echo.Server.ConnContext = connsave.SaveConn
        return m.echo.StartServer(m.echo.Server)
    })
    defer closeWithErrCheck("echo", m.echo)

    start("cmux listener", mux.Serve)

    // 堵住 防止退出，只有接受到错误消息或者ctx.Done()才退出
    select {
    case err := <-errs:
        return err
    case <-ctx.Done():
        return ctx.Err()
    }
```

#### 创建notebook分析流程

> 上面启动流程中说了一些路由是通过grpc来实现的是需要实现，主要是实现`proto.DeterminedServer`这个接口启动`LaunchNotebook()`是创建Experiment的实现逻辑

- 在protobuf中定义了接口，且定义了http的接口

```protobuf
  // Launch a notebook.
  rpc LaunchNotebook(LaunchNotebookRequest) returns (LaunchNotebookResponse) {
    option (google.api.http) = {
      post: "/api/v1/notebooks"
      body: "*"
    };
    option (grpc.gateway.protoc_gen_swagger.options.openapiv2_operation) = {
      tags: "Notebooks"
    };
  }
```

- go`apiServer`中则要实现

```go
// master/internal/api_notebook.go

func (a *apiServer) LaunchNotebook(
  ctx context.Context, req *apiv1.LaunchNotebookRequest,
) (*apiv1.LaunchNotebookResponse, error) {

  launchReq, launchWarnings, err := a.getCommandLaunchParams(ctx, &protoCommandParams{
  TemplateName: req.TemplateName,
  WorkspaceID:  req.WorkspaceId,
  Config:       req.Config,
  Files:        req.Files,
  }, user)

/*
    中间都是一些参数处理launchReq
*/

  // Launch a Notebook.
  // 拉起一个task和job类型都是是notebook的通用命令
  genericCmd, err := command.DefaultCmdService.LaunchGenericCommand(
    model.TaskTypeNotebook,
    model.JobTypeNotebook,
    launchReq)
  if err != nil {
    return nil, err
  }

  // 返回给前端
  return &apiv1.LaunchNotebookResponse{
    Notebook: genericCmd.ToV1Notebook(),
    Config:   protoutils.ToStruct(launchReq.Spec.Config),
    Warnings: pkgCommand.LaunchWarningToProto(launchWarnings),
  }, nil
 
}
```

- LaunchGenericCommand()

```go
// master/internal/command/command_service.go
// LaunchGenericCommand creates NTSC commands and persists them to the database.
func (cs *CommandService) LaunchGenericCommand(
    taskType model.TaskType,
    jobType model.JobType,
    req *CreateGeneric,
) (*Command, error) {

    // 省略掉一些创建id和传值的代码
    cmd := &Command{
        db: cs.db,
        rm: cs.rm,
        GenericCommandSpec: *req.Spec,
        taskID:           taskID,
        taskType:         taskType,
        jobType:          jobType,
        jobID:            jobID,
        contextDirectory: req.ContextDirectory,
        logCtx:           logCtx,
        syslog:           logrus.WithFields(logrus.Fields{"component": "command"}).WithFields(logCtx.Fields()),
    }
    // 开始启动,看下start方法
    if err := cmd.Start(context.TODO()); err != nil {
        return nil, err
    }
    // 启动完成之后将task保存
    // Add it to the registry.
    cs.commands[cmd.taskID] = cmd
    return cmd, nil
}
```

```go
// master/internal/command/command.go

// Start starts the command & its respective allocation. Once started, it persists to the db.
func (c *Command) Start(ctx context.Context) error {

    // 开始分配
    err := task.DefaultService.StartAllocation(c.logCtx,
        sproto.AllocateRequest{
            AllocationID:        c.allocationID,
            TaskID:              c.taskID,
            JobID:               c.jobID,
            JobSubmissionTime:   c.registeredTime,
            IsUserVisible:       true,
            Name:                c.Config.Description,
            SlotsNeeded:         c.Config.Resources.Slots,
            ResourcePool:        c.Config.Resources.ResourcePool,
            FittingRequirements: sproto.FittingRequirements{SingleAgent: true},
            ProxyPorts:          sproto.NewProxyPortConfig(c.GenericCommandSpec.ProxyPorts(), c.taskID),
            IdleTimeout:         idleWatcherConfig,
            Restore:             c.restored,
            ProxyTLS:            c.TaskType == model.TaskTypeNotebook,
        }, c.db, c.rm, c.GenericCommandSpec, c.OnExit)

    // Once the command is persisted to the dbs & allocation starts, register it with the local job service.
    // 注册到job server
    jobservice.DefaultService.RegisterJob(c.jobID, c)

    // 持久化到到数据库
    if err := c.persist(); err != nil {
        c.syslog.WithError(err).Warnf("command persist failure")
    }
    return nil
}
```

- StartAllocation,是一个接口

```go
// master/internal/task/allocation_service.go

// StartAllocation starts an allocation and returns a handle to it.
func (as *allocationService) StartAllocation(
    logCtx detLogger.Context,
    req sproto.AllocateRequest,
    db db.DB,
    rm rm.ResourceManager,
    specifier tasks.TaskSpecifier,
    onExit func(*AllocationExited),
) error {
/*
...
*/
    // 随后进入分配环节
    ref, err := newAllocation(logCtx, req, db, rm, specifier)
    as.allocations[req.AllocationID] = ref
    go func() {
        // 开启一个协程等待的资源结束
        // 返回请求消息
        _ = ref.awaitTermination()
        ref.Cleanup()

        as.mu.Lock()
        delete(as.allocations, req.AllocationID)
        as.mu.Unlock() // don't defer in case onExit calls back into the service

        onExit(ref.exited)

        as.syslog.Info("allocation cleaned up and removed from cache")
    }()
    return nil
}
```

```go
// master/internal/task/allocation.go


// newAllocation returns a new allocation, which tracks allocation state in a fairly generic way.
func newAllocation(
    logCtx detLogger.Context, req sproto.AllocateRequest, db db.DB, rm rm.ResourceManager,
    specifier tasks.TaskSpecifier,
) (*allocation, error) {
    a := &allocation{
        db: db,
        rm: rm,
        wg:     waitgroupx.WithContext(context.Background()),
        syslog: logrus.WithFields(logCtx.Fields()),
        req: req,
        model: model.Allocation{
            AllocationID: req.AllocationID,
            TaskID:       req.TaskID,
            Slots:        req.SlotsNeeded,
            ResourcePool: req.ResourcePool,
            Ports:        map[string]int{},
        },
        specifier: specifier,
        resources: resourcesList{},
        logCtx: req.LogContext,
    }

    // 请求资源
    rmEvents, err := a.requestResources()
    // 根据返回的rm事件运行
    a.wg.Go(func(ctx context.Context) { a.run(ctx, rmEvents) })
    return a, nil
}
```

##### requestResources

```go
// master/internal/task/allocation.go

// requestResources sets up the allocation.
func (a *allocation) requestResources() (*sproto.ResourcesSubscription, error) {
    // 数据库保存
    a.setModelState(model.AllocationStatePending)
    if err := db.AddAllocation(context.TODO(), &a.model); err != nil {
        return nil, errors.Wrap(err, "saving trial allocation")
    }
    // 调用资源管理的Allocate方法，这也是个接口
    sub, err := a.rm.Allocate(a.req)
    return sub, nil
}
```

- Allocate

```go
// master/internal/rm/kubernetesrm/kubernetes_resource_manager.go

// Allocate implements rm.ResourceManager.
func (k *ResourceManager) Allocate(msg sproto.AllocateRequest) (*sproto.ResourcesSubscription, error) {
    // This code exists to handle the case where an experiment does not have
    // an explicit resource pool specified in the config. This should never happen
    // for newly created/forked experiments as the default pool is filled in to the
    // config at creation time. However, old experiments which were created prior to
    // the introduction of resource pools could have no resource pool associated with
    // them and so we need to handle that case gracefully.

    // 通过传入的资源池找到该资源池
    rp, err := k.poolByName(msg.ResourcePool)

    // 订阅事件这个AllocationID事件
    sub := rmevents.Subscribe(msg.AllocationID)
    fmt.Println("分配请求")
    // 分配请求的资源
    rp.AllocateRequest(msg)
    return sub, nil
}
```

- AllocateRequest

```go
// master/internal/rm/kubernetesrm/resource_pool.go

func (k *kubernetesResourcePool) AllocateRequest(msg sproto.AllocateRequest) {
    k.mu.Lock()
    defer k.mu.Unlock()
    k.reschedule = true
    // 添加一个task
    k.addTask(msg)
}
```

- addTask

```go
func (k *kubernetesResourcePool) addTask(msg sproto.AllocateRequest) {
    if len(msg.AllocationID) == 0 {
        msg.AllocationID = model.AllocationID(uuid.New().String())
    }
    k.getOrCreateGroup(msg.JobID)
    if len(msg.Name) == 0 {
        msg.Name = "Unnamed-k8-Task"
    }

    k.syslog.WithField("restore", msg.Restore).Infof(
        "resources are requested by %s (Allocation ID: %s)",
        msg.Name, msg.AllocationID,
    )
    if msg.IsUserVisible {
        if _, ok := k.queuePositions[msg.JobID]; !ok {
            k.queuePositions[msg.JobID] = tasklist.InitializeQueuePosition(
                msg.JobSubmissionTime,
                true,
            )
        }
        k.jobIDToAllocationID[msg.JobID] = msg.AllocationID
        k.allocationIDToJobID[msg.AllocationID] = msg.JobID
        k.allocationIDToRunningPods[msg.AllocationID] = 0
    }
    // 添加到 reqlist中
    k.reqList.AddTask(&msg)
}
```

- 随后rp.Schedule将分配资源并发布消息，跳转至[schedul](#schedule)

##### run

- 回到newAllocation,requestResources执行完成之后开始run

```go
// master/internal/task/allocation.go

    // 请求资源
    rmEvents, err := a.requestResources()
    // 根据返回的rm事件运行
    a.wg.Go(func(ctx context.Context) { a.run(ctx, rmEvents) })
    return a, nil
```

- run

```go
// master/internal/task/allocation.go

func (a *allocation) run(ctx context.Context, sub *sproto.ResourcesSubscription) {
    for {
        // 循环获取sub事件
        event, err := sub.GetWithContext(ctx)
        if err != nil {
            // The following block is only used by tests to simulate a master crash by calling detach().
            // It follows, though, no one should ever call detach() or wg.Cancel() in the code unless you are
            // implementing graceful shutdown.
            return
        }
        // 处理获取的时间
        done := a.HandleRMEvent(event)
        if done {
            return
        }
    }
}
```

- HandleRMEvent

```go
// master/internal/task/allocation.go

// HandleRMEvent handles downstream events from the resource manager.
func (a *allocation) HandleRMEvent(msg sproto.ResourcesEvent) (done bool) {
    switch msg := msg.(type) {
    case *sproto.ResourcesAllocated:
        // 资源创建事件处理
        if err := a.resourcesAllocated(msg); err != nil {
            a.crash(err)
        }
    case *sproto.ResourcesStateChanged:
        a.resourcesStateChanged(msg)
    case *sproto.ReleaseResources:
        a.releaseResources(msg)
    case *sproto.ContainerLog:
        a.sendTaskLog(msg.ToTaskLog())
    case *sproto.ResourcesRestoreError:
        a.restoreResourceFailure(msg)
        return true
    case *sproto.InvalidResourcesRequestError:
        a.crash(msg.Cause)
        return true
    case sproto.ResourcesReleasedEvent:
        return true
    default:
        panic(fmt.Errorf("unexpected RM event"))
    }
    return false
}
```

- resourcesAllocated

```go
// master/internal/task/allocation.go

// resourcesAllocated handles receiving resources from the resource manager. Note: it makes a single
// ask to the parent to build its task spec.. this is mostly a hack to defer lots of computationally
// heavy stuff unless it is necessarily (which also works to spread occurrences of the same work
// out). Eventually, Allocations should just be started with their TaskSpec.
func (a *allocation) resourcesAllocated(msg *sproto.ResourcesAllocated) error {
        for cID, r := range a.resources {
            // 启动函数这个也是个接口
            if err := r.Start(a.logCtx, spec, sproto.ResourcesRuntimeInfo{
                Token:        token,
                AgentRank:    a.resources[cID].Rank,
                IsMultiAgent: len(a.resources) > 1,
            }); err != nil {
                return fmt.Errorf("starting resources (%v): %w", r, err)
            }
        }
```

- Start

```go
// master/internal/rm/kubernetesrm/resource_pool.go

// Start notifies the pods actor that it should launch a pod for the provided task spec.
func (p k8sPodResources) Start(
    logCtx logger.Context, spec tasks.TaskSpec, rri sproto.ResourcesRuntimeInfo,
) error {
    // 调用podSservice的StartTaskPod
    return p.podsService.StartTaskPod(StartTaskPod{
        Req:          p.req,
        AllocationID: p.req.AllocationID,
        Spec:         spec,
        Slots:        p.slots,
        Rank:         rri.AgentRank,
        Namespace:    p.namespace,
        LogContext:   logCtx,
    })
}
```

- StartTaskPod

```go
// master/internal/rm/kubernetesrm/pods.go

func (p *pods) StartTaskPod(msg StartTaskPod) error {
    p.mu.Lock()
    defer p.mu.Unlock()
    // 执行接受启动任务
    return p.receiveStartTaskPod(msg)
}
```

- receiveStartTaskPod

```go
// master/internal/rm/kubernetesrm/pods.go
func (p *pods) receiveStartTaskPod(msg StartTaskPod) error {
    // podHandle启动pod
    err := newPodHandler.start()
    if err != nil {
        return fmt.Errorf("creating pod: %w", err)
    }

    return nil
}
```

- start

```go
func (p *pod) start() error {
    if p.restore {
        if p.container.State == cproto.Running {
            err := p.startPodLogStreamer()
        }
    } else {
        // 创建pod并提交
        if err := p.createPodSpecAndSubmit(); err != nil {
            return fmt.Errorf("creating pod spec: %w", err)
        }
    }
    return nil
}
```

- createPodSpecAndSubmit

```go
// master/internal/rm/kubernetesrm/pod.go
func (p *pod) createPodSpecAndSubmit() error {
    // 创建k8spod的配置
    if err := p.createPodSpec(p.scheduler); err != nil {
        return err
    }

    // 调用资源请求队列的创建资源
    p.resourceRequestQueue.createKubernetesResources(p.pod, p.configMap)
    return nil
}
```

- createKubernetesResources

```go
// master/internal/rm/kubernetesrm/request_queue.go
func (r *requestQueue) createKubernetesResources(
    podSpec *k8sV1.Pod,
    configMapSpec *k8sV1.ConfigMap,
) {
    // 发送创建消息工作ch，资源申请创建完成，
    select {
    case r.workerChan <- msg:
        r.creationInProgress.Insert(ref)
    default:
        queuedRequest := &queuedResourceRequest{createResources: &msg}
        r.queue = append(r.queue, queuedRequest)
        r.pendingResourceCreations[ref] = queuedRequest
    }
}
```

##### buiuldRM

- 上面最终发给了一个workchan，workchan是在`Run`中的`buuldRM`中初始化

```go
// master/internal/core.go

func buildRM(
    db *db.PgDB,
    echo *echo.Echo,
    rmConfigs []*config.ResourceManagerWithPoolsConfig,
    tcd *model.TaskContainerDefaultsConfig,
    opts *aproto.MasterSetAgentOptions,
    cert *tls.Certificate,
) (rm.ResourceManager, error) {
    if len(rmConfigs) <= 1 {
        config := rmConfigs[0]
        switch {
        case config.ResourceManager.AgentRM != nil:
            return agentrm.New(db, echo, config, opts, cert)
        case config.ResourceManager.KubernetesRM != nil:
            return kubernetesrm.New(db, config, tcd, opts, cert)
        case config.ResourceManager.DispatcherRM != nil,
            config.ResourceManager.PbsRM != nil:
            license.RequireLicense("dispatcher resource manager")
            return dispatcherrm.New(db, echo, config, opts, cert)
        default:
            return nil, fmt.Errorf("no expected resource manager config is defined")
        }
    }

    return multirm.New(defaultRMName, rms), nil
}
```

- kubernetesrm.New

```go
// New returns a new ResourceManager, which communicates with
// and submits work to a Kubernetes apiserver.
func New(
    db *db.PgDB,
    rmConfigs *config.ResourceManagerWithPoolsConfig,
    taskContainerDefaults *model.TaskContainerDefaultsConfig,
    opts *aproto.MasterSetAgentOptions,
    cert *tls.Certificate,
) (*ResourceManager, error) {

    poolNamespaces := make(map[string]string)
    for i := range k.poolsConfig {
        if k.poolsConfig[i].KubernetesNamespace == "" {
            k.poolsConfig[i].KubernetesNamespace = k.config.Namespace
        }

        poolNamespaces[k.poolsConfig[i].KubernetesNamespace] = k.poolsConfig[i].PoolName
    }

    // 创建一个新的podserver
    k.podsService = newPodsService()

    for _, poolConfig := range k.poolsConfig {
        poolConfig := poolConfig
        rp := newResourcePool(maxSlotsPerPod, &poolConfig, k.podsService, k.db)
        go func() {
            // 隔一段时间就从处理 rqelist 中的创建任务
            t := time.NewTicker(podSubmissionInterval)
            defer t.Stop()
            for range t.C {
                // 调度任务并发布消息
                rp.Schedule()
            }
        }()
        k.pools[poolConfig.PoolName] = rp
    }
    return k, nil
}
```

###### newPodsService

- newPodsService

```go
// master/internal/rm/kubernetesrm/pods.go

// newPodsService creates a new pod service for launching, querying and interacting with k8s pods.
func newPodsService(
    namespace string,
    namespaceToPoolName map[string]string,
    masterServiceName string,
    masterTLSConfig model.TLSClientConfig,
    loggingConfig model.LoggingConfig,
    scheduler string,
    slotType device.Type,
    slotResourceRequests config.PodSlotResourceRequests,
    resourcePoolConfigs []config.ResourcePoolConfig,
    taskContainerDefaults *model.TaskContainerDefaultsConfig,
    detMasterIP string,
    detMasterPort int32,
    kubeconfigPath string,
    podStatusUpdateCallback podStatusUpdateCallback,
) *pods {
    loggingTLSConfig := masterTLSConfig
    if loggingConfig.ElasticLoggingConfig != nil {
        loggingTLSConfig = loggingConfig.ElasticLoggingConfig.Security.TLS
    }
    p := &pods{
        wg: waitgroupx.WithContext(context.Background()),

        namespace:                    namespace,
        namespaceToPoolName:          namespaceToPoolName,
        masterServiceName:            masterServiceName,
        masterTLSConfig:              masterTLSConfig,
        scheduler:                    scheduler,
        loggingTLSConfig:             loggingTLSConfig,
        loggingConfig:                loggingConfig,
        podNameToPodHandler:          make(map[string]*pod),
        podNameToResourcePool:        make(map[string]string),
        containerIDToPodName:         make(map[string]string),
        containerIDToSchedulingState: make(map[string]sproto.SchedulingState),
        podNameToContainerID:         make(map[string]string),
        podHandlerToMetadata:         make(map[*pod]podMetadata),
        slotType:                     slotType,
        slotResourceRequests:         slotResourceRequests,
        resourcePoolConfigs:          resourcePoolConfigs,
        baseContainerDefaults:        taskContainerDefaults,
        detMasterIP:                  detMasterIP,
        detMasterPort:                detMasterPort,
        currentNodes:                 make(map[string]*k8sV1.Node),
        nodeToSystemResourceRequests: make(map[string]int64),
        podInterfaces:                make(map[string]typedV1.PodInterface),
        configMapInterfaces:          make(map[string]typedV1.ConfigMapInterface),
        syslog:                       logrus.WithField("namespace", namespace),
        podStatusUpdateCallback:      podStatusUpdateCallback,

        kubeconfigPath: kubeconfigPath,
    }
    // 初始化k8s客户端
    if err := p.startClientSet(); err != nil {
    }
    if err := p.getMasterIPAndPort(); err != nil {
    }
    if err := p.getSystemResourceRequests(); err != nil {
    }

    // 启动资源请求队列
    // 这里会创建一些woker 这些work监听workerChan发送过来的请求
    p.startResourceRequestQueue()

    // 启动pod的Informer
    err := p.startPodInformer()
    // 启动node的Informer
    err = p.startNodeInformer()
    switch {
    case err != nil && k8error.IsForbidden(err):
    case err != nil:
        panic(err)
    }
    // k8s 事件监听
    err = p.startEventListeners()
    err = p.startPreemptionListeners()
    return p
}
```

- startResourceRequestQueue

```go
// master/internal/rm/kubernetesrm/pods.go


func (p *pods) startResourceRequestQueue() {
    failures := make(chan resourcesRequestFailure, 16)
    // 启动请求队列
    p.resourceRequestQueue = startRequestQueue(p.podInterfaces, p.configMapInterfaces, failures)
    p.wg.Go(func(ctx context.Context) {
        for {
            select {
            case failure := <-failures:
                // 处理情况
                p.handleResourceRequestFailure(failure)
            case <-ctx.Done():
                return
            }
        }
    })
}
```

```go
// master/internal/rm/kubernetesrm/pods.go

func startRequestQueue(
    podInterfaces map[string]typedV1.PodInterface,
    configMapInterfaces map[string]typedV1.ConfigMapInterface,
    failures chan<- resourcesRequestFailure,
) *requestQueue {
    r := &requestQueue{
        podInterfaces:       podInterfaces,
        configMapInterfaces: configMapInterfaces,
        failures:            failures,

        workerChan: make(chan interface{}),

        queue: make([]*queuedResourceRequest, 0),

        creationInProgress:       make(set.Set[requestID]),
        pendingResourceCreations: make(map[requestID]*queuedResourceRequest),
        blockedResourceDeletions: make(map[requestID]*queuedResourceRequest),

        syslog: logrus.New().WithField("component", "kubernetesrm-queue"),
    }
    // 启动workers
    r.startWorkers()
    return r
}
```

- startWorkers

```go
// master/internal/rm/kubernetesrm/pods.go

func (r *requestQueue) startWorkers() {
    // 根据numKubernetesWorkers来开启worker
    for i := 0; i < numKubernetesWorkers; i++ {
        startRequestProcessingWorker(
            r.podInterfaces,
            r.configMapInterfaces,
            strconv.Itoa(i),
            r.workerChan,
            r.workerReady,
            r.failures,
        )
    }
}
```

- startRequestProcessingWorker

```go
// master/internal/rm/kubernetesrm/request_workers.go
func startRequestProcessingWorker(
    podInterfaces map[string]typedV1.PodInterface,
    configMapInterfaces map[string]typedV1.ConfigMapInterface,
    id string,
    in <-chan interface{},
    ready readyCallbackFunc,
    failures chan<- resourcesRequestFailure,
) *requestProcessingWorker {
    syslog := logrus.New().WithField("component", "kubernetesrm-worker").WithField("id", id)
    r := &requestProcessingWorker{
        podInterfaces:       podInterfaces,
        configMapInterfaces: configMapInterfaces,
        failures:            failures,
        syslog:              syslog,
    }
    // 接受请求并处理
    go r.receive(in, ready)
    return r
}
```

- receive

```go
func (r *requestProcessingWorker) receive(in <-chan interface{}, ready readyCallbackFunc) {
    go ready("")
    for msg := range in {
        switch msg := msg.(type) {
        case createKubernetesResources:
            // 创建资源事件
            r.receiveCreateKubernetesResources(msg)
            go ready(keyForCreate(msg))
        case deleteKubernetesResources:
            r.receiveDeleteKubernetesResources(msg)
            go ready("")
        default:
            errStr := fmt.Sprintf("unexpected message %T", msg)
            r.syslog.Error(errStr)
            panic(errStr)
        }
    }
}

```

- receiveCreateKubernetesResources,到这里完成整个资源的创建

```go
// master/internal/rm/kubernetesrm/request_workers.go

func (r *requestProcessingWorker) receiveCreateKubernetesResources(
    msg createKubernetesResources,
) {
    r.syslog.Debugf("creating configMap with spec %v", msg.configMapSpec)
    // 创建configmap
    configMap, err := r.configMapInterfaces[msg.podSpec.Namespace].Create(
        context.TODO(), msg.configMapSpec, metaV1.CreateOptions{})
    if err != nil {
        r.syslog.WithError(err).Errorf("error creating configMap %s", msg.configMapSpec.Name)
        r.failures <- resourceCreationFailed{podName: msg.podSpec.Name, err: err}
        return
    }
    r.syslog.Infof("created configMap %s", configMap.Name)

    r.syslog.Debugf("launching pod with spec %v", msg.podSpec)
    // 创建pod
    pod, err := r.podInterfaces[msg.podSpec.Namespace].Create(
        context.TODO(), msg.podSpec, metaV1.CreateOptions{},
    )
    if err != nil {
        r.syslog.WithError(err).Errorf("error creating pod %s", msg.podSpec.Name)
        r.failures <- resourceCreationFailed{podName: msg.podSpec.Name, err: err}
        return
    }
    r.syslog.Infof("created pod %s", pod.Name)
}
```

###### Schedule

- 将定期处理reqlist中的任务

```go
// New returns a new ResourceManager, which communicates with
// and submits work to a Kubernetes apiserver.
func New(
    db *db.PgDB,
    rmConfigs *config.ResourceManagerWithPoolsConfig,
    taskContainerDefaults *model.TaskContainerDefaultsConfig,
    opts *aproto.MasterSetAgentOptions,
    cert *tls.Certificate,
) (*ResourceManager, error) {
/*

*/
        go func() {
            t := time.NewTicker(podSubmissionInterval)
            defer t.Stop()
            for range t.C {
                // 这里处理retlist
                rp.Schedule()
            }
        }()
}
```

- Schedule

```go
func (k *kubernetesResourcePool) Schedule() {
    k.mu.Lock()
    defer k.mu.Unlock()

    if k.reschedule {
        // 调度等待的任务
        k.schedulePendingTasks()
    }
    k.reschedule = false
}

```

- schedulePendingTasks

```go
func (k *kubernetesResourcePool) schedulePendingTasks() {
    // 遍历 reqList中的所有任务
    for it := k.reqList.Iterator(); it.Next(); {
        req := it.Value()
        group := k.groups[req.JobID]
        if group == nil {
            k.syslog.Warnf("schedulePendingTasks cannot find group for job %s", req.JobID)
            continue
        }
        if !k.reqList.IsScheduled(req.AllocationID) {
            if maxSlots := group.MaxSlots; maxSlots != nil {
                if k.slotsUsedPerGroup[group]+req.SlotsNeeded > *maxSlots {
                    continue
                }
            }
            // 分配资源
            k.assignResources(req)
        }
    }
}

```

- assignResources

```go
func (k *kubernetesResourcePool) assignResources(
    req *sproto.AllocateRequest,
) {

/*
    分配资源逻辑
*/

    allocations := sproto.ResourceList{}
    for _, rs := range resources {
        allocations[rs.Summary().ResourcesID] = rs
        k.allocationIDToContainerID[req.AllocationID] = rs.containerID
        k.containerIDtoAllocationID[rs.containerID.String()] = req.AllocationID
    }

    assigned := sproto.ResourcesAllocated{
        ID:                req.AllocationID,
        Resources:         allocations,
        JobSubmissionTime: req.JobSubmissionTime,
    }
    // 添加套reqList中已分配列表中
    k.reqList.AddAllocationRaw(req.AllocationID, &assigned)
    // 发布分配完成的消息
    rmevents.Publish(req.AllocationID, assigned.Clone())

}
```
