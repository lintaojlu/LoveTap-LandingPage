#!/bin/bash

# LoveTap 项目 rsync 同步脚本
# 用途：将本地项目文件同步到服务器

# 配置变量
SERVER_USER="root"
SERVER_HOST="123.56.229.52"
SERVER_PATH="/root/backends/lovetap-landingpage/"
LOCAL_PATH="./"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 开始使用 rsync 同步 LoveTap 项目到服务器...${NC}"
echo -e "${YELLOW}📡 服务器: ${SERVER_USER}@${SERVER_HOST}${NC}"
echo -e "${YELLOW}📁 目标路径: ${SERVER_PATH}${NC}"
echo ""

# rsync 参数说明：
# -a: 归档模式，保持文件属性
# -v: 详细输出
# -z: 压缩传输
# -h: 人类可读的输出格式
# --progress: 显示传输进度
# --delete: 删除目标目录中源目录没有的文件
# --exclude-from: 使用排除文件

echo -e "${BLUE}📋 rsync 参数说明:${NC}"
echo "  -a: 归档模式，保持文件属性"
echo "  -v: 详细输出"
echo "  -z: 压缩传输"
echo "  -h: 人类可读的输出格式"
echo "  --progress: 显示传输进度"
echo "  --delete: 删除目标目录中多余的文件"
echo "  --exclude-from: 使用排除文件"
echo ""

# 开始同步
echo -e "${GREEN}🔄 开始同步文件...${NC}"

rsync -avzh \
    --progress \
    --delete \
    --exclude-from=.rsyncignore \
    "${LOCAL_PATH}" \
    "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}"

# 检查同步结果
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 文件同步成功！${NC}"
    
    # 在服务器上设置正确的权限
    echo -e "${BLUE}🔧 设置服务器文件权限...${NC}"
    ssh "${SERVER_USER}@${SERVER_HOST}" \
        "chown -R www-data:www-data ${SERVER_PATH} && \
         chmod -R 755 ${SERVER_PATH} && \
         find ${SERVER_PATH} -type f -name '*.html' -exec chmod 644 {} \; && \
         find ${SERVER_PATH} -type f -name '*.css' -exec chmod 644 {} \; && \
         find ${SERVER_PATH} -type f -name '*.js' -exec chmod 644 {} \; && \
         find ${SERVER_PATH} -type f -name '*.png' -exec chmod 644 {} \; && \
         find ${SERVER_PATH} -type f -name '*.jpg' -exec chmod 644 {} \; && \
         find ${SERVER_PATH} -type f -name '*.svg' -exec chmod 644 {} \;"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 权限设置完成！${NC}"
        
        # 重新加载nginx配置
        echo -e "${BLUE}🔄 重新加载nginx配置...${NC}"
        ssh "${SERVER_USER}@${SERVER_HOST}" "systemctl reload nginx"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ nginx配置重新加载完成！${NC}"
            echo ""
            echo -e "${GREEN}🎉 同步完成！${NC}"
            echo -e "${YELLOW}🌐 访问地址: http://${SERVER_HOST}:9870${NC}"
            echo ""
            echo -e "${BLUE}🧪 测试访问:${NC}"
            echo "  curl -I http://${SERVER_HOST}:9870"
        else
            echo -e "${RED}❌ nginx重新加载失败${NC}"
        fi
    else
        echo -e "${RED}❌ 权限设置失败${NC}"
    fi
else
    echo ""
    echo -e "${RED}❌ 文件同步失败！${NC}"
    exit 1
fi 