const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const db = admin.firestore();

// POST endpoint to receive cough events from ESP32
router.post('/', async (req, res) => {
  try {
    const eventData = req.body;
    
    // Validate required fields
    const requiredFields = ['device_id', 'timestamp', 'telemetry'];
    for (const field of requiredFields) {
      if (!eventData[field]) {
        return res.status(400).json({
          error: `Missing required field: ${field}`,
          received_data: eventData
        });
      }
    }
    
    // Add server timestamp and unique ID
    const coughEvent = {
      ...eventData,
      server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
      event_id: `${eventData.device_id}_${Date.now()}`,
      processed: false
    };
    
    // Save to Firebase Firestore
    const docRef = await db.collection('cough_events').add(coughEvent);
    
    console.log(`📥 Cough event saved: ${docRef.id} from ${coughEvent.device_id}`);
    
    // Send acknowledgment
    res.status(201).json({
      status: 'success',
      message: 'Cough event recorded successfully',
      event_id: docRef.id,
      device_id: coughEvent.device_id,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error saving cough event:', error);
    res.status(500).json({
      error: 'Failed to save cough event',
      message: error.message
    });
  }
});

// GET endpoint to retrieve cough events for a specific device
router.get('/:device_id', async (req, res) => {
  try {
    const { device_id } = req.params;
    const { limit = 50, start_date, end_date } = req.query;
    
    let query = db.collection('cough_events')
      .where('device_id', '==', device_id)
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit));
    
    // Apply date filters if provided
    if (start_date) {
      query = query.where('timestamp', '>=', start_date);
    }
    if (end_date) {
      query = query.where('timestamp', '<=', end_date);
    }
    
    const snapshot = await query.get();
    
    const events = [];
    snapshot.forEach(doc => {
      events.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json({
      device_id,
      count: events.length,
      events
    });
    
  } catch (error) {
    console.error('❌ Error fetching cough events:', error);
    res.status(500).json({
      error: 'Failed to fetch cough events',
      message: error.message
    });
  }
});

module.exports = router;