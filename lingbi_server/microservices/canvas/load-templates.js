const fs = require('fs');
const path = require('path');
const sqlite3 = require('better-sqlite3');

const dbPath = path.join(__dirname, 'canvas.db');
const db = new sqlite3(dbPath);

// Create templates table if it doesn't exist
db.exec(`
  CREATE TABLE IF NOT EXISTS templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT DEFAULT 'story',
    structure TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// Load templates from templates directory
const templatesDir = path.join(__dirname, 'templates');

const loadTemplates = () => {
  if (!fs.existsSync(templatesDir)) {
    console.log('Templates directory not found');
    return;
  }

  const templateFiles = fs.readdirSync(templatesDir)
    .filter(file => file.endsWith('.json'));

  const insertTemplate = db.prepare(`
    INSERT INTO templates (name, description, category, structure) 
    VALUES (?, ?, ?, ?)
    ON CONFLICT(name) DO UPDATE SET
      description = excluded.description,
      category = excluded.category,
      structure = excluded.structure
  `);

  templateFiles.forEach(file => {
    try {
      const content = fs.readFileSync(path.join(templatesDir, file), 'utf-8');
      const template = JSON.parse(content);

      insertTemplate.run(
        template.name,
        template.description || '',
        template.category || 'story',
        JSON.stringify(template.structure)
      );

      console.log(`Loaded template: ${template.name}`);
    } catch (error) {
      console.error(`Error loading template ${file}:`, error.message);
    }
  });

  console.log(`Loaded ${templateFiles.length} templates`);
};

loadTemplates();
