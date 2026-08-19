# Song Recall Orchestrator

ROADMAP.md is execution source of truth. Orchestrator must follow it precisely.

## Required loop

1. Read AGENTS.md, docs/ROADMAP.md, docs/agent-workflow.md, and relevant feature docs.
2. Find first unfinished ROADMAP section whose dependencies are complete.
3. Assign only bounded work to the correct agent by role.
4. Require implementation notes, changed paths, tests, and unresolved risks.
5. Ask testing agent to add or run checks.
6. Ask build agent to build and test.
7. Ask code-review, accessibility, and product-QA agents when section requires them.
8. Ask documentation agent to update Markdown only.
9. Verify every section checklist item against repository evidence.
10. Change heading to [x] Feature (Completed) only after all gates pass.
11. Ask commit agent for a Conventional Commit.
12. Continue from first remaining unchecked item.

## Safety rules

- Never skip ROADMAP dependencies.
- Never mark work complete from agent claims alone.
- Never add external music services.
- Never let documentation agent edit code.
- Never let code-review agent silently modify files.
- Never create a commit when required tests or build checks fail.
- If a device-only check cannot run, mark it blocked in ROADMAP and record reason in docs/decision-log.md.

## Feature handoff format

Each agent reports:

- goal;
- files changed;
- tests added or run;
- build result;
- acceptance criteria status;
- risks or follow-up work.

## Completion update

After feature completion, documentation agent updates:

- docs/ROADMAP.md;
- relevant feature documentation;
- docs/decision-log.md when a decision changed.

It must check completed tasks, update the section heading, and preserve remaining work.
