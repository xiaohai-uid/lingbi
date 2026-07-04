const express = require('express');
const sqlite3 = require('better-sqlite3');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = 8091;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Database setup
const db = new sqlite3(path.join(__dirname, 'canvas.db'));
db.pragma('journal_mode = WAL');

// Create tables
const createTables = () => {
  db.exec(`
    CREATE TABLE IF NOT EXISTS canvases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS nodes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      canvas_id INTEGER NOT NULL,
      type TEXT NOT NULL DEFAULT 'text',
      position_x REAL NOT NULL,
      position_y REAL NOT NULL,
      width REAL DEFAULT 200,
      height REAL DEFAULT 100,
      content TEXT,
      metadata TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (canvas_id) REFERENCES canvases(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS edges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      canvas_id INTEGER NOT NULL,
      source_node_id INTEGER NOT NULL,
      target_node_id INTEGER NOT NULL,
      type TEXT NOT NULL DEFAULT 'arrow',
      label TEXT,
      metadata TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (canvas_id) REFERENCES canvases(id) ON DELETE CASCADE,
      FOREIGN KEY (source_node_id) REFERENCES nodes(id) ON DELETE CASCADE,
      FOREIGN KEY (target_node_id) REFERENCES nodes(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      description TEXT,
      category TEXT DEFAULT 'story',
      structure TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS template_usage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      canvas_id INTEGER NOT NULL,
      template_id INTEGER NOT NULL,
      used_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (canvas_id) REFERENCES canvases(id) ON DELETE CASCADE,
      FOREIGN KEY (template_id) REFERENCES templates(id) ON DELETE CASCADE
    );
  `);
};

createTables();

// Force-directed layout algorithm
const calculateForceDirectedLayout = (nodes, edges, iterations = 300) => {
  const width = 1000;
  const height = 800;
  const repulsion = 1000;
  const attraction = 0.01;
  const damping = 0.7;
  
  // Initialize positions randomly if needed
  nodes.forEach(node => {
    if (node.position_x === undefined || node.position_y === undefined) {
      node.position_x = Math.random() * width;
      node.position_y = Math.random() * height;
      node.velocity_x = 0;
      node.velocity_y = 0;
    }
  });
  
  // Create node lookup map
  const nodeMap = new Map();
  nodes.forEach(node => nodeMap.set(node.id, node));
  
  for (let iter = 0; iter < iterations; iter++) {
    // Reset forces
    nodes.forEach(node => {
      node.force_x = 0;
      node.force_y = 0;
    });
    
    // Repulsion between all nodes
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i];
        const b = nodes[j];
        const dx = b.position_x - a.position_x;
        const dy = b.position_y - a.position_y;
        const distance = Math.sqrt(dx * dx + dy * dy) || 0.1;
        
        const force = repulsion / (distance * distance);
        const fx = (dx / distance) * force;
        const fy = (dy / distance) * force;
        
        a.force_x -= fx;
        a.force_y -= fy;
        b.force_x += fx;
        b.force_y += fy;
      }
    }
    
    // Attraction along edges
    edges.forEach(edge => {
      const source = nodeMap.get(edge.source_node_id);
      const target = nodeMap.get(edge.target_node_id);
      
      if (!source || !target) return;
      
      const dx = target.position_x - source.position_x;
      const dy = target.position_y - source.position_y;
      const distance = Math.sqrt(dx * dx + dy * dy) || 0.1;
      
      const force = distance * attraction;
      const fx = (dx / distance) * force;
      const fy = (dy / distance) * force;
      
      source.force_x += fx;
      source.force_y += fy;
      target.force_x -= fx;
      target.force_y -= fy;
    });
    
    // Update positions
    nodes.forEach(node => {
      node.velocity_x = (node.velocity_x + node.force_x) * damping;
      node.velocity_y = (node.velocity_y + node.force_y) * damping;
      
      node.position_x += node.velocity_x;
      node.position_y += node.velocity_y;
      
      // Boundary constraints
      node.position_x = Math.max(0, Math.min(width - node.width, node.position_x));
      node.position_y = Math.max(0, Math.min(height - node.height, node.position_y));
    });
  }
  
  return nodes;
};

// Routes
app.get('/canvas/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    const canvas = db.prepare('SELECT * FROM canvases WHERE id = ?').get(id);
    if (!canvas) {
      return res.status(404).json({ error: 'Canvas not found' });
    }
    
    const nodes = db.prepare('SELECT * FROM nodes WHERE canvas_id = ? ORDER BY id')
      .all(id);
    const edges = db.prepare('SELECT * FROM edges WHERE canvas_id = ? ORDER BY id')
      .all(id);
    
    res.json({
      canvas,
      nodes,
      edges
    });
  } catch (error) {
    console.error('Error fetching canvas:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/canvas/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, nodes: newNodes, edges: newEdges, applyLayout } = req.body;
    
    const canvas = db.prepare('SELECT * FROM canvases WHERE id = ?').get(id);
    if (!canvas) {
      return res.status(404).json({ error: 'Canvas not found' });
    }
    
    const dbTransaction = db.transaction(() => {
      // Update canvas
      if (title !== undefined || description !== undefined) {
        db.prepare('UPDATE canvases SET title = COALESCE(?, title), description = COALESCE(?, description), updated_at = CURRENT_TIMESTAMP WHERE id = ?')
          .run(title, description, id);
      }
      
      // Update nodes if provided
      if (newNodes) {
        // Delete existing nodes
        db.prepare('DELETE FROM edges WHERE canvas_id = ?').run(id);
        db.prepare('DELETE FROM nodes WHERE canvas_id = ?').run(id);
        
        // Insert new nodes
        const insertNode = db.prepare('INSERT INTO nodes (canvas_id, type, position_x, position_y, width, height, content, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
        newNodes.forEach(node => {
          insertNode.run(
            id,
            node.type || 'text',
            node.position_x || 0,
            node.position_y || 0,
            node.width || 200,
            node.height || 100,
            node.content || '',
            node.metadata ? JSON.stringify(node.metadata) : null
          );
        });
        
        // Insert new edges
        const insertEdge = db.prepare('INSERT INTO edges (canvas_id, source_node_id, target_node_id, type, label, metadata) VALUES (?, ?, ?, ?, ?, ?)');
        newEdges?.forEach(edge => {
          insertEdge.run(
            id,
            edge.source_node_id,
            edge.target_node_id,
            edge.type || 'arrow',
            edge.label || null,
            edge.metadata ? JSON.stringify(edge.metadata) : null
          );
        });
      }
      
      // Apply force-directed layout if requested
      if (applyLayout) {
        const nodes = db.prepare('SELECT * FROM nodes WHERE canvas_id = ?').all(id);
        const edges = db.prepare('SELECT * FROM edges WHERE canvas_id = ?').all(id);
        
        if (nodes.length > 0) {
          const updatedNodes = calculateForceDirectedLayout([...nodes], [...edges]);
          
          const updateNodePosition = db.prepare('UPDATE nodes SET position_x = ?, position_y = ? WHERE id = ?');
          updatedNodes.forEach(node => {
            updateNodePosition.run(node.position_x, node.position_y, node.id);
          });
        }
      }
      
      // Return updated data
      const updatedCanvas = db.prepare('SELECT * FROM canvases WHERE id = ?').get(id);
      const updatedNodes = db.prepare('SELECT * FROM nodes WHERE canvas_id = ? ORDER BY id').all(id);
      const updatedEdges = db.prepare('SELECT * FROM edges WHERE canvas_id = ? ORDER BY id').all(id);
      
      return { canvas: updatedCanvas, nodes: updatedNodes, edges: updatedEdges };
    });
    
    const result = dbTransaction();
    res.json(result);
  } catch (error) {
    console.error('Error updating canvas:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/canvas', (req, res) => {
  try {
    const { title, description, template, initialNodes, initialEdges } = req.body;
    
    const insertCanvas = db.prepare('INSERT INTO canvases (title, description) VALUES (?, ?)');
    const canvasResult = insertCanvas.run(title || 'Untitled Canvas', description || '');
    const canvasId = canvasResult.lastInsertRowid;
    
    // Apply template if provided
    if (template) {
      const templateData = db.prepare('SELECT * FROM templates WHERE name = ?').get(template);
      if (templateData) {
        const structure = JSON.parse(templateData.structure);
        
        // Record template usage
        db.prepare('INSERT INTO template_usage (canvas_id, template_id) VALUES (?, ?)').run(canvasId, templateData.id);
        
        // Create nodes and edges from template
        if (structure.nodes) {
          const insertNode = db.prepare('INSERT INTO nodes (canvas_id, type, position_x, position_y, width, height, content, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
          structure.nodes.forEach(node => {
            insertNode.run(
              canvasId,
              node.type || 'text',
              node.position_x || 0,
              node.position_y || 0,
              node.width || 200,
              node.height || 100,
              node.content || '',
              node.metadata ? JSON.stringify(node.metadata) : null
            );
          });
        }
        
        if (structure.edges) {
          const insertEdge = db.prepare('INSERT INTO edges (canvas_id, source_node_id, target_node_id, type, label, metadata) VALUES (?, ?, ?, ?, ?, ?)');
          structure.edges.forEach(edge => {
            insertEdge.run(
              canvasId,
              edge.source_node_id,
              edge.target_node_id,
              edge.type || 'arrow',
              edge.label || null,
              edge.metadata ? JSON.stringify(edge.metadata) : null
            );
          });
        }
      }
    }
    
    // Add initial nodes/edges if provided
    if (initialNodes) {
      const insertNode = db.prepare('INSERT INTO nodes (canvas_id, type, position_x, position_y, width, height, content, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
      initialNodes.forEach(node => {
        insertNode.run(
          canvasId,
          node.type || 'text',
          node.position_x || 0,
          node.position_y || 0,
          node.width || 200,
          node.height || 100,
          node.content || '',
          node.metadata ? JSON.stringify(node.metadata) : null
        );
      });
    }
    
    if (initialEdges) {
      const insertEdge = db.prepare('INSERT INTO edges (canvas_id, source_node_id, target_node_id, type, label, metadata) VALUES (?, ?, ?, ?, ?, ?)');
      initialEdges.forEach(edge => {
        insertEdge.run(
          canvasId,
          edge.source_node_id,
          edge.target_node_id,
          edge.type || 'arrow',
          edge.label || null,
          edge.metadata ? JSON.stringify(edge.metadata) : null
        );
      });
    }
    
    const canvas = db.prepare('SELECT * FROM canvases WHERE id = ?').get(canvasId);
    const nodes = db.prepare('SELECT * FROM nodes WHERE canvas_id = ? ORDER BY id').all(canvasId);
    const edges = db.prepare('SELECT * FROM edges WHERE canvas_id = ? ORDER BY id').all(canvasId);
    
    res.status(201).json({ canvas, nodes, edges });
  } catch (error) {
    console.error('Error creating canvas:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/canvas/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    const canvas = db.prepare('SELECT * FROM canvases WHERE id = ?').get(id);
    if (!canvas) {
      return res.status(404).json({ error: 'Canvas not found' });
    }
    
    // Delete related data (foreign keys will handle this, but being explicit)
    db.prepare('DELETE FROM template_usage WHERE canvas_id = ?').run(id);
    db.prepare('DELETE FROM edges WHERE canvas_id = ?').run(id);
    db.prepare('DELETE FROM nodes WHERE canvas_id = ?').run(id);
    db.prepare('DELETE FROM canvases WHERE id = ?').run(id);
    
    res.json({ message: 'Canvas deleted successfully' });
  } catch (error) {
    console.error('Error deleting canvas:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Template routes
app.get('/templates', (req, res) => {
  try {
    const templates = db.prepare('SELECT * FROM templates ORDER BY category, name').all();
    res.json(templates);
  } catch (error) {
    console.error('Error fetching templates:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/templates/:id', (req, res) => {
  try {
    const { id } = req.params;
    const template = db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!template) {
      return res.status(404).json({ error: 'Template not found' });
    }
    
    template.structure = JSON.parse(template.structure);
    res.json(template);
  } catch (error) {
    console.error('Error fetching template:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/templates', (req, res) => {
  try {
    const { name, description, category, structure } = req.body;
    
    if (!name || !structure) {
      return res.status(400).json({ error: 'Name and structure are required' });
    }
    
    const insertTemplate = db.prepare('INSERT INTO templates (name, description, category, structure) VALUES (?, ?, ?, ?)');
    const result = insertTemplate.run(name, description || '', category || 'story', JSON.stringify(structure));
    
    const template = db.prepare('SELECT * FROM templates WHERE id = ?').get(result.lastInsertRowid);
    template.structure = JSON.parse(template.structure);
    
    res.status(201).json(template);
  } catch (error) {
    console.error('Error creating template:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Layout endpoint
app.post('/canvas/:id/layout', (req, res) => {
  try {
    const { id } = req.params;
    
    const nodes = db.prepare('SELECT * FROM nodes WHERE canvas_id = ?').all(id);
    const edges = db.prepare('SELECT * FROM edges WHERE canvas_id = ?').all(id);
    
    if (nodes.length === 0) {
      return res.json({ nodes, edges });
    }
    
    const updatedNodes = calculateForceDirectedLayout([...nodes], [...edges]);
    
    const updateNodePosition = db.prepare('UPDATE nodes SET position_x = ?, position_y = ? WHERE id = ?');
    updatedNodes.forEach(node => {
      updateNodePosition.run(node.position_x, node.position_y, node.id);
    });
    
    res.json({
      nodes: updatedNodes,
      edges: edges,
      message: 'Layout applied successfully'
    });
  } catch (error) {
    console.error('Error applying layout:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'canvas-service', port: PORT });
});

// Start server
app.listen(PORT, () => {
  console.log(`Canvas Service running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
