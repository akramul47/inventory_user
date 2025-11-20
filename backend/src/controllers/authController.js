const bcrypt = require('bcrypt');
const { OAuth2Client } = require('google-auth-library');
const { generateToken } = require('../utils/jwt');
const db = require('../config/database');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Register new user
async function register(req, res) {
    try {
        const { email, password, name } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                status: false,
                message: 'Email and password are required'
            });
        }

        // Check if user already exists
        const [existingUsers] = await db.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (existingUsers.length > 0) {
            return res.status(409).json({
                status: false,
                message: 'User with this email already exists'
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create user
        const [result] = await db.query(
            'INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)',
            [email, hashedPassword, name || email.split('@')[0], 'user']
        );

        const user = {
            id: result.insertId,
            email,
            name: name || email.split('@')[0],
            role: 'user'
        };

        // Generate token
        const token = generateToken(user);

        res.status(201).json({
            status: true,
            message: 'User registered successfully',
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                jwt_token: token
            }
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            status: false,
            message: 'Internal server error'
        });
    }
}

// Email/Password Login
async function login(req, res) {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                status: false,
                message: 'Email and password are required'
            });
        }

        // Find user by email
        const [users] = await db.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                status: false,
                message: 'Invalid credentials'
            });
        }

        const user = users[0];

        // Verify password
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({
                status: false,
                message: 'Invalid credentials'
            });
        }

        // Generate token
        const token = generateToken(user);

        res.json({
            status: true,
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                profile_image: user.profile_image,
                jwt_token: token
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            status: false,
            message: 'Internal server error'
        });
    }
}

// Google OAuth Login
async function googleLogin(req, res) {
    try {
        const { id_token } = req.body;

        if (!id_token) {
            return res.status(400).json({
                status: false,
                message: 'ID token is required'
            });
        }

        // Verify Google ID token
        const ticket = await googleClient.verifyIdToken({
            idToken: id_token,
            audience: process.env.GOOGLE_CLIENT_ID
        });

        const payload = ticket.getPayload();
        const googleId = payload.sub;
        const email = payload.email;
        const name = payload.name;
        const profileImage = payload.picture;

        // Check if user exists
        const [existingUsers] = await db.query(
            'SELECT * FROM users WHERE google_id = ? OR email = ?',
            [googleId, email]
        );

        let user;

        if (existingUsers.length > 0) {
            // User exists, update Google ID if needed
            user = existingUsers[0];

            if (!user.google_id) {
                await db.query(
                    'UPDATE users SET google_id = ?, profile_image = ? WHERE id = ?',
                    [googleId, profileImage, user.id]
                );
                user.google_id = googleId;
                user.profile_image = profileImage;
            }
        } else {
            // Create new user
            const [result] = await db.query(
                'INSERT INTO users (email, google_id, name, profile_image, role) VALUES (?, ?, ?, ?, ?)',
                [email, googleId, name, profileImage, 'user']
            );

            user = {
                id: result.insertId,
                email,
                google_id: googleId,
                name,
                profile_image: profileImage,
                role: 'user'
            };
        }

        // Generate token
        const token = generateToken(user);

        res.json({
            status: true,
            message: 'Google login successful',
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                google_id: user.google_id,
                profile_image: user.profile_image,
                jwt_token: token
            }
        });
    } catch (error) {
        console.error('Google login error:', error);
        res.status(500).json({
            status: false,
            message: 'Google authentication failed'
        });
    }
}

// Get current user
async function getCurrentUser(req, res) {
    try {
        const userId = req.user.id;

        const [users] = await db.query(
            'SELECT id, email, name, role, profile_image FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'User not found'
            });
        }

        res.json({
            status: true,
            user: users[0]
        });
    } catch (error) {
        console.error('Get current user error:', error);
        res.status(500).json({
            status: false,
            message: 'Internal server error'
        });
    }
}

module.exports = {
    register,
    login,
    googleLogin,
    getCurrentUser
};
