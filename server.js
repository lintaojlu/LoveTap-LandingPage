const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const app = express();
const port = 3000;

// 启用CORS
app.use(cors());

// 确保统计目录存在
const statsDir = path.join(__dirname, 'stats');
const visitsDir = path.join(statsDir, 'visits');
const downloadsDir = path.join(statsDir, 'downloads');

[visitsDir, downloadsDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// 记录统计数据的函数
function recordStat(type, date) {
    const dir = type === 'visit' ? visitsDir : downloadsDir;
    const filePath = path.join(dir, `${date}.txt`);
    
    try {
        // 读取当前计数
        let count = 1;
        if (fs.existsSync(filePath)) {
            count = parseInt(fs.readFileSync(filePath, 'utf8')) + 1;
        }
        
        // 写入新计数
        fs.writeFileSync(filePath, count.toString());
        return count;
    } catch (error) {
        console.error(`Error recording ${type} stat:`, error);
        return -1;
    }
}

// 记录统计数据的端点
app.post('/record-stat', (req, res) => {
    const { type, date } = req.query;
    
    // 验证参数
    if (!type || !date || !['visit', 'download'].includes(type)) {
        return res.status(400).json({ error: 'Invalid parameters' });
    }
    
    // 验证日期格式 (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return res.status(400).json({ error: 'Invalid date format' });
    }
    
    const count = recordStat(type, date);
    if (count === -1) {
        return res.status(500).json({ error: 'Failed to record stat' });
    }
    
    res.json({ type, date, count });
});

// 获取统计数据的端点
app.get('/get-stats', (req, res) => {
    const { date } = req.query;
    
    // 验证日期格式
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return res.status(400).json({ error: 'Invalid date format' });
    }
    
    try {
        // 读取访问量
        const visitPath = path.join(visitsDir, `${date}.txt`);
        const visits = fs.existsSync(visitPath) ? parseInt(fs.readFileSync(visitPath, 'utf8')) : 0;
        
        // 读取下载量
        const downloadPath = path.join(downloadsDir, `${date}.txt`);
        const downloads = fs.existsSync(downloadPath) ? parseInt(fs.readFileSync(downloadPath, 'utf8')) : 0;
        
        res.json({ date, visits, downloads });
    } catch (error) {
        console.error('Error getting stats:', error);
        res.status(500).json({ error: 'Failed to get stats' });
    }
});

// 启动服务器
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 