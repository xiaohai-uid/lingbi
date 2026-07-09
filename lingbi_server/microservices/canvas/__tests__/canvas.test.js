const request = require('supertest');
const app = require('../index');

describe('Canvas Service API', () => {
  let server;
  let nodeId;
  let edgeId;

  beforeAll(() => {
    server = app;
  });

  afterAll(() => {
    // Close the server if it has a close method
    if (server.close) {
      server.close();
    }
  });

  // ========== Health check ==========
  describe('GET /canvas/health', () => {
    it('should return health status', async () => {
      const res = await request(server).get('/canvas/health');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'healthy');
      expect(res.body).toHaveProperty('service', 'canvas-service');
      expect(res.body).toHaveProperty('port', 8091);
    });
  });

  // ========== Templates ==========
  describe('GET /canvas/templates', () => {
    it('should return template list', async () => {
      const res = await request(server).get('/canvas/templates');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(2);
      expect(res.body.some(t => t.name === 'mind-map')).toBe(true);
      expect(res.body.some(t => t.name === 'story-flow')).toBe(true);
    });
  });

  describe('GET /canvas/templates/:id', () => {
    it('should return template detail by id', async () => {
      const listRes = await request(server).get('/canvas/templates');
      const templateId = listRes.body[0].id;
      const res = await request(server).get(`/canvas/templates/${templateId}`);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('structure');
    });

    it('should return 404 for non-existent template', async () => {
      const res = await request(server).get('/canvas/templates/non-existent-id');
      expect(res.status).toBe(404);
    });
  });

  // ========== Nodes ==========
  describe('POST /canvas/nodes', () => {
    it('should create a new node', async () => {
      const res = await request(server)
        .post('/canvas/nodes')
        .send({
          canvasId: 'canvas-123',
          type: 'character',
          label: '主角',
          x: 100,
          y: 200,
          data: { description: 'Main character' }
        });
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('canvasId', 'canvas-123');
      expect(res.body).toHaveProperty('type', 'character');
      expect(res.body).toHaveProperty('label', '主角');
      expect(res.body).toHaveProperty('x', 100);
      expect(res.body).toHaveProperty('y', 200);
      nodeId = res.body.id;
    });

    it('should return 400 if canvasId is missing', async () => {
      const res = await request(server)
        .post('/canvas/nodes')
        .send({ type: 'character' });
      expect(res.status).toBe(400);
    });
  });

  describe('PUT /canvas/nodes/:id', () => {
    it('should update an existing node', async () => {
      const res = await request(server)
        .put(`/canvas/nodes/${nodeId}`)
        .send({ label: 'Updated主角', x: 300 });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('label', 'Updated主角');
      expect(res.body).toHaveProperty('x', 300);
      expect(res.body).toHaveProperty('y', 200);
    });

    it('should return 404 for non-existent node', async () => {
      const res = await request(server)
        .put('/canvas/nodes/non-existent-id')
        .send({ label: 'test' });
      expect(res.status).toBe(404);
    });
  });

  // ========== Edges ==========
  describe('POST /canvas/edges', () => {
    it('should create a new edge', async () => {
      // Create a second node first
      const node2Res = await request(server)
        .post('/canvas/nodes')
        .send({
          canvasId: 'canvas-123',
          type: 'setting',
          label: '场景',
          x: 300,
          y: 400,
          data: {}
        });
      const node2Id = node2Res.body.id;

      const res = await request(server)
        .post('/canvas/edges')
        .send({
          canvasId: 'canvas-123',
          source: nodeId,
          target: node2Id,
          label: '关系描述',
          type: 'arrow'
        });
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('canvasId', 'canvas-123');
      expect(res.body).toHaveProperty('source', nodeId);
      expect(res.body).toHaveProperty('target', node2Id);
      expect(res.body).toHaveProperty('label', '关系描述');
      edgeId = res.body.id;
    });

    it('should return 400 if source or target is missing', async () => {
      const res = await request(server)
        .post('/canvas/edges')
        .send({ canvasId: 'canvas-123', label: 'test' });
      expect(res.status).toBe(400);
    });
  });

  describe('PUT /canvas/edges/:id', () => {
    it('should update an existing edge', async () => {
      const res = await request(server)
        .put(`/canvas/edges/${edgeId}`)
        .send({ label: 'Updated关系' });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('label', 'Updated关系');
    });

    it('should return 404 for non-existent edge', async () => {
      const res = await request(server)
        .put('/canvas/edges/non-existent-id')
        .send({ label: 'test' });
      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /canvas/nodes/:id', () => {
    it('should delete an existing node', async () => {
      const res = await request(server).delete(`/canvas/nodes/${nodeId}`);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Node deleted successfully');

      // Verify it's gone
      const getRes = await request(server)
        .put(`/canvas/nodes/${nodeId}`)
        .send({ label: 'test' });
      expect(getRes.status).toBe(404);
    });

    it('should return 404 for non-existent node on delete', async () => {
      const res = await request(server).delete('/canvas/nodes/non-existent-id');
      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /canvas/edges/:id', () => {
    it('should delete an existing edge', async () => {
      // Create fresh nodes and edge for this test
      const n1 = await request(server)
        .post('/canvas/nodes')
        .send({ canvasId: 'canvas-del', type: 'a', label: 'A', x: 0, y: 0, data: {} });
      const n2 = await request(server)
        .post('/canvas/nodes')
        .send({ canvasId: 'canvas-del', type: 'b', label: 'B', x: 100, y: 100, data: {} });
      const edgeRes = await request(server)
        .post('/canvas/edges')
        .send({ canvasId: 'canvas-del', source: n1.body.id, target: n2.body.id, label: 'edge', type: 'arrow' });
      const eId = edgeRes.body.id;

      const res = await request(server).delete(`/canvas/edges/${eId}`);
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Edge deleted successfully');
    });

    it('should return 404 for non-existent edge on delete', async () => {
      const res = await request(server).delete('/canvas/edges/non-existent-id');
      expect(res.status).toBe(404);
    });
  });

  // ========== Layout ==========
  describe('POST /canvas/layout', () => {
    it('should apply force-directed layout', async () => {
      // Create nodes and edges for layout
      const n1 = await request(server)
        .post('/canvas/nodes')
        .send({ canvasId: 'canvas-layout', type: 'a', label: 'A', x: 10, y: 10, data: {} });
      const n2 = await request(server)
        .post('/canvas/nodes')
        .send({ canvasId: 'canvas-layout', type: 'b', label: 'B', x: 500, y: 500, data: {} });
      const n3 = await request(server)
        .post('/canvas/nodes')
        .send({ canvasId: 'canvas-layout', type: 'c', label: 'C', x: 100, y: 300, data: {} });
      await request(server)
        .post('/canvas/edges')
        .send({ canvasId: 'canvas-layout', source: n1.body.id, target: n2.body.id, label: 'e1', type: 'arrow' });
      await request(server)
        .post('/canvas/edges')
        .send({ canvasId: 'canvas-layout', source: n2.body.id, target: n3.body.id, label: 'e2', type: 'arrow' });

      const res = await request(server)
        .post('/canvas/layout')
        .send({ canvasId: 'canvas-layout', type: 'force-directed', options: {} });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('nodes');
      expect(res.body).toHaveProperty('edges');
      expect(res.body.nodes.length).toBe(3);
    });

    it('should apply tree layout', async () => {
      const res = await request(server)
        .post('/canvas/layout')
        .send({ canvasId: 'canvas-layout', type: 'tree', options: {} });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('nodes');
      expect(res.body.nodes.length).toBe(3);
    });

    it('should apply radial layout', async () => {
      const res = await request(server)
        .post('/canvas/layout')
        .send({ canvasId: 'canvas-layout', type: 'radial', options: {} });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('nodes');
      expect(res.body.nodes.length).toBe(3);
    });

    it('should return 404 for invalid canvasId', async () => {
      const res = await request(server)
        .post('/canvas/layout')
        .send({ canvasId: 'non-existent', type: 'force-directed', options: {} });
      expect(res.status).toBe(404);
    });

    it('should return 400 for invalid layout type', async () => {
      const res = await request(server)
        .post('/canvas/layout')
        .send({ canvasId: 'canvas-layout', type: 'invalid-type', options: {} });
      expect(res.status).toBe(400);
    });
  });

  // ========== Export ==========
  describe('POST /canvas/export', () => {
    it('should export canvas as JSON', async () => {
      const res = await request(server)
        .post('/canvas/export')
        .send({ canvasId: 'canvas-123' });
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('canvasId', 'canvas-123');
      expect(res.body).toHaveProperty('nodes');
      expect(res.body).toHaveProperty('edges');
      expect(Array.isArray(res.body.nodes)).toBe(true);
      expect(Array.isArray(res.body.edges)).toBe(true);
    });

    it('should return 404 for non-existent canvas', async () => {
      const res = await request(server)
        .post('/canvas/export')
        .send({ canvasId: 'non-existent-canvas' });
      expect(res.status).toBe(404);
    });
  });
});