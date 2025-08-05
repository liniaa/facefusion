#!/bin/bash

echo "=== 配置Docker镜像加速器（中国区） ==="

# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 配置Docker镜像加速器
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://reg-mirror.qiniu.com",
    "https://dockerhub.azk8s.cn"
  ],
  "insecure-registries": [],
  "debug": false,
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
EOF

echo "✓ Docker配置文件已更新"

# 重启Docker服务
echo "重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "✓ Docker服务已重启"

# 验证配置
echo "验证Docker镜像加速器配置："
docker info | grep -A 10 "Registry Mirrors" || echo "配置可能未生效，请检查Docker状态"

echo "=== 配置完成 ==="
echo "现在可以使用以下命令构建："
echo "docker compose -f docker-compose.china.yml build"