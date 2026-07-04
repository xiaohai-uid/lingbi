const express = require('express');
const cors = require('cors');
const path = require('path');
const { Storage } = require('./storage');
const { Crypto } = require('./crypto');

const app = express();
const PORT = 8087;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Initialize storage
const storage = new Storage(path.join(__dirname, 'settings.json'));
const crypto = new Crypto('lingbi-settings-encryption-key-2024');

// Settings fields
const SETTINGS_FIELDS = ['theme', 'language', 'apiKey', 'model', 'quota'];

// GET / - Get all settings
app.get('/', async (req, res) => {
  try {
    const settings = await storage.readAll();
    
    // Decrypt apiKey if present
    if (settings.apiKey) {
      try {
        settings.apiKey = crypto.decrypt(settings.apiKey);
      } catch (err) {
        console.error('Failed to decrypt apiKey:', err.message);
      }
    }
    
    res.json({
      success: true,
      data: settings,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error reading settings:', err);
    res.status(500).json({
      success: false,
      error: 'Failed to read settings',
      message: err.message
    });
  }
});

// PUT / - Create or update settings
app.put('/', async (req, res) => {
  try {
    const settings = req.body;
    
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({
        success: false,
        error: 'Invalid input',
        message: 'Settings must be an object'
      });
    }
    
    // Validate and sanitize input
    const sanitizedSettings = {};
    for (const [key, value] of Object.entries(settings)) {
      if (SETTINGS_FIELDS.includes(key)) {
        if (key === 'apiKey' && value) {
          // Encrypt apiKey before storing
          sanitizedSettings[key] = crypto.encrypt(String(value));
        } else {
          sanitizedSettings[key] = value;
        }
      }
    }
    
    // Merge with existing settings
    const existingSettings = await storage.readAll();
    const updatedSettings = { ...existingSettings, ...sanitizedSettings };
    
    await storage.writeAll(updatedSettings);
    
    // Decrypt apiKey for response
    if (updatedSettings.apiKey) {
      try {
        updatedSettings.apiKey = crypto.decrypt(updatedSettings.apiKey);
      } catch (err) {
        console.error('Failed to decrypt apiKey for response:', err.message);
      }
    }
    
    res.json({
      success: true,
      data: updatedSettings,
      message: 'Settings updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error updating settings:', err);
    res.status(500).json({
      success: false,
      error: 'Failed to update settings',
      message: err.message
    });
  }
});

// DELETE / - Reset settings to defaults
app.delete('/', async (req, res) => {
  try {
    const defaultSettings = {
      theme: 'light',
      language: 'en',
      apiKey: '',
      model: 'default',
      quota: 1000
    };
    
    await storage.writeAll(defaultSettings);
    
    res.json({
      success: true,
      data: defaultSettings,
      message: 'Settings reset to defaults',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error resetting settings:', err);
    res.status(500).json({
      success: false,
      error: 'Failed to reset settings',
      message: err.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    service: 'settings-service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Settings Service running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API Endpoints: GET/PUT/DELETE http://localhost:${PORT}/`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

module.exports = app;
