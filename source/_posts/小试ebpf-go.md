
---
title: 小试ebpf-go
author: Nature丿灵然
tags:
  - ebpf
date: 2025-06-14 15:15:00
---
ebpf-go是cilium开发的一个使用go来编写ebfp程序的框架

<!--more-->

#### 环境准备

- Linux 内核版本 5.7 或更高版本，用于 bpf_link 支持
- LLVM 11 或更高版本 （clang 和 llvm-strip）
- libbpf headers
  - Fedora是`libbpf-devel`
  - debian/ubuntu是`libbpf-dev`
- Linux 内核头文件
  - amd64架构的ubuntu/debian是`linux-headers-amd64`
  - 在Fedora上是`kernel-devel`这个包
  - 在debian上可能需要执行`ln -sf /usr/include/asm-generic/ /usr/include/asm`,下面的例子需要`<asm/types.h>`
- ebpf-go 的 Go 模块支持的 Go 编译器版本

- 安装依赖

```shell
sudo apt install clang
sudo apt install llvm
apt install libbpf-dev

sudo apt install pkg-config
sudo apt install m4
sudo apt install libelf-dev
sudo apt install libpcap-dev
sudo apt install gcc-multilib
```

#### 例子

- 大概流程如下：

```mermaid
graph LR
    A[eBPF的C代码] --> B[Go代码绑定]
    B --> C[main.go集成]
    C --> D[生成最终可执行文件]
```

- 创建一个空目录

- 这个ebpf的程序，将其保存为counter.c放在创建的目录中，下面的操作都在这个目录中

```c
//go:build ignore

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY); 
    __type(key, __u32);
    __type(value, __u64);
    __uint(max_entries, 1);
} pkt_count SEC(".maps"); 

// count_packets atomically increases a packet counter on every invocation.
SEC("xdp") 
int count_packets() {
    __u32 key    = 0; 
    __u64 *count = bpf_map_lookup_elem(&pkt_count, &key); 
    if (count) { 
        __sync_fetch_and_add(count, 1); 
    }

    return XDP_PASS; 
}

char __license[] SEC("license") = "Dual MIT/GPL";
```

- 保存为gen.go,用于执行go generate

```go
package main

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -tags linux counter counter.c

```

- 初始化go mod

```shell
go mod init ebpf-test
go mod tidy
```

- 安装bpf2go

```shell
go get github.com/cilium/ebpf/cmd/bpf2go
```

- 使用go generate生成go代码，如果环境依赖有问题这步会报错

```shell
go generate
```

- 保存为main.go调用生成的go代码

```go
package main

import (
    "log"
    "net"
    "os"
    "os/signal"
    "time"

    "github.com/cilium/ebpf/link"
    "github.com/cilium/ebpf/rlimit"
)

func main() {
    // Remove resource limits for kernels <5.11.
    if err := rlimit.RemoveMemlock(); err != nil {
        log.Fatal("Removing memlock:", err)
    }

    // Load the compiled eBPF ELF and load it into the kernel.
    var objs counterObjects
    if err := loadCounterObjects(&objs, nil); err != nil {
        log.Fatal("Loading eBPF objects:", err)
    }
    defer objs.Close()

    ifname := "eth0" // Change this to an interface on your machine.
    iface, err := net.InterfaceByName(ifname)
    if err != nil {
        log.Fatalf("Getting interface %s: %s", ifname, err)
    }

    // Attach count_packets to the network interface.
    link, err := link.AttachXDP(link.XDPOptions{
        Program:   objs.CountPackets,
        Interface: iface.Index,
    })
    if err != nil {
        log.Fatal("Attaching XDP:", err)
    }
    defer link.Close()

    log.Printf("Counting incoming packets on %s..", ifname)

    // Periodically fetch the packet counter from PktCount,
    // exit the program when interrupted.
    tick := time.Tick(time.Second)
    stop := make(chan os.Signal, 5)
    signal.Notify(stop, os.Interrupt)
    for {
        select {
        case <-tick:
            var count uint64
            err := objs.PktCount.Lookup(uint32(0), &count)
            if err != nil {
                log.Fatal("Map lookup:", err)
            }
            log.Printf("Received %d packets", count)
        case <-stop:
            log.Print("Received signal, exiting..")
            return
        }
    }
}
```

- 最终目录下应该有下面的文件

```shell
tree ebpf-test
# ebpf-test
# ├── counter.c
# ├── counter_bpfeb.go
# ├── counter_bpfeb.o
# ├── counter_bpfel.go
# ├── counter_bpfel.o
# ├── gen.go
# ├── go.mod
# ├── go.sum
# └── main.go
```

- 编译运行，可以看到日志打印

```shell
go build && sudo ./ebpf-test
# 2025/06/12 16:37:08 Counting incoming packets on eth0..
# 2025/06/12 16:37:09 Received 16 packets
# 2025/06/12 16:37:10 Received 26 packets
# 2025/06/12 16:37:11 Received 32 packets
```

- 和其他的代码生成器一样，如果c代码有变动需要重新运行`go generate`重新生成go代码

#### 参考资料

<https://ebpf-go.dev/guides/getting-started/>
