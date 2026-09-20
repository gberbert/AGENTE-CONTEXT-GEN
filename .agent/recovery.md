# AGENT CONTEXT RECOVERY PROTOCOL

## FUNDAMENTAL RULE

Recovery is not execution.

Recovering previous context does not automatically authorize previous work.

Use this document when starting a new session, when context was lost, when instructed to "continue", or whenever memory uncertainty is detected.

---

# CASE A — MEMORY LOSS DURING CURRENT EXECUTION

If context is lost while actively executing a user-authorized task (`.agent/current_task.md` status is `ACTIVE` and `Resume Authorization: YES`):

1. Read `.agent/current_task.md`.
2. Read the latest relevant checkpoint from `.agent/execution_journal.md`.
3. Inspect relevant source files listed under "Relevant Files".
4. Determine the last safe checkpoint.
5. Resume from `Next Safe Action`.

Do not repeat completed work. Do not restart from the beginning.

---

# CASE B — NEW CHAT

A new chat does NOT by itself authorize continuation of any persisted task.

Wait for the user's current message. Classify it as `NEW_TASK`, `CONTINUE_TASK`, or `INFORMATIONAL` (see `AGENTS.md` → INTENT CLASSIFICATION).

- If `NEW_TASK`: follow the new task; mark any `ACTIVE` task in `current_task.md` as `SUSPENDED` with `Resume Authorization: NO`.
- If `CONTINUE_TASK`: recover `.agent/current_task.md` per Case A.
- If `INFORMATIONAL`: answer only the current request; do not touch `current_task.md`.

---

# CASE C — AMBIGUOUS MEMORY

If uncertain whether work was already completed:

1. Check `.agent/current_task.md` → "Completed" / "In Progress" / "Not Started".
2. Check `.agent/execution_journal.md` for the latest checkpoint and whether a `BEFORE_ACTION` has a matching `AFTER_ACTION`.
3. Check the actual source code / file state directly.
4. Prefer implementation evidence over any written claim.

Never guess. Never repeat a side-effecting action (file write, migration, command with side effects, commit, push) without confirming it did not already happen.

---

# CASE D — STALE MEMORY

If memory disagrees with the real implementation:

SOURCE CODE WINS.

Correct the stale persistent memory file (`state.md`, `current_task.md`, etc.) to reflect reality after confirming via direct inspection.

---

# RECOVERY ORDER

1. `.agent/current_task.md`
2. latest relevant `.agent/execution_journal.md` checkpoint
3. relevant source files
4. `.agent/state.md`
5. `.agent/decisions.md`
6. `.stack_tech.md`
7. selective `.agent/history/` search only if needed

---

# ABSOLUTE RULE

Never ask the user to repeat project context before attempting recovery from persistent memory.

Never execute historical work solely because it exists in memory.

---

# STEP-BY-STEP EXECUTION

## Step 1 — Read Bootstrap Files (in order)

1. `AGENTS.md` (repo root)
2. `.agent/current_task.md` (is there an active/suspended task requiring resume authorization?)
3. `.agent/state.md`
4. `.agent/decisions.md` (skim headers only, read full ADR if relevant to current task)
5. `.stack_tech.md`
6. selective `.agent/history/` search only if needed

## Step 2 — Cross-check State vs Reality

`.agent/state.md` and `.agent/current_task.md` are claims, not guarantees. Verify against the actual filesystem/code when in doubt:

- Confirm files listed under "Relevant Components" / "Relevant Files" still exist and roughly match described purpose.
- If a task references files being created/modified, verify with `list_files`/`read_file` whether that actually happened before assuming the task is incomplete or complete.
- If unsure whether a described change was applied, use `read_file` or `search_files` to confirm directly in code rather than trusting memory files blindly.

## Step 3 — Resume Work

- If `.agent/current_task.md` status is `ACTIVE` and `Resume Authorization: YES`, and the current user message is `CONTINUE_TASK` (or context was lost mid-execution of that same task), continue from "Next Safe Action" in `.agent/current_task.md`.
- If status is `COMPLETED`, treat the described state as ground truth and wait for a new user request — never re-execute automatically.
- If status is `SUSPENDED`, treat as historical context only; do not resume unless the current user message is explicitly `CONTINUE_TASK` referring to it.
- If status is `CANCELLED`, never resume automatically under any circumstance.

## Step 4 — On Task Completion

Update `.agent/current_task.md`:
- Mark `Status: COMPLETED`, `Resume Authorization: NO`.

Update `.agent/state.md`:
- Move completed items from "Pending Work"/"Open Threads" into "Recent Changes".
- Update "Known Issues" if resolved.

Also:
- If a new durable architectural choice was made, add an ADR entry to `.agent/decisions.md` (do not put it only in state.md).
- If the change is significant, append a dated entry to the current month's file in `.agent/history/` (e.g. `.agent/history/2026-09.md`).
- Reinitialize `.agent/execution_journal.md` for the next task once consolidated.

## Step 5 — Never

- Never delete `.agent/`, `AGENTS.md`, or any of the support instruction files without explicit user request.
- Never treat `.agent/state.md` or `.agent/execution_journal.md` as an append-only log — keep them current and concise, moving stale detail to `.agent/history/`.
- Never assume git history is available in this workspace (see ADR-003 in `.agent/decisions.md`) — verify with `git status` first.
- Never execute a task solely because it appears as `ACTIVE`/`PENDING`/`SUSPENDED` in memory — only the current user request authorizes execution.
