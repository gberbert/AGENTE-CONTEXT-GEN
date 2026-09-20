# Copilot Instructions — AXET Video Pipeline

This repository uses a persistent, file-based memory architecture. Before assisting with any task in this project:

1. Read `AGENTS.md` at the repository root — it is the authoritative bootstrap file defining memory recovery rules, source-of-truth hierarchy, and operating policy.
2. Read `.agent/state.md` for current project state (active task, pending work, known issues).
3. Read `.stack_tech.md` for confirmed architecture/stack details.
4. Follow `.stdout-stderr-instructions.md` when running any shell command.
5. Follow `.answer_instructions.md` for response language/style (pt-BR, direct/technical).

Do not rely on conversation history alone to determine project state — the workspace files listed above are the source of truth. If `.agent/state.md` conflicts with what you recall from the conversation, the file wins.

## Active Execution Recovery

The latest user request defines current intent. Persistent memory provides context only.

For active execution recovery use:
- `.agent/current_task.md` — execution checkpoint of the current or suspended task.
- `.agent/execution_journal.md` — transactional log of what actually happened during the current task.

Never resume historical work merely because it exists in memory (`current_task.md`, `state.md`, or `history/`). A previous task may only be resumed when the current user message explicitly indicates continuation, or when context was lost during the currently executing task.

If context is lost during active execution, recover from checkpoints (`current_task.md` → `execution_journal.md` → source code) before asking the user to repeat context.

Full details: see `AGENTS.md`.
