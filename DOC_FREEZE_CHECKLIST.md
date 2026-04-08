# SIMPLE RPG - Documentation Freeze Checklist

## Purpose

This file is the final pre-implementation checklist for the documentation set.

Use it before declaring the baseline "frozen enough" to move into sustained implementation.

This checklist is not an authoritative rule source.
It is a quality gate for the doc set itself.

## Freeze Standard

The doc set is ready to freeze when:
- repo entry is clear
- authority boundaries are clear
- technical baseline is locked
- growth rules are clear
- deferred topics are separated from active rules
- a new human or AI can orient quickly without rereading the entire chat history

## Current Assessment

Assessment date: `2026-04-09`

Current result: `PASS`

Decision:
- the documentation set is frozen enough for implementation
- the next step is implementation and stabilization, not more doc restructuring
- future doc updates should be targeted rule changes, not another broad rewrite

## Checklist

### 1. Entry And Orientation

- [x] `README.md` is not empty and works as the repo entrypoint
- [x] `README.md` points to the correct first-read docs
- [x] `Docs/HANDOFF.md` reflects current project state
- [x] a new chat can start from `README.md` and `Docs/HANDOFF.md` without re-explaining the project from scratch

### 2. Authority And Precedence

- [x] `Docs/DOC_PRECEDENCE.md` clearly separates authoritative docs from workflow/history docs
- [x] every major topic has one closest authoritative document
- [x] `DECISION_LOG.md` is treated as history, not active contract
- [x] `DEFERRED_DECISIONS.md` is treated as timing/open-topics tracking, not active contract
- [x] `EXPERIMENT_BANK.md` is clearly non-authoritative

### 3. Technical Baseline

- [x] `Docs/TECH_BASELINE.md` locks engine, scripting, content format, save scope, RNG policy, autoload policy, and repo layout
- [x] engine choice is no longer ambiguous
- [x] content canonical format is no longer ambiguous
- [x] save baseline is no longer ambiguous
- [x] gameplay autoload policy is no longer ambiguous

### 4. Architecture And Ownership

- [x] `Docs/ARCHITECTURE.md` defines layer boundaries clearly
- [x] `Docs/SOURCE_OF_TRUTH.md` defines authoritative ownership clearly
- [x] `RunState` vs `CombatState` ownership handoff is explicit
- [x] UI is clearly excluded from owning gameplay truth
- [x] scene/composition code is clearly separated from core rule ownership

### 5. Content Growth Safety

- [x] `Docs/CONTENT_ARCHITECTURE_SPEC.md` defines canonical content path and required fields
- [x] `one-definition-per-file` is explicit
- [x] `lower_snake_case` stable ID rule is explicit
- [x] display text is explicitly forbidden as a logic key
- [x] controlled tag vocabulary is explicit
- [x] new content vs new mechanic distinction is explicit

### 6. Combat Clarity

- [x] `Docs/COMBAT_RULE_CONTRACT.md` defines the official action set
- [x] turn order is explicit
- [x] dodge and durability behavior is explicit
- [x] fallback attack rule is explicit
- [x] simultaneous death priority is explicit
- [x] `Docs/COMBAT_INFO_MODEL.md` defines the minimum visible information set

### 7. Save And Test Readiness

- [x] `Docs/SAVE_SCHEMA.md` defines safe-state save support and non-supported early states
- [x] RNG stream persistence is explicit
- [x] pending choice restore is explicit
- [x] `Docs/TEST_STRATEGY.md` covers pure core tests, validation, invariants, and Godot smoke checks
- [x] validation expectations for content files are explicit

### 8. Workflow Discipline

- [x] `AGENTS.md` is short, strict, and operational
- [x] `CLAUDE.md` stays a short memory file and does not duplicate rule contracts
- [x] `Docs/HANDOFF.md` is the only rolling current-state summary file
- [x] `README.md` is treated as a stable entrypoint, not a rolling status file
- [x] `DECISION_LOG.md` is restricted to accepted project-level decisions
- [x] `DEFERRED_DECISIONS.md` is restricted to consciously open topics, not backlog tracking
- [x] new doc creation has a high threshold and requires clear ownership need
- [x] docs have a clear update discipline:
  - `README.md` rarely
  - `HANDOFF.md` often
  - authoritative docs only when the actual rule changes
  - `DECISION_LOG.md` only when a project-level decision is accepted

### 9. Scope And Deferred Topics

- [x] `Docs/SCOPE.md` clearly distinguishes lock-now vs validate-in-prototype vs deferred
- [x] `Docs/DEFERRED_DECISIONS.md` contains only genuinely open topics
- [x] experimental ideas are not leaking into authoritative specs

### 10. Freeze Decision

Freeze is acceptable when:
- [x] there is no major ambiguity about structure
- [x] there is no major ambiguity about ownership
- [x] there is no major ambiguity about content format
- [x] there is no major ambiguity about save baseline
- [x] there is no major ambiguity about what is deferred
- [x] the next step is implementation, not more document restructuring

## Current Recommended Use

Run this checklist before:
- starting the minimum playable slice
- switching to a new chat/thread
- publishing the repo baseline to another collaborator
