layout: draft
title: containerd源码-content
author: Nature丿灵然
tags:
  - k8s
  - containerd
categories:
  - 开发
date: 2023-11-03 14:15:00
---

content 主要负责存储下载后的原本的层

<!--more-->

代码版本为v.17.5

##### content

> content主要负责存储下载的layer接口定义在`content/content.go`中

```go
// content/content.go

type ReaderAt interface {
  io.ReaderAt
  io.Closer
  Size() int64
}

type Provider interface {
  ReaderAt(ctx context.Context, desc ocispec.Descriptor) (ReaderAt, error)
}

type Ingester interface {
  Writer(ctx context.Context, opts ...WriterOpt) (Writer, error)
}

type Info struct {
  Digest    digest.Digest
  Size      int64
  CreatedAt time.Time
  UpdatedAt time.Time
  Labels    map[string]string
}

// Status of a content operation
type Status struct {
  Ref       string
  Offset    int64
  Total     int64
  Expected  digest.Digest
  StartedAt time.Time
  UpdatedAt time.Time
}


type WalkFunc func(Info) error
type Manager interface {
  Info(ctx context.Context, dgst digest.Digest) (Info, error)
  Update(ctx context.Context, info Info, fieldpaths ...string) (Info, error)
  Walk(ctx context.Context, fn WalkFunc, filters ...string) error
  Delete(ctx context.Context, dgst digest.Digest) error
}
type IngestManager interface {
  Status(ctx context.Context, ref string) (Status, error)
  ListStatuses(ctx context.Context, filters ...string) ([]Status, error)
  Abort(ctx context.Context, ref string) error
}


type Writer interface {
  io.WriteCloser
  Digest() digest.Digest
  Commit(ctx context.Context, size int64, expected digest.Digest, opts ...Opt) error
  Status() (Status, error)
  Truncate(size int64) error
}

type Store interface {
  Manager
  Provider
  IngestManager
  Ingester
}
```

###### content grpc类型

- grpc类型的content注册在这里,使用统一的注册，申明名字类型以及依赖
- 然后从initcontent中获取所有service的插件,然后拿到一个`ContentService`实例
- 使用这个实例调用`contentserver.New()`,`contentserver.New()`实现了grpc相关方法

```go
// services/content/service.go
func init() {
  plugin.Register(&plugin.Registration{
    Type: plugin.GRPCPlugin,
    ID:   "content",
    Requires: []plugin.Type{
      plugin.ServicePlugin,
    },
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      plugins, err := ic.GetByType(plugin.ServicePlugin)
      if err != nil {
        return nil, err
      }

      p, ok := plugins[services.ContentService]
      if !ok {
        return nil, errors.New("content store service not found")
      }
      cs, err := p.Instance()
      if err != nil {
        return nil, err
      }
      return contentserver.New(cs.(content.Store)), nil
    },
  })
}
```

- `service`就是抽象了`content.Store`

- `New()`设置了上层

```go
// services/content/contentserver/contentserver.go

type service struct {
  store content.Store
}

// New returns the content GRPC server
func New(cs content.Store) api.ContentServer {
  return &service{store: cs}
}

func (s *service) Register(server *grpc.Server) error {
  api.RegisterContentServer(server, s)
  return nil
}
```

- 由于接口很多就不一样介绍了，这里只介绍一个简单的接口
- 可以看到grpc请求来的参数传到`store.Status()`然后再将返回的组装成grpc结果并返回，其他api也是类似这种

```go
// services/content/contentserver/contentserver.go

func (s *service) Status(ctx context.Context, req *api.StatusRequest) (*api.StatusResponse, error) {
  status, err := s.store.Status(ctx, req.Ref)
  if err != nil {
    return nil, errdefs.ToGRPCf(err, "could not get status for ref %q", req.Ref)
  }

  var resp api.StatusResponse
  resp.Status = &api.Status{
    StartedAt: status.StartedAt,
    UpdatedAt: status.UpdatedAt,
    Ref:       status.Ref,
    Offset:    status.Offset,
    Total:     status.Total,
    Expected:  status.Expected,
  }

  return &resp, nil
}
```

###### content service类型

- 这里他依赖`plugin.MetadataPlugin`这个类型,然后将获取的meteada传入`meatadata.ContentStore()`

```go
// services/content/store.go

func init() {
  plugin.Register(&plugin.Registration{
    Type: plugin.ServicePlugin,
    ID:   services.ContentService,
    Requires: []plugin.Type{
      plugin.MetadataPlugin,
    },
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      m, err := ic.Get(plugin.MetadataPlugin)
      if err != nil {
        return nil, err
      }

      // 这里注册 content的svc
      s, err := newContentStore(m.(*metadata.DB).ContentStore(), ic.Events)
      return s, err
    },
  })
}


func newContentStore(cs content.Store, publisher events.Publisher) (content.Store, error) {
  return &store{
    Store:     cs,
    publisher: publisher,
  }, nil
}
```

- 可以看到前面调用的`ContentStore()`返回的就是初始化,而meteadata创建的注册在`services/server/server.go`前面介绍启动过程介绍过

```go
// metadata/db.go


// NewDB creates a new metadata database using the provided
// bolt database, content store, and snapshotters.
func NewDB(db *bolt.DB, cs content.Store, ss map[string]snapshots.Snapshotter, opts ...DBOpt) *DB {
  m := &DB{
    db:      db,
    ss:      make(map[string]*snapshotter, len(ss)),
    dirtySS: map[string]struct{}{},
    dbopts: dbOptions{
      shared: true,
    },
  }

  for _, opt := range opts {
    opt(&m.dbopts)
  }

  // Initialize data stores
  m.cs = newContentStore(m, m.dbopts.shared, cs)
  for name, sn := range ss {
    m.ss[name] = newSnapshotter(m, name, sn)
  }

  return m
}

// ContentStore returns a namespaced content store
// proxied to a content store.
func (m *DB) ContentStore() content.Store {
  if m.cs == nil {
    return nil
  }
  return m.cs
}
```

- 同样实现了content的很多方法,下面得了例子可以看到这里先读取数据库，然后在调用`store.Status()`

```go
// metadata/content.go

func (cs *contentStore) Status(ctx context.Context, ref string) (content.Status, error) {
  ns, err := namespaces.NamespaceRequired(ctx)

  var bref string
  if err := view(ctx, cs.db, func(tx *bolt.Tx) error {
    bref = getRef(tx, ns, ref)
    if bref == "" {
      return errors.Wrapf(errdefs.ErrNotFound, "reference %v", ref)
    }

    return nil
  }); err != nil {
    return content.Status{}, err
  }

  st, err := cs.Store.Status(ctx, bref)
  if err != nil {
    return content.Status{}, err
  }
  st.Ref = ref
  return st, nil
}
```

###### content类型

> content有2中实现,一种本地(local),一种prox(远程)

- local:就是本地实现,目前可以理解为真正实现
- proxy:则是调用远程的实现，因为content有插件

- 注册则在`loadPlugin()`中首先会将本地的注册，随后读取配置文件中的`proxy_plugin`配置在注册proxy类型的，
需要注意的是插件在整理之后会返回第一个可能导致你注册的content需要再配置文件中`disabled_plugins`参数关闭local强制使用proxy类型的

```go
// services/server/server.go

  plugin.Register(&plugin.Registration{
    Type: plugin.ContentPlugin,
    ID:   "content",
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      ic.Meta.Exports["root"] = ic.Root
      return local.NewStore(ic.Root)
    },
  })

  clients := &proxyClients{}
  for name, pp := range config.ProxyPlugins {
    var (
      t plugin.Type
      f func(*grpc.ClientConn) interface{}

      address = pp.Address
    )

    // nsap逻辑

    case string(plugin.ContentPlugin), "content":
      t = plugin.ContentPlugin
      f = func(conn *grpc.ClientConn) interface{} {
        return csproxy.NewContentStore(csapi.NewContentClient(conn))
      }
    default:
      log.G(ctx).WithField("type", pp.Type).Warn("unknown proxy plugin type")
    }

    plugin.Register(&plugin.Registration{
      Type: t,
      ID:   name,
      InitFn: func(ic *plugin.InitContext) (interface{}, error) {
        ic.Meta.Exports["address"] = address
        conn, err := clients.getClient(address)
        if err != nil {
          return nil, err
        }
        return f(conn), nil
      },
    })
```

- 接口实现本质就是读取存储的文件一些信息,然后返回

```go
// content/local/store.go

// status works like stat above except uses the path to the ingest.
func (s *store) status(ingestPath string) (content.Status, error) {
  dp := filepath.Join(ingestPath, "data")
  fi, err := os.Stat(dp)

  ref, err := readFileString(filepath.Join(ingestPath, "ref"))

  startedAt, err := readFileTimestamp(filepath.Join(ingestPath, "startedat"))
 
  updatedAt, err := readFileTimestamp(filepath.Join(ingestPath, "updatedat"))
 
  // because we don't write updatedat on every write, the mod time may
  // actually be more up to date.
  if fi.ModTime().After(updatedAt) {
    updatedAt = fi.ModTime()
  }

  return content.Status{
    Ref:       ref,
    Offset:    fi.Size(),
    Total:     s.total(ingestPath),
    UpdatedAt: updatedAt,
    StartedAt: startedAt,
  }, nil
}
```
