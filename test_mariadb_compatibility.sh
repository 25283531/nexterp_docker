#!/bin/bash

set -e
echo "====================================="
echo "测试MariaDB兼容性和配置..."
echo "====================================="

# 检查MariaDB版本
echo "\n1. 检查MariaDB版本..."
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version | grep -oP 'MariaDB (\d+\.\d+)' | grep -oP '\d+\.\d+')
    echo "检测到的MariaDB版本: $MYSQL_VERSION"
    
    # 验证版本兼容性
    REQUIRED_VERSION="10.6"
    if (( $(echo "$MYSQL_VERSION >= $REQUIRED_VERSION" | bc -l) )); then
        echo "✓ 版本兼容性检查通过: $MYSQL_VERSION >= $REQUIRED_VERSION"
    else
        echo "✗ 版本兼容性检查失败: $MYSQL_VERSION < $REQUIRED_VERSION"
        exit 1
    fi
else
    echo "MariaDB客户端未安装"
fi

# 检查MariaDB配置
echo "\n2. 检查MariaDB配置..."
if [ -f "/etc/mysql/conf.d/erpnext.cnf" ]; then
    echo "✓ 找到ERPNext MariaDB配置文件"
    echo "配置内容:"
    cat /etc/mysql/conf.d/erpnext.cnf
else
    echo "✗ 未找到ERPNext MariaDB配置文件"
fi

# 检查数据目录权限
echo "\n3. 检查数据目录权限..."
if [ -d "/var/lib/mysql" ]; then
    echo "MySQL数据目录权限:"
    ls -la /var/lib/mysql | head -3
fi

# 检查连接参数
echo "\n4. 测试连接参数..."
echo "当前配置的MariaDB环境变量:"
echo "MARIADB_VERSION=${MARIADB_VERSION:-未设置}"

# 打印系统信息
echo "\n5. 系统信息..."
echo "操作系统: $(uname -a)"
echo "内存信息: $(free -h | head -2)"
echo "磁盘信息: $(df -h | grep /dev/sda1)"

echo "\n====================================="
echo "测试完成！"
echo "====================================="