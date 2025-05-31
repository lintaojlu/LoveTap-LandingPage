#!/bin/bash

# LoveTap 落地页自动部署脚本
# 作者：Assistant
# 用途：一键部署到服务器（支持 HTTPS）

echo "🚀 开始部署 LoveTap 落地页..."

# 配置变量
DOMAIN="guesswhat.site"  # 域名
DEPLOY_PATH="/var/www/lovetap"  # 网站部署路径
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"  # Nginx 配置文件路径
EMAIL="your-email@example.com"  # 替换为您的邮箱，用于SSL证书申请
STATS_PATH="$DEPLOY_PATH/stats"  # 统计数据存储路径

# 确保以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 安装必要软件
echo "📦 安装必要软件..."
apt update
apt install -y nginx nodejs npm certbot python3-certbot-nginx

# 2. 创建网站目录
echo "📁 创建网站目录..."
mkdir -p $DEPLOY_PATH
mkdir -p $STATS_PATH/visits
mkdir -p $STATS_PATH/downloads
rm -rf $DEPLOY_PATH/*  # 清理旧文件，但保留stats目录
mv $STATS_PATH /tmp/stats_backup 2>/dev/null  # 临时备份统计数据

# 3. 复制网站文件
echo "📄 复制网站文件..."
cp -r ./* $DEPLOY_PATH/
[ -d "/tmp/stats_backup" ] && mv /tmp/stats_backup $STATS_PATH  # 恢复统计数据

# 4. 设置正确的权限
echo "🔒 设置文件权限..."
chown -R www-data:www-data $DEPLOY_PATH
chmod -R 755 $DEPLOY_PATH
chmod -R 775 $STATS_PATH  # 确保Node.js应用可以写入统计数据
chown -R www-data:www-data $STATS_PATH

# 5. 安装Node.js依赖
echo "📦 安装Node.js依赖..."
cd $DEPLOY_PATH
npm install --production

# 6. 配置systemd服务
echo "⚙️ 配置系统服务..."
cat > /etc/systemd/system/lovetap.service << EOF
[Unit]
Description=LoveTap Landing Page
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$DEPLOY_PATH
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=PORT=3000
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lovetap
systemctl start lovetap

# 7. 配置Nginx
echo "⚙️ 配置Nginx..."
cat > $NGINX_CONFIG << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    root $DEPLOY_PATH;
    index index.html;

    # SSL配置将由certbot自动添加

    # Node.js API反向代理 - 计数器API
    location /record-stat {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 安全设置
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        
        # 错误处理
        proxy_intercept_errors on;
        error_page 500 502 503 504 /50x.html;
    }

    # 静态文件处理
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # 静态资源缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # 禁止直接访问统计数据目录
    location /stats/ {
        deny all;
        return 404;
    }

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=63072000" always;
}
EOF

# 8. 启用Nginx配置
echo "🔄 启用Nginx配置..."
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 9. 申请SSL证书
echo "🔒 申请SSL证书..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# 10. 测试Nginx配置
echo "🧪 测试Nginx配置..."
nginx -t

# 11. 重启服务
echo "🔄 重启服务..."
systemctl restart nginx
systemctl restart lovetap

# 12. 配置防火墙
echo "🔒 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 80
    ufw allow 443
fi

# 13. 测试计数器API
echo "🧪 测试计数器API..."
curl -X POST "http://localhost:3000/record-stat?type=visit&date=$(date +%Y-%m-%d)" || echo "API测试失败"

# 14. 显示部署结果
echo ""
echo "🎉 部署完成！"
echo "🌐 网站地址: https://$DOMAIN"
echo "📁 部署路径: $DEPLOY_PATH"
echo "📊 统计数据: $STATS_PATH"
echo "⚙️ Nginx配置: $NGINX_CONFIG"
echo ""
echo "📝 后续步骤："
echo "1. 确保域名 $DOMAIN 已正确解析到服务器IP"
echo "2. 检查服务状态："
echo "   - Nginx状态: systemctl status nginx"
echo "   - 应用状态: systemctl status lovetap"
echo "3. 查看日志："
echo "   - Nginx日志: tail -f /var/log/nginx/error.log"
echo "   - 应用日志: journalctl -u lovetap -f"
echo "4. 检查计数器："
echo "   - 访问统计: ls -l $STATS_PATH/visits/"
echo "   - 下载统计: ls -l $STATS_PATH/downloads/"
echo ""
echo "🔍 测试网站可访问性："
echo "curl -Ik https://$DOMAIN"
