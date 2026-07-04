/**
 * Unit tests for Settings Service
 * Tests crypto.js, storage.js, and service.js
 */
const request = require('supertest');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');

// Set test environment before requiring modules
process.env.SETTINGS_SECRET = 'test-secret-key-for-unit-tests-2024';

const { Crypto } = require('../crypto');
const { Storage } = require('../storage');

// We need to import the app but avoid starting the server listener
// The service.js exports app at the end
let app;

beforeAll(() => {
  // Set test file path
  process.env.SETTINGS_FILE_PATH = path.join(__dirname, 'test-settings.json');
  app = require('../service');
});

afterAll(async () => {
  // Clean up test file
  try {
    await fs.unlink(path.join(__dirname, 'test-settings.json'));
  } catch (_) {
    // ignore
  }
  // Forcefully close any open handles
  delete require.cache[require.resolve('../service')];
});

describe('Crypto (AES-256-GCM)', () => {
  let crypto;

  beforeAll(() => {
    crypto = new Crypto(process.env.SETTINGS_SECRET);
  });

  test('should encrypt and decrypt text correctly', () => {
    const original = 'Hello Lingbi!';
    const encrypted = crypto.encrypt(original);
    expect(encrypted).toBeDefined();
    expect(typeof encrypted).toBe('string');
    expect(encrypted).not.toBe(original);
    const decrypted = crypto.decrypt(encrypted);
    expect(decrypted).toBe(original);
  });

  test('should produce different ciphertext for same plaintext (random IV)', () => {
    const original = 'same text';
    const encrypted1 = crypto.encrypt(original);
    const encrypted2 = crypto.encrypt(original);
    expect(encrypted1).not.toBe(encrypted2);
  });

  test('should handle empty string', () => {
    const encrypted = crypto.encrypt('');
    const decrypted = crypto.decrypt(encrypted);
    expect(decrypted).toBe('');
  });

  test('should handle special characters and unicode', () => {
    const original = '你好世界! @#$%^&*() 日本語 🔑';
    const encrypted = crypto.encrypt(original);
    const decrypted = crypto.decrypt(encrypted);
    expect(decrypted).toBe(original);
  });

  test('should throw on invalid encrypted data', () => {
    expect(() => crypto.decrypt('invalid-hex-data')).toThrow();
  });

  test('should use SETTINGS_SECRET env var', () => {
    const crypto1 = new Crypto('secret1');
    const crypto2 = new Crypto('secret2');
    const encrypted1 = crypto1.encrypt('test');
    const encrypted2 = crypto2.encrypt('test');
    expect(encrypted1).not.toBe(encrypted2);
    expect(crypto1.decrypt(encrypted1)).toBe('test');
    expect(() => crypto2.decrypt(encrypted1)).toThrow();
  });

  test('should derive key using device fingerprint when no secret provided', () => {
    const cryptoDefault = new Crypto();
    const txt = 'default-key-test';
    const enc = cryptoDefault.encrypt(txt);
    expect(cryptoDefault.decrypt(enc)).toBe(txt);
  });
});

describe('Storage', () => {
  const testFilePath = path.join(__dirname, 'test-storage.json');
  let crypto;
  let storage;

  beforeAll(() => {
    crypto = new Crypto(process.env.SETTINGS_SECRET);
  });

  beforeEach(async () => {
    // Remove test file if exists
    try {
      await fs.unlink(testFilePath);
    } catch (_) { /* ignore */ }
    storage = new Storage(testFilePath, crypto);
    // Wait for async init
    await new Promise(resolve => setTimeout(resolve, 50));
  });

  afterAll(async () => {
    try {
      await fs.unlink(testFilePath);
    } catch (_) { /* ignore */ }
  });

  test('should initialize with default settings', async () => {
    const settings = await storage.readAll();
    expect(settings.theme).toBe('system');
    expect(settings.language).toBe('zh-CN');
    expect(settings.autoSave).toBe(true);
    expect(settings.autoSaveInterval).toBe(30);
    expect(settings.fontSize).toBe(16);
    expect(settings.editorMode).toBe('wysiwyg');
  });

  test('should auto-encrypt sensitive fields on write', async () => {
    const data = {
      theme: 'dark',
      apiKey: 'sk-test-key-12345',
      secret: 'my-secret-value',
      token: 'auth-token-abc',
      language: 'en'
    };
    await storage.writeAll(data);
    // Read raw file to verify encryption
    const raw = await fs.readFile(testFilePath, 'utf8');
    const rawObj = JSON.parse(raw);
    expect(rawObj.theme).toBe('dark');
    expect(rawObj.language).toBe('en');
    // Sensitive fields should be encrypted (not plaintext)
    expect(rawObj.apiKey).not.toBe('sk-test-key-12345');
    expect(rawObj.secret).not.toBe('my-secret-value');
    expect(rawObj.token).not.toBe('auth-token-abc');
    expect(typeof rawObj.apiKey).toBe('string');
    expect(rawObj.apiKey.length).toBeGreaterThan(10);
  });

  test('should auto-decrypt sensitive fields on read', async () => {
    const data = {
      theme: 'dark',
      apiKey: 'sk-test-key-12345',
      secret: 'my-secret-value',
      token: 'auth-token-abc'
    };
    await storage.writeAll(data);
    const settings = await storage.readAll();
    expect(settings.apiKey).toBe('sk-test-key-12345');
    expect(settings.secret).toBe('my-secret-value');
    expect(settings.token).toBe('auth-token-abc');
    expect(settings.theme).toBe('dark');
  });

  test('should respect validation rules', async () => {
    storage.setValidation('theme', (val) => {
      return ['light', 'dark', 'system'].includes(val);
    });
    const result = storage.validate('theme', 'dark');
    expect(result.valid).toBe(true);
    const result2 = storage.validate('theme', 'invalid-theme');
    expect(result2.valid).toBe(false);
  });
});

describe('Service API', () => {
  const testFilePath = path.join(__dirname, 'test-settings.json');

  beforeAll(async () => {
    // Clear test file
    try {
      await fs.unlink(testFilePath);
    } catch (_) { /* ignore */ }
  });

  afterAll(async () => {
    try {
      await fs.unlink(testFilePath);
    } catch (_) { /* ignore */ }
  });

  // Test health check
  test('GET /settings/health should return healthy status', async () => {
    const res = await request(app).get('/settings/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.service).toBe('settings-service');
    expect(res.body.status).toBe('healthy');
    expect(res.body).toHaveProperty('timestamp');
  });

  // Test get all settings
  test('GET /settings should return all settings with defaults', async () => {
    const res = await request(app).get('/settings');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.theme).toBe('system');
    expect(res.body.data.language).toBe('zh-CN');
    expect(res.body.data.autoSave).toBe(true);
    expect(res.body.data.autoSaveInterval).toBe(30);
    expect(res.body.data.fontSize).toBe(16);
    expect(res.body.data.editorMode).toBe('wysiwyg');
    expect(res.body).toHaveProperty('timestamp');
  });

  // Test get single setting
  test('GET /settings/:key should return a single setting', async () => {
    const res = await request(app).get('/settings/theme');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.key).toBe('theme');
    expect(res.body.data.value).toBe('system');
  });

  test('GET /settings/:key should return 404 for missing key', async () => {
    const res = await request(app).get('/settings/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  // Test update single setting
  test('PUT /settings/:key should update a setting', async () => {
    const res = await request(app)
      .put('/settings/theme')
      .send({ value: 'dark' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.theme).toBe('dark');
  });

  test('PUT /settings/:key should reject invalid value', async () => {
    const res = await request(app)
      .put('/settings/autoSaveInterval')
      .send({ value: -5 });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('PUT /settings/:key should return 404 for unknown key', async () => {
    const res = await request(app)
      .put('/settings/unknownKey')
      .send({ value: 'test' });
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  // Test encrypt endpoint
  test('POST /settings/encrypt should encrypt sensitive data', async () => {
    const res = await request(app)
      .post('/settings/encrypt')
      .send({ text: 'my-secret-api-key' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body).toHaveProperty('encrypted');
    expect(typeof res.body.encrypted).toBe('string');
    expect(res.body.encrypted).not.toBe('my-secret-api-key');
  });

  // Test decrypt endpoint
  test('POST /settings/decrypt should decrypt encrypted data', async () => {
    // First encrypt
    const encRes = await request(app)
      .post('/settings/encrypt')
      .send({ text: 'decrypt-me-please' });
    const encrypted = encRes.body.encrypted;

    // Then decrypt
    const decRes = await request(app)
      .post('/settings/decrypt')
      .send({ encrypted });
    expect(decRes.status).toBe(200);
    expect(decRes.body.success).toBe(true);
    expect(decRes.body.decrypted).toBe('decrypt-me-please');
  });

  // Test export
  test('GET /settings/export should export all settings as JSON', async () => {
    const res = await request(app).get('/settings/export');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('theme');
    expect(res.body.data).toHaveProperty('language');
    expect(res.body).toHaveProperty('exportedAt');
  });

  // Test import
  test('POST /settings/import should import settings from JSON', async () => {
    const importData = {
      theme: 'light',
      language: 'en-US',
      fontSize: 18
    };
    const res = await request(app)
      .post('/settings/import')
      .send({ settings: importData });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.theme).toBe('light');
    expect(res.body.data.language).toBe('en-US');
    expect(res.body.data.fontSize).toBe(18);
    // Original defaults should still be there for non-overridden fields
    expect(res.body.data.autoSave).toBe(true);
  });

  test('POST /settings/import should reject invalid import data', async () => {
    const res = await request(app)
      .post('/settings/import')
      .send({ settings: 'not-an-object' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Test reset
  test('POST /settings/reset should reset to defaults', async () => {
    // First change a setting
    await request(app)
      .put('/settings/theme')
      .send({ value: 'light' });
    // Then reset
    const res = await request(app).post('/settings/reset');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.theme).toBe('system');
    expect(res.body.data.language).toBe('zh-CN');
    expect(res.body.data.autoSave).toBe(true);
    expect(res.body.data.autoSaveInterval).toBe(30);
    expect(res.body.data.fontSize).toBe(16);
    expect(res.body.data.editorMode).toBe('wysiwyg');
  });

  // Test validate
  test('POST /settings/validate should validate settings', async () => {
    const res = await request(app)
      .post('/settings/validate')
      .send({ key: 'theme', value: 'dark' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.valid).toBe(true);
  });

  test('POST /settings/validate should reject invalid values', async () => {
    const res = await request(app)
      .post('/settings/validate')
      .send({ key: 'autoSaveInterval', value: -1 });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.valid).toBe(false);
    expect(res.body).toHaveProperty('message');
  });
});