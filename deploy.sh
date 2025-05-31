#!/bin/bash

# LoveTap 落地页自动部署脚本
# 作者：Assistant
# 用途：一键部署到服务器（支持 HTTPS）

echo "🚀 开始部署 LoveTap 落地页..."

# 配置变量（请根据实际情况修改）
DOMAIN="guesswhat.site"  # 替换为您的域名
DEPLOY_PATH="/var/www/lovetap"  # 网站部署路径
NGINX_CONFIG="/etc/nginx/sites-available/guesswhat.site"  # Nginx 配置文件路径
SSL_CERT="/etc/ssl/certs/$DOMAIN.pem"  # SSL 证书路径
SSL_KEY="/etc/ssl/private/$DOMAIN.key"  # SSL 私钥路径

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
rm -rf $DEPLOY_PATH/*  # 清理旧文件
chown -R www-data:www-data $DEPLOY_PATH

# 3. 复制网站文件
echo "📄 复制网站文件..."
cp -r ./* $DEPLOY_PATH/
chown -R www-data:www-data $DEPLOY_PATH

# 4. 检查 SSL 证书
echo "🔒 检查 SSL 证书..."
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "❌ SSL 证书文件不存在！请确保以下文件存在："
    echo "证书: $SSL_CERT"
    echo "私钥: $SSL_KEY"
    exit 1
fi

# 确保私钥权限正确
chmod 600 $SSL_KEY

# 5. 配置 Nginx
echo "⚙️ 配置 Nginx..."
cat > $NGINX_CONFIG << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    root $DEPLOY_PATH;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# 6. 移除其他可能冲突的配置
echo "🧹 清理可能冲突的配置..."
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/lovetap

# 7. 启用新配置
echo "🔄 启用新配置..."
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/

# 8. 测试 Nginx 配置
echo "🧪 测试 Nginx 配置..."
if nginx -t; then
    echo "✅ Nginx 配置测试通过"
else
    echo "❌ Nginx 配置有误，请检查"
    exit 1
fi

# 9. 重启 Nginx
echo "🔄 重启 Nginx 服务..."
systemctl restart nginx
systemctl enable nginx

# 10. 配置防火墙（UFW）
echo "🔒 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 80
    ufw allow 443
    echo "✅ 防火墙端口 80, 443 配置完成"
fi

# 11. 显示部署结果
echo ""
echo "🎉 部署完成！"
echo "🌐 网站地址: https://$DOMAIN"
echo "📁 部署路径: $DEPLOY_PATH"
echo "⚙️ Nginx 配置: $NGINX_CONFIG"
echo "🔒 SSL 证书: $SSL_CERT"
echo "🔑 SSL 私钥: $SSL_KEY"
echo ""
echo "📝 后续步骤："
echo "1. 确保域名 $DOMAIN 已解析到此服务器"
echo "2. 可使用 'systemctl status nginx' 检查服务状态"
echo "3. 测试 HTTPS 是否正常工作"
echo ""
echo "🔗 测试访问: curl -Ik https://$DOMAIN"
