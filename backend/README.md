# Inventory Backend - Node.js/Express

Backend API for inventory management mobile app.

## Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- MySQL (v5.7 or higher)
- npm or yarn

### Installation

1. **Install dependencies**:
```bash
cd backend
npm install
```

2. **Configure environment**:
```bash
# Copy the example env file
cp .env.example .env

# Edit .env with your settings:
# - Database credentials
# - JWT secret
# - Google OAuth credentials
```

3. **Create database and run migrations**:
```bash
npm run migrate
```

### Running the Server

**Development mode** (with auto-restart):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

The server will run on `http://localhost:3000` (or the PORT in your .env file)

## API Endpoints

### Authentication
- `POST /api/auth/login` - Email/password login
- `POST /api/auth/google` - Google OAuth login
- `GET /api/auth/me` - Get current user (protected)

### Products (Coming soon)
- `GET /api/products` - List products
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Health Check
- `GET /health` - Server health status

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js      # MySQL connection
│   │   └── migrate.js       # Database migration
│   ├── controllers/
│   │   └── authController.js
│   ├── middleware/
│   │   └── auth.js          # JWT authentication
│   ├── routes/
│   │   └── auth.js
│   ├── utils/
│   │   └── jwt.js
│   └── app.js
├── uploads/                  # Product images
├── .env                      # Environment variables
├── package.json
└── server.js                 # Entry point
```

## Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add your client ID to `.env`
6. Update Flutter app's `api_constants.dart` with backend URL

## Next Steps

- [ ] Implement product endpoints
- [ ] Add image upload handling
- [ ] Implement reports endpoints
- [ ] Add CSV import/export
- [ ] Deploy to cPanel
