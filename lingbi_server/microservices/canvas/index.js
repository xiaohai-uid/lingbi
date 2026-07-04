const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { loadTemplates } = require('./load-templates');

const app = express();
const PORT = 8091;

// Middleware
app.use(express.json());

// =============================================================================
// In-memory data stores
// =============================================================================
const nodesStore = new Map();   // key: nodeId, value: node object
const edgesStore = new Map();   // key: edgeId, value: edge object
const templates = loadTemplates();

// Helper: query nodes by canvasId
const getNodesByCanvas = (canvasId) =>
  [...nodesStore.values()].filter(n => n.canvasId === canvasId);

// Helper: query edges by canvasId
const getEdgesByCanvas = (canvasId) =>
  [...edgesStore.values()].filter(e => e.canvasId === canvasId);

// =============================================================================
// Layout Algorithms
// =============================================================================

/**
 * Force-directed layout: simulate repulsion/attraction forces.
 */
const calculateForceDirectedLayout = (nodes, edges, options = {}) => {
  const width = options.width || 1000;
  const height = options.height || 800;
  const repulsion = options.repulsion || 1000;
  const attraction = options.attraction || 0.01;
  const damping = options.damping || 0.7;
  const iterations = options.iterations || 300;

  // Shallow copy so we don't mutate originals
  const layoutNodes = nodes.map(n => ({
    ...n,
    position_x: n.x ?? Math.random() * width,
    position_y: n.y ?? Math.random() * height,
    velocity_x: 0,
    velocity_y: 0,
    force_x: 0,
    force_y: 0
  }));

  const nodeMap = new Map();
  layoutNodes.forEach(node => nodeMap.set(node.id, node));

  // Build adjacency lookup for edges (by internal node ids)
  const edgePairs = [];
  edges.forEach(edge => {
    const source = edge.source;
    const target = edge.target;
    if (source && target) {
      edgePairs.push({ source, target });
    }
  });

  for (let iter = 0; iter < iterations; iter++) {
    // Reset forces
    layoutNodes.forEach(node => {
      node.force_x = 0;
      node.force_y = 0;
    });

    // Repulsion between all nodes
    for (let i = 0; i < layoutNodes.length; i++) {
      for (let j = i + 1; j < layoutNodes.length; j++) {
        const a = layoutNodes[i];
        const b = layoutNodes[j];
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
    edgePairs.forEach(({ source, target }) => {
      const s = nodeMap.get(source);
      const t = nodeMap.get(target);
      if (!s || !t) return;

      const dx = t.position_x - s.position_x;
      const dy = t.position_y - s.position_y;
      const distance = Math.sqrt(dx * dx + dy * dy) || 0.1;

      const force = distance * attraction;
      const fx = (dx / distance) * force;
      const fy = (dy / distance) * force;

      s.force_x += fx;
      s.force_y += fy;
      t.force_x -= fx;
      t.force_y -= fy;
    });

    // Update positions
    layoutNodes.forEach(node => {
      node.velocity_x = (node.velocity_x + node.force_x) * damping;
      node.velocity_y = (node.velocity_y + node.force_y) * damping;

      node.position_x += node.velocity_x;
      node.position_y += node.velocity_y;

      // Boundary constraints
      node.position_x = Math.max(0, Math.min(width, node.position_x));
      node.position_y = Math.max(0, Math.min(height, node.position_y));
    });
  }

  // Map back to { x, y } format
  return layoutNodes.map(n => ({
    ...n,
    x: Math.round(n.position_x),
    y: Math.round(n.position_y),
    position_x: undefined,
    position_y: undefined,
    velocity_x: undefined,
    velocity_y: undefined,
    force_x: undefined,
    force_y: undefined
  }));
};

/**
 * Tree layout: arrange nodes in a hierarchical tree.
 * Root is the node with the most outgoing edges.
 */
const calculateTreeLayout = (nodes, edges, options = {}) => {
  const horizontalSpacing = options.horizontalSpacing || 200;
  const verticalSpacing = options.verticalSpacing || 150;
  const startX = options.startX || 100;
  const startY = options.startY || 100;

  if (nodes.length === 0) return nodes;

  // Build adjacency: count outgoing edges to find root
  const outDegree = new Map();
  nodes.forEach(n => outDegree.set(n.id, 0));
  edges.forEach(e => {
    if (outDegree.has(e.source)) {
      outDegree.set(e.source, outDegree.get(e.source) + 1);
    }
  });

  // Find root (node with most outgoing edges, or first node)
  let rootId = nodes[0].id;
  let maxDegree = -1;
  outDegree.forEach((deg, id) => {
    if (deg > maxDegree) {
      maxDegree = deg;
      rootId = id;
    }
  });

  // Build children map
  const childrenMap = new Map();
  nodes.forEach(n => childrenMap.set(n.id, []));
  edges.forEach(e => {
    const children = childrenMap.get(e.source);
    if (children) {
      children.push(e.target);
    }
  });

  // BFS to assign positions
  const layoutNodes = nodes.map(n => ({ ...n }));
  const nodeMap = new Map();
  layoutNodes.forEach(n => nodeMap.set(n.id, n));

  const visited = new Set();
  const queue = [{ id: rootId, level: 0, index: 0 }];
  // Track level counts for centering
  const levelCounts = new Map();
  const levelIndices = new Map();

  while (queue.length > 0) {
    const { id, level, index } = queue.shift();
    if (visited.has(id)) continue;
    visited.add(id);

    const node = nodeMap.get(id);
    if (!node) continue;

    const levelCount = (levelCounts.get(level) || 0) + 1;
    levelCounts.set(level, levelCount);
    levelIndices.set(id, index);

    const children = childrenMap.get(id) || [];
    children.forEach((childId, i) => {
      if (!visited.has(childId)) {
        queue.push({ id: childId, level: level + 1, index: i });
      }
    });
  }

  // Assign positions
  visited.clear();
  const queue2 = [{ id: rootId, level: 0 }];
  const levelMaxIndices = new Map();
  levelCounts.forEach((count, level) => {
    levelMaxIndices.set(level, count);
  });

  while (queue2.length > 0) {
    const { id, level } = queue2.shift();
    if (visited.has(id)) continue;
    visited.add(id);

    const node = nodeMap.get(id);
    if (!node) continue;

    const idx = levelIndices.get(id) || 0;
    const maxIdx = levelMaxIndices.get(level) || 1;
    // Center the node horizontally within its level
    const centerOffset = (maxIdx - 1) * horizontalSpacing / 2;
    node.x = startX + idx * horizontalSpacing - centerOffset;
    node.y = startY + level * verticalSpacing;

    const children = childrenMap.get(id) || [];
    children.forEach(childId => {
      if (!visited.has(childId)) {
        queue2.push({ id: childId, level: level + 1 });
      }
    });
  }

  return layoutNodes;
};

/**
 * Radial layout: arrange nodes in concentric circles.
 */
const calculateRadialLayout = (nodes, edges, options = {}) => {
  const centerX = options.centerX || 500;
  const centerY = options.centerY || 400;
  const radiusStep = options.radiusStep || 150;
  const startAngle = options.startAngle || 0;

  if (nodes.length === 0) return nodes;

  // Build adjacency to find root (most outgoing edges)
  const outDegree = new Map();
  nodes.forEach(n => outDegree.set(n.id, 0));
  edges.forEach(e => {
    if (outDegree.has(e.source)) {
      outDegree.set(e.source, outDegree.get(e.source) + 1);
    }
  });

  let rootId = nodes[0].id;
  let maxDegree = -1;
  outDegree.forEach((deg, id) => {
    if (deg > maxDegree) {
      maxDegree = deg;
      rootId = id;
    }
  });

  // Build children map
  const childrenMap = new Map();
  nodes.forEach(n => childrenMap.set(n.id, []));
  edges.forEach(e => {
    const children = childrenMap.get(e.source);
    if (children) {
      children.push(e.target);
    }
  });

  const layoutNodes = nodes.map(n => ({ ...n }));
  const nodeMap = new Map();
  layoutNodes.forEach(n => nodeMap.set(n.id, n));

  // BFS to assign levels
  const levelMap = new Map(); // id -> level
  const visited = new Set();
  const queue = [{ id: rootId, level: 0 }];
  const levelNodes = new Map(); // level -> [id]

  while (queue.length > 0) {
    const { id, level } = queue.shift();
    if (visited.has(id)) continue;
    visited.add(id);
    levelMap.set(id, level);
    if (!levelNodes.has(level)) levelNodes.set(level, []);
    levelNodes.get(level).push(id);

    const children = childrenMap.get(id) || [];
    children.forEach(childId => {
      if (!visited.has(childId)) {
        queue.push({ id: childId, level: level + 1 });
      }
    });
  }

  // Assign positions by level in concentric circles
  levelNodes.forEach((ids, level) => {
    if (level === 0) {
      // Root at center
      const node = nodeMap.get(ids[0]);
      if (node) {
        node.x = centerX;
        node.y = centerY;
      }
      return;
    }

    const radius = level * radiusStep;
    const count = ids.length;
    ids.forEach((id, i) => {
      const node = nodeMap.get(id);
      if (!node) return;
      const angle = startAngle + (2 * Math.PI * i / count);
      node.x = Math.round(centerX + radius * Math.cos(angle));
      node.y = Math.round(centerY + radius * Math.sin(angle));
    });
  });

  // Any unvisited nodes (disconnected) placed at center
  nodes.forEach(n => {
    if (!visited.has(n.id)) {
      const node = nodeMap.get(n.id);
      if (node) {
        node.x = centerX;
        node.y = centerY;
      }
    }
  });

  return layoutNodes;
};

// =============================================================================
// Routes
// =============================================================================

// ---- Health Check ----
app.get('/canvas/health', (_req, res) => {
  res.json({ status: 'healthy', service: 'canvas-service', port: PORT });
});

// ---- Templates ----
app.get('/canvas/templates', (_req, res) => {
  res.json(templates);
});

app.get('/canvas/templates/:id', (req, res) => {
  const template = templates.find(t => t.id === req.params.id);
  if (!template) {
    return res.status(404).json({ error: 'Template not found' });
  }
  res.json(template);
});

// ---- Nodes CRUD ----
app.post('/canvas/nodes', (req, res) => {
  const { canvasId, type, label, x, y, data } = req.body;
  if (!canvasId) {
    return res.status(400).json({ error: 'canvasId is required' });
  }

  const node = {
    id: uuidv4(),
    canvasId,
    type: type || 'text',
    label: label || '',
    x: x ?? 0,
    y: y ?? 0,
    data: data || {},
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  nodesStore.set(node.id, node);
  res.status(201).json(node);
});

app.put('/canvas/nodes/:id', (req, res) => {
  const node = nodesStore.get(req.params.id);
  if (!node) {
    return res.status(404).json({ error: 'Node not found' });
  }

  const { type, label, x, y, data } = req.body;
  if (type !== undefined) node.type = type;
  if (label !== undefined) node.label = label;
  if (x !== undefined) node.x = x;
  if (y !== undefined) node.y = y;
  if (data !== undefined) node.data = data;
  node.updatedAt = new Date().toISOString();

  res.json(node);
});

app.delete('/canvas/nodes/:id', (req, res) => {
  const node = nodesStore.get(req.params.id);
  if (!node) {
    return res.status(404).json({ error: 'Node not found' });
  }

  // Also delete all edges referencing this node
  for (const [edgeId, edge] of edgesStore) {
    if (edge.source === req.params.id || edge.target === req.params.id) {
      edgesStore.delete(edgeId);
    }
  }

  nodesStore.delete(req.params.id);
  res.json({ message: 'Node deleted successfully' });
});

// ---- Edges CRUD ----
app.post('/canvas/edges', (req, res) => {
  const { canvasId, source, target, label, type, data } = req.body;
  if (!canvasId || !source || !target) {
    return res.status(400).json({ error: 'canvasId, source, and target are required' });
  }

  const edge = {
    id: uuidv4(),
    canvasId,
    source,
    target,
    label: label || '',
    type: type || 'arrow',
    data: data || {},
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  edgesStore.set(edge.id, edge);
  res.status(201).json(edge);
});

app.put('/canvas/edges/:id', (req, res) => {
  const edge = edgesStore.get(req.params.id);
  if (!edge) {
    return res.status(404).json({ error: 'Edge not found' });
  }

  const { source, target, label, type, data } = req.body;
  if (source !== undefined) edge.source = source;
  if (target !== undefined) edge.target = target;
  if (label !== undefined) edge.label = label;
  if (type !== undefined) edge.type = type;
  if (data !== undefined) edge.data = data;
  edge.updatedAt = new Date().toISOString();

  res.json(edge);
});

app.delete('/canvas/edges/:id', (req, res) => {
  const edge = edgesStore.get(req.params.id);
  if (!edge) {
    return res.status(404).json({ error: 'Edge not found' });
  }

  edgesStore.delete(req.params.id);
  res.json({ message: 'Edge deleted successfully' });
});

// ---- Layout ----
app.post('/canvas/layout', (req, res) => {
  const { canvasId, type, options } = req.body;
  if (!canvasId) {
    return res.status(400).json({ error: 'canvasId is required' });
  }

  const nodes = getNodesByCanvas(canvasId);
  const edges = getEdgesByCanvas(canvasId);

  if (nodes.length === 0) {
    return res.status(404).json({ error: 'No nodes found for this canvas' });
  }

  let layoutNodes;
  switch (type) {
    case 'force-directed':
      layoutNodes = calculateForceDirectedLayout(nodes, edges, options || {});
      break;
    case 'tree':
      layoutNodes = calculateTreeLayout(nodes, edges, options || {});
      break;
    case 'radial':
      layoutNodes = calculateRadialLayout(nodes, edges, options || {});
      break;
    default:
      return res.status(400).json({ error: `Unknown layout type: ${type}. Supported: force-directed, tree, radial` });
  }

  // Update the store with new positions
  layoutNodes.forEach(updatedNode => {
    const existing = nodesStore.get(updatedNode.id);
    if (existing) {
      existing.x = updatedNode.x;
      existing.y = updatedNode.y;
      existing.updatedAt = new Date().toISOString();
    }
  });

  res.json({
    nodes: layoutNodes,
    edges,
    message: 'Layout applied successfully'
  });
});

// ---- Export ----
app.post('/canvas/export', (req, res) => {
  const { canvasId } = req.body;
  if (!canvasId) {
    return res.status(400).json({ error: 'canvasId is required' });
  }

  const nodes = getNodesByCanvas(canvasId);
  const edges = getEdgesByCanvas(canvasId);

  if (nodes.length === 0 && edges.length === 0) {
    return res.status(404).json({ error: 'Canvas not found' });
  }

  res.json({
    canvasId,
    nodes,
    edges,
    exportedAt: new Date().toISOString()
  });
});

// =============================================================================
// Start server (only if not in test mode)
// =============================================================================
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Canvas Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/canvas/health`);
  });
}

module.exports = app;