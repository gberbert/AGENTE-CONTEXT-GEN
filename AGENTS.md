# AXET VIDEO PIPELINE — AGENT BOOTSTRAP

## FUNDAMENTAL RULE

The workspace is the persistent memory of the project.

Conversation history is NOT the authoritative source of project state.

Never depend exclusively on chat memory to understand the current state of the project.

The agent can lose conversation memory at any moment.

Therefore no critical execution state may exist only in chat.

MEMORY PROVIDES CONTEXT. MEMORY DOES NOT CREATE INTENT.

The latest user message determines WHAT must be done.

Persistent files determine HOW to recover the context needed to execute that.

---

# ABSOLUTE PRIORITY

The latest user message is always the authoritative source of current intent.

Persistent memory provides context. Persistent memory does not create intent.

Never execute a task only because it appears as ACTIVE, PENDING, TODO, NEXT, RECOMMENDED, IN_PROGRESS, SUSPENDED, OPEN THREAD or NEXT RECOMMENDED ACTION in memory.

---

# AUTHORITY HIERARCHY

Mandatory priority order:

1. CURRENT USER REQUEST
2. `.agent/current_task.md`
3. actual workspace source code
4. `.agent/state.md`
5. `.agent/decisions.md`
6. `.stack_tech.md`
7. `.agent/execution_journal.md`
8. `.agent/history/`
9. conversation history

`.agent/current_task.md` may only trigger resumption of execution when the current user message indicates continuation, or when context was lost during the currently executing task.

A new, different user message always takes priority over any persisted task.

---

# INTENT CLASSIFICATION

Before performing technical work, classify the latest user message internally as one of:

- **NEW_TASK** — a request different from the persisted task.
  Result: old task → SUSPENDED (Resume Authorization: NO); new request → ACTIVE.
- **CONTINUE_TASK** — messages such as "continue", "prossiga", "continue de onde paramos", "retome", "pode continuar", "termine aquilo", "continue a implementação anterior".
  Result: read `.agent/current_task.md` → recover checkpoint → verify source → continue.
- **INFORMATIONAL** — questions or analysis that do not mean resuming previous work (e.g. "Qual porta esse servidor utiliza?").
  Result: answer the question. Do NOT resume old task.

A new chat session does NOT by itself mean CONTINUE_TASK. Session bootstrap only restores understanding of the rules; it never authorizes automatic execution of old work. The correct flow is:

```
NEW CHAT → load AGENTS.md rules → WAIT FOR USER MESSAGE → classify intent
```

It is forbidden to do: `NEW CHAT → read old task → execute automatically`.

---

# ZOMBIE TASK DETECTOR

A ZOMBIE TASK is an old task executed without authorization from the current request.

Before any technical action, verify internally:

"Does this action belong to the CURRENT USER REQUEST, or to a task explicitly resumed?"

If NO → STOP. Do not proceed with that action.

---

# TASK DRIFT PREVENTION

Every action during execution must relate to the `Task ID` in `.agent/current_task.md`.

If an unrelated but interesting problem appears, record it in `.agent/state.md` → `Open Threads` and do NOT execute it as part of the current task.

---

# SESSION BOOTSTRAP

At the beginning of a new session, new chat, recovered conversation, or whenever context may have been lost:

1. Read `.agent/state.md`.
2. Read `.stack_tech.md`.
3. Read `.stdout-stderr-instructions.md`.
4. Read `.answer_instructions.md`.

Do not automatically load the complete historical memory.

Load additional context only when necessary.

---

# MEMORY RECOVERY — MANDATORY

If you:

- lose conversation context;
- receive a summarized conversation;
- cannot remember the last request;
- cannot determine the current implementation state;
- encounter an ambiguous reference to previous work;
- suspect information disappeared from the context window;
- receive a request such as "continue";
- are about to ask the user to repeat project information;

you MUST recover context from project files BEFORE asking the user.

Mandatory recovery order:

1. `.agent/state.md`
2. `.agent/decisions.md`
3. `.stack_tech.md`
4. relevant source files
5. selective search inside `.agent/history/`

Never guess missing project context.

Never reconstruct technical facts purely from conversational memory when the workspace can be inspected.

Only ask the user after the recovery procedure fails to provide the information.

---

# SOURCE OF TRUTH

Current implementation:

Actual workspace files.

Current operational state:

`.agent/state.md`

Architecture and technology:

`.stack_tech.md`

Architectural decisions:

`.agent/decisions.md`

Historical information:

`.agent/history/`

Recovery protocol:

`.agent/recovery.md`

Conversation history:

Auxiliary only.

---

# CONTEXT EFFICIENCY

Protect the model context window.

DO NOT recursively load the entire repository.

DO NOT automatically read the complete history.

DO NOT copy large logs into context when search or grep is sufficient.

DO NOT store large deprecated code blocks in operational memory.

Retrieve information selectively.

---

# CURRENT STATE

`.agent/state.md` must remain concise.

It contains only information needed to continue the project NOW:

- current objective;
- current version;
- architecture summary;
- active task;
- current implementation status;
- pending work;
- known issues;
- latest relevant changes;
- next recommended action.

Historical details belong in:

`.agent/history/`

Permanent architectural decisions belong in:

`.agent/decisions.md`

---

# BEFORE IMPLEMENTATION

Before modifying the project:

1. Recover current state if necessary.
2. Understand the request.
3. Inspect only relevant files.
4. Update `.agent/state.md` with the planned activity.
5. Implement.
6. Validate.
7. Update `.agent/state.md` with the result.

Reading persistent memory is always allowed before writing the plan.

---

# AFTER IMPLEMENTATION

After completing a meaningful technical change:

1. Update `.agent/state.md`.
2. Record permanent architectural decisions in `.agent/decisions.md`.
3. Record relevant history in `.agent/history/`.
4. Remove obsolete operational information from `state.md`.

Do not allow `.agent/state.md` to become an append-only log.

---

# ENVIRONMENT POLICY

STAGING:

Autonomous development operations are allowed.

PRODUCTION:

Production or deployment changes require explicit user approval.

---

# SAFETY

Never perform destructive permanent file operations without explicit authorization.

Prefer atomic commands.

Never run indefinite commands merely to observe stdout or stderr.

Follow:

`.stdout-stderr-instructions.md`

---

# FAILURE MODE

If conversational memory and project files disagree:

THE PROJECT FILES WIN.

Inspect the real implementation before making assumptions.

If `.agent/state.md` is stale:

Update it to reflect the real workspace.

Code is the ultimate source of implementation truth.

---

# CONTEXT LOSS DETECTION

Treat any indication that conversation history was:

- summarized;
- compressed;
- truncated;
- removed;
- unavailable;

as a MEMORY RECOVERY EVENT.

Immediately recover context from `.agent/state.md`.

---

# CONTINUE COMMAND

If the user writes:

"continue"

or any equivalent request:

DO NOT immediately ask what should be continued.

Read `.agent/state.md`.

Use:

- Active Task
- Pending Work
- Next Recommended Action

to recover the previous activity.

Only ask the user if the project memory does not provide enough information.

---

# MEMORY LOSS WATCHDOG

Assume conversational memory can disappear at any moment.

No critical execution information may exist only in conversation history.

During long or multi-step work, persist checkpoints in:

`.agent/current_task.md`

and:

`.agent/execution_journal.md`

---

# MEMORY UNCERTAINTY DETECTION

If at any moment you are uncertain about:

- what task is currently being executed;
- which step is active;
- what has already been completed;
- what file was changed;
- why a change was made;
- whether a command already ran;
- what the next safe action is;
- whether you are about to repeat previous work;

STOP.

Do not guess. Do not repeat previous steps.

Read `.agent/current_task.md`, then inspect `.agent/execution_journal.md`, then reconcile with the actual relevant source files.

Resume only after identifying the last safe checkpoint.

---

# RECOVERY IS NOT AUTHORIZATION

Recovering previous context does not automatically authorize previous work.

A previous task may only be resumed when:

1. the current user request explicitly indicates continuation;

OR

2. context was lost during the currently executing task.

---

# CURRENT TASK

`.agent/current_task.md` contains the execution checkpoint for the current or suspended task.

It is not authorization by itself.

---

# CHECKPOINT POLICY

Persist a checkpoint in `.agent/execution_journal.md` whenever:

- investigation identifies the root cause;
- an important technical decision is made;
- a relevant file is modified;
- a planned step completes;
- validation succeeds or fails;
- execution moves to another subsystem;
- the next safe action changes;
- memory uncertainty is detected;
- conversation summarization or context loss occurs.

Do not register every trivial command — only relevant state transitions (investigation → root cause, planning → implementation, file unchanged → modified, implementation → validation, one subsystem → another, memory stable → memory uncertain).

---

# WRITE-AHEAD CHECKPOINT

Before a significant change, persist: intended action, relevant file, reason, current state, expected next action.

After the change, persist: what actually changed, result, validation, next safe action.

If a `BEFORE_ACTION` checkpoint exists without a matching `AFTER_ACTION`, do not assume the action happened — verify the real file/state and record a `RECOVERY` checkpoint before continuing.

---

# NO REPEATED ACTIONS

Before repeating a file modification, migration, configuration change, side-effect command, artifact generation, commit or push, confirm in `current_task.md`, `execution_journal.md` and the source code whether it already happened. If marked completed and the code confirms it, do NOT repeat it.

---

# BOOTSTRAP VERIFICATION

If asked:

`bootstrap-status`

respond with:

BOOTSTRAP_ACTIVE

Then verify the existence of:

`.agent/current_task.md`
`.agent/state.md`
`.agent/execution_journal.md`

Report for each, e.g.:

`.agent/current_task.md: FOUND` or `NOT FOUND`
`.agent/state.md: FOUND` or `NOT FOUND`
`.agent/execution_journal.md: FOUND` or `NOT FOUND`

---

# RECOVERY STATUS

If asked:

`recovery-status`

DO NOT execute the pending task. Only read `.agent/current_task.md` and the latest checkpoint in `.agent/execution_journal.md`, then respond with:

```
Task ID:
Status:
Phase:
Current Step:
Last Safe Checkpoint:
Last Action:
Next Safe Action:
Resume Authorization:
```

---

# CHECKPOINT STATUS

If asked:

`checkpoint-status`

Return only:

```
Task ID:
Latest Checkpoint:
Checkpoint State:
Latest Confirmed Result:
Next Safe Action:
```

Without executing the next action.

## Artefatos transitórios de sessão

Scripts ou arquivos criados **só para executar uma tarefa pontual** e **fora** da estrutura versionada do framework (`scripts/`, `docs/`, `systems/{id}/`) **devem ser removidos ao término da tarefa** — idealmente pelo próprio agent, antes do handoff.

| Proibido versionar | Onde | Ação ao concluir |
|---|---|---|
| `_*.*` na raiz ou em `scripts/` | ex.: `_*.mjs`, `_*.json`, `_*.js`, `_*.ts` | **Deletar** ou `npm run cleanup:transient` |
| Pastas de smoke/piloto/scratch | `.graphify/`, `smoke-run/`, `legacy_piloto/`, `scratch/` | `cleanup:transient` |
| Arquivos temporários | `*.tmp`, `*.temp`, `*.bak` | `cleanup:transient` |
| Código inventado em `legacy/` | Regra #0 | Nunca criar |

**Preferir:** comandos allowlisted (`terminologia:enrich-apply`, `validate:*`, etc.) em vez de gerar script auxiliar. Se um script one-off for inevitável, registrar o path e apagá-lo na última etapa.

**Atalho chat:** `Limpar ambiente de trabalho` → `npm run cleanup:transient`
