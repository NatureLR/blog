layout: draft
title: contaInerd源码-diff
author: Nature丿灵然
tags:
  - k8s
  - containerd
date: 2023-11-03 18:13:00
---

diff主要负责解压缩过程

<!--more-->

代码版本为v.17.5

#### 接口定义

- 接口比较少只有2个

```go
// diff/diff.go
type Applier interface {
  // Apply applies the content referred to by the given descriptor to
  // the provided mount. The method of applying is based on the
  // implementation and content descriptor. For example, in the common
  // case the descriptor is a file system difference in tar format,
  // that tar would be applied on top of the mounts.
  Apply(ctx context.Context, desc ocispec.Descriptor, mount []mount.Mount, opts ...ApplyOpt) (ocispec.Descriptor, error)
}

type Comparer interface {
  // Compare computes the difference between two mounts and returns a
  // descriptor for the computed diff. The options can provide
  // a ref which can be used to track the content creation of the diff.
  // The media type which is used to determine the format of the created
  // content can also be provided as an option.
  Compare(ctx context.Context, lower, upper []mount.Mount, opts ...Opt) (ocispec.Descriptor, error)
}
```

#### diff grpc类型

- 常规的注册,从`serivce`类型中拿到`diffservice`一个实例

```go
// services/diff/service.go

func init() {
  plugin.Register(&plugin.Registration{
    Type: plugin.GRPCPlugin,
    ID:   "diff",
    Requires: []plugin.Type{
      plugin.ServicePlugin,
    },
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      plugins, err := ic.GetByType(plugin.ServicePlugin)

      p, ok := plugins[services.DiffService]
 
      i, err := p.Instance()

      return &service{local: i.(diffapi.DiffClient)}, nil
    },
  })
}
```

- 同样实现了接口直接调用了service的apply

```go
func (s *service) Apply(ctx context.Context, er *diffapi.ApplyRequest) (*diffapi.ApplyResponse, error) {
  return s.local.Apply(ctx, er)
}
```

#### diff service类型

- 这里注册的时候添加了一个config,获取更下面的`DiffPlugin`一个实例

```go
// services/diff/local.go
func init() {
  plugin.Register(&plugin.Registration{
    Type: plugin.ServicePlugin,
    ID:   services.DiffService,
    Requires: []plugin.Type{
      plugin.DiffPlugin,
    },
    Config: defaultDifferConfig,
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      differs, err := ic.GetByType(plugin.DiffPlugin)
  
      orderedNames := ic.Config.(*config).Order
      ordered := make([]differ, len(orderedNames))
      for i, n := range orderedNames {
        differp, ok := differs[n]
    
        d, err := differp.Instance()
   
        ordered[i], ok = d.(differ)

      }
      return &local{
        differs: ordered,
      }, nil
    },
  })
}
```

- 组合好opt然后传入到Apply

```go
// services/diff/local.go
func (l *local) Apply(ctx context.Context, er *diffapi.ApplyRequest, _ ...grpc.CallOption) (*diffapi.ApplyResponse, error) {
  var (
    ocidesc ocispec.Descriptor
    err     error
    desc    = toDescriptor(er.Diff)
    mounts  = toMounts(er.Mounts)
  )

  var opts []diff.ApplyOpt
  if er.Payloads != nil {
    opts = append(opts, diff.WithPayloads(er.Payloads))
  }

  for _, differ := range l.differs {
    ocidesc, err = differ.Apply(ctx, desc, mounts, opts...)
    if !errdefs.IsNotImplemented(err) {
      break
    }
  }
  return &diffapi.ApplyResponse{
    Applied: fromDescriptor(ocidesc),
  }, nil

}
```

#### diff类型

- 这里注册一个`DiffPlugin`,这里不一样的是从插件里拿的是`MetadataPlugin`,然后获取metadata的ContentStore()并传值给`Comparer`和`Applier`

```go
// diff/walking/plugin/plugin.go

func init() {
  plugin.Register(&plugin.Registration{
    Type: plugin.DiffPlugin,
    ID:   "walking",
    Requires: []plugin.Type{
      plugin.MetadataPlugin,
    },
    InitFn: func(ic *plugin.InitContext) (interface{}, error) {
      md, err := ic.Get(plugin.MetadataPlugin)

      ic.Meta.Platforms = append(ic.Meta.Platforms, platforms.DefaultSpec())
      cs := md.(*metadata.DB).ContentStore()

      return diffPlugin{
        Comparer: walking.NewWalkingDiff(cs),
        Applier:  apply.NewFileSystemApplier(cs),
      }, nil
    },
  })
}
```

- fsApplier只有个store

```go
// diff/apply/apply.go

// NewFileSystemApplier returns an applier which simply mounts
// and applies diff onto the mounted filesystem.
func NewFileSystemApplier(cs content.Provider) diff.Applier {
  return &fsApplier{
    store: cs,
  }
}
```

- 这里开始从`content`里读取blob
- 然后申明一个`processor`,`processor`主要和解压有关如gz等
- 从配置里获取一个processor并赋值
- 随后processor赋值到`readCounter`中
- ra传递给`apply()`进行下一步处理

```go
// diff/apply/apply.go

func (s *fsApplier) Apply(ctx context.Context, desc ocispec.Descriptor, mounts []mount.Mount, opts ...diff.ApplyOpt) (d ocispec.Descriptor, err error) {
  // 从content读取
  ra, err := s.store.ReaderAt(ctx, desc)
  defer ra.Close()

  var processors []diff.StreamProcessor
  processor := diff.NewProcessorChain(desc.MediaType, content.NewReader(ra))
  processors = append(processors, processor)
  for {
    if processor, err = diff.GetProcessor(ctx, processor, config.ProcessorPayloads); err != nil {
      return emptyDesc, errors.Wrapf(err, "failed to get stream processor for %s", desc.MediaType)
    }
    processors = append(processors, processor)
    if processor.MediaType() == ocispec.MediaTypeImageLayer {
      break
    }
  }
  defer processor.Close()

  digester := digest.Canonical.Digester()
  rc := &readCounter{
    r: io.TeeReader(processor, digester.Hash()),
  }

  //真正开始apply
  if err := apply(ctx, mounts, rc); err != nil {
    return emptyDesc, err
  }

  // Read any trailing data
  if _, err := io.Copy(io.Discard, rc); err != nil {
    return emptyDesc, err
  }

  for _, p := range processors {
    if ep, ok := p.(interface{ Err() error }); ok {
      if err := ep.Err(); err != nil {
        return emptyDesc, err
      }
    }
  }
  return ocispec.Descriptor{
    MediaType: ocispec.MediaTypeImageLayer,
    Size:      rc.c,
    Digest:    digester.Digest(),
  }, nil
}
```

- `apply()`首先通过mouonts的长度和类型判断是否是临时挂载和使用哪个驱动
- 一般在解压是需要`mount.WithTempMount()`挂载
- 需要注意的是apply有各个平台的实现

```go
// diff/apply/apply_linux.go

func apply(ctx context.Context, mounts []mount.Mount, r io.Reader) error {
  switch {
  case len(mounts) == 1 && mounts[0].Type == "overlay":
    // OverlayConvertWhiteout (mknod c 0 0) doesn't work in userns.
    // https://github.com/containerd/containerd/issues/3762
    if userns.RunningInUserNS() {
      break
    }
    path, parents, err := getOverlayPath(mounts[0].Options)
    if err != nil {
      if errdefs.IsInvalidArgument(err) {
        break
      }
      return err
    }
    opts := []archive.ApplyOpt{
      archive.WithConvertWhiteout(archive.OverlayConvertWhiteout),
    }
    if len(parents) > 0 {
      opts = append(opts, archive.WithParents(parents))
    }
    _, err = archive.Apply(ctx, path, r, opts...)
    return err
  case len(mounts) == 1 && mounts[0].Type == "aufs":
    path, parents, err := getAufsPath(mounts[0].Options)
    if err != nil {
      if errdefs.IsInvalidArgument(err) {
        break
      }
      return err
    }
    opts := []archive.ApplyOpt{
      archive.WithConvertWhiteout(archive.AufsConvertWhiteout),
    }
    if len(parents) > 0 {
      opts = append(opts, archive.WithParents(parents))
    }
    _, err = archive.Apply(ctx, path, r, opts...)
    return err
  }
  return mount.WithTempMount(ctx, mounts, func(root string) error {
    _, err := archive.Apply(ctx, root, r)
    return err
  })
}
```

- 这里开始执行bind挂载

```go
// mount/temp.go

// WithTempMount mounts the provided mounts to a temp dir, and pass the temp dir to f.
// The mounts are valid during the call to the f.
// Finally we will unmount and remove the temp dir regardless of the result of f.
func WithTempMount(ctx context.Context, mounts []Mount, f func(root string) error) (err error) {
  root, uerr := ioutil.TempDir(tempMountLocation, "containerd-mount")
  if uerr != nil {
    return errors.Wrapf(uerr, "failed to create temp dir")
  }
  // We use Remove here instead of RemoveAll.
  // The RemoveAll will delete the temp dir and all children it contains.
  // When the Unmount fails, RemoveAll will incorrectly delete data from
  // the mounted dir. However, if we use Remove, even though we won't
  // successfully delete the temp dir and it may leak, we won't loss data
  // from the mounted dir.
  // For details, please refer to #1868 #1785.
  defer func() {
    if uerr = os.Remove(root); uerr != nil {
      log.G(ctx).WithError(uerr).WithField("dir", root).Errorf("failed to remove mount temp dir")
    }
  }()

  // We should do defer first, if not we will not do Unmount when only a part of Mounts are failed.
  defer func() {
    if uerr = UnmountAll(root, 0); uerr != nil {
      uerr = errors.Wrapf(uerr, "failed to unmount %s", root)
      if err == nil {
        err = uerr
      } else {
        err = errors.Wrap(err, uerr.Error())
      }
    }
  }()

  // [{bind /root/snapshotter/snapshots/1/fs [rw rbind]}] /var/lib/containerd/tmpmounts/containerd-mount4278343774
  if uerr = All(mounts, root); uerr != nil {
    return errors.Wrapf(uerr, "failed to mount %s", root)
  }
  return errors.Wrapf(f(root), "mount callback failed on %s", root)
}
```

- `All()`遍历所有mouts并执行挂载

```go
// mount/mount.go

// All mounts all the provided mounts to the provided target
func All(mounts []Mount, target string) error {
  for _, m := range mounts {
    if err := m.Mount(target); err != nil {
      return err
    }
  }
  return nil
}
```

```go
// mount/mount_linux.go
func (m *Mount) Mount(target string) (err error) {
  for _, helperBinary := range allowedHelperBinaries {
    // helperBinary = "mount.fuse", typePrefix = "fuse."
    typePrefix := strings.TrimPrefix(helperBinary, "mount.") + "."
    if strings.HasPrefix(m.Type, typePrefix) {
      return m.mountWithHelper(helperBinary, typePrefix, target)
    }
  }
  var (
    chdir   string
    options = m.Options
  )

  // avoid hitting one page limit of mount argument buffer
  //
  // NOTE: 512 is a buffer during pagesize check.
  if m.Type == "overlay" && optionsSize(options) >= pagesize-512 {
    chdir, options = compactLowerdirOption(options)
  }

  flags, data, losetup := parseMountOptions(options)
  if len(data) > pagesize {
    return errors.Errorf("mount options is too long")
  }

  // propagation types.
  const ptypes = unix.MS_SHARED | unix.MS_PRIVATE | unix.MS_SLAVE | unix.MS_UNBINDABLE

  // Ensure propagation type change flags aren't included in other calls.
  oflags := flags &^ ptypes

  // In the case of remounting with changed data (data != ""), need to call mount (moby/moby#34077).
  if flags&unix.MS_REMOUNT == 0 || data != "" {
    // Initial call applying all non-propagation flags for mount
    // or remount with changed data
    source := m.Source
    if losetup {
      loFile, err := setupLoop(m.Source, LoopParams{
        Readonly:  oflags&unix.MS_RDONLY == unix.MS_RDONLY,
        Autoclear: true})
      if err != nil {
        return err
      }
      defer loFile.Close()

      // Mount the loop device instead
      source = loFile.Name()
    }
    // 执行mount系统调用
    if err := mountAt(chdir, source, target, m.Type, uintptr(oflags), data); err != nil {
      return err
    }
  }
```

- 看完bind挂载在看下普通的Apply()
- 根据applyFunc参数来确定使用哪个apply，没有则默认使用`applyFunc`

```go
// archive/tar.go

// Apply applies a tar stream of an OCI style diff tar.
// See https://github.com/opencontainers/image-spec/blob/master/layer.md#applying-changesets
func Apply(ctx context.Context, root string, r io.Reader, opts ...ApplyOpt) (int64, error) {
  root = filepath.Clean(root)

  var options ApplyOptions
  for _, opt := range opts {
    if err := opt(&options); err != nil {
      return 0, errors.Wrap(err, "failed to apply option")
    }
  }
  if options.Filter == nil {
    options.Filter = all
  }
  if options.applyFunc == nil {
    options.applyFunc = applyFunc // 这里调用了applyNaive
  }

  return options.applyFunc(ctx, root, r, options)
}
```

- applyNaive负责将tar文件解压到指定目录中(和snap绑定的临时目录tmpmounts)

```go
// archive/tar.go

// applyNaive applies a tar stream of an OCI style diff tar to a directory
// applying each file as either a whole file or whiteout.
// See https://github.com/opencontainers/image-spec/blob/master/layer.md#applying-changesets
func applyNaive(ctx context.Context, root string, r io.Reader, options ApplyOptions) (size int64, err error) {
  var (
    dirs []*tar.Header

    tr = tar.NewReader(r)

    // Used for handling opaque directory markers which
    // may occur out of order
    unpackedPaths = make(map[string]struct{})

    convertWhiteout = options.ConvertWhiteout
  )

  if convertWhiteout == nil {
    // handle whiteouts by removing the target files
    convertWhiteout = func(hdr *tar.Header, path string) (bool, error) {
      base := filepath.Base(path)
      dir := filepath.Dir(path)
      if base == whiteoutOpaqueDir {
        _, err := os.Lstat(dir)
        if err != nil {
          return false, err
        }
        err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
          if err != nil {
            if os.IsNotExist(err) {
              err = nil // parent was deleted
            }
            return err
          }
          if path == dir {
            return nil
          }
          if _, exists := unpackedPaths[path]; !exists {
            err := os.RemoveAll(path)
            return err
          }
          return nil
        })
        return false, err
      }

      if strings.HasPrefix(base, whiteoutPrefix) {
        originalBase := base[len(whiteoutPrefix):]
        originalPath := filepath.Join(dir, originalBase)

        return false, os.RemoveAll(originalPath)
      }

      return true, nil
    }
  }

  // Iterate through the files in the archive.
  for {
    select {
    case <-ctx.Done():
      return 0, ctx.Err()
    default:
    }

    hdr, err := tr.Next()
    if err == io.EOF {
      // end of tar archive
      break
    }
    if err != nil {
      return 0, err
    }

    size += hdr.Size

    // Normalize name, for safety and for a simple is-root check
    hdr.Name = filepath.Clean(hdr.Name)

    accept, err := options.Filter(hdr)
    if err != nil {
      return 0, err
    }
    if !accept {
      continue
    }

    if skipFile(hdr) {
      log.G(ctx).Warnf("file %q ignored: archive may not be supported on system", hdr.Name)
      continue
    }

    // Split name and resolve symlinks for root directory.
    ppath, base := filepath.Split(hdr.Name)
    ppath, err = fs.RootPath(root, ppath)
    if err != nil {
      return 0, errors.Wrap(err, "failed to get root path")
    }

    // Join to root before joining to parent path to ensure relative links are
    // already resolved based on the root before adding to parent.
    path := filepath.Join(ppath, filepath.Join("/", base))
    if path == root {
      log.G(ctx).Debugf("file %q ignored: resolved to root", hdr.Name)
      continue
    }

    // If file is not directly under root, ensure parent directory
    // exists or is created.
    if ppath != root {
      parentPath := ppath
      if base == "" {
        parentPath = filepath.Dir(path)
      }
      if err := mkparent(ctx, parentPath, root, options.Parents); err != nil {
        return 0, err
      }
    }

    // Naive whiteout convert function which handles whiteout files by
    // removing the target files.
    if err := validateWhiteout(path); err != nil {
      return 0, err
    }
    writeFile, err := convertWhiteout(hdr, path)
    if err != nil {
      return 0, errors.Wrapf(err, "failed to convert whiteout file %q", hdr.Name)
    }
    if !writeFile {
      continue
    }
    // If path exits we almost always just want to remove and replace it.
    // The only exception is when it is a directory *and* the file from
    // the layer is also a directory. Then we want to merge them (i.e.
    // just apply the metadata from the layer).
    if fi, err := os.Lstat(path); err == nil {
      if !(fi.IsDir() && hdr.Typeflag == tar.TypeDir) {
        if err := os.RemoveAll(path); err != nil {
          return 0, err
        }
      }
    }

    srcData := io.Reader(tr)
    srcHdr := hdr

    if err := createTarFile(ctx, path, root, srcHdr, srcData); err != nil {
      return 0, err
    }

    // Directory mtimes must be handled at the end to avoid further
    // file creation in them to modify the directory mtime
    if hdr.Typeflag == tar.TypeDir {
      dirs = append(dirs, hdr)
    }
    unpackedPaths[path] = struct{}{}
  }

  for _, hdr := range dirs {
    path, err := fs.RootPath(root, hdr.Name)
    if err != nil {
      return 0, err
    }
    if err := chtimes(path, boundTime(latestTime(hdr.AccessTime, hdr.ModTime)), boundTime(hdr.ModTime)); err != nil {
      return 0, err
    }
  }

  return size, nil
}
```

#### Processor

- processor主要负责解压缩相关比如gz等
- 在apply这个函数中获取了processor

```go
// diff/apply/apply.go
func (s *fsApplier) Apply(ctx context.Context, desc ocispec.Descriptor, mounts []mount.Mount, opts ...diff.ApplyOpt) (d ocispec.Descriptor, err error) {
  // 从content读取
  ra, err := s.store.ReaderAt(ctx, desc)
  defer ra.Close()

  var processors []diff.StreamProcessor
  processor := diff.NewProcessorChain(desc.MediaType, content.NewReader(ra))
  processors = append(processors, processor)
  for {
    if processor, err = diff.GetProcessor(ctx, processor, config.ProcessorPayloads); err != nil {
      return emptyDesc, errors.Wrapf(err, "failed to get stream processor for %s", desc.MediaType)
    }
    processors = append(processors, processor)
    if processor.MediaType() == ocispec.MediaTypeImageLayer {
      break
    }
  }
  defer processor.Close()

  digester := digest.Canonical.Digester()
  rc := &readCounter{
    r: io.TeeReader(processor, digester.Hash()),
  }
```

- 注册在这里，从配置文件遍历然后注册

```go
// services/server/server.go

// New creates and initializes a new containerd server
func New(ctx context.Context, config *srvconfig.Config) (*Server, error) {
  // ...

  for id, p := range config.StreamProcessors {
    diff.RegisterProcessor(diff.BinaryHandler(id, p.Returns, p.Accepts, p.Path, p.Args, p.Env)) // 注册 processor
  }
// ...
```

- 从注释来看是根据配置配置的`MediaType`,来选择二进制解压

```go
// diff/stream.go
// BinaryHandler creates a new stream processor handler which calls out to the given binary.
// The id is used to identify the stream processor and allows the caller to send
// payloads specific for that stream processor (i.e. decryption keys for decrypt stream processor).
// The binary will be called for the provided mediaTypes and return the given media type.
func BinaryHandler(id, returnsMediaType string, mediaTypes []string, path string, args, env []string) Handler {
  set := make(map[string]struct{}, len(mediaTypes))
  for _, m := range mediaTypes {
    set[m] = struct{}{}
  }
  return func(_ context.Context, mediaType string) (StreamProcessorInit, bool) {
    if _, ok := set[mediaType]; ok {
      return func(ctx context.Context, stream StreamProcessor, payloads map[string]*types.Any) (StreamProcessor, error) {
        payload := payloads[id]
        return NewBinaryProcessor(ctx, mediaType, returnsMediaType, stream, path, args, env, payload)
      }, true
    }
    return nil, false
  }
}
```

- 而默认情况下是`compressedHandler()`

```go
func init() {
  // register the default compression handler
  RegisterProcessor(compressedHandler)
}

func compressedHandler(ctx context.Context, mediaType string) (StreamProcessorInit, bool) {
  compressed, err := images.DiffCompression(ctx, mediaType)

  if compressed != "" {
    return func(ctx context.Context, stream StreamProcessor, payloads map[string]*types.Any) (StreamProcessor, error) {
      ds, err := compression.DecompressStream(stream)

      return &compressedProcessor{
        rc: ds,
      }, nil
    }, true
  }
  return func(ctx context.Context, stream StreamProcessor, payloads map[string]*types.Any) (StreamProcessor, error) {
    return &stdProcessor{
      rc: stream,
    }, nil
  }, true
}
```

- Decompress()就负责读取压缩格式

```go
// DecompressStream decompresses the archive and returns a ReaderCloser with the decompressed archive.
func DecompressStream(archive io.Reader) (DecompressReadCloser, error) {
  buf := newBufferedReader(archive)
  bs, err := buf.Peek(10)
  if err != nil && err != io.EOF {
    // Note: we'll ignore any io.EOF error because there are some odd
    // cases where the layer.tar file will be empty (zero bytes) and
    // that results in an io.EOF from the Peek() call. So, in those
    // cases we'll just treat it as a non-compressed stream and
    // that means just create an empty layer.
    // See Issue docker/docker#18170
    return nil, err
  }

  switch compression := DetectCompression(bs); compression {
  case Uncompressed:
    return &readCloserWrapper{
      Reader:      buf,
      compression: compression,
    }, nil
  case Gzip:
    ctx, cancel := context.WithCancel(context.Background())
    gzReader, err := gzipDecompress(ctx, buf)
    if err != nil {
      cancel()
      return nil, err
    }

    return &readCloserWrapper{
      Reader:      gzReader,
      compression: compression,
      closer: func() error {
        cancel()
        return gzReader.Close()
      },
    }, nil
  case Zstd:
    zstdReader, err := zstd.NewReader(buf)
    if err != nil {
      return nil, err
    }
    return &readCloserWrapper{
      Reader:      zstdReader,
      compression: compression,
      closer: func() error {
        zstdReader.Close()
        return nil
      },
    }, nil

  default:
    return nil, fmt.Errorf("unsupported compression format %s", (&compression).Extension())
  }
}
```
