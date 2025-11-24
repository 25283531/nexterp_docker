# 使用Ubuntu 22.04作为基础镜像
FROM ubuntu:22.04

# 避免交互式前端
ARG DEBIAN_FRONTEND=noninteractive

# 设置时区
RUN apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# 安装基本依赖
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
    libmariadb-dev \
    redis-server \
    nodejs \
    npm \
    yarn \
    && npm install -g yarn

# 创建frappe用户
RUN useradd -m -s /bin/bash frappe && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe

# 复制安装脚本到容器中
COPY install-erpnext15.sh /root/install-erpnext15.sh

# 给脚本添加执行权限
RUN chmod +x /root/install-erpnext15.sh

# 运行安装脚本，使用Docker模式和静默模式
# 增加调试输出
RUN echo "开始安装ERPNext..." && \
    echo "当前目录内容:" && ls -la && \
    echo "执行脚本..." && \
    /root/install-erpnext15.sh -q -d \
    mariadbRootPassword=Pass1234 \
    adminPassword=admin \
    siteName=site1.local \
    siteDbPassword=Pass1234 \
    productionMode=yes \
    altAptSources=no

# 创建日志目录
RUN mkdir -p /var/run/log && chmod 777 /var/run/log

# 暴露端口
EXPOSE 80 8000 3306

# 设置启动命令
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]