# 🐳 Docker 快速部署 ngrok 服务端

> 使用 Docker 快速部署 ngrok 服务端，无需担心 Go 版本兼容性问题！

## ⚡ 超级快速开始（推荐！）

### 开发环境（1 分钟启动）

```bash
# 1. 运行快速启动脚本
./quick-start.sh dev

# 就这么简单！服务已启动 🎉
```

### 生产环境

```bash
# 1. 准备证书（放到 certs/ 目录）
mkdir -p certs
cp your-server.key certs/
cp your-server.crt certs/

# 2. 配置域名
cp .env.example .env
# 编辑 .env，设置 DOMAIN=your-domain.com

# 3. 启动
./quick-start.sh prod
```

## 📦 包含的文件

```
ngrok/
├── Dockerfile                   # Docker 镜像定义
├── docker-compose.yml           # 生产环境配置
├── docker-compose.dev.yml       # 开发环境配置
├── docker-entrypoint.sh         # 容器启动脚本
├── quick-start.sh               # 快速启动脚本 ⭐
├── .env.example                 # 环境变量示例
├── .dockerignore                # Docker 构建忽略文件
└── docs/
    └── DOCKER_DEPLOYMENT.md     # 详细部署文档
```

## 🎯 快速启动脚本命令

```bash
./quick-start.sh dev      # 开发环境（无需证书）
./quick-start.sh prod     # 生产环境（需要证书）
./quick-start.sh stop     # 停止服务
./quick-start.sh logs     # 查看日志
./quick-start.sh status   # 查看状态
```

## 🔥 主要特性

- ✅ **零依赖**: 无需安装 Go、Mercurial 等工具
- ✅ **一键启动**: 运行一个脚本即可启动
- ✅ **自动配置**: 自动处理 hosts、证书等配置
- ✅ **开发友好**: 开发环境无需 TLS 证书
- ✅ **生产就绪**: 完整的生产环境配置
- ✅ **跨平台**: Mac、Linux、Windows (WSL2) 都能用

## 📚 详细文档

完整的 Docker 部署文档请查看：**[docs/DOCKER_DEPLOYMENT.md](docs/DOCKER_DEPLOYMENT.md)**

包含内容：
- 详细的安装步骤
- 高级配置选项
- 故障排查指南
- 生产环境优化
- 集群部署方案

## 🆚 为什么选择 Docker？

| 传统部署 | Docker 部署 |
|---------|------------|
| 需要安装 Go 1.4-1.6 | ✅ 无需安装任何依赖 |
| 需要安装 Mercurial | ✅ 镜像内已包含 |
| 环境冲突风险 | ✅ 完全隔离 |
| 部署复杂 | ✅ 一行命令启动 |
| 难以迁移 | ✅ 轻松迁移 |

## 🌟 使用示例

### 开发测试

```bash
# 启动开发环境
./quick-start.sh dev

# 客户端配置 ~/.ngrok
cat > ~/.ngrok << EOF
server_addr: ngrok.me:4443
trust_host_root_certs: false
EOF

# 连接测试
ngrok -config=~/.ngrok 8080
```

### 生产部署

```bash
# 1. 配置域名和证书
cp .env.example .env
vim .env  # 设置 DOMAIN

# 2. 准备证书
mkdir -p certs
cp your-cert.crt certs/server.crt
cp your-key.key certs/server.key

# 3. 启动
./quick-start.sh prod

# 4. 查看状态
./quick-start.sh status
```

## 🔧 手动部署（不使用脚本）

### 开发环境

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 生产环境

```bash
docker-compose up -d
```

## 📊 端口说明

| 端口 | 用途 | 环境 |
|------|------|------|
| 4443 | 客户端连接 | 开发/生产 |
| 80 | HTTP 隧道 | 生产 |
| 443 | HTTPS 隧道 | 生产 |
| 8080 | HTTP 隧道 | 开发 |
| 8443 | HTTPS 隧道 | 开发 |

## 🐛 常见问题

### 1. 端口被占用

```bash
# 修改 docker-compose.yml 的端口映射
ports:
  - "14443:4443"  # 改用 14443
```

### 2. 查看日志

```bash
./quick-start.sh logs
# 或
docker-compose logs -f
```

### 3. 完全重新构建

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 💡 提示

1. **开发环境**建议使用 `docker-compose.dev.yml`，无需证书
2. **生产环境**务必使用正式的 TLS 证书
3. 证书文件权限设置为 `600` (server.key) 和 `644` (server.crt)
4. 使用 `./quick-start.sh` 获得最佳体验

## 🔗 相关链接

- [详细 Docker 部署文档](docs/DOCKER_DEPLOYMENT.md)
- [Mac 原生部署文档](docs/MAC_DEPLOYMENT.md)
- [自托管文档](docs/SELFHOSTING.md)
- [开发者指南](docs/DEVELOPMENT.md)

## ⚠️ 注意

- 本项目为 ngrok v1 归档版本
- 生产环境建议使用官方服务：https://ngrok.com
- Docker 需要 root/sudo 权限运行

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**快速开始**: `./quick-start.sh dev` 🚀
