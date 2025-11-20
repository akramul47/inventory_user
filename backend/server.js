const app = require('./src/app');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 Server running on port ${PORT}`);
    console.log(`📍 API: http://localhost:${PORT}/api`);
    console.log(`📍 Network: http://192.168.31.64:${PORT}/api`);
    console.log(`💚 Health: http://localhost:${PORT}/health\n`);
});
