const crypto = require('crypto');

class Crypto {
  constructor(secretKey) {
    // Generate a 32-byte key from the secret (for AES-256)
    this.algorithm = 'aes-256-cbc';
    this.key = crypto.scryptSync(secretKey, 'salt', 32);
  }

  encrypt(text) {
    try {
      // Generate a random initialization vector (IV)
      const iv = crypto.randomBytes(16);
      
      // Create cipher
      const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
      
      // Encrypt text
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Combine IV and encrypted data
      return iv.toString('hex') + ':' + encrypted;
    } catch (err) {
      console.error('Encryption error:', err);
      throw new Error('Failed to encrypt data');
    }
  }

  decrypt(encryptedText) {
    try {
      // Split IV and encrypted data
      const parts = encryptedText.split(':');
      if (parts.length !== 2) {
        throw new Error('Invalid encrypted data format');
      }
      
      const iv = Buffer.from(parts[0], 'hex');
      const encrypted = parts[1];
      
      // Create decipher
      const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
      
      // Decrypt
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (err) {
      console.error('Decryption error:', err);
      throw new Error('Failed to decrypt data');
    }
  }
}

module.exports = { Crypto };
