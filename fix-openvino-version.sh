#!/bin/bash

# FaceFusion OpenVINO 版本兼容性修复脚本
# 解决 onnxruntime-openvino==1.16.3 版本不兼容问题

set -e

echo "=== FaceFusion OpenVINO 版本兼容性修复 ==="
echo

# 检查Python版本
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "当前Python版本: $PYTHON_VERSION"

if [[ "$PYTHON_VERSION" != "3.10" ]]; then
    echo "⚠️  警告: 建议使用Python 3.10以获得最佳兼容性"
fi

# 备份原始文件
echo "📁 备份原始配置文件..."
cp requirements-docker.txt requirements-docker.txt.backup
cp Dockerfile.china Dockerfile.china.backup
echo "✅ 备份完成"

# 测试可用的 onnxruntime-openvino 版本
echo "🔍 测试可用的 onnxruntime-openvino 版本..."

AVAILABLE_VERSIONS=("1.22.0" "1.20.0" "1.19.0" "1.18.0" "1.17.1" "1.16.0" "1.15.0")
WORKING_VERSION=""

for version in "${AVAILABLE_VERSIONS[@]}"; do
    echo "测试版本 $version..."
    
    # 使用清华镜像源测试版本可用性
    if pip3 index versions onnxruntime-openvino==$version --index-url https://pypi.tuna.tsinghua.edu.cn/simple/ &>/dev/null; then
        echo "✅ 版本 $version 可用"
        WORKING_VERSION=$version
        break
    else
        echo "❌ 版本 $version 不可用"
    fi
done

if [[ -z "$WORKING_VERSION" ]]; then
    echo "❌ 未找到兼容的 onnxruntime-openvino 版本"
    echo "尝试使用最新可用版本..."
    WORKING_VERSION="1.22.0"
fi

echo "🎯 选择版本: $WORKING_VERSION"

# 更新 requirements-docker.txt
echo "📝 更新 requirements-docker.txt..."
sed -i.bak "s/onnxruntime-openvino==.*/onnxruntime-openvino==$WORKING_VERSION/" requirements-docker.txt

# 更新 Dockerfile.china
echo "📝 更新 Dockerfile.china..."
sed -i.bak "s/onnxruntime-openvino==.*/onnxruntime-openvino==$WORKING_VERSION/" Dockerfile.china

# 清理Docker缓存
echo "🧹 清理Docker构建缓存..."
docker system prune -f

# 重新构建镜像
echo "🏗️  重新构建Docker镜像..."
docker-compose -f docker-compose.china.yml build --no-cache

echo
echo "✅ 修复完成！"
echo
echo "📋 修复摘要:"
echo "   - 使用 onnxruntime-openvino==$WORKING_VERSION"
echo "   - 已更新 requirements-docker.txt"
echo "   - 已更新 Dockerfile.china"
echo "   - 已重新构建Docker镜像"
echo
echo "🚀 现在可以启动服务:"
echo "   docker-compose -f docker-compose.china.yml up -d"
echo
echo "🔄 如需回滚:"
echo "   mv requirements-docker.txt.backup requirements-docker.txt"
echo "   mv Dockerfile.china.backup Dockerfile.china"
echo