# Task 1: Canvas Service 完善 — Report

## Status
DONE

## Commit hash
`cb9947b3efc247fe893c21b65287d9b8cc26f8be`

## Test summary
- **Total tests:** 23
- **Passed:** 23
- **Failed:** 0
- **Coverage:** 92.06% statements, 67.74% branches, 98.07% functions, 96.2% lines

## Implementation details

### package.json
- Dependencies: `express@^4.18.0`, `uuid@^9.0.0`
- DevDependencies: `jest@^29.0.0`, `supertest@^6.3.0`
- Script: `npm test` runs Jest with coverage and forceExit

### index.js — Complete REST API (11 endpoints)
| Endpoint | Method | Description |
|---|---|---|
| `/canvas/templates` | GET | List all templates from `templates/` directory |
| `/canvas/templates/:id` | GET | Get template detail by id (filename-based) |
| `/canvas/nodes` | POST | Create a node (requires canvasId) |
| `/canvas/nodes/:id` | PUT | Update node position/label/type |
| `/canvas/nodes/:id` | DELETE | Delete node (cascades to edges) |
| `/canvas/edges` | POST | Create an edge (requires canvasId, source, target) |
| `/canvas/edges/:id` | PUT | Update edge label/type |
| `/canvas/edges/:id` | DELETE | Delete edge |
| `/canvas/layout` | POST | Apply layout algorithm (force-directed, tree, radial) |
| `/canvas/export` | POST | Export canvas as JSON |
| `/canvas/health` | GET | Health check (returns status, service name, port) |

### load-templates.js
- Reads all `.json` files from `templates/` directory
- Assigns stable `id` based on filename (e.g. `mind-map`, `story-flow`)
- Returns array of template objects

### Layout algorithms (3 implemented)
1. **Force-directed** — simulated repulsion/attraction with configurable iterations, damping, and boundary constraints
2. **Tree** — BFS-based hierarchical layout with root auto-detection (most outgoing edges) and level-based centering
3. **Radial** — concentric circle layout with auto-detected root

### Tests (23 tests, 11 describe blocks)
- Health check (1), Templates list/detail/404 (3), Node CRUD (4 including error cases), Edge CRUD (4 including error cases), Node delete (2), Edge delete (2), Layout (5 covering 3 algorithms + 2 error cases), Export (2)

## Concerns
None. All requirements met:
- ✅ 11 REST API endpoints exactly matching the brief
- ✅ 3 layout algorithms (force-directed, tree, radial)
- ✅ Template loading from JSON files
- ✅ 23 unit tests (≥10 required)
- ✅ npm test passes with 92% coverage (≥80% required)
- ✅ Port 8091
- ✅ In-memory storage with UUID-based IDs
