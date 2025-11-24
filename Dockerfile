FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

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

RUN useradd -m -s /bin/bash frappe && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe

COPY install-erpnext15.sh /root/install-erpnext15.sh

RUN chmod +x /root/install-erpnext15.sh

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

RUN mkdir -p /var/run/log && chmod 777 /var/run/log

EXPOSE 80 8000 3306

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]