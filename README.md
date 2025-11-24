# ERPNext 15 自动化部署方案

## 项目简介

本仓库提供了ERPNext 15的自动化部署解决方案，包含：
- 自动化安装脚本 (`install-erpnext15.sh`)：一键完成ERPNext 15的安装配置
- Docker支持：提供Dockerfile和构建指南，实现容器化部署
- CI/CD工作流：配置GitHub Actions自动构建和推送Docker镜像

本方案适用于开发环境和生产环境，旨在简化ERPNext的部署流程，减少手动配置错误，提高部署效率。

## 功能特点

- **一键自动化安装**：通过`install-erpnext15.sh`脚本实现ERPNext 15的完整安装
- **Docker容器化支持**：提供Dockerfile和构建指南，支持容器化部署
- **CI/CD集成**：包含GitHub Actions工作流配置，支持自动化构建和推送Docker镜像
- **生产环境就绪**：配置了适当的服务管理、端口设置和权限管理

## 安装与部署

### 方法一：使用Docker部署（推荐）

1. **构建Docker镜像**

```bash
docker build -t erpnext15:latest .
```

**重要提示：**
- 命令末尾的`.`表示当前目录作为构建上下文，是必需参数
- 请确保在包含Dockerfile的目录（通常是项目根目录）执行此命令

2. **运行Docker容器**

```bash
docker run -d \
  -p 80:80 \
  -v erpnext-data:/home/frappe/frappe-bench/sites \
  --name erpnext15 \
  erpnext15:latest
```

3. **持久化数据**

使用Docker卷`erpnext-data`来持久化ERPNext的站点数据，确保容器重启后数据不会丢失。

### 方法二：直接在服务器上安装

1. **克隆仓库**

```bash
git clone https://github.com/username/nexterp.git
cd nexterp
```

2. **运行安装脚本**

```bash
chmod +x install-erpnext15.sh
./install-erpnext15.sh --silent
```

## GitHub Actions CI/CD

本项目包含完整的GitHub Actions工作流配置，位于`.github/workflows/docker-ci.yml`，支持以下功能：

- 当代码推送到`main`分支时自动构建并推送Docker镜像
- 当创建PR到`main`分支时自动构建镜像（但不推送，避免污染生产镜像）
- 使用共享缓存机制加速后续构建过程
- 支持Docker Hub自动登录和镜像推送

### 配置要求

在GitHub仓库的Settings > Secrets and variables > Actions中添加以下密钥：

- `DOCKER_USERNAME`：Docker Hub用户名
- `DOCKER_TOKEN`：Docker Hub访问令牌（在Docker Hub的Account Settings > Security中生成）

## 网络问题解决方法

如果在构建过程中遇到网络连接问题（如`failed to fetch oauth token`），可以尝试以下解决方案：

1. **检查网络连接**：确保网络连接正常，能够访问Docker Hub
2. **重试构建命令**：网络问题可能是暂时的，重试命令可能会成功
3. **使用Docker镜像加速器**：
   - Windows系统：通过Docker Desktop设置Docker Engine JSON配置
   - Linux系统：编辑`/etc/docker/daemon.json`文件
4. **验证防火墙设置**：确保没有防火墙阻止Docker访问外部网络

## 常用命令

### 容器管理

```bash
# 查看容器状态
docker ps

# 停止容器
docker stop erpnext15

# 启动容器
docker start erpnext15

# 查看容器日志
docker logs -f erpnext15
```

### 访问ERPNext

安装完成后，可以通过以下方式访问ERPNext：

- Web界面：`http://localhost`或`http://服务器IP地址`
- 默认登录凭证：
  - 用户名：`Administrator`
  - 密码：Docker环境中默认为`admin`（生产环境请务必修改）

**首次登录建议：**
- 修改默认密码
- 配置公司信息
- 设置用户权限和角色

## 项目结构

```
nexterp/
├── .github/workflows/    # GitHub Actions工作流配置
│   └── docker-ci.yml     # Docker镜像构建和推送配置
├── Dockerfile           # Docker镜像构建文件
├── install-erpnext15.sh  # ERPNext自动化安装脚本
├── docker_build_guide.md # Docker构建和运行指南
└── README.md            # 项目文档（当前文件）
```

## 贡献指南

欢迎提交Issue和Pull Request来改进本项目。在提交PR之前，请确保：

1. 您的代码符合项目的代码风格
2. 您已经测试了您的更改
3. 提供了详细的更改说明

## 许可证

本项目采用MIT许可证

## 联系方式

如有任何问题或建议，请通过GitHub Issues提交：
https://github.com/username/nexterp/issues