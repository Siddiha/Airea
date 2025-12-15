const admin = require('firebase-admin');

// Initialize Firebase connection
const initializeFirebase = () => {
  try {
    // Check if Firebase is already initialized
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL
        })
      });
      console.log('✅ Firebase Admin SDK initialized');
    }
    
    const db = admin.firestore();
    
    // Test connection
    db.collection('connection_test').doc('test').set({
      test: true,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    }).then(() => {
      console.log('✅ Firebase Firestore connection successful');
    }).catch(err => {
      console.error('❌ Firebase Firestore connection failed:', err);
    });
    
    return db;
  } catch (error) {
    console.error('❌ Failed to initialize Firebase:', error);
    throw error;
  }
};

module.exports = { initializeFirebase };