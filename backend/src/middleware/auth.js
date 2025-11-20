const { verifyToken } = require('../utils/jwt');

// Authentication middleware
async function authenticate(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                status: false,
                message: 'Unauthorized. No token provided.'
            });
        }

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token);

        if (!decoded) {
            return res.status(401).json({
                status: false,
                message: 'Unauthorized. Invalid or expired token.'
            });
        }

        // Attach user info to request
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({
            status: false,
            message: 'Unauthorized'
        });
    }
}

module.exports = {
    authenticate
};
