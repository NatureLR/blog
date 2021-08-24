layout: draft
title: go资源内嵌embed
author: Nature丿灵然
tags: 
  - go
categories:
  - 开发
date: 2021-03-19 11:30:00
---
Go官方在1.16版本发布了官方内嵌资源到二进制的功能，使得部署更加简单

<!--more-->

> 在开发web的时候往往会有一些web文件，而部署的时候需要部署一个二进制还要部署web文件比较繁琐，在go1.16之前也有很多包实现了内嵌资源文件到二进制中如<https://github.com/gobuffalo/packr>，而如今go官方实现了这个特性

#### 基本用法

```go
package main

import (
	_ "embed"
	"fmt"
)

//go:embed Dockerfile
var f string

func main() {
	fmt.Println(f)
}
```

上面的例子就是将当前目录的dockerfile内容内嵌到变量f中,编译之后即使这个文件不存在也能打印出内容

#### 嵌入文件夹

```go
package main

import (
    "embed"
    "fmt"
    "path/filepath"
)

//go:embed foo
var fs embed.FS

func main() {
    files, err := fs.ReadDir("foo")
    if err != nil {
        fmt.Println(err)
    }
    for _, file := range files {
        d, _ := fs.ReadFile(filepath.Join("foo", file.Name()))
        if err != nil {
            fmt.Println(err)
        }
        fmt.Println("文件名:", file.Name(), "内容:", string(d))
    }
}
```

> 上面的代码将目录下的foo目录内嵌到fs这个变量中，然后打印出这个文件夹里文字的名字和内容

```shell
$ tree foo 
foo
├── test
└── test2

0 directories, 2 files

# 编译
$ go build -o test .

# 执行
$ ./test                
文件名: test 内容: hahah
文件名: test2 内容: testest
```

#### 注意

- 路径默认是从mod的目录为根目录
- 会忽略”.“开头和”_“开头的文件
- 不管是win还是linux都使用”/“
- 支持匹配如，`//go:embed foo/*.yaml`
- 可以同时导入多个目录 如`//go:embed foo test`

#### 参考资料

<https://www.cnblogs.com/apocelipes/p/13907858.html>
