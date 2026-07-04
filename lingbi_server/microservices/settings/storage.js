/**
 * Storage utility for Settings Service
 * Encrypted JSON file storage with auto-encryption of sensitive fields
 */
const fs = require('fs').promises;
const path = require('path');

// Fields that should be automatically encrypted when stored
const SENSITIVE_FIELDS = ['apiKey', 'secret', 'token'];

// Default settings as specified in the task brief
const DEFAULT_SETTINGS = {
  theme: 'system',
  language: 'zh-CN',
  autoSave: true,
  autoSaveInterval: 30,
  fontSize: 16,
  editorMode: 'wysiwyg'
};

class Storage {
  /**
   * @param {string} filePath - Path to the settings JSON file
   * @param {import('./crypto').Crypto} cryptoInstance - Crypto instance for encryption/decryption
   */
  constructor(filePath, cryptoInstance) {
    this.filePath = filePath;
    this.crypto = cryptoInstance;
    this._validators = {};
    this._initialized = this._init();
  }

  async _init() {
    await this._ensureFileExists();
  }

  async _ensureFileExists() {
    try {
      await fs.access(this.filePath);
    } catch {
      const dir = path.dirname(this.filePath);
      await fs.mkdir(dir, { recursive: true });
      await this._writeRaw(JSON.stringify(DEFAULT_SETTINGS, null, 2));
    }
  }

  async _readRaw() {
    return await fs.readFile(this.filePath, 'utf8');
  }

  async _writeRaw(content) {
    await fs.writeFile(this.filePath, content, 'utf8');
  }

  /**
   * Check if a field name is sensitive (needs encryption)
   * @param {string} key
   * @returns {boolean}
   */
  _isSensitive(key) {
    return SENSITIVE_FIELDS.some(
      (sf) => key.toLowerCase().includes(sf.toLowerCase())
    );
  }

  /**
   * Read all settings, decrypting sensitive fields
   * @returns {Promise<object>}
   */
  async readAll() {
    try {
      await this._initialized;
      const raw = await this._readRaw();
      const data = JSON.parse(raw);
      // Decrypt sensitive fields
      for (const key of Object.keys(data)) {
        if (this._isSensitive(key) && typeof data[key] === 'string' && data[key]) {
          // Check if the value looks encrypted (contains colons)
          if (data[key].includes(':')) {
            try {
              data[key] = this.crypto.decrypt(data[key]);
            } catch {
              // If decryption fails, keep the value as-is
            }
          }
        }
      }
      return data;
    } catch {
      return { ...DEFAULT_SETTINGS };
    }
  }

  /**
   * Write all settings, encrypting sensitive fields
   * @param {object} data
   */
  async writeAll(data) {
    await this._initialized;
    const toWrite = { ...data };
    for (const key of Object.keys(toWrite)) {
      if (this._isSensitive(key) && toWrite[key]) {
        toWrite[key] = this.crypto.encrypt(String(toWrite[key]));
      }
    }
    await this._writeRaw(JSON.stringify(toWrite, null, 2));
  }

  /**
   * Register a validation function for a given key
   * @param {string} key
   * @param {function} validatorFn - Returns boolean
   */
  setValidation(key, validatorFn) {
    this._validators[key] = validatorFn;
  }

  /**
   * Validate a setting value against registered rules
   * @param {string} key
   * @param {*} value
   * @returns {{ valid: boolean, message?: string }}
   */
  validate(key, value) {
    if (this._validators[key]) {
      try {
        const result = this._validators[key](value);
        if (result === true) {
          return { valid: true };
        }
        return { valid: false, message: typeof result === 'string' ? result : `Invalid value for '${key}'` };
      } catch (err) {
        return { valid: false, message: err.message };
      }
    }
    return { valid: true };
  }
}

module.exports = { Storage, DEFAULT_SETTINGS, SENSITIVE_FIELDS };