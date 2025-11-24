FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# 添加MariaDB 10.6官方仓库
RUN curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup && \
    chmod +x mariadb_repo_setup && \
    ./mariadb_repo_setup --mariadb-server-version=10.6 && \
    rm mariadb_repo_setup

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    bash \
    sudo \
    supervisor \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    mariadb-server=1:10.6* \
    mariadb-client=1:10.6* \
    libmariadb-dev \
    redis-server \
    nodejs \
    npm \
    yarn \
    && npm install -g yarn

RUN useradd -m -s /bin/bash frappe && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe

COPY install-erpnext15.sh /root/install-erpnext15.sh
COPY test_mariadb_compatibility.sh /root/test_mariadb_compatibility.sh

RUN chmod +x /root/install-erpnext15.sh /root/test_mariadb_compatibility.sh

RUN echo "Starting ERPNext installation..." && \
    echo "Current directory contents:" && ls -la && \
    echo "Executing script..." && \
    /root/install-erpnext15.sh -q -d \
    mariadbRootPassword=Pass1234 \
    adminPassword=admin \
    siteName=site1.local \
    siteDbPassword=Pass1234 \
    productionMode=yes \
    altAptSources=no

# 配置MariaDB数据目录和权限
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# 创建日志目录并设置权限
RUN mkdir -p /var/run/log && chmod 777 /var/run/log

# 创建MariaDB配置文件，优化性能和兼容性
RUN echo "[mysqld]" > /etc/mysql/conf.d/erpnext.cnf && \
    echo "character-set-client-handshake=FALSE" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "character-set-server=utf8mb4" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "collation-server=utf8mb4_unicode_ci" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "bind-address=0.0.0.0" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "max_connections=100" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "innodb_file_per_table=1" >> /etc/mysql/conf.d/erpnext.cnf && \
    echo "innodb_buffer_pool_size=256M" >> /etc/mysql/conf.d/erpnext.cnf

EXPOSE 80 8000 3306

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]