#!/bin/bash

# LoveTap 落地页本地测试脚本
echo "🚀 开始本地测试部署..."

# 配置变量
DEPLOY_PATH="./local-deploy"  # 本地测试目录

# 1. 创建测试目录
echo "📁 创建测试目录..."
mkdir -p $DEPLOY_PATH
mkdir -p $DEPLOY_PATH/stats/visits
mkdir -p $DEPLOY_PATH/stats/downloads

# 2. 复制网站文件
echo "📄 复制网站文件..."
cp -r ./* $DEPLOY_PATH/

# 3. 安装Node.js依赖
echo "📦 安装Node.js依赖..."
cd $DEPLOY_PATH
npm install

# 4. 启动服务
echo "🚀 启动Node.js服务..."
echo "服务将在 http://localhost:3000 运行"
node server.js 