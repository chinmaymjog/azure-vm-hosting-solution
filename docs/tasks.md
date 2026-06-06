# Task Tracker

## Document Control

- Project: Azure Shared Hosting Platform (Hardened)
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## Current Focus

- Theme: Directory and Standard Alignment
- Current objective: Restructure directories and update references to align with engineering system standards.
- This week target: Align layout, update Makefile, configure Git ignore lists, and author core docs.

## Now (Do First)

| ID | Task | Requirement IDs | Owner | Verification | Status |
| -- | ---- | --------------- | ----- | ------------ | ------ |
| T-007 | Create task tracking tracker | FR-001 | Human+AI | Check file existence | In Progress |
| T-008 | Update links and paths in HOW_TO_GUIDE & SITE_MANAGEMENT | FR-003 / NFR-003 | Human+AI | Review markdown links | Not Started |

## Done

| ID | Completed On | Requirement IDs | Validation Evidence | Notes |
| -- | ------------ | --------------- | ------------------- | ----- |
| T-001 | 2026-06-06 | FR-001 / NFR-003 | `git status` check | Restructured folders to `infra/` |
| T-002 | 2026-06-06 | FR-003 / NFR-003 | `make help` and `git diff` | Updated Makefile & gitignore |
| T-003 | 2026-06-06 | FR-001 / FR-003 | `cat README.md` check | Reorganized README layout |
| T-004 | 2026-06-06 | FR-001 | `cat CONTRIBUTING.md` | Conventional commit guidelines added |
| T-005 | 2026-06-06 | FR-001 | File review | Spec created with requirement IDs |
| T-006 | 2026-06-06 | FR-001 | File review | Architecture doc created with ADRs |

## Quick Coverage Check

- [x] Every task in Now has requirement IDs.
- [x] Every task in Done has validation evidence.
- [x] docs/project-spec.md reflects current scope.
- [x] docs/architecture.md reflects major decisions.
