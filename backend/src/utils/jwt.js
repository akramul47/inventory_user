const jwt = require('jsonwebtoken');

// Generate JWT token
function generateToken(user) {
    const payload = {
        id: user.id,
        email: user.email,
        role: user.role
    };

    return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: '30d' // Token valid for 30 days
    });
}

// Verify and decode JWT token
function verifyToken(token) {
    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        return null;
    }
}

module.exports = {
    generateToken,
    verifyToken
};
