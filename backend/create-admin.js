const axios = require('axios');

const API_URL = 'http://127.0.0.1:3000/api';

async function createAdmin() {
    try {
        console.log('Creating admin user...');

        const userData = {
            name: 'Admin User',
            email: 'admin@test.com',
            password: 'password123',
            role: 'admin'
        };

        try {
            const response = await axios.post(`${API_URL}/auth/register`, userData);
            console.log('✅ Admin user created successfully!');
            console.log('Email:', userData.email);
            console.log('Password:', userData.password);
            console.log('Token:', response.data.token);
        } catch (error) {
            if (error.response && error.response.status === 400 && error.response.data.message === 'User already exists') {
                console.log('⚠️ Admin user already exists.');
                console.log('Email:', userData.email);
                console.log('Password:', userData.password);
            } else {
                throw error;
            }
        }

    } catch (error) {
        console.error('❌ Failed to create admin user:', error.response ? error.response.data : error.message);
    }
}

createAdmin();
