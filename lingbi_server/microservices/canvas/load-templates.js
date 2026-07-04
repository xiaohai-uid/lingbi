const fs = require('fs');
const path = require('path');

const templatesDir = path.join(__dirname, 'templates');

/**
 * Load all templates from the templates/ directory.
 * Returns an array of template objects parsed from JSON files.
 */
const loadTemplates = () => {
  if (!fs.existsSync(templatesDir)) {
    console.log('Templates directory not found');
    return [];
  }

  const templateFiles = fs.readdirSync(templatesDir)
    .filter(file => file.endsWith('.json'));

  const templates = [];

  templateFiles.forEach(file => {
    try {
      const content = fs.readFileSync(path.join(templatesDir, file), 'utf-8');
      const template = JSON.parse(content);
      // Assign an id based on the filename (without extension) so it's stable
      const id = path.basename(file, '.json');
      templates.push({ id, ...template });
      console.log(`Loaded template: ${template.name} (${id})`);
    } catch (error) {
      console.error(`Error loading template ${file}:`, error.message);
    }
  });

  console.log(`Loaded ${templates.length} templates`);
  return templates;
};

module.exports = { loadTemplates };