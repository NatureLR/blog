---
title: linux登录欢迎页
author: Nature丿灵然
tags:
  - linux
date: 2020-08-03 14:51:00
---
ssh每次登录的时候显示一些信息
<!--more-->
编辑`/etc/motd`中的内容，即可在登录的时候打印出来

![upload successful](../images/pasted-0.png)

例如将下面的复制进去

```string
......................阿弥陀佛......................
                      _oo0oo_
                     o8888888o
                     88" . "88
                     (| -_- |)
                     0\  =  /0
                   ___/‘---’\___
                  .' \|       |/ '.
                 / \\|||  :  |||// \
                / _||||| -卍-|||||_ \
               |   | \\\  -  /// |   |
               | \_|  ''\---/''  |_/ |
               \  .-\__  '-'  ___/-. /
             ___'. .'  /--.--\  '. .'___
         ."" ‘<  ‘.___\_<|>_/___.’>’ "".
       | | :  ‘- \‘.;‘\ _ /’;.’/ - ’ : | |
         \  \ ‘_.   \_ __\ /__ _/   .-’ /  /
    =====‘-.____‘.___ \_____/___.-’___.-’=====
                      ‘=---=’

....................佛祖保佑 ,永无BUG...................
```
