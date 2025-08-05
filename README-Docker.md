# FaceFusion Intel UHD Graphics Docker 部署指南

本指南专为在中国境内使用Intel UHD Graphics的机器上部署FaceFusion而设计。

## 系统要求

- Ubuntu 18.04+ 或其他Linux发行版
- Intel UHD Graphics (集成显卡)
- Docker 20.10+
- Docker Compose 1.29+
- 至少4GB内存
- 至少10GB可用磁盘空间

## 快速部署

### 1. 准备环境

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 2. 手动部署（如果脚本失败）

#### 安装Docker（使用阿里云镜像源）

```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加Docker官方GPG密钥（使用阿里云镜像）
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 安装Docker Compose
sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 配置Docker镜像源

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "registry-mirrors": [
        "https://registry.cn-hangzhou.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

#### 用户权限配置

```bash
# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 重新登录或运行以下命令
newgrp docker
```

### 3. 构建和启动

```bash
# 创建必要目录
mkdir -p models cache output input

# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d
```

## 使用说明

### 访问Web界面

启动成功后，在浏览器中访问：
```
http://localhost:7860
```

### 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 进入容器
docker-compose exec facefusion bash
```

### 文件管理

- **输入文件**: 放置在 `./input/` 目录
- **输出文件**: 生成在 `./output/` 目录  
- **模型文件**: 缓存在 `./models/` 目录
- **临时缓存**: 存储在 `./cache/` 目录

## Intel GPU 优化配置

### 环境变量说明

```yaml
environment:
  - OPENVINO_DEVICE=GPU          # 使用Intel GPU
  - INTEL_OPENVINO_DIR=...       # OpenVINO路径
```

### 性能调优

1. **内存限制**: 根据系统内存调整 `docker-compose.yml` 中的内存限制
2. **并发设置**: Intel UHD Graphics建议使用单线程处理
3. **分辨率控制**: 建议先用较小分辨率测试

## 故障排除

### 常见问题

#### 1. Intel GPU未检测到

```bash
# 检查GPU设备
ls -la /dev/dri/

# 检查GPU驱动
lspci | grep -i intel

# 安装Intel GPU驱动
sudo apt-get install intel-media-va-driver-non-free
```

#### 2. 权限问题

```bash
# 检查用户组
groups $USER

# 添加到video组
sudo usermod -aG video $USER

# 重新登录
```

#### 3. 网络问题

```bash
# 测试镜像源连通性
curl -I https://mirrors.aliyun.com/pypi/simple/

# 手动配置DNS
echo "nameserver 223.5.5.5" | sudo tee /etc/resolv.conf
```

#### 4. 模型下载失败

```bash
# 手动下载模型
docker-compose run --rm facefusion python3 facefusion.py force-download

# 使用不同的下载源
docker-compose run --rm facefusion python3 facefusion.py force-download --download-provider github
```

### 日志分析

```bash
# 查看详细日志
docker-compose logs --tail=100 facefusion

# 查看系统资源使用
docker stats facefusion-intel-gpu
```

## 性能优化建议

### Intel UHD Graphics 特定优化

1. **分辨率限制**: 建议处理720p以下视频
2. **批处理**: 避免同时处理多个文件
3. **内存管理**: 监控内存使用，避免OOM
4. **温度控制**: 长时间运行注意散热

### 系统级优化

```bash
# 增加交换空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 优化内核参数
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

## 更新和维护

### 更新镜像

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build --no-cache

# 重启服务
docker-compose up -d
```

### 清理空间

```bash
# 清理Docker缓存
docker system prune -a

# 清理模型缓存
rm -rf ./cache/*
```

## 安全注意事项

1. **网络访问**: 默认绑定到所有接口，生产环境建议限制访问
2. **文件权限**: 注意输入输出目录的权限设置
3. **资源限制**: 设置合适的内存和CPU限制

## 支持和反馈

如遇到问题，请检查：

1. 系统日志: `journalctl -u docker`
2. 容器日志: `docker-compose logs`
3. GPU状态: `intel_gpu_top` (如果可用)

---

**注意**: Intel UHD Graphics性能有限，建议先用小文件测试效果和性能表现。