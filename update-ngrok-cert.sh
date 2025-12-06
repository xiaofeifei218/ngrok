#!/bin/bash
#
# ngrok 证书自动更新脚本（简化版）
# 每天凌晨执行，无脑复制证书并重启容器
#
# 使用方法：
# 1. 修改下面的路径配置
# 2. chmod +x update-ngrok-cert.sh
# 3. 添加到 crontab: 0 4 * * * /path/to/update-ngrok-cert.sh >> /tmp/ngrok-update.log 2>&1
#

# ============================================
# 配置部分 - 请根据实际情况修改
# ============================================

# acme.sh 证书目录（Mac 上通常是这个路径）
ACME_CERT_DIR="/Users/xiaofeifei/.ssl/xiaofeifei.fun"

# ngrok 项目目录（改成你的实际路径）
NGROK_DIR="/path/to/ngrok"

# ============================================
# 主逻辑 - 无需修改
# ============================================

echo "=========================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始更新证书并重启容器..."

# 检查源证书是否存在
if [ ! -f "$ACME_CERT_DIR/fullchain.pem" ]; then
    echo "[错误] 证书文件不存在: $ACME_CERT_DIR/fullchain.pem"
    exit 1
fi

if [ ! -f "$ACME_CERT_DIR/key.pem" ]; then
    echo "[错误] 私钥文件不存在: $ACME_CERT_DIR/key.pem"
    exit 1
fi

# 创建证书目录（如果不存在）
mkdir -p "$NGROK_DIR/certs"

# 复制证书
echo "复制证书文件..."
cp "$ACME_CERT_DIR/fullchain.pem" "$NGROK_DIR/certs/server.crt"
cp "$ACME_CERT_DIR/key.pem" "$NGROK_DIR/certs/server.key"

# 设置权限
chmod 644 "$NGROK_DIR/certs/server.crt"
chmod 600 "$NGROK_DIR/certs/server.key"

echo "证书复制完成"

# 验证证书
echo "证书有效期:"
openssl x509 -in "$NGROK_DIR/certs/server.crt" -noout -dates

# 重启容器
echo "重启 ngrokd 容器..."
cd "$NGROK_DIR"
docker-compose restart ngrokd

# 等待容器启动
sleep 3

# 检查容器状态
if docker-compose ps | grep -q "ngrokd.*Up"; then
    echo "[成功] ✅ 容器重启成功"
else
    echo "[失败] ❌ 容器启动失败"
    docker-compose logs --tail 20 ngrokd
    exit 1
fi

echo "[完成] 证书更新完成！"
echo "=========================================="
