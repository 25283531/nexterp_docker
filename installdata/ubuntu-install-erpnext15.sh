#!/bin/bash

# ERPNext 15 Ubuntu 安装脚本 - 单行命令安装版本
# 使用方法1: curl -fsSL https://example.com/ubuntu-install-erpnext15.sh | bash -s -- [参数]
# 使用方法2: sudo bash ubuntu-install-erpnext15.sh [参数]

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 定义进度变量
TOTAL_STEPS=8
CURRENT_STEP=0

# 显示进度条
show_progress() {
    local step_name=$1
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local bar_length=50
    local filled_length=$((percentage * bar_length / 100))
    
    # 创建进度条
    local bar=""
    for ((i=0; i<filled_length; i++)); do
        bar="${bar}█"
    done
    for ((i=filled_length; i<bar_length; i++)); do
        bar="${bar}░"
    done
    
    # 显示进度条
    printf "\r${CYAN}[%-${bar_length}s] ${percentage}%% ${step_name}${NC}" "$bar"
    
    # 如果是最后一步，换行
    if [[ $CURRENT_STEP -eq $TOTAL_STEPS ]]; then
        echo ""
    fi
}

# 日志文件
LOG_FILE="/tmp/erpnext_install_$(date +%Y%m%d_%H%M%S).log"

set -e

# 错误检查函数
check_error() {
  if [ $1 -ne 0 ]; then
    echo -e "${RED}错误: 第 $2 步执行失败，请查看日志 $LOG_FILE 获取详细信息${NC}"
    exit $1
  fi
}

# 日志记录函数
log() {
  local level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO")
      # 输出到控制台 (不与进度条冲突)
      if [[ $CURRENT_STEP -eq 0 ]]; then
        echo -e "${BLUE}[INFO]${NC} $message"
      else
        # 如果有进度条在显示，先换行再显示日志
        echo ""
        echo -e "${BLUE}[INFO]${NC} $message"
        # 重新显示进度条
        local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        local bar_length=50
        local filled_length=$((percentage * bar_length / 100))
        local bar=""
        for ((i=0; i<filled_length; i++)); do
            bar="${bar}█"
        done
        printf "\r${CYAN}[%-${bar_length}s] ${percentage}%%${NC}" "$bar"
      fi
      echo "[$timestamp] [INFO] $message" >> $LOG_FILE
      ;;
    "SUCCESS")
      # 成功信息始终显示完整
      echo -e "${GREEN}[SUCCESS]${NC} $message"
      echo "[$timestamp] [SUCCESS] $message" >> $LOG_FILE
      ;;
    "WARNING")
      # 警告信息处理与普通信息相同
      if [[ $CURRENT_STEP -eq 0 ]]; then
        echo -e "${YELLOW}[WARNING]${NC} $message"
      else
        echo ""
        echo -e "${YELLOW}[WARNING]${NC} $message"
        # 重新显示进度条
        local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
        local bar_length=50
        local filled_length=$((percentage * bar_length / 100))
        local bar=""
        for ((i=0; i<filled_length; i++)); do
            bar="${bar}█"
        done
        printf "\r${CYAN}[%-${bar_length}s] ${percentage}%%${NC}" "$bar"
      fi
      echo "[$timestamp] [WARNING] $message" >> $LOG_FILE
      ;;
    "ERROR")
      # 错误信息始终显示完整
      echo -e "${RED}[ERROR]${NC} $message"
      echo "[$timestamp] [ERROR] $message" >> $LOG_FILE
      ;;
  esac
}

# 默认参数设置
mariadbRootPassword="admin"
adminPassword="admin"
installDir="frappe-bench"
userName="frappe"
siteName="erp.example.com"
webPort="8000"
benchVersion=""
frappeBranch="version-15"
erpnextBranch="version-15"
altAptSources="no"
quiet="no"
productionMode="no"

# 创建日志文件
touch $LOG_FILE
log "INFO" "开始安装ERPNext 15，日志文件: $LOG_FILE"

# 路径标准化函数
normalize_path() {
    # 移除多余的斜杠
    local path="$1"
    path=$(echo "$path" | sed 's/\/\+/\//g')
    # 移除末尾的斜杠（如果有）
    path=$(echo "$path" | sed 's/\/$//' || echo "$path")
    echo "$path"
}

# 显示帮助信息
show_help() {
    echo "ERPNext 15 Ubuntu 安装脚本"
    echo "使用方法: curl -fsSL https://example.com/ubuntu-install-erpnext15.sh | bash -s -- [选项]"
    echo ""
    echo "选项:"
    echo "  --db-password <password>    数据库root密码 (默认: admin)"
    echo "  --admin-password <password> 管理员密码 (默认: admin)"
    echo "  --install-dir <dir>         安装目录 (默认: frappe-bench)"
    echo "  --user <username>           创建的用户名 (默认: frappe)"
    echo "  --site <sitename>           站点名称 (默认: erp.example.com)"
    echo "  --port <port>               Web端口 (默认: 8000)"
    echo "  --production                生产模式安装"
    echo "  --quiet                     静默模式，不提示确认"
    echo "  --use-mirrors               使用国内镜像源加速安装"
    echo "  -h, --help                  显示此帮助信息"
}

# 参数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db-password)
                mariadbRootPassword="$2"
                shift 2
                ;;
            --admin-password)
                adminPassword="$2"
                shift 2
                ;;
            --install-dir)
                installDir="$2"
                shift 2
                ;;
            --user)
                userName="$2"
                shift 2
                ;;
            --site)
                siteName="$2"
                shift 2
                ;;
            --port)
                webPort="$2"
                shift 2
                ;;
            --production)
                productionMode="yes"
                shift
                ;;
            --quiet)
                quiet="yes"
                shift
                ;;
            --use-mirrors)
                altAptSources="yes"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 计算完整安装路径
    userHome="/home/$userName"
    fullInstallDir="$userHome/$installDir"
    fullInstallDir=$(normalize_path "$fullInstallDir")
}

# 检查系统环境
check_environment() {
    log "INFO" "正在检查系统环境..."
    
    # 检查Ubuntu版本
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        log "WARNING" "此脚本专为Ubuntu 22.04设计，当前系统可能不兼容。"
        if [[ "$quiet" != "yes" ]]; then
            read -p "是否继续安装? (y/n): " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                log "ERROR" "用户取消安装"
                exit 1
            fi
        fi
    else
        log "INFO" "检测到Ubuntu 22.04，符合推荐版本"
    fi
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "此脚本需要以root用户权限运行。"
        exit 1
    fi
    
    log "SUCCESS" "系统环境检查完成。"
}

# 显示安装信息
show_install_info() {
    echo "========================================"
    echo "ERPNext 15 安装配置信息"
    echo "========================================"
    echo "数据库root密码: ********"
    echo "管理员密码: ********"
    echo "安装目录: $installDir"
    echo "安装用户: $userName"
    echo "站点名称: $siteName"
    echo "Web端口: $webPort"
    echo "是否使用国内镜像: $altAptSources"
    echo "安装模式: $([[ "$productionMode" == "yes" ]] && echo "生产模式" || echo "开发模式")"
    echo "========================================"
    
    if [[ "$quiet" != "yes" ]]; then
        read -p "确认安装配置? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            exit 1
        fi
    fi
}

# 安装依赖包
install_dependencies() {
    log "INFO" "开始安装依赖包..."
    
    # 修改安装源加速国内安装
    if [[ "$altAptSources" == "yes" ]]; then
        log "INFO" "正在配置国内镜像源..."
        # 备份原sources.list
        if [[ ! -e /etc/apt/sources.list.bak ]]; then
            cp /etc/apt/sources.list /etc/apt/sources.list.bak >> $LOG_FILE 2>&1
            check_error $? "备份源列表"
        fi
        
        # 替换为清华大学镜像源
        bash -c "cat << EOF > /etc/apt/sources.list
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF" >> $LOG_FILE 2>&1
        check_error $? "配置国内镜像源"
        log "INFO" "apt已修改为国内源"
    fi
    
    # 更新apt并安装必要的包
    log "INFO" "正在更新apt..."
    apt update -y >> $LOG_FILE 2>&1
    check_error $? "更新apt包列表"
    
    log "INFO" "正在升级系统包..."
    DEBIAN_FRONTEND=noninteractive apt upgrade -y >> $LOG_FILE 2>&1
    check_error $? "升级系统包"
    
    log "INFO" "正在安装基础软件包..."
    DEBIAN_FRONTEND=noninteractive apt install -y \
        ca-certificates \
        sudo \
        locales \
        tzdata \
        cron \
        wget \
        curl \
        python3-dev \
        python3-venv \
        python3-setuptools \
        python3-pip \
        python3-testresources \
        git \
        software-properties-common \
        mariadb-server \
        mariadb-client \
        libmysqlclient-dev \
        xvfb \
        libfontconfig \
        wkhtmltopdf \
        supervisor \
        pkg-config \
        build-essential \
        libcairo2-dev \
        libpango1.0-dev \
        libjpeg-dev \
        libgif-dev \
        nginx \
        gettext-base >> $LOG_FILE 2>&1
    check_error $? "安装基础软件包"
    
    # 设置pip镜像源
    log "INFO" "正在配置pip镜像源..."
    mkdir -p /root/.pip >> $LOG_FILE 2>&1
    check_error $? "创建pip配置目录"
    
    cat > /root/.pip/pip.conf << EOF
[global]
index-url=https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=mirrors.tuna.tsinghua.edu.cn
EOF
    
    # 升级pip
    log "INFO" "正在升级pip..."
    python3 -m pip install --upgrade pip >> $LOG_FILE 2>&1
    check_error $? "升级pip"
    
    python3 -m pip install --upgrade setuptools cryptography psutil >> $LOG_FILE 2>&1
    check_error $? "安装Python工具包"
    
    # 创建软链接
    log "INFO" "创建python和pip软链接..."
    ln -sf /usr/bin/python3 /usr/bin/python >> $LOG_FILE 2>&1
    ln -sf /usr/bin/pip3 /usr/bin/pip >> $LOG_FILE 2>&1
    
    log "SUCCESS" "依赖包安装完成。"
}

# 配置数据库
configure_database() {
    log "INFO" "开始配置数据库..."
    
    # 配置MariaDB
    log "INFO" "正在配置MariaDB..."
    
    # 检查并修改数据库配置文件
    if ! grep -q "# ERPNext install script added" /etc/mysql/my.cnf 2>/dev/null; then
        # 如果my.cnf不存在或不可写，尝试修改mariadb.conf.d目录下的配置
        if [[ -d "/etc/mysql/mariadb.conf.d" ]]; then
            log "INFO" "在mariadb.conf.d目录下创建配置文件..."
            config_file="/etc/mysql/mariadb.conf.d/99-erpnext.cnf"
            cat > "$config_file" << EOF
# ERPNext install script added
[mysqld]
character-set-client-handshake=FALSE
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
bind-address=0.0.0.0
max_connections=100
innodb-file-format=barracuda
innodb-file-per-table=1
innodb-large-prefix=1
skip-name-resolve
EOF
            check_error $? "创建MariaDB配置文件"
            log "INFO" "已在 $config_file 中添加ERPNext所需的数据库配置"
        else
            log "INFO" "修改my.cnf文件..."
            echo "# ERPNext install script added" >> /etc/mysql/my.cnf
            echo "[mysqld]" >> /etc/mysql/my.cnf
            echo "character-set-client-handshake=FALSE" >> /etc/mysql/my.cnf
            echo "character-set-server=utf8mb4" >> /etc/mysql/my.cnf
            echo "collation-server=utf8mb4_unicode_ci" >> /etc/mysql/my.cnf
            echo "bind-address=0.0.0.0" >> /etc/mysql/my.cnf
            echo "max_connections=100" >> /etc/mysql/my.cnf
            echo "innodb-file-format=barracuda" >> /etc/mysql/my.cnf
            echo "innodb-file-per-table=1" >> /etc/mysql/my.cnf
            echo "innodb-large-prefix=1" >> /etc/mysql/my.cnf
            echo "skip-name-resolve" >> /etc/mysql/my.cnf
            check_error $? "修改my.cnf文件"
        fi
    else
        log "INFO" "数据库配置文件已存在，跳过配置"
    fi
    
    # 重启MariaDB服务
    log "INFO" "正在重启MariaDB服务..."
    systemctl restart mysql || systemctl restart mariadb >> $LOG_FILE 2>&1
    check_error $? "重启MariaDB服务"
    
    # 等待服务启动
    log "INFO" "等待MariaDB服务启动..."
    sleep 5
    
    # 设置root密码和权限
    log "INFO" "正在设置数据库root密码和权限..."
    
    # 首先尝试无密码登录并设置密码
    mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mariadbRootPassword}';" 2>/dev/null || {
        # 如果失败，尝试使用debian-sys-maint用户
        if [[ -f /etc/mysql/debian.cnf ]]; then
            log "INFO" "使用debian-sys-maint用户设置root密码..."
            deb_user=$(grep -m 1 user /etc/mysql/debian.cnf | cut -d'=' -f2 | tr -d ' ')
            deb_pass=$(grep -m 1 password /etc/mysql/debian.cnf | cut -d'=' -f2 | tr -d ' ')
            mysql -u"$deb_user" -p"$deb_pass" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mariadbRootPassword}';" 2>/dev/null || {
                # 如果仍然失败，尝试使用mysqladmin
                log "INFO" "使用mysqladmin设置root密码..."
                mysqladmin -u root password "${mariadbRootPassword}" 2>/dev/null || {
                    log "WARNING" "设置root密码失败，尝试其他方法"
                }
            }
        fi
    }
    
    # 验证密码设置
    if mysql -uroot -p"${mariadbRootPassword}" -e "SELECT 1;" >/dev/null 2>&1; then
        log "SUCCESS" "数据库root密码设置成功"
        
        # 清理旧的root用户记录
        log "INFO" "清理旧的root用户记录..."
        mysql -u root -p"${mariadbRootPassword}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> $LOG_FILE 2>&1 || {
            log "WARNING" "清理root用户记录失败"
        }
        
        # 配置远程访问权限
        log "INFO" "配置远程访问权限..."
        mysql -u root -p"${mariadbRootPassword}" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${mariadbRootPassword}' WITH GRANT OPTION;" >> $LOG_FILE 2>&1 || {
            log "WARNING" "配置远程访问权限失败"
        }
        
        # 刷新权限表
        log "INFO" "刷新权限表..."
        mysql -u root -p"${mariadbRootPassword}" -e "FLUSH PRIVILEGES;" >> $LOG_FILE 2>&1
        check_error $? "刷新MySQL权限"
        
        # 更新debian.cnf文件
        log "INFO" "更新debian.cnf文件..."
        if [ -f /etc/mysql/debian.cnf ]; then
            sed -i "s/^password.*$/password='${mariadbRootPassword}'/" /etc/mysql/debian.cnf >> $LOG_FILE 2>&1
            check_error $? "更新debian.cnf文件"
        else
            log "WARNING" "debian.cnf文件不存在"
        fi
    else
        log "WARNING" "无法验证root密码设置，请确保密码正确"
    fi
    
    # 确保MariaDB服务自动启动
    log "INFO" "设置MariaDB服务自动启动..."
    systemctl enable mysql || systemctl enable mariadb >> $LOG_FILE 2>&1
    check_error $? "设置MariaDB自启动"
    
    log "SUCCESS" "数据库配置完成。"
}

# 安装Node.js和Redis
install_nodejs_redis() {
    log "INFO" "开始安装Node.js和Redis..."
    
    # 安装Redis
    log "INFO" "正在安装Redis..."
    # 清理可能的旧配置
    log "INFO" "清理可能的旧Redis配置..."
    rm -rf /var/lib/redis /etc/redis /etc/default/redis-server /etc/init.d/redis-server >> $LOG_FILE 2>&1
    
    # 添加Redis官方仓库
    log "INFO" "添加Redis官方仓库..."
    rm -f /usr/share/keyrings/redis-archive-keyring.gpg >> $LOG_FILE 2>&1
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg >> $LOG_FILE 2>&1
    check_error $? "下载Redis GPG密钥"
    
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list >> $LOG_FILE 2>&1
    
    # 安装Redis
    log "INFO" "更新apt并安装Redis..."
    apt update >> $LOG_FILE 2>&1
    check_error $? "更新apt包列表"
    
    DEBIAN_FRONTEND=noninteractive apt install -y redis-tools redis-server redis >> $LOG_FILE 2>&1
    check_error $? "安装Redis"
    
    # 启动Redis服务
    log "INFO" "启动Redis服务..."
    systemctl enable redis-server >> $LOG_FILE 2>&1
    check_error $? "设置Redis自启动"
    
    systemctl start redis-server >> $LOG_FILE 2>&1
    check_error $? "启动Redis服务"
    
    # 检查Redis版本
    redis_version=$(redis-server -v 2>> $LOG_FILE)
    log "INFO" "已安装Redis: $redis_version"
    
    # 安装Node.js 20
    log "INFO" "正在安装Node.js 20..."
    
    # 下载最新的Node.js 20版本
    log "INFO" "获取最新的Node.js 20版本链接..."
    nodejsLink=$(curl -sL https://registry.npmmirror.com/-/binary/node/latest-v20.x/ 2>> $LOG_FILE | grep -oE "https?://[a-zA-Z0-9\._&=@$%?~#-]*node-v20\.[0-9][0-9]\.[0-9]{1,2}"-linux-x64.tar.xz | tail -1)
    
    if [[ -z "$nodejsLink" ]]; then
        # 如果无法获取最新版本链接，使用固定版本
        log "WARNING" "无法获取最新Node.js版本，使用固定版本..."
        nodejsLink="https://registry.npmmirror.com/-/binary/node/v20.11.0/node-v20.11.0-linux-x64.tar.xz"
    fi
    
    nodejsFileName=${nodejsLink##*/}
    nodejsVer=${nodejsFileName%%.tar.xz}
    nodejsVer=${nodejsVer#node-}
    
    log "INFO" "Node.js版本: $nodejsVer"
    log "INFO" "下载链接: $nodejsLink"
    
    # 下载并安装Node.js
    log "INFO" "下载Node.js..."
    wget $nodejsLink -P /tmp/ >> $LOG_FILE 2>&1
    check_error $? "下载Node.js"
    
    log "INFO" "安装Node.js..."
    mkdir -p /usr/local/lib/nodejs >> $LOG_FILE 2>&1
    check_error $? "创建Node.js安装目录"
    
    tar -xJf /tmp/${nodejsFileName} -C /usr/local/lib/nodejs/ >> $LOG_FILE 2>&1
    check_error $? "解压Node.js"
    
    mv /usr/local/lib/nodejs/${nodejsFileName%%.tar.xz} /usr/local/lib/nodejs/${nodejsVer} >> $LOG_FILE 2>&1
    check_error $? "移动Node.js文件"
    
    # 设置环境变量
    log "INFO" "设置Node.js环境变量..."
    echo "export PATH=/usr/local/lib/nodejs/${nodejsVer}/bin:\$PATH" > /etc/profile.d/nodejs.sh
    echo "export PATH=/usr/local/lib/nodejs/${nodejsVer}/bin:\$PATH" >> /root/.bashrc
    
    # 立即应用环境变量
    export PATH=/usr/local/lib/nodejs/${nodejsVer}/bin:$PATH
    
    # 检查Node.js版本
    node_version=$(node -v 2>> $LOG_FILE)
    log "INFO" "已安装Node.js: $node_version"
    
    # 配置npm镜像源
    log "INFO" "配置npm镜像源..."
    npm config set registry https://registry.npmmirror.com -g >> $LOG_FILE 2>&1
    check_error $? "配置npm镜像源"
    
    # 升级npm
    log "INFO" "正在升级npm..."
    npm install -g npm@10 >> $LOG_FILE 2>&1
    check_error $? "升级npm"
    
    # 安装yarn
    log "INFO" "正在安装yarn..."
    npm install -g yarn >> $LOG_FILE 2>&1
    check_error $? "安装yarn"
    
    # 配置yarn镜像源
    log "INFO" "配置yarn镜像源..."
    yarn config set registry https://registry.npmmirror.com -g >> $LOG_FILE 2>&1
    check_error $? "配置yarn镜像源"
    
    log "SUCCESS" "Node.js和Redis安装完成。"
}

# 创建用户和目录
create_user_and_directory() {
    log "INFO" "开始创建用户和目录..."
    
    # 创建用户组
    log "INFO" "正在创建用户组..."
    if ! getent group "$userName" >/dev/null 2>&1; then
        gid=1000
        # 查找可用的GID
        while getent group "$gid" >/dev/null 2>&1; do
            gid=$((gid + 1))
        done
        groupadd -g "$gid" "$userName" >> $LOG_FILE 2>&1
        check_error $? "创建用户组"
        log "INFO" "已创建用户组 $userName，GID: $gid"
    else
        log "INFO" "用户组 $userName 已存在"
        gid=$(getent group "$userName" | cut -d: -f3)
    fi
    
    # 创建用户
    log "INFO" "正在创建用户..."
    if ! getent passwd "$userName" >/dev/null 2>&1; then
        uid=1000
        # 查找可用的UID
        while getent passwd "$uid" >/dev/null 2>&1; do
            uid=$((uid + 1))
        done
        useradd --no-log-init -r -m -u "$uid" -g "$gid" -G sudo -s /bin/bash "$userName" >> $LOG_FILE 2>&1
        check_error $? "创建用户"
        log "INFO" "已创建用户 $userName，UID: $uid"
    else
        log "INFO" "用户 $userName 已存在"
        uid=$(getent passwd "$userName" | cut -d: -f3)
    fi
    
    # 配置sudo权限
    log "INFO" "正在配置sudo权限..."
    if ! grep -q "^$userName" /etc/sudoers; then
        echo "$userName ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        check_error $? "配置sudo权限"
        log "INFO" "已为用户 $userName 添加sudo权限"
    else
        log "INFO" "用户 $userName 已具有sudo权限"
    fi
    
    # 创建安装目录
    log "INFO" "正在创建安装目录..."
    mkdir -p "$fullInstallDir" >> $LOG_FILE 2>&1
    check_error $? "创建安装目录"
    
    # 复制pip配置到用户目录
    log "INFO" "正在配置用户pip镜像源..."
    mkdir -p "/home/$userName/.pip" >> $LOG_FILE 2>&1
    check_error $? "创建用户pip目录"
    
    if [ -f /root/.pip/pip.conf ]; then
        cp -af /root/.pip/pip.conf "/home/$userName/.pip/" >> $LOG_FILE 2>&1
        check_error $? "复制pip配置"
    else
        # 如果pip配置不存在，创建一个
        cat > "/home/$userName/.pip/pip.conf" << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple/
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
    fi
    
    # 设置目录权限
    log "INFO" "正在设置目录权限..."
    chown -R "$userName:$userName" "/home/$userName" >> $LOG_FILE 2>&1
    check_error $? "设置用户目录权限"
    
    chown -R "$userName:$userName" "$fullInstallDir" >> $LOG_FILE 2>&1
    check_error $? "设置安装目录权限"
    
    # 设置语言环境
    log "INFO" "正在设置语言环境..."
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen >> $LOG_FILE 2>&1
    check_error $? "修改locale.gen"
    
    locale-gen >> $LOG_FILE 2>&1
    check_error $? "生成语言环境"
    
    # 为root用户配置环境变量
    log "INFO" "为root用户配置环境变量..."
    sed -i "/^export.*LC_ALL=.*/d" /root/.bashrc
    sed -i "/^export.*LC_CTYPE=.*/d" /root/.bashrc
    sed -i "/^export.*LANG=.*/d" /root/.bashrc
    echo -e "export LC_ALL=en_US.UTF-8\nexport LC_CTYPE=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> /root/.bashrc
    
    # 为frappe用户配置环境变量
    log "INFO" "为$userName用户配置环境变量..."
    sed -i "/^export.*LC_ALL=.*/d" "/home/$userName/.bashrc"
    sed -i "/^export.*LC_CTYPE=.*/d" "/home/$userName/.bashrc"
    sed -i "/^export.*LANG=.*/d" "/home/$userName/.bashrc"
    echo -e "export LC_ALL=en_US.UTF-8\nexport LC_CTYPE=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> "/home/$userName/.bashrc"
    
    # 添加PATH环境变量
    grep -q "^export PATH=.*\$HOME\/.local\/bin" "/home/$userName/.bashrc" || \
        echo "export PATH=\$HOME/.local/bin:\$PATH" >> "/home/$userName/.bashrc"
    
    # 设置时区为上海
    log "INFO" "正在设置时区..."
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata >> $LOG_FILE 2>&1
    check_error $? "设置时区"
    
    # 设置监控文件数量上限
    log "INFO" "正在设置监控文件数量上限..."
    if ! grep -q "^fs.inotify.max_user_watches=" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
        # 使其立即生效
        /sbin/sysctl -p >> $LOG_FILE 2>&1
        check_error $? "更新sysctl设置"
    else
        log "INFO" "inotify.max_user_watches已配置"
    fi
    
    log "SUCCESS" "用户和目录创建完成。"
}

# 安装Frappe Bench
install_frappe_bench() {
    log "INFO" "开始安装Frappe Bench..."
    
        log "INFO" "清理可能的旧安装..."
    if [[ -d "$fullInstallDir" ]]; then
        rm -rf "$fullInstallDir" >> $LOG_FILE 2>&1
        check_error $? "清理旧的安装目录"
        mkdir -p "$fullInstallDir" >> $LOG_FILE 2>&1
        check_error $? "创建安装目录"
        chown -R "$userName:$userName" "$fullInstallDir" >> $LOG_FILE 2>&1
        check_error $? "设置安装目录权限"
    fi
    
    # 以frappe用户身份安装bench
    log "INFO" "正在以 $userName 用户身份安装bench..."
    sudo -u "$userName" -i bash -c "
        # 安装bench
        echo '安装bench命令行工具...'
        pip install --user frappe-bench
        
        # 确保bench在PATH中
        export PATH=~/.local/bin:$PATH
        
        # 初始化bench
        echo '初始化bench目录...'
        cd \"$fullInstallDir/..\"
        bench init --skip-redis-config-generation --frappe-branch \"$frappeBranch\" \"$installDir\"
        
        # 进入bench目录
        cd \"$fullInstallDir\"
        
        # 安装ERPNext应用
        echo '安装ERPNext应用...'
        bench get-app --branch \"$erpnextBranch\" erpnext https://github.com/frappe/erpnext.git
        
        # 如果有指定的bench版本，进行降级
        if [[ \"$benchVersion\" != \"\" ]]; then
            echo '安装指定版本的bench...'
            pip install --user frappe-bench==\"$benchVersion\"
        fi
        
        echo 'Frappe Bench安装和配置完成。'
    " >> $LOG_FILE 2>&1
    check_error $? "安装Frappe Bench"
    
    log "SUCCESS" "Frappe Bench安装完成。"
}

# 创建站点
create_site() {
    log "INFO" "开始创建站点..."
    
    # 确保安装目录存在
    if [ ! -d "$fullInstallDir" ]; then
        log "ERROR" "安装目录 $fullInstallDir 不存在"
        return 1
    fi
    
    # 以frappe用户身份创建站点
    log "INFO" "正在以 $userName 用户身份创建站点..."
    sudo -u "$userName" -i bash -c "
        # 确保bench在PATH中
        export PATH=~/.local/bin:$PATH
        
        # 进入bench目录
        cd \"$fullInstallDir\" || exit 1
        
        # 检查站点是否已存在
        if [[ -d \"$fullInstallDir/sites/$siteName\" ]]; then
            log '站点已存在，删除旧站点...'
            bench drop-site $siteName --force
        fi
        
        # 创建新站点
        log '创建新站点 $siteName...'
        bench new-site $siteName \
            --db-name ${siteName//./_} \
            --mariadb-root-password '$mariadbRootPassword' \
            --admin-password '$adminPassword' \
            --no-mariadb-socket
        
        # 安装ERPNext应用到站点
        log '安装ERPNext应用到站点...'
        bench --site $siteName install-app erpnext
        
        # 设置为默认站点
        log '设置为默认站点...'
        bench use $siteName
        
        # 更新站点端口配置
        log '配置站点端口...'
        bench set-config -g webserver_port $webPort
        
        log '站点创建和配置完成。'
    " >> $LOG_FILE 2>&1
    check_error $? "创建站点"
    
    log "SUCCESS" "站点创建完成。"
}

# 配置生产模式（如果需要）
configure_production() {
    if [[ "$productionMode" == "yes" ]]; then
        log "INFO" "开始配置生产模式..."
        
        # 确保安装目录存在
        if [ ! -d "$fullInstallDir" ]; then
            log "ERROR" "安装目录 $fullInstallDir 不存在"
            return 1
        fi
        
        # 以frappe用户身份配置并启动服务
        log "INFO" "正在以 $userName 用户身份配置服务..."
        sudo -u "$userName" -i bash -c "
            # 确保bench在PATH中
            export PATH=~/.local/bin:$PATH
            
            # 进入bench目录
            cd \"$fullInstallDir\" || {
                echo '无法进入bench目录'
                exit 1
            }
            
            # 生成Procfile
            echo '生成Procfile...'
            bench setup procfile || {
                echo '生成Procfile失败'
                exit 1
            }
            
            # 生成socket文件
            echo '生成socket文件...'
            bench setup socketio || {
                echo '生成socket文件失败'
                exit 1
            }
            
            # 配置Nginx
            echo '配置Nginx...'
            sudo bench setup nginx --yes || {
                echo '配置Nginx失败'
                exit 1
            }
            
            # 配置supervisor
            echo '配置supervisor...'
            bench setup supervisor --yes --user \"$userName\" --with-celery || {
                echo '配置supervisor失败'
                exit 1
            }
            
            # 重载supervisor配置
            echo '重载supervisor配置...'
            sudo supervisorctl reread || echo 'reread命令警告'
            sudo supervisorctl update || echo 'update命令警告'
            
            # 启动所有服务
            echo '启动ERPNext服务...'
            sudo supervisorctl start all || {
                echo '启动所有服务失败，尝试单独启动...'
                sudo supervisorctl start frappe:*
            }
            
            # 重启Nginx
            echo '重启Nginx服务...'
            sudo systemctl restart nginx
            
            echo '服务配置和启动完成。'
        " >> $LOG_FILE 2>&1
        check_error $? "配置生产模式服务"
        
        # 等待服务启动
        log "INFO" "等待服务启动..."
        sleep 10
        
        # 检查服务状态
        log "INFO" "检查服务状态..."
        sudo supervisorctl status
        
        # 额外检查关键服务状态
        log "INFO" "检查关键服务状态..."
        systemctl is-active nginx >/dev/null 2>&1 && \
            log "INFO" "Nginx服务正在运行" || \
            log "WARNING" "Nginx服务可能未正常运行"
        
        supervisorctl status frappe:* >/dev/null 2>&1 && \
            log "INFO" "Frappe服务正在运行" || \
            log "WARNING" "Frappe服务可能未正常运行"
        
        log "SUCCESS" "生产模式配置完成。"
        log "INFO" "可以通过 http://localhost:$webPort 访问ERPNext系统"
    fi
}

# 显示完成信息
show_completion_info() {
    log "SUCCESS" ""
    log "SUCCESS" "========================================"
    log "SUCCESS" "ERPNext 15 安装成功！"
    log "SUCCESS" "========================================"
    log "INFO" "安装路径: $fullInstallDir"
    log "INFO" "站点名称: $siteName"
    log "INFO" "访问地址: http://localhost:${webPort}"
    log "INFO" "管理员账号: Administrator"
    log "INFO" "密码: $adminPassword"
    log "WARNING" "重要：请妥善保存您的管理员密码！"
    log "SUCCESS" "========================================"
    log "INFO" "以下是一些常用命令："
    log "INFO" "重启服务: sudo supervisorctl restart all"
    log "INFO" "停止服务: sudo supervisorctl stop all"
    log "INFO" "启动服务: sudo supervisorctl start all"
    log "INFO" "查看服务状态: sudo supervisorctl status"
    log "SUCCESS" "========================================"
    
    if [[ "$productionMode" == "no" ]]; then
        log "INFO" "开发模式安装完成，请运行以下命令启动服务:"
        log "INFO" "  sudo -u $userName -i"
        log "INFO" "  cd $installDir"
        log "INFO" "  bench start"
    fi
}

# 主函数
main() {
    # 解析参数
    parse_args "$@"
    
    log "INFO" "========== ERPNext 15 安装脚本 =========="
    log "INFO" "开始安装ERPNext 15..."
    log "INFO" "脚本将自动安装所有依赖并配置系统"
    log "INFO" "详细安装日志记录在: $LOG_FILE"
    
    # 显示安装配置信息
    log "INFO" "安装配置信息："
    log "INFO" "- 安装目录: $fullInstallDir"
    log "INFO" "- 站点名称: $siteName"
    log "INFO" "- 访问端口: $webPort"
    
    # 检查环境
    log "INFO" "开始环境检查..."
    check_environment || {
        log "ERROR" "环境检查失败，脚本无法继续执行"
        exit 1
    }
    show_progress "环境检查完成"

    # 显示安装信息
    show_install_info
    
    # 执行安装步骤
    log "INFO" "开始安装系统依赖..."
    install_dependencies || {
        log "ERROR" "系统依赖安装失败，请检查错误日志"
        exit 1
    }
    show_progress "系统依赖安装完成"

    log "INFO" "开始配置数据库..."
    configure_database || {
        log "ERROR" "数据库配置失败，请检查错误日志"
        exit 1
    }
    show_progress "数据库配置完成"

    log "INFO" "开始安装Node.js和Redis..."
    install_nodejs_redis || {
        log "ERROR" "Node.js和Redis安装失败，请检查错误日志"
        exit 1
    }
    show_progress "Node.js和Redis安装完成"

    log "INFO" "开始创建用户和目录..."
    create_user_and_directory || {
        log "ERROR" "用户和目录创建失败，请检查错误日志"
        exit 1
    }
    show_progress "用户和目录创建完成"

    log "INFO" "开始安装Frappe Bench..."
    install_frappe_bench || {
        log "ERROR" "Frappe Bench安装失败，请检查错误日志"
        exit 1
    }
    show_progress "Frappe Bench安装完成"

    log "INFO" "开始创建ERPNext站点..."
    create_site || {
        log "ERROR" "站点创建失败，请检查错误日志"
        exit 1
    }
    show_progress "ERPNext站点创建完成"

    # 配置生产模式（如果启用）
    if [[ "$productionMode" == "yes" ]]; then
        log "INFO" "开始配置生产模式..."
        configure_production || {
            log "WARNING" "生产模式配置遇到问题，但安装基本完成"
        }
    fi
    show_progress "服务配置完成"

    # 显示完成信息
    show_completion_info
    
    log "INFO" "如需重新启动服务，请使用: sudo supervisorctl restart all"
    log "INFO" "如需查看日志，请检查: $LOG_FILE"
}

# 执行主函数
main "$@"