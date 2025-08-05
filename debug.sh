#!/bin/bash

echo "=== FaceFusion Docker 调试脚本 ==="
echo

# 检查容器状态
echo "1. 检查容器状态："
docker compose -f docker-compose.yml ps
echo

# 检查最近的日志
echo "2. 最近50行日志："
docker compose -f docker-compose.yml logs --tail=50
echo

# 检查Intel GPU设备
echo "3. 检查Intel GPU设备："
ls -la /dev/dri/
echo

# 检查容器资源使用
echo "4. 容器资源使用："
docker stats facefusion-intel-gpu --no-stream
echo

# 检查网络连接
echo "5. 检查端口7860是否可访问："
curl -I http://localhost:7860/ 2>/dev/null || echo "端口7860无法访问"
echo

# 提供进入容器的命令
echo "6. 如需进入容器调试，运行："
echo "   docker exec -it facefusion-intel-gpu /bin/bash"
echo

# 提供查看实时日志的命令
echo "7. 查看实时日志："
echo "   docker compose -f docker-compose.yml logs -f"