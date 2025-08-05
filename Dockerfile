# 使用Ubuntu 22.04基础镜像（原生支持Python 3.10）
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# 设置工作目录
WORKDIR /app

# 配置国内APT镜像源（提高下载速度）
RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list && \
    sed -i 's@//.*security.ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list

# 安装系统依赖（Ubuntu 22.04原生支持Python 3.10）
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3-pip \
    curl \
    wget \
    git \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    && rm -rf /var/lib/apt/lists/*

# 创建Python符号链接
RUN ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.10 /usr/bin/python

# 配置pip使用阿里云镜像源
RUN mkdir -p ~/.pip && \
    echo "[global]" > ~/.pip/pip.conf && \
    echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> ~/.pip/pip.conf && \
    echo "trusted-host = mirrors.aliyun.com" >> ~/.pip/pip.conf

# 升级pip
RUN python3 -m pip install --upgrade pip

# 安装Intel OpenVINO运行时 (使用清华镜像源)
RUN pip3 install openvino==2023.3.0 -i https://pypi.tuna.tsinghua.edu.cn/simple/

# 复制项目文件
COPY . /app/

# 安装Python依赖（使用Docker专用依赖文件）
RUN pip3 install -r requirements-docker.txt -i https://mirrors.aliyun.com/pypi/simple/

# 安装额外的Intel GPU支持依赖
RUN pip3 install onnxruntime-openvino==1.22.0 -i https://mirrors.aliyun.com/pypi/simple/

# 创建模型缓存目录
RUN mkdir -p /app/.assets/models && \
    mkdir -p /app/.caches

# 设置Intel GPU环境变量
ENV OPENVINO_DEVICE=GPU
ENV INTEL_OPENVINO_DIR=/usr/local/lib/python3.10/dist-packages/openvino
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/openvino/libs:$LD_LIBRARY_PATH

# 暴露端口
EXPOSE 7860

# 创建启动脚本
RUN echo '#!/bin/bash\n\
echo "正在启动FaceFusion..."\n\
echo "检测Intel GPU支持..."\n\
python3 -c "import openvino as ov; core = ov.Core(); print(f\"可用设备: {core.available_devices}\")"\n\
echo "启动FaceFusion Web界面..."\n\
python3 facefusion.py run \\\n\
    --execution-providers openvino \\\n\
    --execution-device-id 0 \\\n\
    --ui-layouts default \\\n\
    --server-host 0.0.0.0 \\\n\
    --server-port 7860\n' > /app/start.sh && \
    chmod +x /app/start.sh

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# 启动命令
CMD ["/app/start.sh"]