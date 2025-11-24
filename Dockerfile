# erpnext
FROM ubuntu:22.04
LABEL author=xiaohui0302

# 设定非敏感参数
ENV SITE_NAME=site1.local
ENV PRODUCTION_MODE=yes
ENV ALT_APT_SOURCES=no

# 注意：敏感参数(MARIADB_ROOT_PASSWORD、ADMIN_PASSWORD、SITE_DB_PASSWORD)请在运行时通过-e参数传入
# 例如：docker run -e MARIADB_ROOT_PASSWORD=yourpassword -e ADMIN_PASSWORD=youradminpass -e SITE_DB_PASSWORD=yoursitepass ...

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
    bc \
    procps \
    net-tools

# 安装Node.js 20的最新稳定版本
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# 创建frappe用户并设置sudo权限
RUN useradd -m -s /bin/bash frappe && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe

# 创建installdata目录并设置权限
RUN mkdir -p /installdata && chmod -R 777 /installdata

# 创建frappe-bench目录
RUN mkdir -p /home/frappe/frappe-bench && chown -R frappe:frappe /home/frappe/frappe-bench

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

# 拷贝基础软件安装脚本
COPY ./installdata /installdata

# 设置脚本权限
RUN chmod -R 777 /installdata/*

# 切换到frappe用户
USER frappe
WORKDIR /home/frappe/frappe-bench

# 运行安装脚本，为敏感参数提供默认值以允许构建完成
# 注意：在运行容器时应通过-e参数传入实际的敏感参数值
RUN /bin/bash -c "echo 'Starting ERPNext installation...' && \
    /installdata/install-erpnext15.sh -qd \
    mariadbRootPassword=${MARIADB_ROOT_PASSWORD:-DefaultBuildTimePassword} \
    adminPassword=${ADMIN_PASSWORD:-DefaultBuildTimeAdmin} \
    siteName=$SITE_NAME \
    siteDbPassword=${SITE_DB_PASSWORD:-DefaultBuildTimeSiteDb} \
    productionMode=$PRODUCTION_MODE \
    altAptSources=$ALT_APT_SOURCES"

# 暴露端口
EXPOSE 3306 80 8000

# 持久化数据卷
VOLUME /home/frappe/frappe-bench/sites
VOLUME /var/lib/mysql

STOPSIGNAL SIGTERM

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["sudo /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf"]