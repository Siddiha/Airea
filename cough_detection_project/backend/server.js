const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Initialize Firebase
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL
    })
  });
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Firebase initialization error:', error);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Simple API key middleware (for device authentication)
const authenticateDevice = (req, res, next) => {
  const apiKey = req.headers['x-api-key'] || req.query.api_key;
  
  if (!apiKey || apiKey !== process.env.API_SECRET_KEY) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or missing API key'
    });
  }
  next();
};

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Cough Detection Backend API',
    status: 'running',
    version: '1.0.0',
    endpoints: {
      telemetry: 'POST /api/telemetry',
      stats: 'GET /api/stats/:device_id'
    }
  });
});

// Import routes
const telemetryRoutes = require('./routes/telemetry');
app.use('/api/telemetry', authenticateDevice, telemetryRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    database: 'Firebase Firestore'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📡 Local: http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

