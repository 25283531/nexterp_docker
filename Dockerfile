FROM ubuntu:22.04
LABEL author=lvxj11

# 设定参数
ENV MARIADB_ROOT_PASSWORD=Pass1234
ENV ADMIN_PASSWORD=admin
ENV SITE_NAME=site1.local
ENV SITE_DB_PASSWORD=Pass1234
ENV PRODUCTION_MODE=yes
ENV ALT_APT_SOURCES=no

ARG DEBIAN_FRONTEND=noninteractive

# 设置时区
RUN apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# 使用Ubuntu默认仓库安装MariaDB，添加必要的依赖
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
    mariadb-server \
    mariadb-client \
    libmariadb-dev \
    redis-server \
    nodejs \
    npm \
    yarn \
    bc \
    procps \
    net-tools \
    && npm install -g yarn

# 创建frappe用户并设置sudo权限
RUN useradd -m -s /bin/bash frappe && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe

# 创建installdata目录并设置权限
RUN mkdir -p /installdata && chmod -R 777 /installdata

# 拷贝安装脚本到installdata目录
COPY install-erpnext15.sh /installdata/install-erpnext15.sh
COPY test_mariadb_compatibility.sh /installdata/test_mariadb_compatibility.sh

# 设置脚本权限
RUN chmod -R 777 /installdata/*

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

# 运行安装脚本，使用环境变量作为参数
RUN /bin/bash -c "echo 'Starting ERPNext installation...' && \
    /installdata/install-erpnext15.sh -qd \
    mariadbRootPassword=$MARIADB_ROOT_PASSWORD \
    adminPassword=$ADMIN_PASSWORD \
    siteName=$SITE_NAME \
    siteDbPassword=$SITE_DB_PASSWORD \
    productionMode=$PRODUCTION_MODE \
    altAptSources=$ALT_APT_SOURCES"

# 暴露端口
EXPOSE 3306 80 8000

# 持久化数据卷
VOLUME /home/frappe/frappe-bench/sites
VOLUME /var/lib/mysql

# 优雅停止容器
STOPSIGNAL SIGTERM

# 切换用户和工作目录
USER frappe
WORKDIR /home/frappe/frappe-bench

# 启动命令
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["sudo /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf"]