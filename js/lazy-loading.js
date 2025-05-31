/* ===========================================
   lovetap 产品广告网页 - 懒加载JavaScript
   =========================================== */

// 等待DOM加载完成
document.addEventListener('DOMContentLoaded', function() {
    initImageLazyLoading();
    initContentLazyLoading();
    initPreloadOptimization();
});

/* ===========================================
   图片懒加载初始化
   =========================================== */
function initImageLazyLoading() {
    // 支持现代浏览器的原生懒加载
    if ('loading' in HTMLImageElement.prototype) {
        // 为所有图片添加原生懒加载
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            if (!img.hasAttribute('loading')) {
                img.setAttribute('loading', 'lazy');
            }
        });
    } else {
        // 降级到Intersection Observer
        initIntersectionObserverLazyLoading();
    }
    
    // 为重要图片添加预加载
    preloadCriticalImages();
}

/* ===========================================
   Intersection Observer 懒加载
   =========================================== */
function initIntersectionObserverLazyLoading() {
    if (!('IntersectionObserver' in window)) {
        // 不支持Intersection Observer，直接加载所有图片
        loadAllImages();
        return;
    }

    // 配置观察器选项
    const observerOptions = {
        root: null,
        rootMargin: '50px', // 提前50px开始加载
        threshold: 0.01
    };

    // 创建图片观察器
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                loadImage(img);
                observer.unobserve(img);
            }
        });
    }, observerOptions);

    // 观察所有需要懒加载的图片
    const lazyImages = document.querySelectorAll('img[data-src], img[data-srcset]');
    lazyImages.forEach(img => {
        // 添加占位符
        addImagePlaceholder(img);
        imageObserver.observe(img);
    });
}

/* ===========================================
   加载单个图片
   =========================================== */
function loadImage(img) {
    return new Promise((resolve, reject) => {
        // 显示加载状态
        img.classList.add('loading');
        
        // 创建新的图片对象用于预加载
        const imageLoader = new Image();
        
        imageLoader.onload = function() {
            // 图片加载成功
            if (img.dataset.src) {
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
            }
            
            if (img.dataset.srcset) {
                img.srcset = img.dataset.srcset;
                img.removeAttribute('data-srcset');
            }
            
            // 添加加载完成的动画
            img.classList.remove('loading');
            img.classList.add('loaded');
            
            // 添加淡入效果
            requestAnimationFrame(() => {
                img.style.opacity = '1';
            });
            
            resolve(img);
        };
        
        imageLoader.onerror = function() {
            // 图片加载失败，显示占位符
            img.classList.remove('loading');
            img.classList.add('error');
            
            // 设置错误占位符
            img.src = createErrorPlaceholder();
            img.alt = '图片加载失败';
            
            reject(new Error('Image loading failed'));
        };
        
        // 开始加载图片
        if (img.dataset.src) {
            imageLoader.src = img.dataset.src;
        }
    });
}

/* ===========================================
   添加图片占位符
   =========================================== */
function addImagePlaceholder(img) {
    // 如果图片还没有src，添加占位符
    if (!img.src || img.src === window.location.href) {
        img.src = createPlaceholder(img);
        img.style.opacity = '0.7';
        img.style.transition = 'opacity 0.3s ease';
    }
}

/* ===========================================
   创建占位符
   =========================================== */
function createPlaceholder(img) {
    // 获取图片的期望尺寸
    const width = img.getAttribute('width') || 300;
    const height = img.getAttribute('height') || 200;
    
    // 创建SVG占位符
    const placeholder = `
        <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}">
            <rect width="100%" height="100%" fill="#f0f0f0"/>
            <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="14" fill="#999" text-anchor="middle" dominant-baseline="middle">
                加载中...
            </text>
        </svg>
    `;
    
    return 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(placeholder)));
}

/* ===========================================
   创建错误占位符
   =========================================== */
function createErrorPlaceholder() {
    const errorPlaceholder = `
        <svg width="300" height="200" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200">
            <rect width="100%" height="100%" fill="#f8f9fa"/>
            <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="14" fill="#6c757d" text-anchor="middle" dominant-baseline="middle">
                图片无法加载
            </text>
        </svg>
    `;
    
    return 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(errorPlaceholder)));
}

/* ===========================================
   预加载关键图片
   =========================================== */
function preloadCriticalImages() {
    // 预加载首屏重要图片
    const criticalImages = [
        'assets/images/logo/lovetap-icon.png',
        'assets/images/logo/lovetap-logo.png'
    ];
    
    criticalImages.forEach(src => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.as = 'image';
        link.href = src;
        document.head.appendChild(link);
    });
}

/* ===========================================
   内容懒加载
   =========================================== */
function initContentLazyLoading() {
    if (!('IntersectionObserver' in window)) {
        return;
    }

    // 配置内容观察器
    const contentObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const element = entry.target;
                loadContent(element);
                observer.unobserve(element);
            }
        });
    }, {
        rootMargin: '100px'
    });

    // 观察需要懒加载的内容区域
    const lazyContents = document.querySelectorAll('.lazy-content');
    lazyContents.forEach(content => {
        contentObserver.observe(content);
    });
}

/* ===========================================
   加载内容
   =========================================== */
function loadContent(element) {
    // 添加加载状态
    element.classList.add('content-loading');
    
    // 模拟内容加载延迟
    setTimeout(() => {
        element.classList.remove('content-loading');
        element.classList.add('content-loaded');
        
        // 触发内容显示动画
        element.style.opacity = '1';
        element.style.transform = 'translateY(0)';
    }, 300);
}

/* ===========================================
   预加载优化
   =========================================== */
function initPreloadOptimization() {
    // 预加载下一个视窗的图片
    preloadNextViewportImages();
    
    // 预加载字体
    preloadFonts();
    
    // 预连接外部资源
    preconnectExternalResources();
}

/* ===========================================
   预加载下一个视窗的图片
   =========================================== */
function preloadNextViewportImages() {
    if (!('IntersectionObserver' in window)) {
        return;
    }

    const preloadObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // 当前区域进入视窗，预加载下面的图片
                const nextSection = entry.target.nextElementSibling;
                if (nextSection) {
                    const nextImages = nextSection.querySelectorAll('img[data-src]');
                    nextImages.forEach(img => {
                        if (img.dataset.src) {
                            // 开始预加载
                            const preloadImg = new Image();
                            preloadImg.src = img.dataset.src;
                        }
                    });
                }
            }
        });
    }, {
        rootMargin: '200px'
    });

    // 观察主要内容区域
    const sections = document.querySelectorAll('section');
    sections.forEach(section => {
        preloadObserver.observe(section);
    });
}

/* ===========================================
   预加载字体
   =========================================== */
function preloadFonts() {
    const fonts = [
        'assets/fonts/NotoSansCJK/NotoSansCJK-Regular.woff2',
        'assets/fonts/NotoSansCJK/NotoSansCJK-Bold.woff2'
    ];
    
    fonts.forEach(fontUrl => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.as = 'font';
        link.type = 'font/woff2';
        link.href = fontUrl;
        link.crossOrigin = 'anonymous';
        document.head.appendChild(link);
    });
}

/* ===========================================
   预连接外部资源
   =========================================== */
function preconnectExternalResources() {
    const domains = [
        'https://fonts.googleapis.com',
        'https://fonts.gstatic.com'
    ];
    
    domains.forEach(domain => {
        const link = document.createElement('link');
        link.rel = 'preconnect';
        link.href = domain;
        link.crossOrigin = 'anonymous';
        document.head.appendChild(link);
    });
}

/* ===========================================
   降级处理：加载所有图片
   =========================================== */
function loadAllImages() {
    const images = document.querySelectorAll('img[data-src]');
    images.forEach(img => {
        if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
        }
        if (img.dataset.srcset) {
            img.srcset = img.dataset.srcset;
            img.removeAttribute('data-srcset');
        }
    });
}

/* ===========================================
   响应式图片处理
   =========================================== */
function initResponsiveImages() {
    const responsiveImages = document.querySelectorAll('img[data-sizes]');
    
    responsiveImages.forEach(img => {
        // 根据屏幕尺寸选择合适的图片
        const sizes = JSON.parse(img.dataset.sizes);
        const currentWidth = window.innerWidth;
        
        let selectedSrc = sizes.default;
        
        // 选择最合适的图片尺寸
        for (const breakpoint in sizes) {
            if (breakpoint !== 'default' && currentWidth >= parseInt(breakpoint)) {
                selectedSrc = sizes[breakpoint];
            }
        }
        
        img.dataset.src = selectedSrc;
    });
}

/* ===========================================
   懒加载性能监控
   =========================================== */
function monitorLazyLoadingPerformance() {
    // 记录懒加载性能指标
    const performanceData = {
        imagesLoaded: 0,
        totalImages: document.querySelectorAll('img').length,
        startTime: performance.now()
    };
    
    // 监听图片加载完成
    document.addEventListener('load', function(e) {
        if (e.target.tagName === 'IMG') {
            performanceData.imagesLoaded++;
            
            // 计算加载进度
            const progress = (performanceData.imagesLoaded / performanceData.totalImages) * 100;
            
            // 触发进度事件
            const progressEvent = new CustomEvent('lazyLoadProgress', {
                detail: {
                    progress: progress,
                    imagesLoaded: performanceData.imagesLoaded,
                    totalImages: performanceData.totalImages
                }
            });
            
            document.dispatchEvent(progressEvent);
            
            // 所有图片加载完成
            if (performanceData.imagesLoaded === performanceData.totalImages) {
                const loadTime = performance.now() - performanceData.startTime;
                console.log(`所有图片加载完成，耗时: ${loadTime.toFixed(2)}ms`);
            }
        }
    }, true);
}

/* ===========================================
   错误处理和重试机制
   =========================================== */
function initImageRetryMechanism() {
    document.addEventListener('error', function(e) {
        if (e.target.tagName === 'IMG') {
            const img = e.target;
            const retryCount = parseInt(img.dataset.retryCount || '0');
            
            if (retryCount < 3) {
                // 重试加载图片
                setTimeout(() => {
                    img.dataset.retryCount = (retryCount + 1).toString();
                    img.src = img.dataset.src || img.src;
                }, 1000 * Math.pow(2, retryCount)); // 指数退避
            } else {
                // 最终失败，显示占位符
                img.src = createErrorPlaceholder();
                img.alt = '图片加载失败';
            }
        }
    }, true);
}

// 初始化响应式图片
initResponsiveImages();

// 初始化性能监控
monitorLazyLoadingPerformance();

// 初始化重试机制
initImageRetryMechanism();

// 监听窗口大小变化，重新计算响应式图片
window.addEventListener('resize', debounce(initResponsiveImages, 250));

/* ===========================================
   工具函数：防抖
   =========================================== */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
} 