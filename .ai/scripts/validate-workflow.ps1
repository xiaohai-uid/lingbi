param([string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Require-File([string]$RelativePath) {
  if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $RelativePath) -PathType Leaf)) {
    $failures.Add("Missing file: $RelativePath")
  }
}

function Require-Text([string]$RelativePath, [string]$Pattern) {
  $path = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
      -not (Select-String -LiteralPath $path -Pattern $Pattern -Quiet)) {
    $failures.Add("Missing contract in ${RelativePath}: $Pattern")
  }
}

$requiredFiles = @(
  'AGENTS.md',
  '.ai/PROJECT_MAP.md',
  '.ai/tasks/README.md',
  '.ai/templates/SPEC.template.md',
  '.ai/templates/STATE.template.md',
  '.ai/templates/EVIDENCE.template.md',
  '.ai/templates/REVIEW_BUNDLE.template.md',
  '.ai/templates/REVIEW.template.md',
  '.ai/templates/QODER_REVIEW.template.md',
  '.ai/scripts/validate-workflow.ps1'
)

foreach ($file in $requiredFiles) {
  Require-File $file
}

$requiredContracts = @(
  @{ File = 'AGENTS.md'; Pattern = 'GPT/Codex.*plans, classifies, assigns, and makes the final review decision' },
  @{ File = 'AGENTS.md'; Pattern = 'Qoder Quest.*executes `COMPLEX` tasks in a dedicated worktree' },
  @{ File = 'AGENTS.md'; Pattern = 'Qoder Ultra Review.*runs in a separate ordinary Chat context against a frozen Git range' },
  @{ File = 'AGENTS.md'; Pattern = 'OpenCode.*executes `SIMPLE` tasks or a GPT-reassigned released task' },
  @{ File = 'AGENTS.md'; Pattern = 'Each task has one execution lease' },
  @{ File = 'AGENTS.md'; Pattern = 'SIMPLE.*OPENCODE.*COMPLEX.*QODER.*require first-pass review' },
  @{ File = 'AGENTS.md'; Pattern = 'separate from Qoder Quest execution' },
  @{ File = 'AGENTS.md'; Pattern = 'Completion evidence includes executor provenance' },
  @{ File = 'AGENTS.md'; Pattern = 'Executors and reviewers must not merge or push' },
  @{ File = '.ai/PROJECT_MAP.md'; Pattern = 'Three-role workflow contract' },
  @{ File = '.ai/PROJECT_MAP.md'; Pattern = 'single held execution lease' },
  @{ File = '.ai/PROJECT_MAP.md'; Pattern = 'Qoder first-pass review is advisory evidence' },
  @{ File = '.ai/tasks/README.md'; Pattern = '### Complex task' },
  @{ File = '.ai/tasks/README.md'; Pattern = '### Released-task takeover' },
  @{ File = '.ai/tasks/README.md'; Pattern = 'separate ordinary Qoder Chat performs read-only Ultra Review' },
  @{ File = '.ai/templates/SPEC.template.md'; Pattern = 'Complexity: `<SIMPLE \| COMPLEX>`' },
  @{ File = '.ai/templates/SPEC.template.md'; Pattern = 'Assigned executor: `<OPENCODE \| QODER>`' },
  @{ File = '.ai/templates/SPEC.template.md'; Pattern = 'First-pass review: `<REQUIRED \| NOT_REQUIRED>`' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = '## Execution lease' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = 'Active executor: `<NONE \| OPENCODE \| QODER>`' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = 'Lease status: `<RELEASED \| HELD>`' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = 'Lease acquired at: `<timestamp or N/A>`' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = 'Worktree path: `<absolute path>`' },
  @{ File = '.ai/templates/STATE.template.md'; Pattern = 'Checkpoint commit: `<full SHA or UNCOMMITTED>`' },
  @{ File = '.ai/templates/EVIDENCE.template.md'; Pattern = '## Executor and review provenance' },
  @{ File = '.ai/templates/EVIDENCE.template.md'; Pattern = 'Assigned executor: `<OPENCODE \| QODER>`' },
  @{ File = '.ai/templates/EVIDENCE.template.md'; Pattern = 'Checkpoint commit: `<full SHA or UNCOMMITTED>`' },
  @{ File = '.ai/templates/EVIDENCE.template.md'; Pattern = 'Qoder review artifact' },
  @{ File = '.ai/templates/EVIDENCE.template.md'; Pattern = 'Frozen Qoder review range' },
  @{ File = '.ai/templates/REVIEW_BUNDLE.template.md'; Pattern = 'Qoder review artifact' },
  @{ File = '.ai/templates/REVIEW_BUNDLE.template.md'; Pattern = 'Qoder review status' },
  @{ File = '.ai/templates/REVIEW.template.md'; Pattern = '# GPT/Codex final review result' },
  @{ File = '.ai/templates/REVIEW.template.md'; Pattern = 'Only GPT/Codex may complete this template' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Review context: `SEPARATE_QODER_CHAT`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Frozen baseline: `<full SHA>`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Frozen checkpoint: `<full SHA>`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Ultra Review target: `<exact range or commit>`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Status: `<PASS \| PASS_WITH_FINDINGS \| FAIL>`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'Files modified by reviewer: `NONE`' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = '\| ID \| Severity \| File:line \| Evidence \| Required disposition \|' },
  @{ File = '.ai/templates/QODER_REVIEW.template.md'; Pattern = 'This report is advisory technical evidence' }
)

foreach ($contract in $requiredContracts) {
  Require-Text $contract.File $contract.Pattern
}

if ($failures.Count -gt 0) {
  foreach ($failure in $failures) {
    Write-Output $failure
  }
  exit 1
}

Write-Output "Workflow validation passed: $($requiredFiles.Count) files and $($requiredContracts.Count) contracts verified."
exit 0
