/* ===========================================
   LoveTap 产品广告网页 - 主要JavaScript逻辑
   =========================================== */

// 等待DOM加载完成
document.addEventListener('DOMContentLoaded', function() {
    // 初始化所有功能
    initNavigation();
    initButtonEffects();
    initDescriptionToggle();
    initLazyLoading();
    initScreenshotLightbox();
});

/* ===========================================
   导航功能初始化
   =========================================== */
function initNavigation() {
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-menu a');
    
    // 移动端菜单切换功能
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', function() {
            navToggle.classList.toggle('active');
            navMenu.classList.toggle('active');
        });
    }
    
    // 平滑滚动到对应区域
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            
            if (targetId.startsWith('#')) {
                const targetElement = document.querySelector(targetId);
                if (targetElement) {
                    // 关闭移动端菜单
                    if (navMenu && navToggle) {
                        navMenu.classList.remove('active');
                        navToggle.classList.remove('active');
                    }
                    
                    // 平滑滚动到目标位置
                    const headerHeight = document.querySelector('.header').offsetHeight;
                    const targetPosition = targetElement.offsetTop - headerHeight - 20;
                    
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                }
            }
        });
    });
    
    // 点击页面其他地方关闭移动端菜单
    document.addEventListener('click', function(e) {
        if (navMenu && navToggle && 
            !navMenu.contains(e.target) && 
            !navToggle.contains(e.target) &&
            navMenu.classList.contains('active')) {
            navMenu.classList.remove('active');
            navToggle.classList.remove('active');
        }
    });
}

/* ===========================================
   按钮效果初始化
   =========================================== */
function initButtonEffects() {
    const buttons = document.querySelectorAll('.primary-btn');
    
    buttons.forEach(button => {
        // 添加波纹效果
        button.addEventListener('click', function(e) {
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                left: ${x}px;
                top: ${y}px;
                background: rgba(255, 255, 255, 0.6);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s linear;
                pointer-events: none;
            `;
            
            this.appendChild(ripple);
            
            // 移除波纹元素
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
}

/* ===========================================
   应用描述展开/收起功能
   =========================================== */
function initDescriptionToggle() {
    const expandBtn = document.querySelector('.expand-btn');
    const descriptionMore = document.querySelector('.description-more');
    
    if (expandBtn && descriptionMore) {
        let isExpanded = false;
        
        expandBtn.addEventListener('click', function() {
            if (!isExpanded) {
                descriptionMore.classList.add('show');
                this.textContent = '...收起';
                isExpanded = true;
            } else {
                descriptionMore.classList.remove('show');
                this.textContent = '...展开';
                isExpanded = false;
            }
        });
    }
}

/* ===========================================
   懒加载初始化
   =========================================== */
function initLazyLoading() {
    // 检查是否支持 Intersection Observer
    if ('IntersectionObserver' in window) {
        const lazyImages = document.querySelectorAll('img[loading="lazy"]');
        
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.src; // 触发加载
                    img.classList.add('fade-in');
                    observer.unobserve(img);
                }
            });
        });
        
        lazyImages.forEach(img => imageObserver.observe(img));
    }
}

/* ===========================================
   下载应用功能
   =========================================== */
function downloadApp() {
    // 模拟下载功能
    const button = event.target;
    const originalText = button.textContent;
    
    // 显示加载状态
    button.classList.add('loading');
    button.textContent = 'ストアに移動中...'; 
    button.disabled = true;
    
    // 统一跳转到指定的App Store链接
    const downloadUrl = 'https://apps.apple.com/us/app/id6744844995';
    
    // 模拟跳转延时
    setTimeout(() => {
        // 打开下载链接
        window.open(downloadUrl, '_blank');
        
        // 恢复按钮状态
        button.classList.remove('loading');
        button.textContent = originalText;
        button.disabled = false;
        
        // 发送下载统计
        trackDownload();
    }, 1000);
}

/* ===========================================
   展开更多描述功能
   =========================================== */
function toggleDescription() {
    const moreContent = document.getElementById('descriptionMore');
    const expandBtn = event.target;
    
    if (moreContent.classList.contains('show')) {
        moreContent.classList.remove('show');
        expandBtn.textContent = '...展开';
    } else {
        moreContent.classList.add('show');
        expandBtn.textContent = '...收起';
    }
}

/* ===========================================
   统计功能
   =========================================== */
function trackDownload() {
    // 这里可以添加下载统计代码
    console.log('下载按钮被点击');
}

/* ===========================================
   错误处理
   =========================================== */
window.addEventListener('error', function(e) {
    console.error('页面错误:', e.error);
    // 这里可以添加错误上报逻辑
});

/* ===========================================
   截图点击放大灯箱功能
   =========================================== */
function initScreenshotLightbox() {
    // 获取所有截图图片
    const screenshotImgs = document.querySelectorAll('.screenshot-img');
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightboxImg');
    const lightboxClose = document.getElementById('lightboxClose');

    screenshotImgs.forEach(img => {
        img.addEventListener('click', function() {
            lightboxImg.src = this.src;
            lightbox.style.display = 'flex';
            document.body.style.overflow = 'hidden'; // 禁止页面滚动
        });
    });

    // 关闭按钮
    lightboxClose.addEventListener('click', function() {
        lightbox.style.display = 'none';
        lightboxImg.src = '';
        document.body.style.overflow = '';
    });

    // 点击遮罩关闭
    lightbox.addEventListener('click', function(e) {
        if (e.target === lightbox) {
            lightbox.style.display = 'none';
            lightboxImg.src = '';
            document.body.style.overflow = '';
        }
    });
} 