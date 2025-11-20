const axios = require('axios');

const API_URL = 'http://localhost:3000/api';

// Test data
const testUser = {
    email: 'test@example.com',
    password: 'Test123456',
    name: 'Test User'
};

let authToken = '';

// Helper function to make requests
async function makeRequest(method, endpoint, data = null, headers = {}) {
    try {
        const response = await axios({
            method,
            url: `${API_URL}${endpoint}`,
            data,
            headers
        });
        return { success: true, data: response.data, status: response.status };
    } catch (error) {
        return {
            success: false,
            error: error.response?.data || error.message,
            status: error.response?.status
        };
    }
}

// Test 1: Register new user
async function testRegister() {
    console.log('\n📝 Testing User Registration...');
    console.log('POST /api/auth/register');
    console.log('Data:', JSON.stringify(testUser, null, 2));

    const result = await makeRequest('POST', '/auth/register', testUser);

    if (result.success) {
        console.log('✅ Registration successful!');
        console.log('Response:', JSON.stringify(result.data, null, 2));
        authToken = result.data.token || result.data.user?.jwt_token;
        return true;
    } else {
        console.log('❌ Registration failed!');
        console.log('Error:', JSON.stringify(result.error, null, 2));

        // If user already exists, try to login instead
        if (result.status === 409) {
            console.log('\n⚠️  User already exists, will try login instead...');
            return false;
        }
        return false;
    }
}

// Test 2: Login with credentials
async function testLogin() {
    console.log('\n🔐 Testing User Login...');
    console.log('POST /api/auth/login');
    console.log('Data:', JSON.stringify({
        email: testUser.email,
        password: testUser.password
    }, null, 2));

    const result = await makeRequest('POST', '/auth/login', {
        email: testUser.email,
        password: testUser.password
    });

    if (result.success) {
        console.log('✅ Login successful!');
        console.log('Response:', JSON.stringify(result.data, null, 2));
        authToken = result.data.token || result.data.user?.jwt_token;
        return true;
    } else {
        console.log('❌ Login failed!');
        console.log('Error:', JSON.stringify(result.error, null, 2));
        return false;
    }
}

// Test 3: Get current user (protected route)
async function testGetCurrentUser() {
    console.log('\n👤 Testing Get Current User (Protected Route)...');
    console.log('GET /api/auth/me');
    console.log('Authorization: Bearer', authToken ? authToken.substring(0, 20) + '...' : 'NO TOKEN');

    const result = await makeRequest('GET', '/auth/me', null, {
        'Authorization': `Bearer ${authToken}`
    });

    if (result.success) {
        console.log('✅ Get current user successful!');
        console.log('Response:', JSON.stringify(result.data, null, 2));
        return true;
    } else {
        console.log('❌ Get current user failed!');
        console.log('Error:', JSON.stringify(result.error, null, 2));
        return false;
    }
}

// Test 4: Test protected route without token
async function testProtectedWithoutToken() {
    console.log('\n🚫 Testing Protected Route Without Token...');
    console.log('GET /api/auth/me (no auth header)');

    const result = await makeRequest('GET', '/auth/me');

    if (!result.success) {
        console.log('✅ Correctly rejected! (Expected behavior)');
        console.log('Error:', JSON.stringify(result.error, null, 2));
        return true;
    } else {
        console.log('❌ Should have been rejected but was accepted!');
        return false;
    }
}

// Run all tests
async function runTests() {
    console.log('='.repeat(60));
    console.log('🧪 AUTHENTICATION ENDPOINT TESTS');
    console.log('='.repeat(60));

    let testResults = {
        passed: 0,
        failed: 0
    };

    // Test registration
    const registerSuccess = await testRegister();
    if (registerSuccess) testResults.passed++;
    else testResults.failed++;

    // Always test login (even if registration failed due to existing user)
    const loginSuccess = await testLogin();
    if (loginSuccess) testResults.passed++;
    else testResults.failed++;

    // Test protected route with token
    if (authToken) {
        const getCurrentUserSuccess = await testGetCurrentUser();
        if (getCurrentUserSuccess) testResults.passed++;
        else testResults.failed++;

        // Test protected route without token
        const protectedWithoutTokenSuccess = await testProtectedWithoutToken();
        if (protectedWithoutTokenSuccess) testResults.passed++;
        else testResults.failed++;
    } else {
        console.log('\n⚠️  Skipping protected route tests - no auth token available');
        testResults.failed += 2;
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 TEST SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Passed: ${testResults.passed}`);
    console.log(`❌ Failed: ${testResults.failed}`);
    console.log(`📈 Total: ${testResults.passed + testResults.failed}`);
    console.log('='.repeat(60));

    process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run tests
runTests();
