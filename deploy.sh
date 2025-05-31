#!/bin/bash

# LoveTap 落地页自动部署脚本
# 作者：Assistant
# 用途：一键部署到服务器

echo "🚀 开始部署 LoveTap 落地页..."

# 配置变量（请根据实际情况修改）
DOMAIN="entropyai.cn"  # 替换为您的域名
PORT="9870"  # 监听端口
DEPLOY_PATH="/root/backends/lovetap-landingpage"  # 网站部署路径
NGINX_CONFIG="/etc/nginx/sites-available/lovetap"  # Nginx 配置文件路径

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 安装 Nginx（如果未安装）
echo "📦 检查并安装 Nginx..."
if ! command -v nginx &> /dev/null; then
    apt update
    apt install -y nginx
    echo "✅ Nginx 安装完成"
else
    echo "✅ Nginx 已安装"
fi

# 2. 创建网站目录
echo "📁 创建网站目录..."
mkdir -p $DEPLOY_PATH
chown -R www-data:www-data $DEPLOY_PATH

# 3. 复制网站文件
echo "📄 复制网站文件..."
cp -r ./* $DEPLOY_PATH/
chown -R www-data:www-data $DEPLOY_PATH

# 4. 配置 Nginx
echo "⚙️ 配置 Nginx..."
cp nginx.conf $NGINX_CONFIG

# 更新配置文件中的域名
sed -i "s/yourdomain.com/$DOMAIN/g" $NGINX_CONFIG

# 启用站点
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. 测试 Nginx 配置
echo "🧪 测试 Nginx 配置..."
if nginx -t; then
    echo "✅ Nginx 配置测试通过"
else
    echo "❌ Nginx 配置有误，请检查"
    exit 1
fi

# 6. 重启 Nginx
echo "🔄 重启 Nginx 服务..."
systemctl restart nginx
systemctl enable nginx

# 7. 配置防火墙（UFW）
echo "🔒 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow $PORT
    echo "✅ 防火墙端口 $PORT 配置完成"
fi

# 8. 显示部署结果
echo ""
echo "🎉 部署完成！"
echo "🌐 网站地址: http://$DOMAIN:$PORT"
echo "📁 部署路径: $DEPLOY_PATH"
echo "⚙️ Nginx 配置: $NGINX_CONFIG"
echo "🔌 监听端口: $PORT"
echo ""
echo "📝 后续步骤："
echo "1. 确保域名 $DOMAIN 已解析到此服务器"
echo "2. 如需 HTTPS，请申请 SSL 证书并更新 Nginx 配置"
echo "3. 可使用 'systemctl status nginx' 检查服务状态"
echo ""
echo "🔗 测试访问: curl -I http://$DOMAIN:$PORT" 