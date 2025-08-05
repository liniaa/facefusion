#!/usr/bin/env python3
"""
测试依赖包兼容性脚本
用于验证 onnxruntime-openvino 版本兼容性
"""

import sys
import subprocess
import pkg_resources

def test_package_availability(package_name, versions):
    """测试包的可用版本"""
    print(f"\n=== 测试 {package_name} 可用版本 ===")
    
    for version in versions:
        try:
            # 尝试检查版本是否可用
            result = subprocess.run([
                sys.executable, '-m', 'pip', 'index', 'versions', f'{package_name}=={version}'
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print(f"✓ {package_name}=={version} - 可用")
            else:
                print(f"✗ {package_name}=={version} - 不可用")
                
        except Exception as e:
            print(f"✗ {package_name}=={version} - 检查失败: {e}")

def check_installed_packages():
    """检查已安装的相关包"""
    print("\n=== 已安装的相关包 ===")
    
    packages_to_check = [
        'onnxruntime',
        'onnxruntime-openvino', 
        'openvino',
        'numpy',
        'opencv-python'
    ]
    
    for package in packages_to_check:
        try:
            version = pkg_resources.get_distribution(package).version
            print(f"✓ {package}: {version}")
        except pkg_resources.DistributionNotFound:
            print(f"✗ {package}: 未安装")

def main():
    print("FaceFusion 依赖兼容性测试")
    print("=" * 50)
    
    # 检查已安装包
    check_installed_packages()
    
    # 测试 onnxruntime-openvino 可用版本
    openvino_versions = ['1.15.0', '1.16.0', '1.17.1', '1.18.0', '1.19.0', '1.20.0', '1.22.0']
    test_package_availability('onnxruntime-openvino', openvino_versions)
    
    print(f"\nPython 版本: {sys.version}")
    print("测试完成!")

if __name__ == "__main__":
    main()