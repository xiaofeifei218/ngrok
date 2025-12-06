# Dockerfile for ngrok server (ngrokd)
# 使用多阶段构建来减小最终镜像大小

# 构建阶段
FROM golang:1.11-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git make mercurial gcc musl-dev

# 设置工作目录
WORKDIR /ngrok

# 复制源代码
COPY . .

# 设置环境变量
ENV GOPATH=/ngrok \
    GO111MODULE=off

# 编译 ngrokd 服务端
# 分步骤处理，避免依赖版本冲突
RUN set -ex && \
    # 1. 构建 assets
    GOOS="" GOARCH="" go get github.com/jteeuwen/go-bindata/go-bindata && \
    bin/go-bindata -nomemcopy -pkg=assets -tags=release -debug=false \
        -o=src/ngrok/server/assets/assets_release.go assets/server/... && \
    # 2. 下载依赖（允许部分失败）
    go get -tags 'release' -d -v ngrok/... || true && \
    # 3. 修复 golang.org/x/net 版本到 Go 1.11 兼容分支
    if [ -d src/golang.org/x/net ]; then \
        cd src/golang.org/x/net && \
        git checkout release-branch.go1.11 && \
        cd /ngrok; \
    fi && \
    # 4. 编译 ngrokd
    go install -tags 'release' ngrok/main/ngrokd

# 运行阶段
FROM alpine:3.8

# 安装运行时依赖
RUN apk add --no-cache ca-certificates

# 创建工作目录
WORKDIR /app

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /ngrok/bin/ngrokd /app/ngrokd

# 创建证书目录
RUN mkdir -p /app/certs

# 暴露端口
# 4443: 客户端连接端口
# 80: HTTP 隧道端口
# 443: HTTPS 隧道端口
EXPOSE 4443 80 443

# 设置默认环境变量
ENV DOMAIN="ngrok.example.com" \
    TLS_KEY="/app/certs/server.key" \
    TLS_CRT="/app/certs/server.crt" \
    HTTP_ADDR=":80" \
    HTTPS_ADDR=":443" \
    TUNNEL_ADDR=":4443"

# 启动脚本
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
