# ERPNext 15 Docker 构建指南

## 构建Docker镜像

请确保您在包含Dockerfile的正确目录中运行以下命令：

```bash
docker build -t erpnext15:latest .
```

**重要提示**：
1. 命令末尾的`.`表示当前目录作为构建上下文，这是必需的参数，不能省略。
2. 请确保您在包含Dockerfile的目录中执行此命令，通常是`e:\git\nexterp`目录，而不是其子目录。

### 网络连接问题解决方法

如果您在构建过程中遇到类似以下的网络连接错误：
```
failed to fetch oauth token: Post "https://auth.docker.io/token": read tcp ...: An existing connection was forcibly closed by the remote host
```

请尝试以下解决方案：

1. **检查网络连接**：确保您的网络连接正常工作
2. **重试构建命令**：网络问题有时是临时的，重试可能会解决问题
3. **使用Docker镜像加速器**：如果您在中国大陆，可以配置Docker镜像加速器来提高下载速度和稳定性

   **Windows系统配置方法**：
   1. 打开Docker Desktop
   2. 点击右上角的设置图标（Settings）
   3. 选择左侧导航栏中的"Docker Engine"
   4. 在右侧JSON配置中添加镜像加速器地址，例如：
      ```json
      {
        "registry-mirrors": [
          "https://registry.docker-cn.com",
          "https://mirror.baidubce.com",
          "https://hub-mirror.c.163.com"
        ]
      }
      ```
   5. 点击"Apply & Restart"按钮保存配置并重启Docker

   **Linux系统配置方法**：
   1. 创建或编辑Docker配置文件：
      ```bash
      sudo vim /etc/docker/daemon.json
      ```
   2. 添加镜像加速器地址：
      ```json
      {
        "registry-mirrors": [
          "https://registry.docker-cn.com",
          "https://mirror.baidubce.com",
          "https://hub-mirror.c.163.com"
        ]
      }
      ```
   3. 保存文件并重启Docker服务：
      ```bash
      sudo systemctl daemon-reload
      sudo systemctl restart docker
      ```
4. **验证防火墙设置**：确保防火墙没有阻止Docker访问外部网络

### 构建参数说明

- `-t erpnext15:latest`: 为镜像指定标签，格式为 `[名称]:[标签]`
- `.`: 表示使用当前目录中的Dockerfile

### 可选构建参数

如果需要自定义构建过程，可以使用以下参数：

```bash
docker build \
  --build-arg DEBIAN_FRONTEND=noninteractive \
  -t erpnext15:custom \
  -f Dockerfile .
```

## 运行Docker容器

构建完成后，使用以下命令运行容器：

```bash
docker run -d \
  --name erpnext15 \
  -p 80:80 \
  -p 3306:3306 \
  erpnext15:latest
```

### 运行参数说明

- `-d`: 后台运行容器
- `--name erpnext15`: 为容器指定名称
- `-p 80:80`: 将容器的80端口映射到主机的80端口（HTTP访问）
- `-p 3306:3306`: 将容器的3306端口映射到主机的3306端口（MySQL访问）
- `erpnext15:latest`: 使用的镜像名称和标签

### 持久化数据

为了保证数据持久化，可以使用数据卷：

```bash
docker volume create erpnext_mysql
docker volume create erpnext_bench

docker run -d \
  --name erpnext15 \
  -p 80:80 \
  -p 3306:3306 \
  -v erpnext_mysql:/var/lib/mysql \
  -v erpnext_bench:/home/frappe/frappe-bench \
  erpnext15:latest
```

## 环境变量配置

如需修改默认配置，可以在运行容器时添加环境变量：

```bash
docker run -d \
  --name erpnext15 \
  -p 80:80 \
  -p 3306:3306 \
  -e MARIADB_ROOT_PASSWORD=NewPassword123 \
  -e ADMIN_PASSWORD=NewAdminPass123 \
  erpnext15:latest
```

## 查看容器日志

使用以下命令查看容器日志：

```bash
docker logs erpnext15
```

## 访问ERPNext

构建并运行容器后，可以通过以下方式访问ERPNext：

- Web界面：`http://localhost` 或 `http://[您的服务器IP]`
- 默认用户名：`administrator`
- 默认密码：`admin`（在Dockerfile中配置）

## 进入容器

如需进入容器进行调试或管理：

```bash
docker exec -it erpnext15 bash
```

## 停止和启动容器

```bash
# 停止容器
docker stop erpnext15

# 启动容器
docker start erpnext15
```

## 将镜像推送到Docker Hub

### 1. 登录Docker Hub

首先，您需要登录到Docker Hub账户：

```bash
docker login
```

系统会提示您输入Docker Hub的用户名和密码。

### 2. 为镜像添加标签

在推送之前，您需要为镜像添加Docker Hub仓库的标签：

```bash
docker tag erpnext15:latest [您的Docker Hub用户名]/erpnext15:latest
```

例如：

```bash
docker tag erpnext15:latest username/erpnext15:latest
```

您也可以添加版本标签：

```bash
docker tag erpnext15:latest username/erpnext15:15.0.0
```

### 3. 推送镜像到Docker Hub

使用`docker push`命令将镜像推送到Docker Hub：

```bash
docker push username/erpnext15:latest
docker push username/erpnext15:15.0.0
```

### 4. 从Docker Hub拉取镜像

推送完成后，您或其他人可以从任何地方拉取这个镜像：

```bash
docker pull username/erpnext15:latest
```

### 5. 最佳实践建议

- 为每次构建使用有意义的标签（版本号、日期等）
- 保留`latest`标签指向最新稳定版本
- 对于生产环境，避免使用`latest`标签，而是使用具体版本号
- 定期清理本地不再需要的镜像以节省空间

```bash
# 清理未使用的镜像
docker image prune -a
```