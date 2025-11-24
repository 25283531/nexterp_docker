#!/bin/bash

# 验证installdata目录结构
echo "===== 验证installdata目录结构 ======"
ls -la ./installdata/

# 验证文件是否存在
echo "\n===== 验证脚本文件是否存在 ======"
if [ -f "./installdata/install-erpnext15.sh" ]; then
    echo "✓ install-erpnext15.sh 文件存在"
else
    echo "✗ install-erpnext15.sh 文件不存在"
fi

if [ -f "./installdata/test_mariadb_compatibility.sh" ]; then
    echo "✓ test_mariadb_compatibility.sh 文件存在"
else
    echo "✗ test_mariadb_compatibility.sh 文件不存在"
fi

# 验证脚本中的路径引用
echo "\n===== 验证脚本中的路径引用 ======"
echo "测试脚本在install-erpnext15.sh中的路径引用:"
grep -n "/installdata/test_mariadb_compatibility.sh" ./installdata/install-erpnext15.sh || echo "未找到路径引用"

echo "\n===== 验证Dockerfile中的路径引用 ======"
echo "installdata目录在Dockerfile中的COPY引用:"
grep -n "COPY ./installdata" ./Dockerfile || echo "未找到COPY引用"

echo "\n路径验证完成！"