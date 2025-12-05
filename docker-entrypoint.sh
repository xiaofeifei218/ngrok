#!/bin/sh
set -e

# 检查是否提供了必要的环境变量
if [ -z "$DOMAIN" ]; then
    echo "错误: 必须设置 DOMAIN 环境变量"
    exit 1
fi

echo "=========================================="
echo "启动 ngrokd 服务器"
echo "域名: $DOMAIN"
echo "隧道地址: $TUNNEL_ADDR"
echo "HTTP 地址: $HTTP_ADDR"
echo "HTTPS 地址: $HTTPS_ADDR"
echo "=========================================="

# 构建启动命令
CMD="/app/ngrokd -domain=$DOMAIN"

# 如果提供了 TLS 证书，则使用它们
if [ -f "$TLS_KEY" ] && [ -f "$TLS_CRT" ]; then
    echo "使用提供的 TLS 证书"
    CMD="$CMD -tlsKey=$TLS_KEY -tlsCrt=$TLS_CRT"
else
    echo "警告: 未找到 TLS 证书，服务器将在没有 TLS 的情况下运行"
    echo "这仅适用于开发环境！"
fi

# 添加其他参数
if [ -n "$HTTP_ADDR" ]; then
    CMD="$CMD -httpAddr=$HTTP_ADDR"
fi

if [ -n "$HTTPS_ADDR" ]; then
    CMD="$CMD -httpsAddr=$HTTPS_ADDR"
fi

if [ -n "$TUNNEL_ADDR" ]; then
    CMD="$CMD -tunnelAddr=$TUNNEL_ADDR"
fi

# 执行命令
echo "执行命令: $CMD"
echo "=========================================="
exec $CMD
