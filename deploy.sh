#!/bin/bash

# LoveTap 落地页自动部署脚本
# 作者：Assistant
# 用途：一键部署到服务器（支持 HTTPS）

# 错误处理函数
handle_error() {
    echo "❌ 错误: $1"
    exit 1
}

echo "🚀 开始部署 LoveTap 落地页..."

# 配置变量
DOMAIN="guesswhat.site"  # 域名
DEPLOY_PATH="/var/www/lovetap"  # 网站部署路径
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"  # Nginx 配置文件路径
STATS_PATH="$DEPLOY_PATH/stats"  # 统计数据存储路径
NODE_VERSION="18"  # 指定Node.js版本
BACKUP_DIR="/var/backups/lovetap"  # 备份目录

# SSL证书路径
SSL_CERT="/etc/ssl/certs/$DOMAIN.pem"  # SSL证书路径
SSL_KEY="/etc/ssl/private/$DOMAIN.key"  # SSL私钥路径

# 确保以root权限运行
if [ "$EUID" -ne 0 ]; then 
    handle_error "请使用 sudo 运行此脚本"
fi

# 检查SSL证书文件
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    handle_error "SSL证书文件不存在: $SSL_CERT 或 $SSL_KEY"
fi

# 检查必要的命令是否存在
for cmd in curl wget systemctl nginx; do
    if ! command -v $cmd &> /dev/null; then
        handle_error "未找到必要的命令: $cmd"
    fi
done

# 创建备份目录
echo "📦 创建备份目录..."
mkdir -p $BACKUP_DIR

# 1. 安装必要软件
echo "📦 安装必要软件..."
apt update || handle_error "apt update 失败"
apt install -y nginx curl || handle_error "软件安装失败"

# 安装指定版本的 Node.js
echo "📦 安装 Node.js v$NODE_VERSION..."
if ! command -v node &> /dev/null || [[ $(node -v) != *"v$NODE_VERSION"* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - || handle_error "Node.js 仓库配置失败"
    apt install -y nodejs || handle_error "Node.js 安装失败"
fi

# 2. 备份现有部署
if [ -d "$DEPLOY_PATH" ]; then
    echo "💾 备份现有部署..."
    BACKUP_NAME="lovetap_$(date +%Y%m%d_%H%M%S)"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C $(dirname $DEPLOY_PATH) $(basename $DEPLOY_PATH) || handle_error "备份失败"
fi

# 3. 创建网站目录
echo "📁 创建网站目录..."
mkdir -p $DEPLOY_PATH
mkdir -p $DEPLOY_PATH/stats/visits
mkdir -p $DEPLOY_PATH/stats/downloads

# 保存现有统计数据
if [ -d "$STATS_PATH" ]; then
    echo "💾 备份统计数据..."
    cp -r $STATS_PATH /tmp/stats_backup
fi

# 清理并复制新文件
echo "📄 复制网站文件..."
find $DEPLOY_PATH -mindepth 1 -delete
cp -r ./* $DEPLOY_PATH/ || handle_error "文件复制失败"

# 恢复统计数据
if [ -d "/tmp/stats_backup" ]; then
    echo "📊 恢复统计数据..."
    cp -r /tmp/stats_backup/* $STATS_PATH/
    rm -rf /tmp/stats_backup
fi

# 4. 设置权限
echo "🔒 设置文件权限..."
chown -R www-data:www-data $DEPLOY_PATH || handle_error "权限设置失败"
chmod -R 755 $DEPLOY_PATH || handle_error "权限设置失败"
chmod -R 775 $DEPLOY_PATH/stats || handle_error "统计目录权限设置失败"

# 5. 安装Node.js依赖
echo "📦 安装Node.js依赖..."
cd $DEPLOY_PATH || handle_error "无法进入部署目录"

# 检查package.json是否存在
if [ ! -f "package.json" ]; then
    handle_error "package.json 不存在"
fi

# 设置npm配置
echo "⚙️ 配置npm..."
npm config set registry https://registry.npmmirror.com
npm config set disturl https://npmmirror.com/dist
npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
npm config set dns-timeout 30000
npm config set fetch-retries 5
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000

# 安装依赖
echo "📦 执行npm install..."
npm install --production --no-fund --no-audit --prefer-offline || {
    echo "⚠️ 首次安装失败，尝试清除缓存后重新安装..."
    npm cache clean --force
    npm install --production --no-fund --no-audit || handle_error "npm install 失败"
}

# 恢复默认配置
npm config delete registry
npm config delete disturl
npm config delete sass_binary_site

# 6. 检查并配置systemd服务
echo "⚙️ 配置系统服务..."
if [ ! -f "lovetap.service" ]; then
    handle_error "lovetap.service 文件不存在"
fi

cp lovetap.service /etc/systemd/system/ || handle_error "服务文件复制失败"
systemctl daemon-reload || handle_error "systemd 重载失败"
systemctl enable lovetap || handle_error "服务启用失败"
systemctl start lovetap || handle_error "服务启动失败"

# 7. 配置Nginx
echo "⚙️ 配置Nginx..."
if [ ! -d "/etc/nginx" ]; then
    handle_error "Nginx 未正确安装"
fi

# Nginx配置
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

    # SSL配置
    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling off;

    # Node.js API反向代理
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
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/ || handle_error "Nginx配置启用失败"
rm -f /etc/nginx/sites-enabled/default

# 删除certbot相关部分，直接进行Nginx配置测试
echo "🧪 测试Nginx配置..."
nginx -t || handle_error "Nginx配置测试失败"

# 9. 重启服务
echo "🔄 重启服务..."
systemctl restart nginx || handle_error "Nginx重启失败"
systemctl restart lovetap || handle_error "LoveTap服务重启失败"

# 10. 配置防火墙
echo "🔒 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 80 || echo "⚠️ 警告: 无法配置防火墙端口 80"
    ufw allow 443 || echo "⚠️ 警告: 无法配置防火墙端口 443"
fi

# 11. 测试服务
echo "🧪 测试Node.js服务..."
# 等待服务启动
sleep 5
if ! curl -s -X POST "http://localhost:3000/record-stat?type=visit&date=$(date +%Y-%m-%d)"; then
    echo "⚠️ 警告: Node.js服务测试失败，请检查日志"
fi

# 12. 清理临时文件
echo "🧹 清理临时文件..."
rm -rf /tmp/stats_backup* 2>/dev/null

# 13. 显示部署结果
echo ""
echo "🎉 部署完成！"
echo "🌐 网站地址: https://$DOMAIN"
echo "📁 部署路径: $DEPLOY_PATH"
echo "📊 统计数据: $STATS_PATH"
echo "⚙️ Nginx配置: $NGINX_CONFIG"
echo "💾 备份位置: $BACKUP_DIR"
echo ""
echo "📝 后续步骤："
echo "1. 确保域名 $DOMAIN 已正确解析到服务器IP"
echo "2. 检查服务状态："
echo "   - Nginx状态: systemctl status nginx"
echo "   - Node.js服务状态: systemctl status lovetap"
echo "3. 查看日志："
echo "   - Nginx错误日志: tail -f /var/log/nginx/error.log"
echo "   - Node.js服务日志: journalctl -u lovetap -f"
echo "4. 检查计数器："
echo "   - 访问统计: ls -l $DEPLOY_PATH/stats/visits/"
echo "   - 下载统计: ls -l $DEPLOY_PATH/stats/downloads/"
echo ""
echo "🔍 测试网站可访问性："
echo "curl -Ik https://$DOMAIN"

# 检查关键服务状态
echo ""
echo "🔍 服务状态检查："
systemctl is-active --quiet nginx && echo "✅ Nginx 运行中" || echo "❌ Nginx 未运行"
systemctl is-active --quiet lovetap && echo "✅ LoveTap 运行中" || echo "❌ LoveTap 未运行"
