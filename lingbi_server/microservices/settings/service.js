/**
 * Settings Service — Lingbi v2.0
 * Complete REST API with AES-256-GCM encrypted storage,
 * configuration validation, and import/export support.
 *
 * IMPORTANT: Route order matters. Specific routes (health, export, etc.)
 * MUST be registered BEFORE the parameterized /settings/:key route.
 */
const express = require('express');
const cors = require('cors');
const path = require('path');
const { Storage, DEFAULT_SETTINGS } = require('./storage');
const { Crypto } = require('./crypto');

const app = express();
const PORT = 8087;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Initialize storage and crypto
const secretKey = process.env.SETTINGS_SECRET;
const crypto = new Crypto(secretKey);
const filePath = process.env.SETTINGS_FILE_PATH || path.join(__dirname, 'settings.json');
const storage = new Storage(filePath, crypto);

// ---------------------------------------------------------------
// Validation rules
// ---------------------------------------------------------------
storage.setValidation('theme', (val) => {
  return ['light', 'dark', 'system'].includes(val);
});

storage.setValidation('language', (val) => {
  return typeof val === 'string' && val.length >= 2;
});

storage.setValidation('autoSave', (val) => {
  return typeof val === 'boolean';
});

storage.setValidation('autoSaveInterval', (val) => {
  return typeof val === 'number' && val >= 1 && val <= 3600;
});

storage.setValidation('fontSize', (val) => {
  return typeof val === 'number' && val >= 8 && val <= 72;
});

storage.setValidation('editorMode', (val) => {
  return ['wysiwyg', 'markdown', 'source'].includes(val);
});

// Known setting keys (for PUT /settings/:key existence checks)
const KNOWN_KEYS = Object.keys(DEFAULT_SETTINGS);

// ---------------------------------------------------------------
// 1. GET /settings — Get all settings
// ---------------------------------------------------------------
app.get('/settings', async (_req, res) => {
  try {
    const settings = await storage.readAll();
    res.json({
      success: true,
      data: settings,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to read settings',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 10. GET /settings/health — Health check
// (Registered early to avoid /settings/:key capturing "health")
// ---------------------------------------------------------------
app.get('/settings/health', (_req, res) => {
  res.json({
    success: true,
    service: 'settings-service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// ---------------------------------------------------------------
// 6. GET /settings/export — Export all settings as JSON
// ---------------------------------------------------------------
app.get('/settings/export', async (_req, res) => {
  try {
    const settings = await storage.readAll();
    res.json({
      success: true,
      data: settings,
      exportedAt: new Date().toISOString(),
      version: '1.0'
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Export failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 4. POST /settings/encrypt — Encrypt sensitive data
// ---------------------------------------------------------------
app.post('/settings/encrypt', (req, res) => {
  try {
    const { text } = req.body;
    if (typeof text !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Bad request',
        message: 'Body must contain a "text" field with a string value'
      });
    }
    const encrypted = crypto.encrypt(text);
    res.json({
      success: true,
      encrypted,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Encryption failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 5. POST /settings/decrypt — Decrypt sensitive data
// ---------------------------------------------------------------
app.post('/settings/decrypt', (req, res) => {
  try {
    const { encrypted } = req.body;
    if (typeof encrypted !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Bad request',
        message: 'Body must contain an "encrypted" field with a string value'
      });
    }
    const decrypted = crypto.decrypt(encrypted);
    res.json({
      success: true,
      decrypted,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Decryption failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 7. POST /settings/import — Import settings from JSON
// ---------------------------------------------------------------
app.post('/settings/import', async (req, res) => {
  try {
    const { settings: importData } = req.body;
    if (!importData || typeof importData !== 'object' || Array.isArray(importData)) {
      return res.status(400).json({
        success: false,
        error: 'Bad request',
        message: 'Body must contain a "settings" object'
      });
    }

    // Read existing settings, merge with imported ones, keep known keys only
    const current = await storage.readAll();
    const merged = { ...current };
    for (const [key, value] of Object.entries(importData)) {
      if (KNOWN_KEYS.includes(key)) {
        const validation = storage.validate(key, value);
        if (validation.valid) {
          merged[key] = value;
        }
      }
    }
    await storage.writeAll(merged);
    const saved = await storage.readAll();

    res.json({
      success: true,
      data: saved,
      message: 'Settings imported successfully',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Import failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 8. POST /settings/reset — Reset settings to defaults
// ---------------------------------------------------------------
app.post('/settings/reset', async (_req, res) => {
  try {
    await storage.writeAll({ ...DEFAULT_SETTINGS });
    res.json({
      success: true,
      data: { ...DEFAULT_SETTINGS },
      message: 'Settings reset to defaults',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Reset failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 9. POST /settings/validate — Validate a setting value
// ---------------------------------------------------------------
app.post('/settings/validate', (req, res) => {
  try {
    const { key, value } = req.body;
    if (!key || typeof key !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Bad request',
        message: 'Body must contain a "key" field'
      });
    }
    const validation = storage.validate(key, value);
    res.json({
      success: true,
      valid: validation.valid,
      message: validation.message || null,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Validation failed',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 2. GET /settings/:key — Get a single setting
// (Must be after specific routes like /settings/health, /settings/export)
// ---------------------------------------------------------------
app.get('/settings/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const settings = await storage.readAll();
    if (!(key in settings)) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: `Setting '${key}' does not exist`
      });
    }
    res.json({
      success: true,
      data: { key, value: settings[key] },
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to read setting',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// 3. PUT /settings/:key — Update a single setting
// ---------------------------------------------------------------
app.put('/settings/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;

    // Check if key is known
    if (!KNOWN_KEYS.includes(key)) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: `Unknown setting key '${key}'`
      });
    }

    // Validate
    const validation = storage.validate(key, value);
    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        message: validation.message || `Invalid value for '${key}'`
      });
    }

    // Read current, update, write back
    const current = await storage.readAll();
    current[key] = value;
    await storage.writeAll(current);

    // Read back (so sensitive fields get decrypted for response)
    const updated = await storage.readAll();

    res.json({
      success: true,
      data: updated,
      message: `Setting '${key}' updated successfully`,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Failed to update setting',
      message: err.message
    });
  }
});

// ---------------------------------------------------------------
// Start server (only when not in test mode)
// ---------------------------------------------------------------
if (!process.env.SETTINGS_FILE_PATH) {
  app.listen(PORT, () => {
    console.log(`Settings Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/settings/health`);
    console.log(`API Base: http://localhost:${PORT}/settings`);
  });
}

// Graceful shutdown
process.on('SIGTERM', () => {
  process.exit(0);
});

process.on('SIGINT', () => {
  process.exit(0);
});

module.exports = app;