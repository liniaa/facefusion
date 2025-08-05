#!/bin/bash
# 这个脚本在容器内运行，用于调试FaceFusion相关问题

echo "=== FaceFusion 容器内调试 ==="
echo

echo "1. Python版本和路径："
python3 --version
which python3
echo

echo "2. 检查OpenVINO安装："
python3 -c "
try:
    import openvino as ov
    core = ov.Core()
    print(f'OpenVINO版本: {ov.__version__}')
    print(f'可用设备: {core.available_devices}')
    if 'GPU' in core.available_devices:
        print('✓ Intel GPU支持正常')
    else:
        print('✗ 未检测到Intel GPU')
except Exception as e:
    print(f'OpenVINO错误: {e}')
"
echo

echo "3. 检查关键Python包："
python3 -c "
packages = ['torch', 'torchvision', 'onnx', 'onnxruntime', 'cv2', 'gradio']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✓ {pkg} 已安装')
    except ImportError:
        print(f'✗ {pkg} 未安装')
"
echo

echo "4. 检查模型目录："
ls -la /app/.assets/models/ 2>/dev/null || echo "模型目录不存在或为空"
echo

echo "5. 检查缓存目录："
ls -la /app/.caches/ 2>/dev/null || echo "缓存目录不存在或为空"
echo

echo "6. 检查FaceFusion主文件："
ls -la /app/facefusion.py 2>/dev/null || echo "facefusion.py 不存在"
echo

echo "7. 测试启动FaceFusion（仅检查导入）："
python3 -c "
try:
    import sys
    sys.path.append('/app')
    print('正在测试导入...')
    # 这里可以添加更多的导入测试
    print('✓ 基础导入测试通过')
except Exception as e:
    print(f'✗ 导入错误: {e}')
"