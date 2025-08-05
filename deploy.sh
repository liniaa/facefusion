#!/bin/bash

# FaceFusion Intel UHD Graphics 部署脚本
# 适用于中国境内网络环境

set -e

echo "=== FaceFusion Intel GPU 部署脚本 ==="
echo "适用于Intel UHD Graphics，中国境内网络环境"
echo

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    echo "安装命令（Ubuntu/Debian）："
    echo "curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -"
    echo "sudo add-apt-repository \"deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \$(lsb_release -cs) stable\""
    echo "sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，正在安装..."
    sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 检查Intel GPU设备
echo "🔍 检查Intel GPU设备..."
if [ ! -d "/dev/dri" ]; then
    echo "❌ 未检测到Intel GPU设备 (/dev/dri)"
    echo "请确保："
    echo "1. Intel GPU驱动已正确安装"
    echo "2. 用户有权限访问GPU设备"
    exit 1
fi

echo "✅ 检测到Intel GPU设备："
ls -la /dev/dri/

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p models cache output input

# 配置Docker镜像源（中国境内）
echo "🔧 配置Docker镜像源..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "registry-mirrors": [
        "https://registry.cn-hangzhou.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

# 重启Docker服务
echo "🔄 重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 将当前用户添加到docker组
echo "👤 配置Docker用户权限..."
sudo usermod -aG docker $USER

# 构建Docker镜像（使用中国优化版本）
echo "🏗️  构建FaceFusion Docker镜像..."
echo "使用中国网络优化版本 Dockerfile.china..."
docker-compose -f docker-compose.china.yml build --no-cache

# 预下载模型文件（使用国内镜像）
echo "📥 预下载模型文件..."
docker-compose -f docker-compose.china.yml run --rm facefusion python3 facefusion.py force-download --download-provider huggingface

echo
echo "✅ 部署完成！"
echo
echo "🚀 启动命令："
echo "   docker-compose -f docker-compose.china.yml up -d"
echo
echo "🌐 访问地址："
echo "   http://localhost:7860"
echo
echo "📊 查看日志："
echo "   docker-compose -f docker-compose.china.yml logs -f"
echo
echo "🛑 停止服务："
echo "   docker-compose -f docker-compose.china.yml down"
echo
echo "💡 注意事项："
echo "   1. 首次启动可能需要较长时间下载模型"
echo "   2. Intel UHD Graphics性能有限，建议先用小图片测试"
echo "   3. 如遇网络问题，可尝试重新运行此脚本"
echo
echo "🔧 故障排除："
echo "   - 检查GPU权限: ls -la /dev/dri/"
echo "   - 查看容器状态: docker-compose -f docker-compose.china.yml ps"
echo "   - 重新构建: docker-compose -f docker-compose.china.yml build --no-cache"
echo "   - 测试依赖兼容性: python3 test-dependencies.py"
echo