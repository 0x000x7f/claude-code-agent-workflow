# AGENTS.md

## Purpose

This repository contains a portable workflow template for multi-agent coding with
Claude Code, Codex, and Cursor. The main session acts as PM/architect; implementation,
review, and cross-tool handoff are delegated by complexity.

## Rules for coding agents

- Do not modify unrelated files.
- Keep diffs small and reviewable (one reviewable unit per task).
- Prefer Markdown handoff documents for cross-agent context sharing.
- Do not assume access to previous chat context; everything you need must be in the
  handoff document or this repository.
- Treat generated handoff files (`docs/handoff/HANDOFF-*.md`) as task-specific instructions.
- Report changed files, test results, and remaining risks when you finish.

## Validation

Before proposing changes to this template, check:

- agent definitions under `claude/agents/` (frontmatter: name, description, model, tools)
- slash command behavior under `claude/commands/` (empty-argument handling, scope guards)
- reviewer constraints (read-only; Bash limited to inspection commands)
- handoff document self-containment (a reader with zero session context can act on it)
