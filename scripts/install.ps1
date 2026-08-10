#Requires -Version 5.1
<#
.SYNOPSIS
  Install ai-workflows into a project (prompts + rules + optional adapters).

.EXAMPLE
  .\scripts\install.ps1 -Project C:\path\to\app -Adapter cursor
  .\scripts\install.ps1 -Project C:\path\to\app -Adapter all
#>
param(
  [Parameter(Mandatory = $true)]
  [string] $Project,

  [ValidateSet('cursor', 'claude', 'chatgpt', 'all')]
  [string] $Adapter = 'cursor'
)

$ErrorActionPreference = 'Stop'

$PackRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$ProjectRoot = (Resolve-Path -LiteralPath $Project).Path
$Vendor = Join-Path $ProjectRoot '.ai-workflows'
$PackSkills = Join-Path $PackRoot 'adapters\cursor\skills'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8File {
  param([string] $Path, [string] $Content)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content.TrimEnd() + "`n", $Utf8NoBom)
}

function Get-WorkflowNames {
  Get-ChildItem -LiteralPath $PackSkills -Directory |
    Sort-Object Name |
    ForEach-Object { $_.Name }
}

function Assert-PromptParity {
  foreach ($name in Get-WorkflowNames) {
    $prompt = Join-Path $PackRoot "prompts\$name.md"
    if (-not (Test-Path -LiteralPath $prompt)) {
      throw "Skill '$name' has no matching prompts/$name.md"
    }
  }
}

function Copy-PackContent {
  New-Item -ItemType Directory -Force -Path (Join-Path $Vendor 'prompts') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $Vendor 'rules') | Out-Null

  Copy-Item -Force (Join-Path $PackRoot 'prompts\*.md') (Join-Path $Vendor 'prompts')
  Copy-Item -Force (Join-Path $PackRoot 'rules\*.md') (Join-Path $Vendor 'rules')
  Copy-Item -Force (Join-Path $PackRoot 'LICENSE') (Join-Path $Vendor 'LICENSE')

  $when = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $names = (Get-WorkflowNames) -join ', '
  $stamp = @(
    '# ai-workflows'
    ''
    "Vendored install from ``$PackRoot``."
    "Installed: $when"
    "Adapter request: $Adapter"
    "Workflows: $names"
    ''
    'Re-run the install script to refresh prompts and rules.'
    'See LICENSE in this folder.'
  ) -join "`n"
  Write-Utf8File -Path (Join-Path $Vendor 'README.md') -Content $stamp
}

function Install-Cursor {
  $skillsRoot = Join-Path $ProjectRoot '.cursor\skills'
  $rulesRoot = Join-Path $ProjectRoot '.cursor\rules'
  New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null
  New-Item -ItemType Directory -Force -Path $rulesRoot | Out-Null

  foreach ($name in Get-WorkflowNames) {
    $src = Join-Path $PackSkills "$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $src)) { continue }

    $dir = Join-Path $skillsRoot $name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $text = [System.IO.File]::ReadAllText($src)
    $text = $text.Replace('../../../../prompts/', '../../../.ai-workflows/prompts/')
    Write-Utf8File -Path (Join-Path $dir 'SKILL.md') -Content $text
  }

  $rule = @(
    '---'
    'description: Core engineering standards for AI assistants'
    'alwaysApply: true'
    '---'
    ''
    'Read and apply `.ai-workflows/rules/engineering.md` for the whole session,'
    'including the daily workflow loop. Prefer `.ai-workflows/prompts/` for structured tasks.'
  ) -join "`n"
  Write-Utf8File -Path (Join-Path $rulesRoot 'engineering.mdc') -Content $rule
  Write-Host 'Cursor: skills -> .cursor/skills/, rule -> .cursor/rules/engineering.mdc'
}

function Install-Claude {
  $dest = Join-Path $ProjectRoot 'CLAUDE.ai-workflows.md'
  $rows = foreach ($name in Get-WorkflowNames) {
    "| $name | `.ai-workflows/prompts/$name.md` |"
  }
  $content = (@(
    '## AI workflows'
    ''
    'Always apply `.ai-workflows/rules/engineering.md` (including the daily loop).'
    ''
    'When the user asks for a structured task, read and follow the matching prompt:'
    ''
    '| Workflow | File |'
    '| -------- | ---- |'
  ) + $rows + @(
    ''
    'Do not invent a parallel process. Chain workflows when asked (e.g. commit and open a PR).'
  )) -join "`n"
  Write-Utf8File -Path $dest -Content $content
  Write-Host 'Claude: wrote CLAUDE.ai-workflows.md - merge into CLAUDE.md'
}

function Install-ChatGPT {
  $dest = Join-Path $ProjectRoot 'CHATGPT.ai-workflows.md'
  $list = (Get-WorkflowNames) -join ', '
  $content = @(
    'Follow .ai-workflows/rules/engineering.md on every task (including the daily loop).'
    ''
    "For structured work, open the matching file under .ai-workflows/prompts/: $list."
    ''
    'Ask which workflow if unclear. Do not invent a parallel process.'
  ) -join "`n"
  Write-Utf8File -Path $dest -Content $content
  Write-Host 'ChatGPT: wrote CHATGPT.ai-workflows.md - paste into project instructions'
}

Write-Host "Pack:    $PackRoot"
Write-Host "Project: $ProjectRoot"
Write-Host "Adapter: $Adapter"

Assert-PromptParity
Copy-PackContent
Write-Host 'Vendored prompts/rules/LICENSE -> .ai-workflows/'

switch ($Adapter) {
  'cursor' { Install-Cursor }
  'claude' { Install-Claude }
  'chatgpt' { Install-ChatGPT }
  'all' {
    Install-Cursor
    Install-Claude
    Install-ChatGPT
  }
}

Write-Host 'Done.'
