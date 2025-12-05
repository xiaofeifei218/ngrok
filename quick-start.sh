#!/bin/bash
#
# ngrokd 快速启动脚本
# 用法: ./quick-start.sh [dev|prod]
#

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        echo "macOS: brew install --cask docker"
        echo "Linux: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装"
        exit 1
    fi

    print_success "Docker 环境检查通过"
}

# 开发环境启动
start_dev() {
    print_info "启动开发环境..."

    # 检查 hosts 配置
    if ! grep -q "ngrok.me" /etc/hosts; then
        print_warning "/etc/hosts 中未找到 ngrok.me 配置"
        echo ""
        echo "请执行以下命令添加 hosts 配置:"
        echo "  sudo sh -c 'echo \"127.0.0.1 ngrok.me\" >> /etc/hosts'"
        echo "  sudo sh -c 'echo \"127.0.0.1 test.ngrok.me\" >> /etc/hosts'"
        echo ""
        read -p "是否现在添加? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo sh -c 'echo "127.0.0.1 ngrok.me" >> /etc/hosts'
            sudo sh -c 'echo "127.0.0.1 test.ngrok.me" >> /etc/hosts'
            print_success "hosts 配置添加成功"
        else
            print_warning "请手动添加 hosts 配置后再启动"
            exit 0
        fi
    fi

    # 启动服务
    print_info "使用 docker-compose.dev.yml 启动服务..."
    docker-compose -f docker-compose.dev.yml up -d

    # 等待服务启动
    print_info "等待服务启动..."
    sleep 3

    # 显示状态
    docker-compose -f docker-compose.dev.yml ps

    echo ""
    print_success "开发环境启动成功！"
    echo ""
    echo "服务信息:"
    echo "  域名: ngrok.me"
    echo "  客户端连接端口: 4443"
    echo "  HTTP 端口: 8080"
    echo "  HTTPS 端口: 8443"
    echo ""
    echo "客户端配置 (~/.ngrok):"
    echo "  server_addr: ngrok.me:4443"
    echo "  trust_host_root_certs: false"
    echo ""
    echo "查看日志: docker-compose -f docker-compose.dev.yml logs -f"
    echo "停止服务: docker-compose -f docker-compose.dev.yml down"
    echo ""
}

# 生产环境启动
start_prod() {
    print_info "启动生产环境..."

    # 检查 .env 文件
    if [ ! -f .env ]; then
        print_warning ".env 文件不存在，从示例文件创建..."
        if [ -f .env.example ]; then
            cp .env.example .env
            print_warning "请编辑 .env 文件配置您的域名和证书路径"
            echo ""
            echo "必须配置:"
            echo "  1. DOMAIN=your-domain.com"
            echo "  2. 准备 TLS 证书并放到 certs/ 目录"
            echo ""
            read -p "配置完成后按回车继续..."
        else
            print_error ".env.example 文件不存在"
            exit 1
        fi
    fi

    # 检查证书目录
    if [ ! -d certs ]; then
        print_warning "certs 目录不存在，创建中..."
        mkdir -p certs
    fi

    # 检查证书文件
    if [ ! -f certs/server.key ] || [ ! -f certs/server.crt ]; then
        print_warning "未找到 TLS 证书"
        echo ""
        echo "选项 1: 生成自签名证书（仅用于测试）"
        echo "选项 2: 使用正式证书（生产环境）"
        echo ""
        read -p "是否生成自签名证书用于测试? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "请输入域名 (例如: ngrok.example.com): " domain
            openssl req -x509 -newkey rsa:4096 \
                -keyout certs/server.key \
                -out certs/server.crt \
                -days 365 -nodes \
                -subj "/CN=$domain"
            print_success "自签名证书生成成功"
        else
            print_info "请将您的证书文件复制到 certs/ 目录:"
            echo "  cp /path/to/your/server.key certs/"
            echo "  cp /path/to/your/server.crt certs/"
            read -p "证书准备完成后按回车继续..."
        fi
    fi

    # 启动服务
    print_info "启动生产环境服务..."
    docker-compose up -d

    # 等待服务启动
    print_info "等待服务启动..."
    sleep 3

    # 显示状态
    docker-compose ps

    echo ""
    print_success "生产环境启动成功！"
    echo ""
    echo "查看日志: docker-compose logs -f"
    echo "停止服务: docker-compose down"
    echo ""
}

# 显示帮助
show_help() {
    echo "用法: $0 [dev|prod|stop|logs|status]"
    echo ""
    echo "命令:"
    echo "  dev      - 启动开发环境（无需证书，使用 ngrok.me）"
    echo "  prod     - 启动生产环境（需要证书和域名配置）"
    echo "  stop     - 停止所有服务"
    echo "  logs     - 查看日志"
    echo "  status   - 查看服务状态"
    echo ""
    echo "示例:"
    echo "  $0 dev          # 快速启动开发环境"
    echo "  $0 prod         # 启动生产环境"
    echo "  $0 logs         # 查看日志"
    echo ""
}

# 停止服务
stop_services() {
    print_info "停止所有服务..."

    if [ -f docker-compose.dev.yml ]; then
        docker-compose -f docker-compose.dev.yml down
    fi

    if [ -f docker-compose.yml ]; then
        docker-compose down
    fi

    print_success "服务已停止"
}

# 查看日志
show_logs() {
    if docker ps | grep -q ngrokd-dev; then
        docker-compose -f docker-compose.dev.yml logs -f
    elif docker ps | grep -q ngrokd; then
        docker-compose logs -f
    else
        print_warning "没有运行中的 ngrokd 服务"
    fi
}

# 查看状态
show_status() {
    print_info "服务状态:"
    echo ""

    if docker ps | grep -q ngrokd; then
        docker-compose ps
        echo ""
        docker-compose -f docker-compose.dev.yml ps 2>/dev/null || true
    else
        print_warning "没有运行中的 ngrokd 服务"
    fi
}

# 主函数
main() {
    # 检查 Docker
    check_docker

    # 解析命令
    case "${1:-help}" in
        dev)
            start_dev
            ;;
        prod)
            start_prod
            ;;
        stop)
            stop_services
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
