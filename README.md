# YYF-docker

docker image with YYF environment

[YYF运行环境的docker镜像](https://hub.docker.com/r/newfuture/yyf/)

* `full` (lastest) 完整服务(包括数据库客户端): [![](https://images.microbadger.com/badges/image/newfuture/yyf:full.svg)](https://github.com/NewFuture/YYF-docker/tree/master/full)
* `server` 不含数据库管理客户端: [![](https://images.microbadger.com/badges/image/newfuture/yyf:server.svg)](https://github.com/NewFuture/YYF-docker/tree/master/server)
* `demo` 仅仅包含演示源码的最小镜像(约13M): [![](https://images.microbadger.com/badges/image/newfuture/yyf:demo.svg)](https://github.com/NewFuture/YYF-docker/tree/master/demo)

## 运行本地项目
```
docker run -it --rm -p 1122:80 -v "`pwd`":/yyf newfuture/yyf
```

## 演示YYF demo
```
docker run -it --rm -p 1122:80 newfuture/yyf:demo
```
