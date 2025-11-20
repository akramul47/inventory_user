const app = require('./src/app');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`\n🚀 Server running on port ${PORT}`);
    console.log(`📍 API: http://localhost:${PORT}/api`);
    console.log(`💚 Health: http://localhost:${PORT}/health\n`);
});
