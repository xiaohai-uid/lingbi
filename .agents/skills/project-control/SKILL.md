# /project-control

Platform-agnostic local AI control plane (V2.0 governance activation).

## Status: M1.5 Cross-Agent Ready

M1.5 extends M1 read-only canary to support multiple Agents and projects.
Invoke /project-control in any supported Agent session to get a read-only
recovery report for the current repository.

## What this Skill does

1. Locates and validates the V2.0 governance document from Obsidian
2. Scans the current repository for facts (AGENTS.md, CONTEXT.md, ADR, Git)
3. Infers active Workstreams and their phase/status
4. Distinguishes facts from inferences from unknowns
5. Recommends the next Skill to invoke
6. Reports its own capability boundary (read-only in M1/M1.5)

## Invocation

```
/project-control
/project-control --check
/project-control --governance <path>
```

## How it works

The Skill orchestrator reads these instructions and executes:

```bash
cd <source-root>
python -m project_control.main --repo <target-repo-path>
```

Source root: the project-control repository (installed copy points here).

### Options

- --repo <path>: Repository root to scan (default: cwd)
- --governance <path>: Explicit governance document path
- --check: Only validate config, skip repo scan
- --verbose: Include full paths in output

## Output Format

The report contains:
- Governance Status (source, version, effective_level)
- Confirmed Facts [fact]
- Inferences [inference]
- Semantic Unknowns [unknown]
- Conflicts [conflict]
- Missing Evidence [missing]
- Workstream Summary
- Recommended Next Skill
- Capability Boundary

## Governance Source

Rules live in Obsidian only. This Skill never copies or embeds them.
See: AI软件工程系统/00-AI软件项目总控提示词-V2.0.md

## Capability Boundary (M1/M1.5)

- Mode: READ-ONLY
- Does NOT write state.json
- Does NOT modify Issues or claim Lease
- Does NOT auto-invoke recommended Skills
- Does NOT modify the target repository

## Supported Agents

- QoderCN (project-level .agents/skills/)
- Codex CLI (user-level ~/.codex/skills/)
- OpenCode (user-level ~/.opencode/skills/)

## Installation

```powershell
python -m project_control.install --agent qodercn
python -m project_control.install --agent codex
python -m project_control.install --agent opencode
python -m project_control.install --all
python -m project_control.install --uninstall --agent <name>
python -m project_control.install --list
```

Source: C:\codex\project-control (single source of truth)
Installed copies carry version and commit stamps.
Never edit installed copies directly.

## Architecture

See ADR-0010: Platform-Agnostic Local AI Control Plane.
Core is decoupled from Agents and Projects via Adapters.
