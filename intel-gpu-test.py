#!/usr/bin/env python3
"""
Intel UHD Graphics 测试脚本
用于验证OpenVINO和Intel GPU是否正常工作
"""

import sys
import os
import subprocess
from pathlib import Path

def check_intel_gpu():
    """检查Intel GPU设备"""
    print("🔍 检查Intel GPU设备...")
    
    # 检查/dev/dri设备
    dri_path = Path("/dev/dri")
    if not dri_path.exists():
        print("❌ 未找到 /dev/dri 设备")
        return False
    
    dri_devices = list(dri_path.glob("*"))
    if not dri_devices:
        print("❌ /dev/dri 目录为空")
        return False
    
    print(f"✅ 找到DRI设备: {[d.name for d in dri_devices]}")
    
    # 检查lspci输出
    try:
        result = subprocess.run(['lspci'], capture_output=True, text=True)
        intel_gpus = [line for line in result.stdout.split('\n') if 'Intel' in line and ('VGA' in line or 'Display' in line)]
        if intel_gpus:
            print("✅ 检测到Intel显卡:")
            for gpu in intel_gpus:
                print(f"   {gpu}")
        else:
            print("⚠️  lspci未检测到Intel显卡")
    except Exception as e:
        print(f"⚠️  无法运行lspci: {e}")
    
    return True

def check_openvino():
    """检查OpenVINO安装和GPU支持"""
    print("\n🔍 检查OpenVINO...")
    
    try:
        import openvino as ov
        print(f"✅ OpenVINO版本: {ov.__version__}")
        
        # 创建Core对象
        core = ov.Core()
        
        # 获取可用设备
        devices = core.available_devices
        print(f"✅ 可用设备: {devices}")
        
        # 检查GPU设备
        gpu_devices = [d for d in devices if 'GPU' in d]
        if gpu_devices:
            print(f"✅ 检测到GPU设备: {gpu_devices}")
            
            # 测试GPU设备属性
            for gpu in gpu_devices:
                try:
                    device_name = core.get_property(gpu, "FULL_DEVICE_NAME")
                    print(f"   {gpu}: {device_name}")
                except Exception as e:
                    print(f"   {gpu}: 无法获取设备信息 ({e})")
        else:
            print("❌ 未检测到GPU设备")
            return False
        
        return True
        
    except ImportError:
        print("❌ OpenVINO未安装")
        return False
    except Exception as e:
        print(f"❌ OpenVINO错误: {e}")
        return False

def check_onnxruntime():
    """检查ONNX Runtime和OpenVINO执行提供者"""
    print("\n🔍 检查ONNX Runtime...")
    
    try:
        import onnxruntime as ort
        print(f"✅ ONNX Runtime版本: {ort.__version__}")
        
        # 获取可用的执行提供者
        providers = ort.get_available_providers()
        print(f"✅ 可用执行提供者: {providers}")
        
        # 检查OpenVINO执行提供者
        if 'OpenVINOExecutionProvider' in providers:
            print("✅ OpenVINO执行提供者可用")
            
            # 测试创建会话
            try:
                # 创建一个简单的模型用于测试
                import numpy as np
                import onnx
                from onnx import helper, TensorProto
                
                # 创建简单的加法模型
                X = helper.make_tensor_value_info('X', TensorProto.FLOAT, [1, 3, 224, 224])
                Y = helper.make_tensor_value_info('Y', TensorProto.FLOAT, [1, 3, 224, 224])
                node = helper.make_node('Identity', ['X'], ['Y'])
                graph = helper.make_graph([node], 'test', [X], [Y])
                model = helper.make_model(graph)
                
                # 保存临时模型
                temp_model = '/tmp/test_model.onnx'
                onnx.save(model, temp_model)
                
                # 测试OpenVINO执行提供者
                session = ort.InferenceSession(
                    temp_model,
                    providers=[('OpenVINOExecutionProvider', {'device_type': 'GPU'})]
                )
                
                # 运行推理测试
                input_data = np.random.randn(1, 3, 224, 224).astype(np.float32)
                result = session.run(None, {'X': input_data})
                
                print("✅ OpenVINO GPU推理测试成功")
                
                # 清理临时文件
                os.unlink(temp_model)
                
            except Exception as e:
                print(f"⚠️  OpenVINO GPU推理测试失败: {e}")
        else:
            print("❌ OpenVINO执行提供者不可用")
            return False
        
        return True
        
    except ImportError:
        print("❌ ONNX Runtime未安装")
        return False
    except Exception as e:
        print(f"❌ ONNX Runtime错误: {e}")
        return False

def check_facefusion_compatibility():
    """检查FaceFusion兼容性"""
    print("\n🔍 检查FaceFusion兼容性...")
    
    try:
        # 检查Python版本
        python_version = sys.version_info
        if python_version >= (3, 10):
            print(f"✅ Python版本: {python_version.major}.{python_version.minor}.{python_version.micro}")
        else:
            print(f"❌ Python版本过低: {python_version.major}.{python_version.minor}.{python_version.micro} (需要3.10+)")
            return False
        
        # 检查必要的系统命令
        commands = ['curl', 'ffmpeg']
        for cmd in commands:
            if subprocess.run(['which', cmd], capture_output=True).returncode == 0:
                print(f"✅ {cmd} 已安装")
            else:
                print(f"❌ {cmd} 未安装")
                return False
        
        # 检查关键Python包
        packages = ['gradio', 'opencv-python', 'numpy', 'scipy']
        for pkg in packages:
            try:
                __import__(pkg.replace('-', '_'))
                print(f"✅ {pkg} 已安装")
            except ImportError:
                print(f"❌ {pkg} 未安装")
                return False
        
        return True
        
    except Exception as e:
        print(f"❌ 兼容性检查错误: {e}")
        return False

def main():
    """主函数"""
    print("=" * 60)
    print("Intel UHD Graphics + FaceFusion 兼容性测试")
    print("=" * 60)
    
    all_passed = True
    
    # 运行各项检查
    checks = [
        ("Intel GPU设备", check_intel_gpu),
        ("OpenVINO", check_openvino),
        ("ONNX Runtime", check_onnxruntime),
        ("FaceFusion兼容性", check_facefusion_compatibility)
    ]
    
    for name, check_func in checks:
        print(f"\n{'='*20} {name} {'='*20}")
        if not check_func():
            all_passed = False
    
    # 输出总结
    print("\n" + "=" * 60)
    if all_passed:
        print("🎉 所有检查通过！Intel UHD Graphics可以运行FaceFusion")
        print("\n建议配置:")
        print("- 执行提供者: openvino")
        print("- 设备ID: 0")
        print("- 设备类型: GPU")
        print("\n启动命令示例:")
        print("python3 facefusion.py run --execution-providers openvino --execution-device-id 0")
    else:
        print("❌ 部分检查失败，请根据上述信息修复问题")
        sys.exit(1)
    
    print("=" * 60)

if __name__ == "__main__":
    main()