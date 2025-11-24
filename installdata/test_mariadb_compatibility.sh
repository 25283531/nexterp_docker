#!/bin/bash

# 设置详细输出，帮助调试
set -x

# 保存当前目录以便调试
echo "当前工作目录: $(pwd)"

# 检查环境变量
echo "环境变量:"
env | grep -E 'MARIADB|MYSQL|DOCKER'

set -e
echo "====================================="
echo "测试MariaDB兼容性和配置..."
echo "====================================="

# 检查MariaDB版本
echo "\n1. 检查MariaDB版本..."

# 检查MariaDB命令是否可用
echo "检查MariaDB命令是否可用..."
which mysql || echo "mysql命令不可用"

# 尝试多种方式获取MariaDB版本
echo "尝试通过mysql获取版本..."
FULL_MYSQL_OUTPUT=$(mysql --version 2>&1)
echo "mysql --version 输出: $FULL_MYSQL_OUTPUT"

if command -v mysql &> /dev/null; then
    # 尝试不同的正则表达式模式来提取版本号
    echo "尝试提取MariaDB版本号..."
    MYSQL_VERSION=$(echo $FULL_MYSQL_OUTPUT | grep -oP 'MariaDB (\d+\.\d+(\.\d+)?)' | grep -oP '\d+\.\d+(\.\d+)?')
    if [ -z "$MYSQL_VERSION" ]; then
        # 尝试另一种模式
        MYSQL_VERSION=$(echo $FULL_MYSQL_OUTPUT | grep -oP '\d+\.\d+(\.\d+)?')
    fi
    
    echo "提取的MariaDB版本: $MYSQL_VERSION"
    
    # 验证版本兼容性 - 使用纯bash方式进行版本比较
    REQUIRED_VERSION="10.6"
    
    if [ -z "$MYSQL_VERSION" ]; then
        echo "警告：无法从输出中提取有效版本号，但将继续检查..."
    else
        # 将版本号转换为整数进行比较
        ver1=$(echo $MYSQL_VERSION | tr '.' '0')
        ver2=$(echo $REQUIRED_VERSION | tr '.' '0')
        
        echo "转换后的版本整数(当前): $ver1"
        echo "转换后的版本整数(要求): $ver2"
        
        # 确保版本号长度相同
        max_len=$(( ${#ver1} > ${#ver2} ? ${#ver1} : ${#ver2} ))
        ver1=$(printf "%${max_len}s" "$ver1" | tr ' ' '0')
        ver2=$(printf "%${max_len}s" "$ver2" | tr ' ' '0')
        
        echo "标准化后的版本整数(当前): $ver1"
        echo "标准化后的版本整数(要求): $ver2"
        
        if [ "$ver1" -ge "$ver2" ]; then
            echo "✓ 版本兼容性检查通过: $MYSQL_VERSION >= $REQUIRED_VERSION"
        else
            echo "✗ 版本兼容性检查失败: $MYSQL_VERSION < $REQUIRED_VERSION"
            exit 1
        fi
    fi
else
    echo "MariaDB客户端未安装"
    # 在Docker环境中，我们允许继续执行，因为可能是系统还未完全配置
    if [ -f "/.dockerenv" ] || [[ "$inDocker" == "yes" ]]; then
        echo "在Docker环境中，继续执行安装..."
    else
        exit 1
    fi
fi

# 尝试通过mysqld获取版本（如果可用）
echo "尝试通过mysqld获取版本..."
if command -v mysqld &> /dev/null; then
    MYSQLD_VERSION=$(mysqld --version 2>&1)
    echo "mysqld --version 输出: $MYSQLD_VERSION"
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