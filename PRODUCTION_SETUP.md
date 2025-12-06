# 生产环境部署指南

## 🚀 完整部署流程

### 前提条件

- ✅ 有一个域名（如 xiaofeifei.fun）
- ✅ 域名已解析到服务器 IP
- ✅ 已通过 acme.sh 获取 SSL 证书
- ✅ 服务器已安装 Docker 和 Docker Compose

---

## 步骤 1: 准备证书

### 1.1 确认证书文件位置

```bash
# 查看证书文件
ls -lh /Users/xiaofeifei/.ssl/xiaofeifei.fun/

# 应该看到：
# fullchain.pem  (证书文件)
# key.pem        (私钥文件)
```

### 1.2 首次复制证书到项目

```bash
# 进入 ngrok 项目目录
cd /home/user/ngrok

# 创建证书目录
mkdir -p certs

# 复制证书（Mac 上的路径）
cp /Users/xiaofeifei/.ssl/xiaofeifei.fun/fullchain.pem certs/server.crt
cp /Users/xiaofeifei/.ssl/xiaofeifei.fun/key.pem certs/server.key

# 设置权限
chmod 644 certs/server.crt
chmod 600 certs/server.key

# 验证证书
openssl x509 -in certs/server.crt -noout -text | head -20
```

---

## 步骤 2: 配置环境变量

### 2.1 创建 .env 文件

```bash
# 从示例文件创建
cp .env.example .env

# 编辑配置
vim .env
```

### 2.2 .env 文件内容

```bash
# ============================================
# 必填配置
# ============================================

# 服务器域名（改成你的域名）
DOMAIN=xiaofeifei.fun

# ============================================
# TLS 证书配置（生产环境必需）
# ============================================

# TLS 私钥路径（容器内路径，不需要改）
TLS_KEY=/app/certs/server.key

# TLS 证书路径（容器内路径，不需要改）
TLS_CRT=/app/certs/server.crt

# ============================================
# 端口配置（可选，使用默认值）
# ============================================

# 容器内部监听地址（通常不需要改）
HTTP_ADDR=:80
HTTPS_ADDR=:443
TUNNEL_ADDR=:4443
```

### 2.3 验证配置

```bash
# 查看配置
cat .env

# 确认域名正确
grep DOMAIN .env
```

---

## 步骤 3: 启动生产环境

### 3.1 使用快速启动脚本（推荐）

```bash
# 启动生产环境
./quick-start.sh prod
```

脚本会：
- ✅ 检查 .env 配置
- ✅ 检查证书文件
- ✅ 启动 Docker 容器
- ✅ 显示服务状态

### 3.2 或手动启动

```bash
# 启动容器
docker-compose up -d

# 查看日志
docker-compose logs -f ngrokd
```

### 3.3 验证启动成功

```bash
# 查看容器状态
docker-compose ps

# 应该看到：
# NAME     COMMAND                  STATUS    PORTS
# ngrokd   "/app/docker-entrypo…"   Up        0.0.0.0:80->80/tcp, ...

# 查看启动日志
docker-compose logs ngrokd | head -20

# 应该看到类似：
# ==========================================
# 启动 ngrokd 服务器
# 域名: xiaofeifei.fun
# 隧道地址: :4443
# HTTP 地址: :80
# HTTPS 地址: :443
# ==========================================
# 使用提供的 TLS 证书
```

---

## 步骤 4: 测试服务

### 4.1 测试端口监听

```bash
# 检查端口监听
docker-compose exec ngrokd netstat -tlnp | grep ngrokd

# 或从主机测试
nc -zv localhost 4443
nc -zv localhost 80
nc -zv localhost 443

# 测试 HTTPS 证书
curl -I https://xiaofeifei.fun
```

### 4.2 查看容器日志

```bash
# 实时查看日志
docker-compose logs -f

# 查看最近 50 行
docker-compose logs --tail 50
```

---

## 步骤 5: 配置证书自动更新

### 5.1 修改更新脚本路径

```bash
# 编辑更新脚本
vim update-ngrok-cert.sh

# 修改以下两行为你的实际路径：
# ACME_CERT_DIR="/Users/xiaofeifei/.ssl/xiaofeifei.fun"
# NGROK_DIR="/home/user/ngrok"  # 改成实际路径

# 添加执行权限
chmod +x update-ngrok-cert.sh
```

### 5.2 测试脚本

```bash
# 手动执行测试
./update-ngrok-cert.sh

# 应该看到：
# ==========================================
# [2025-12-06 04:00:00] 开始更新证书并重启容器...
# 复制证书文件...
# 证书复制完成
# 证书有效期:
# notBefore=...
# notAfter=...
# 重启 ngrokd 容器...
# [成功] ✅ 容器重启成功
# [完成] 证书更新完成！
# ==========================================
```

### 5.3 添加定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天凌晨 4 点执行）
0 4 * * * /home/user/ngrok/update-ngrok-cert.sh >> /tmp/ngrok-cert-update.log 2>&1

# 保存退出

# 验证定时任务
crontab -l | grep ngrok
```

### 5.4 查看定时任务日志

```bash
# 查看更新日志
tail -f /tmp/ngrok-cert-update.log

# 第二天凌晨 4 点后查看
cat /tmp/ngrok-cert-update.log
```

---

## 步骤 6: 客户端配置

### 6.1 创建客户端配置文件

在你的**本地电脑**（不是服务器）上配置：

```bash
# 创建配置文件
vim ~/.ngrok

# 添加以下内容
server_addr: xiaofeifei.fun:4443
trust_host_root_certs: true
```

### 6.2 启动客户端

```bash
# 假设你本地有个服务在 8080 端口
python -m http.server 8080

# 另一个终端启动 ngrok
ngrok -config=~/.ngrok -subdomain=test 8080

# 应该看到：
# Tunnel Status                 online
# Forwarding                    http://test.xiaofeifei.fun -> localhost:8080
# Forwarding                    https://test.xiaofeifei.fun -> localhost:8080
```

### 6.3 测试访问

```bash
# 在浏览器或命令行访问
curl http://test.xiaofeifei.fun
curl https://test.xiaofeifei.fun

# 浏览器访问应该看到绿色小锁 🔒
```

---

## 📊 常用命令速查

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec ngrokd sh
```

### 证书管理

```bash
# 查看证书有效期
openssl x509 -in certs/server.crt -noout -dates

# 查看证书详情
openssl x509 -in certs/server.crt -text -noout

# 手动更新证书
./update-ngrok-cert.sh

# 查看更新日志
tail -f /tmp/ngrok-cert-update.log
```

### 调试命令

```bash
# 测试端口连通性
nc -zv xiaofeifei.fun 4443
nc -zv xiaofeifei.fun 80
nc -zv xiaofeifei.fun 443

# 查看端口占用
sudo lsof -i :4443
sudo lsof -i :80
sudo lsof -i :443

# 查看容器端口映射
docker port ngrokd

# 测试 HTTPS
curl -I https://xiaofeifei.fun

# 查看容器资源使用
docker stats ngrokd
```

---

## 🔧 故障排查

### 问题 1: 容器启动失败

```bash
# 查看详细日志
docker-compose logs ngrokd

# 常见原因：
# - 端口被占用：sudo lsof -i :80
# - 证书路径错误：ls -lh certs/
# - 配置文件错误：cat .env
```

### 问题 2: 客户端无法连接

```bash
# 检查服务器端口
nc -zv xiaofeifei.fun 4443

# 检查防火墙
sudo ufw status
sudo ufw allow 4443

# 检查容器日志
docker-compose logs -f
```

### 问题 3: HTTPS 证书警告

```bash
# 检查证书是否有效
openssl x509 -in certs/server.crt -noout -dates

# 检查证书域名
openssl x509 -in certs/server.crt -text -noout | grep DNS

# 确认域名匹配
# 访问的域名必须在证书的 DNS 列表中
```

### 问题 4: 证书自动更新失败

```bash
# 查看更新日志
cat /tmp/ngrok-cert-update.log

# 手动执行测试
./update-ngrok-cert.sh

# 检查定时任务
crontab -l

# 检查脚本权限
ls -lh update-ngrok-cert.sh
```

---

## 📋 生产环境检查清单

启动前确认：

- [ ] 域名已正确解析到服务器 IP
- [ ] SSL 证书文件存在（fullchain.pem, key.pem）
- [ ] 证书已复制到 certs/ 目录
- [ ] .env 文件配置正确（DOMAIN）
- [ ] Docker 和 Docker Compose 已安装
- [ ] 防火墙已开放 80、443、4443 端口
- [ ] 更新脚本路径已修改
- [ ] 定时任务已添加
- [ ] 客户端配置文件已创建

---

## 🎯 快速启动摘要

```bash
# 1. 准备证书
cd /home/user/ngrok
mkdir -p certs
cp /Users/xiaofeifei/.ssl/xiaofeifei.fun/fullchain.pem certs/server.crt
cp /Users/xiaofeifei/.ssl/xiaofeifei.fun/key.pem certs/server.key
chmod 644 certs/server.crt
chmod 600 certs/server.key

# 2. 配置环境
cp .env.example .env
vim .env  # 设置 DOMAIN=xiaofeifei.fun

# 3. 启动服务
./quick-start.sh prod
# 或
docker-compose up -d

# 4. 配置自动更新
vim update-ngrok-cert.sh  # 修改路径
chmod +x update-ngrok-cert.sh
crontab -e  # 添加: 0 4 * * * /home/user/ngrok/update-ngrok-cert.sh >> /tmp/ngrok-cert-update.log 2>&1

# 5. 客户端配置（本地电脑）
echo "server_addr: xiaofeifei.fun:4443
trust_host_root_certs: true" > ~/.ngrok

# 6. 测试
ngrok -config=~/.ngrok -subdomain=test 8080
```

---

## 📞 需要帮助？

- 查看完整 Docker 部署文档: `docs/DOCKER_DEPLOYMENT.md`
- 查看端口配置说明: `docs/PORT_CONFIGURATION.md`
- 查看数据流路线图: `docs/DATA_FLOW.md`
- 查看快速参考: `PORT_QUICK_REFERENCE.txt`

---

**祝部署顺利！** 🎉
