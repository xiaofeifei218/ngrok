# 使用 Docker 部署 ngrok 服务端

本指南将帮助您使用 Docker 快速部署 ngrok 服务端（ngrokd），无需担心 Go 版本兼容性问题。

## 📌 为什么选择 Docker？

- ✅ **环境隔离**: 不需要安装特定版本的 Go（项目需要 Go 1.4-1.6）
- ✅ **快速部署**: 一行命令即可启动服务
- ✅ **易于管理**: 使用 docker-compose 管理服务生命周期
- ✅ **跨平台**: 在 Mac、Linux、Windows 上都能运行
- ✅ **易于扩展**: 方便进行负载均衡和集群部署

## 🔧 前置要求

### 安装 Docker

**macOS:**
```bash
# 下载并安装 Docker Desktop for Mac
# https://www.docker.com/products/docker-desktop

# 验证安装
docker --version
docker-compose --version
```

**Linux (Ubuntu/Debian):**
```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 重新登录使组权限生效
```

## 🚀 快速开始

### 方式一: 使用 Docker Compose (推荐)

#### 1. 准备证书（可选，生产环境必需）

```bash
# 创建证书目录
mkdir -p certs

# 选项 A: 使用自签名证书（仅用于开发测试）
openssl req -x509 -newkey rsa:4096 \
  -keyout certs/server.key \
  -out certs/server.crt \
  -days 365 -nodes \
  -subj "/CN=ngrok.example.com"

# 选项 B: 使用正式证书（用于生产环境）
# 将您的证书文件复制到 certs 目录
cp /path/to/your/server.key certs/
cp /path/to/your/server.crt certs/
```

#### 2. 配置环境变量

编辑 `docker-compose.yml` 文件，修改 `DOMAIN` 环境变量：

```yaml
environment:
  - DOMAIN=ngrok.example.com  # 改成您的域名
```

或者创建 `.env` 文件：

```bash
# .env 文件
DOMAIN=ngrok.example.com
HTTP_PORT=80
HTTPS_PORT=443
TUNNEL_PORT=4443
```

#### 3. 启动服务

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看服务状态
docker-compose ps
```

#### 4. 停止服务

```bash
# 停止服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

### 方式二: 使用 Docker 命令

#### 1. 构建镜像

```bash
# 构建 Docker 镜像
docker build -t ngrokd:latest .
```

#### 2. 运行容器

```bash
# 不使用 TLS（仅用于测试）
docker run -d \
  --name ngrokd \
  -p 4443:4443 \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=ngrok.example.com \
  ngrokd:latest

# 使用 TLS 证书
docker run -d \
  --name ngrokd \
  -p 4443:4443 \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=ngrok.example.com \
  -v $(pwd)/certs:/app/certs:ro \
  ngrokd:latest
```

## 📝 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `DOMAIN` | 服务器域名 | `ngrok.example.com` | ✅ 是 |
| `TLS_KEY` | TLS 私钥路径（容器内） | `/app/certs/server.key` | ❌ 否 |
| `TLS_CRT` | TLS 证书路径（容器内） | `/app/certs/server.crt` | ❌ 否 |
| `HTTP_ADDR` | HTTP 监听地址 | `:80` | ❌ 否 |
| `HTTPS_ADDR` | HTTPS 监听地址 | `:443` | ❌ 否 |
| `TUNNEL_ADDR` | 隧道监听地址 | `:4443` | ❌ 否 |

### 端口说明

| 端口 | 用途 |
|------|------|
| `4443` | 客户端连接端口 |
| `80` | HTTP 隧道端口 |
| `443` | HTTPS 隧道端口 |

## 🔐 DNS 配置

配置 DNS 将域名指向您的服务器：

```
# 在 DNS 提供商处添加以下记录
*.example.com  A  123.456.789.0  # 您的服务器 IP
example.com    A  123.456.789.0  # 您的服务器 IP
```

**本地测试** (修改 `/etc/hosts`):
```bash
sudo nano /etc/hosts

# 添加以下行
127.0.0.1 ngrok.me
127.0.0.1 test.ngrok.me
```

## 📱 客户端配置

创建或修改客户端配置文件 `~/.ngrok`:

```yaml
server_addr: example.com:4443
trust_host_root_certs: true
```

使用自签名证书时：
```yaml
server_addr: example.com:4443
trust_host_root_certs: false
```

连接到服务器：
```bash
ngrok -config=~/.ngrok 80
```

## 🛠️ 高级配置

### 使用自定义端口

如果默认端口被占用，可以修改 `docker-compose.yml`:

```yaml
ports:
  - "8443:4443"  # 将 4443 映射到主机的 8443
  - "8080:80"    # 将 80 映射到主机的 8080
  - "8443:443"   # 将 443 映射到主机的 8443
```

### 开发环境配置

创建 `docker-compose.dev.yml` 用于本地开发：

```yaml
version: '3.8'

services:
  ngrokd:
    build: .
    container_name: ngrokd-dev
    environment:
      - DOMAIN=ngrok.me
    ports:
      - "4443:4443"
      - "8080:80"    # 开发环境使用 8080
      - "8443:443"
    networks:
      - ngrok-dev

networks:
  ngrok-dev:
    driver: bridge
```

启动开发环境：
```bash
docker-compose -f docker-compose.dev.yml up
```

### 持久化日志

添加日志卷到 `docker-compose.yml`:

```yaml
volumes:
  - ./certs:/app/certs:ro
  - ./logs:/app/logs
```

### 使用 Docker Hub 镜像（如果已发布）

```bash
# 拉取镜像
docker pull your-username/ngrokd:latest

# 运行
docker run -d \
  --name ngrokd \
  -p 4443:4443 \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=ngrok.example.com \
  -v $(pwd)/certs:/app/certs:ro \
  your-username/ngrokd:latest
```

## 🐛 故障排查

### 查看容器日志

```bash
# 实时查看日志
docker-compose logs -f ngrokd

# 查看最近 100 行日志
docker logs --tail 100 ngrokd

# 查看容器状态
docker-compose ps
docker inspect ngrokd
```

### 进入容器调试

```bash
# 进入运行中的容器
docker exec -it ngrokd sh

# 检查进程
ps aux | grep ngrokd

# 检查端口监听
netstat -tlnp

# 测试端口连通性
nc -zv localhost 4443
```

### 常见问题

#### 1. 端口被占用

```bash
# 查找占用端口的进程
sudo lsof -i :4443
sudo lsof -i :80
sudo lsof -i :443

# 或者修改 docker-compose.yml 使用其他端口
ports:
  - "14443:4443"
  - "8080:80"
```

#### 2. 证书权限问题

```bash
# 确保证书文件权限正确
chmod 644 certs/server.crt
chmod 600 certs/server.key

# 检查证书挂载
docker exec ngrokd ls -la /app/certs
```

#### 3. 容器启动失败

```bash
# 查看完整错误信息
docker-compose logs ngrokd

# 检查配置
docker-compose config

# 重新构建镜像
docker-compose build --no-cache
docker-compose up -d
```

#### 4. 客户端无法连接

```bash
# 检查容器网络
docker network inspect ngrok-network

# 检查端口映射
docker port ngrokd

# 测试连接
telnet your-server-ip 4443
nc -zv your-server-ip 4443
```

## 🚦 生产环境部署建议

### 1. 使用反向代理（推荐）

使用 Nginx 或 Traefik 作为前端代理：

```yaml
# docker-compose.yml 添加 Nginx
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - ngrokd
    networks:
      - ngrok-network

  ngrokd:
    build: .
    environment:
      - DOMAIN=ngrok.example.com
    ports:
      - "4443:4443"
    volumes:
      - ./certs:/app/certs:ro
    networks:
      - ngrok-network

networks:
  ngrok-network:
    driver: bridge
```

### 2. 监控和日志

```yaml
# 添加日志驱动
services:
  ngrokd:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. 资源限制

```yaml
services:
  ngrokd:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
```

### 4. 自动重启

```yaml
services:
  ngrokd:
    restart: unless-stopped
```

### 5. 健康检查

```yaml
services:
  ngrokd:
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "4443"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

## 🔄 更新和维护

### 更新镜像

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build --no-cache

# 重启服务
docker-compose up -d
```

### 备份

```bash
# 备份证书和配置
tar -czf ngrok-backup-$(date +%Y%m%d).tar.gz certs/ docker-compose.yml .env

# 导出镜像
docker save ngrokd:latest | gzip > ngrokd-image.tar.gz
```

## 🌐 多服务器部署

使用 Docker Swarm 或 Kubernetes 进行集群部署：

```bash
# Docker Swarm 初始化
docker swarm init

# 部署服务栈
docker stack deploy -c docker-compose.yml ngrok

# 扩展服务
docker service scale ngrok_ngrokd=3
```

## 📚 相关资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [ngrok SELFHOSTING.md](SELFHOSTING.md)
- [ngrok MAC_DEPLOYMENT.md](MAC_DEPLOYMENT.md)

## ⚠️ 注意事项

- 本项目为 ngrok v1 归档版本，不再维护
- 生产环境建议使用官方 ngrok 服务：https://ngrok.com
- 使用自签名证书仅适合开发测试
- 确保防火墙开放必要端口
- 定期更新 SSL 证书

## 💡 快速命令参考

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 查看状态
docker-compose ps

# 重新构建
docker-compose build --no-cache

# 查看容器信息
docker inspect ngrokd

# 进入容器
docker exec -it ngrokd sh
```
