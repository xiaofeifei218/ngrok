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
RUN make release-server

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
