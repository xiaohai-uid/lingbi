/**
 * Crypto utility for Settings Service
 * AES-256-GCM encryption/decryption using Node.js built-in crypto module
 */
const crypto = require('crypto');
const os = require('os');

class Crypto {
  /**
   * @param {string} [secretKey] - Encryption key. Defaults to device fingerprint.
   */
  constructor(secretKey) {
    this.algorithm = 'aes-256-gcm';
    const key = secretKey || this._getDeviceFingerprint();
    this.key = crypto.scryptSync(key, 'lingbi-settings-salt', 32);
  }

  /**
   * Generate a device fingerprint as fallback key
   * @returns {string}
   */
  _getDeviceFingerprint() {
    const hostname = os.hostname();
    const cpus = os.cpus();
    const cpuInfo = cpus.length > 0 ? cpus[0].model : 'unknown';
    const totalMem = os.totalmem();
    return `${hostname}-${cpuInfo}-${totalMem}-lingbi-default-secret`;
  }

  /**
   * Encrypt text using AES-256-GCM
   * @param {string} text - Plaintext to encrypt
   * @returns {string} Hex-encoded encrypted string (iv:authTag:ciphertext)
   */
  encrypt(text) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
  }

  /**
   * Decrypt hex-encoded encrypted text
   * @param {string} encryptedHex - Hex-encoded encrypted string (iv:authTag:ciphertext)
   * @returns {string} Decrypted plaintext
   */
  decrypt(encryptedHex) {
    const parts = encryptedHex.split(':');
    if (parts.length !== 3) {
      throw new Error('Invalid encrypted data format: expected iv:authTag:ciphertext');
    }
    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encrypted = parts[2];
    const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }
}

module.exports = { Crypto };