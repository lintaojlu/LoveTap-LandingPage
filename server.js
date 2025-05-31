const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const app = express();

// 静态文件服务
app.use(express.static('.'));

// 记录统计数据的端点
app.post('/record-stat', async (req, res) => {
    try {
        const { type, date } = req.query;
        
        // 验证参数
        if (!type || !date || !['visit', 'download'].includes(type)) {
            return res.status(400).send('Invalid parameters');
        }
        
        // 确定文件路径
        const filePath = path.join(__dirname, 'stats', type + 's', `${date}.txt`);
        
        // 读取现有计数（如果文件存在）
        let count = 1;
        try {
            const data = await fs.readFile(filePath, 'utf8');
            count = parseInt(data.trim()) + 1;
        } catch (error) {
            // 文件不存在，使用默认值1
        }
        
        // 写入新的计数
        await fs.writeFile(filePath, count.toString());
        
        res.send('Success');
    } catch (error) {
        console.error('Error recording stat:', error);
        res.status(500).send('Internal server error');
    }
});

// 启动服务器
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
}); 