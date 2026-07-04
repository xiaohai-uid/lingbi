const fs = require('fs').promises;
const path = require('path');

class Storage {
  constructor(filePath) {
    this.filePath = filePath;
    this.init();
  }

  async init() {
    try {
      await this.ensureFileExists();
    } catch (err) {
      console.error('Error initializing storage:', err);
      throw err;
    }
  }

  async ensureFileExists() {
    try {
      await fs.access(this.filePath);
    } catch (err) {
      // File doesn't exist, create it with default content
      const dir = path.dirname(this.filePath);
      await fs.mkdir(dir, { recursive: true });
      
      const defaultSettings = {
        theme: 'light',
        language: 'en',
        apiKey: '',
        model: 'default',
        quota: 1000
      };
      
      await this.writeFile(JSON.stringify(defaultSettings, null, 2));
      console.log(`Created new settings file: ${this.filePath}`);
    }
  }

  async readAll() {
    try {
      const data = await this.readFile();
      return JSON.parse(data);
    } catch (err) {
      console.error('Error reading settings file:', err);
      // Return defaults if file is corrupted or unreadable
      return {
        theme: 'light',
        language: 'en',
        apiKey: '',
        model: 'default',
        quota: 1000
      };
    }
  }

  async writeAll(data) {
    try {
      await this.writeFile(JSON.stringify(data, null, 2));
    } catch (err) {
      console.error('Error writing settings file:', err);
      throw err;
    }
  }

  async readFile() {
    return await fs.readFile(this.filePath, 'utf8');
  }

  async writeFile(content) {
    await fs.writeFile(this.filePath, content, 'utf8');
  }
}

module.exports = { Storage };
