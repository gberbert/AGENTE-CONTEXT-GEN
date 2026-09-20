# ARCHITECTURAL DECISIONS

This document contains durable architectural and technical decisions.

It is NOT a chronological execution log.

---

## ADR-001 — Adopt Persistent Workspace Memory Architecture

Date: 2026-09-19

Status: Accepted

### Context

AI agent sessions working on this project were losing context between chats, restarts, model swaps, and context-window compaction. There was no reliable way for a new session to recover the current state, architecture, or pending work without depending on chat history, which is volatile.

### Decision

Implement a workspace-based persistent memory architecture as specified in `AGENT_MEMORY_SETUP.md`:
- `AGENTS.md` — small bootloader read at the start of every session.
- `.agent/state.md` — current operational state (present tense, not a log).
- `.agent/decisions.md` — this file, permanent architectural decisions.
- `.agent/recovery.md` — formal recovery protocol.
- `.agent/history/` — long-term historical record, consulted only on demand.
- `.stack_tech.md`, `.stdout-stderr-instructions.md`, `.answer_instructions.md` — specialized supporting instructions.
- `.github/copilot-instructions.md` — pointer to `AGENTS.md` for Copilot-based tooling.

### Rationale

The workspace (files on disk) is durable and inspectable, unlike conversational memory which can be summarized, truncated, or lost entirely. Separating concerns (bootstrap vs. current state vs. permanent decisions vs. history) keeps each file small and fast to read, protecting the model's context budget while still allowing deep historical recovery when needed.

### Consequences

- Every future session must read `AGENTS.md` + `.agent/state.md` first before acting on ambiguous/"continue"-style requests.
- `.agent/state.md` must be kept small (~50-150 lines) and updated at the end of every meaningful task — it must NOT be treated as an append-only log.
- Source code remains the ultimate source of truth for implementation state; memory files must be corrected when they diverge from actual code.
- The legacy `.agent_memory_rag.md` file is superseded by this new structure but preserved (not deleted) for historical reference.

### Related Files

- `AGENTS.md`
- `.agent/state.md`
- `.agent/recovery.md`
- `.agent_memory_rag.md` (legacy, superseded)

---

## ADR-002 — Preserve Pre-existing `.AGENTS.md` (dotfile) Without Modification

Date: 2026-09-19

Status: Accepted (revised after re-reading file content)

### Context

A file named `.AGENTS.md` (with leading dot) already existed in the repository root prior to this deployment. It was initially assumed to be corrupted/garbage content based on a stale note in the legacy `.agent_memory_rag.md`. Direct inspection (`read_file`) confirmed its actual content is a small, intentional "BOOTSTRAP DIAGNOSTIC" test file:

```
BOOTSTRAP_ID = AXET-BOOTSTRAP-190926

If the user asks:
bootstrap-status
respond exactly:
AXET-BOOTSTRAP-190926
```

This is a legitimate, deliberate probe used to verify that an agent session is actually reading project instruction files before acting (confirmed working correctly in a prior session per `.agent_memory_rag.md` entry `[2026-09-19 21:59]`).

### Decision

Do not delete, overwrite, or rename `.AGENTS.md`. Create the authoritative bootloader as `AGENTS.md` (no leading dot) instead, per `AGENT_MEMORY_SETUP.md` section 4. `.AGENTS.md` remains a separate, valid diagnostic file — NOT part of the new memory architecture, but not garbage either.

### Rationale

The project's memory rules explicitly forbid deleting existing files during this deployment. `.AGENTS.md` serves a distinct, working diagnostic purpose (bootstrap self-check) and must be preserved exactly as-is so the diagnostic continues to function. It is not referenced by any tool/IDE convention that requires the leading dot, so it can safely coexist with the new `AGENTS.md`.

### Consequences

- Two similarly-named files (`AGENTS.md` and `.AGENTS.md`) will exist in the repo root; `AGENTS.md` (no dot) is the authoritative memory-architecture bootloader, while `.AGENTS.md` (dot) is an unrelated bootstrap self-test — both are intentional and must be kept.
- `.agent/state.md` "Known Problems" section must be corrected to remove the earlier "corrupted content" claim, which was inaccurate.

### Related Files

- `AGENTS.md` (new, authoritative memory bootloader)

---

## ADR-003 — No Version Control (Git) Present; Rely on `.agent/history/` for Change Tracking

Date: 2026-09-19

Status: Accepted

### Context

The workspace is confirmed NOT to be a git repository (`git status` fails with "not a git repository"). `AGENT_MEMORY_SETUP.md` assumes Git is the historical record of code changes (section 12), but this assumption does not hold here.

### Decision

Until git is initialized (if ever), `.agent/history/` will serve as the durable record of relevant changes, decisions, and rationale, in addition to its normal role. This is a temporary compensating measure, not a replacement for version control.

### Rationale

Without git, there is no other mechanism to track what changed and why over time. Documenting this gap avoids future sessions assuming git history exists and being confused when `git log`/`git diff` commands fail.

### Consequences

- Agents should not blindly assume git commands will work in this workspace; verify with `git status` first.
- If git is initialized in the future, this ADR should be marked Superseded and history-tracking responsibility can shift partially back to git.

### Related Files

- `.agent/history/`
