# 在 Mac 上部署 ngrok 服务端指南

本指南将帮助您在 Mac 上部署和运行 ngrok 服务端（ngrokd）。

## 重要提示

⚠️ **注意**：此仓库是 ngrok v1 的归档版本，已不再维护和支持。建议使用官方的 ngrok 云服务：https://ngrok.com/signup

如果您仍需要自托管 ngrok v1 服务端，请继续阅读。

## 系统要求

- **操作系统**: macOS 10.12 或更高版本
- **Go 语言**: Go 1.1 或更高版本（推荐使用 Go 1.7+）
- **Mercurial**: 版本控制工具（Go 依赖管理需要）

## 部署步骤

### 1. 安装依赖

首先安装必要的工具：

```bash
# 安装 Homebrew（如果尚未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Go 语言
brew install go

# 安装 Mercurial
brew install mercurial
```

### 2. 获取代码

```bash
# 克隆仓库
git clone https://github.com/inconshreveable/ngrok.git
cd ngrok
```

### 3. 编译服务端

```bash
# 编译生产版本的服务端
make release-server

# 编译后的二进制文件位于 bin/ngrokd
```

如果只是开发测试，可以使用调试版本：

```bash
# 编译调试版本
make server
```

### 4. 准备 SSL 证书

ngrok 需要 TLS 证书来提供安全连接。您有两个选择：

#### 选项 A：使用正式 SSL 证书（推荐用于生产环境）

1. 购买或申请一个通配符 SSL 证书（例如 `*.example.com`）
2. 获取证书文件（.crt）和私钥文件（.key）
3. 将文件放在安全的位置

#### 选项 B：使用自签名证书（用于开发测试）

```bash
# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes \
  -subj "/CN=ngrok.example.com"
```

**注意**：使用自签名证书时，客户端配置需要设置 `trust_host_root_certs: false`

### 5. 配置 DNS

将您的域名指向服务器：

```bash
# 在 DNS 提供商处添加 A 记录
*.example.com  →  [您的服务器 IP 地址]
example.com    →  [您的服务器 IP 地址]
```

对于本地开发测试，可以修改 `/etc/hosts`：

```bash
sudo nano /etc/hosts

# 添加以下行
127.0.0.1 ngrok.me
127.0.0.1 test.ngrok.me
```

### 6. 运行服务端

使用以下命令启动 ngrokd 服务：

```bash
# 使用正式证书
./bin/ngrokd -tlsKey="/path/to/server.key" \
             -tlsCrt="/path/to/server.crt" \
             -domain="example.com"

# 本地开发测试（不需要 TLS 参数）
./bin/ngrokd -domain="ngrok.me"
```

**常用参数说明**：

- `-tlsKey`: TLS 私钥文件路径
- `-tlsCrt`: TLS 证书文件路径
- `-domain`: 服务器域名
- `-httpAddr`: HTTP 隧道监听地址（默认 :80）
- `-httpsAddr`: HTTPS 隧道监听地址（默认 :443）
- `-tunnelAddr`: 隧道连接地址（默认 :4443）

### 7. 配置客户端

创建或修改客户端配置文件 `~/.ngrok`：

```yaml
# 连接到自己的服务器
server_addr: example.com:4443
trust_host_root_certs: true
```

如果使用自签名证书：

```yaml
server_addr: example.com:4443
trust_host_root_certs: false
```

### 8. 测试连接

运行客户端连接到您的服务器：

```bash
./bin/ngrok -config=~/.ngrok 80
```

## 后台运行

### 使用 launchd（macOS 推荐方式）

创建 launchd 配置文件：

```bash
sudo nano /Library/LaunchDaemons/com.ngrok.ngrokd.plist
```

添加以下内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ngrok.ngrokd</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ngrokd</string>
        <string>-tlsKey=/path/to/server.key</string>
        <string>-tlsCrt=/path/to/server.crt</string>
        <string>-domain=example.com</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/ngrokd.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/ngrokd.error.log</string>
</dict>
</plist>
```

启动服务：

```bash
sudo launchctl load /Library/LaunchDaemons/com.ngrok.ngrokd.plist
sudo launchctl start com.ngrok.ngrokd
```

### 使用 nohup（简单方式）

```bash
nohup ./bin/ngrokd -tlsKey="/path/to/server.key" \
                   -tlsCrt="/path/to/server.crt" \
                   -domain="example.com" \
                   > ngrokd.log 2>&1 &
```

## 防火墙配置

确保以下端口可以访问：

- **4443**: 客户端连接端口
- **80**: HTTP 隧道端口
- **443**: HTTPS 隧道端口

```bash
# macOS 防火墙配置
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /path/to/ngrokd
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /path/to/ngrokd
```

## 故障排查

### 检查服务状态

```bash
# 检查进程是否运行
ps aux | grep ngrokd

# 检查端口监听
lsof -i :4443
lsof -i :80
lsof -i :443

# 查看日志
tail -f ngrokd.log
```

### 常见问题

1. **端口被占用**
   ```bash
   # 查找占用端口的进程
   sudo lsof -i :4443
   # 结束进程
   sudo kill -9 [PID]
   ```

2. **权限不足**
   ```bash
   # 80 和 443 端口需要 root 权限
   sudo ./bin/ngrokd -domain="example.com"
   ```

3. **客户端无法连接**
   - 检查防火墙设置
   - 确认域名 DNS 解析正确
   - 验证证书配置

## 性能优化

### 调整文件描述符限制

```bash
# 查看当前限制
ulimit -n

# 临时增加限制
ulimit -n 65536

# 永久修改（编辑 /etc/sysctl.conf）
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=65536
```

## 安全建议

1. **使用防火墙限制访问**
2. **定期更新 SSL 证书**
3. **监控服务器日志**
4. **使用强密码保护服务器**
5. **考虑使用 VPN 或 IP 白名单**

## 参考文档

- [SELFHOSTING.md](SELFHOSTING.md) - 自托管完整文档
- [DEVELOPMENT.md](DEVELOPMENT.md) - 开发者指南
- [ngrok 官方网站](https://ngrok.com)

## 技术支持

由于这是归档项目，官方不再提供支持。如需帮助：

- 查看 GitHub Issues: https://github.com/inconshreveable/ngrok/issues
- 考虑使用官方 ngrok 服务: https://ngrok.com
