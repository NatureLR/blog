layout: draft
title: k8s-apiserver中loopback证书源码阅读
author: Nature丿灵然
tags:
  - k8s
categories:
  - 开发
date: 2023-07-10 02:06:00
---
apiserver因为loopback证书过期导致一些功能无法使用,

<!--more-->

apiserver启动的时候会生成一个loopback证书，该证书默认只有一年有效期,k8s官方解释说应该每年升级或者重启一次,[issues](https://github.com/kubernetes/kubernetes/issues/86552)

但在实际场景当中不能没事就重启或升级apiserver

#### 生成证书和回环客户端

- 入口

./cmd/kube-apiserver/main.go

- 然后跳转

```shell
./cmd/kube-apiserver/app/server.go
```

```go
// NewAPIServerCommand creates a *cobra.Command object with default parameters
func NewAPIServerCommand() *cobra.Command {
    s := options.NewServerRunOptions()
...
    return Run(completedOptions, genericapiserver.SetupSignalHandler())
}
```

```go
// Run runs the specified APIServer.  This should never exit.
func Run(completeOptions completedServerRunOptions, xstopCh <-chan struct{}) error {
    // To help debugging, immediately log version
    klog.Infof("Version: %+v", version.Get())

    klog.InfoS("Golang settings", "GOGC", os.Getenv("GOGC"), "GOMAXPROCS", os.Getenv("GOMAXPROCS"), "GOTRACEBACK", os.Getenv("GOTRACEBACK"))

    server, err := CreateServerChain(completeOptions, stopCh)
    if err != nil {
        return err
    }

    prepared, err := server.PrepareRun()
    if err != nil {
        return err
    }

    return prepared.Run(stopCh)
}
```

```go
// CreateServerChain creates the apiservers connected via delegation.
func CreateServerChain(completedOptions completedServerRunOptions, stopCh <-chan struct{}) (*aggregatorapiserver.APIAggregator, error) {
    // 回环证书在此创建
    kubeAPIServerConfig, serviceResolver, pluginInitializer, err := CreateKubeAPIServerConfig(completedOptions)
...
```

```go
func CreateKubeAPIServerConfig(s completedServerRunOptions) (
    *controlplane.Config,
    aggregatorapiserver.ServiceResolver,
    []admission.PluginInitializer,
    error,
) {
...
    genericConfig, versionedInformers, serviceResolver, pluginInitializers, admissionPostStartHook, storageFactory, err := buildGenericConfig(s.ServerRunOptions, proxyTransport)
    if err != nil {
        return nil, nil, nil, err
    }
...
}
...
```

```go
// BuildGenericConfig takes the master server options and produces the genericapiserver.Config associated with it
func buildGenericConfig(
    s *options.ServerRunOptions,
    proxyTransport *http.Transport,
) (
    genericConfig *genericapiserver.Config,
    versionedInformers clientgoinformers.SharedInformerFactory,
    serviceResolver aggregatorapiserver.ServiceResolver,
    pluginInitializers []admission.PluginInitializer,
    admissionPostStartHook genericapiserver.PostStartHookFunc,
    storageFactory *serverstorage.DefaultStorageFactory,
    lastErr error,
) {
    genericConfig = genericapiserver.NewConfig(legacyscheme.Codecs)
    genericConfig.MergedResourceConfig = controlplane.DefaultAPIResourceConfigSource()

    if lastErr = s.GenericServerRunOptions.ApplyTo(genericConfig); lastErr != nil {
        return
    }

    // 将生成的回环客户端赋值给genericConfig
    if lastErr = s.SecureServing.ApplyTo(&genericConfig.SecureServing, &genericConfig.LoopbackClientConfig); lastErr != nil {
        return
    }
...
}
...
```

```shell
./k8s.io/apiserver/pkg/server/options/serving_with_loopback.go
```

```go
func (s *SecureServingOptionsWithLoopback) ApplyTo(secureServingInfo **server.SecureServingInfo, loopbackClientConfig **rest.Config) error {
    if s == nil || s.SecureServingOptions == nil || secureServingInfo == nil {
        return nil
    }
...

    // 将正式放到SNICerts,给http服务使用
    (*secureServingInfo).SNICerts = append([]dynamiccertificates.SNICertKeyContentProvider{certProvider}, (*secureServingInfo).SNICerts...)
    secureLoopbackClientConfig, err := (*secureServingInfo).NewLoopbackClientConfig(uuid.New().String(), certPem) // 使用生成的证书创建一个reset客户端
    switch {
    // if we failed and there's no fallback loopback client config, we need to fail
    case err != nil && *loopbackClientConfig == nil:
        (*secureServingInfo).SNICerts = (*secureServingInfo).SNICerts[1:]
        return err

    // if we failed, but we already have a fallback loopback client config (usually insecure), allow it
    case err != nil && *loopbackClientConfig != nil:

    default:
        *loopbackClientConfig = secureLoopbackClientConfig // 传回结构体
    }
```

```shell
./k8s.io/client-go/util/cert/cert.go
```

```go
// GenerateSelfSignedCertKey creates a self-signed certificate and key for the given host.
// Host may be an IP or a DNS name
// You may also specify additional subject alt names (either ip or dns names) for the certificate.
func GenerateSelfSignedCertKey(host string, alternateIPs []net.IP, alternateDNS []string) ([]byte, []byte, error) {
    return GenerateSelfSignedCertKeyWithFixtures(host, alternateIPs, alternateDNS, "")
}


func GenerateSelfSignedCertKeyWithFixtures(host string, alternateIPs []net.IP, alternateDNS []string, fixtureDirectory string) ([]byte, []byte, error) {
    validFrom := time.Now().Add(-time.Hour) // valid an hour earlier to avoid flakes due to clock skew
    maxAge := time.Hour * 24 * 365         // one year self-signed certs # 这里就是控制证书过期的时间

    baseName := fmt.Sprintf("%s_%s_%s", host, strings.Join(ipsToStrings(alternateIPs), "-"), strings.Join(alternateDNS, "-"))
    certFixturePath := filepath.Join(fixtureDirectory, baseName+".crt")
    keyFixturePath := filepath.Join(fixtureDirectory, baseName+".key")
    if len(fixtureDirectory) > 0 {
        cert, err := ioutil.ReadFile(certFixturePath)
        if err == nil {
            key, err := ioutil.ReadFile(keyFixturePath)
            if err == nil {
                return cert, key, nil
            }
            return nil, nil, fmt.Errorf("cert %s can be read, but key %s cannot: %v", certFixturePath, keyFixturePath, err)
        }
        maxAge = 100 * time.Hour * 24 * 365 // 100 years fixtures
    }
...
    caTemplate := x509.Certificate{
        SerialNumber: big.NewInt(1),
        Subject: pkix.Name{
            CommonName: fmt.Sprintf("%s-ca@%d", host, time.Now().Unix()),
        },
        NotBefore: validFrom,
        NotAfter:  validFrom.Add(maxAge),

        KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
        BasicConstraintsValid: true,
        IsCA:                  true,
    }
...

```

- 到此位置生成的证书和回环客户端完成，其中回环客户端复制给了`controlplane.Config.LoopbackClientConfig`,证书给了`controlplane.Config.SNICerts`

#### 使用证书

- 使用证书的地方为

```shell
staging/src/k8s.io/apiserver/pkg/server/genericapiserver.go
```

```go
func (s preparedGenericAPIServer) Run(stopCh <-chan struct{}) error {
...
    stoppedCh, listenerStoppedCh, err := s.NonBlockingRun(stopHttpServerCh, shutdownTimeout)
    if err != nil {
        return err
    }
...
}


func (s preparedGenericAPIServer) NonBlockingRun(stopCh <-chan struct{}, shutdownTimeout time.Duration) (<-chan struct{}, <-chan struct{}, error) {
...
    if s.SecureServingInfo != nil && s.Handler != nil {
        var err error
        stoppedCh, listenerStoppedCh, err = s.SecureServingInfo.Serve(s.Handler, shutdownTimeout, internalStopCh)
        if err != nil {
            close(internalStopCh)
            close(auditStopCh)
            return nil, nil, err
        }
    }
...
    s.RunPostStartHooks(stopCh) //启动之前注册的hook
    if _, err := systemd.SdNotify(true, "READY=1\n"); err != nil {
        klog.Errorf("Unable to send systemd daemon successful start message: %v\n", err)
    }
}
```

- 继续跳转到`server()`

```go
func (s *SecureServingInfo) Serve(handler http.Handler, shutdownTimeout time.Duration, stopCh <-chan struct{}) (<-chan struct{}, <-chan struct{}, error) {
    tlsConfig, err := s.tlsConfig(stopCh) // 这里配置http的证书
    if err != nil {
        return nil, nil, err
    }
}

func (s *SecureServingInfo) tlsConfig(stopCh <-chan struct{}) (*tls.Config, error) {
    // 创建了基本的tls.config
    tlsConfig := &tls.Config{
        // Can't use SSLv3 because of POODLE and BEAST
        // Can't use TLSv1.0 because of POODLE and BEAST using CBC cipher
        // Can't use TLSv1.1 because of RC4 cipher usage
        MinVersion: tls.VersionTLS12,
        // enable HTTP2 for go's 1.7 HTTP Server
        NextProtos: []string{"h2", "http/1.1"},
    }
... 
    // 创建了一个动态证书控制器
    if s.ClientCA != nil || s.Cert != nil || len(s.SNICerts) > 0 {
        dynamicCertificateController := dynamiccertificates.NewDynamicServingCertificateController(
            tlsConfig,
            s.ClientCA,
            s.Cert,
            s.SNICerts,
            nil, // TODO see how to plumb an event recorder down in here. For now this results in simply klog messages.
        )
...
        for _, sniCert := range s.SNICerts {
            sniCert.AddListener(dynamicCertificateController)
            if controller, ok := sniCert.(dynamiccertificates.ControllerRunner); ok {
                    // runonce to try to prime data.  If this fails, it's ok because we fail closed.
                    // Files are required to be populated already, so this is for convenience.
                if err := controller.RunOnce(ctx); err != nil { //
                    klog.Warningf("Initial population of SNI serving certificate failed: %v", err)
                }
            go controller.Run(ctx, 1) // 同步证书
        
            }
        }
...

tlsConfig.GetConfigForClient = dynamicCertificateController.GetConfigForClient // 设置了这个参数之后，接受到https请求之后会调用这个
...
}

```

#### 使用客户端

- 回环证书在很多地方回到`CreateServerChain`这里

```go
// 这里已经有调用了
    apiExtensionsConfig, err := createAPIExtensionsConfig(*kubeAPIServerConfig.GenericConfig, kubeAPIServerConfig.ExtraConfig.VersionedInformers, pluginInitializer, completedOptions.ServerRunOptions, completedOptions.MasterCount,
        serviceResolver, webhook.NewDefaultAuthenticationInfoResolverWrapper(kubeAPIServerConfig.ExtraConfig.ProxyTransport, kubeAPIServerConfig.GenericConfig.EgressSelector, kubeAPIServerConfig.GenericConfig.LoopbackClientConfig, kubeAPIServerConfig.GenericConfig.TracerProvider)) // TODO
    if err != nil {
        return nil, err
    }

...
```

- 最多为hook使用，在http服务启动之后前面注册的hook就开始执行其中传入了回环证书

```go
// RunPostStartHooks runs the PostStartHooks for the server
func (s *GenericAPIServer) RunPostStartHooks(stopCh <-chan struct{}) {
    s.postStartHookLock.Lock()
    defer s.postStartHookLock.Unlock()
    s.postStartHooksCalled = true

    context := PostStartHookContext{
        LoopbackClientConfig: s.LoopbackClientConfig, //使用了回环
        StopCh:               stopCh,
    }

    for hookName, hookEntry := range s.postStartHooks { // 将前面注册的hook全部启动
        go runPostStartHook(hookName, hookEntry, context)
    }
}
```

#### 问题

- 一个服务多个证书，其实就是通过`tsl.Config.GetConfigForClient`来实现

- 为什么要loopback,从代码来看apiserve本身也需要请求一个资源，比如校验参数的正确性,如果不请求自己就需要从新写一套从etcd获取的逻辑，这样就逻辑重复了

- 除了一些零散的调用主要是通过AddPostStartHookOrDie注册的hook在启动后调用

#### 参考资料

<https://mp.weixin.qq.com/mp/appmsgalbum?__biz=Mzg2NTU3NjgxOA==&action=getalbum&album_id=2958341226519298049&scene=173&from_msgid=2247488299&from_itemidx=1&count=3&nolastread=1#wechat_redirect>

<https://github.com/kubernetes/kubernetes/issues/86552>
