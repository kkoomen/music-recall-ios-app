# Agent Workflow

## Source of truth

AGENTS.md defines repository rules. ROADMAP.md defines feature order and completion gates. ORCHESTRATOR.md defines delegation and handoff.

## Standard cycle

1. Read current roadmap and relevant docs.
2. Inspect existing implementation and tests.
3. Pick the first eligible unfinished section.
4. Implement only assigned scope.
5. Add tests.
6. Build and run tests.
7. Review code, accessibility, and product behavior.
8. Update Markdown.
9. Check roadmap items and completion heading if gates pass.
10. Prepare Conventional Commit.

## Handoffs

Every handoff includes changed paths, tests, build result, acceptance status, and risks. Agents must not hide blockers.

## Role boundaries

- Builder edits implementation.
- Testing agent edits tests and test documentation when assigned.
- Build agent runs checks and may edit build configuration only when ROADMAP assigns it.
- Code-review agent is read-only.
- Documentation agent edits Markdown only.
- Commit agent handles commit text and commit operation only after gates pass.

## Roadmap updates

Documentation agent updates ROADMAP.md immediately after a verified feature. It checks every completed task, changes section heading to [x] Feature (Completed), and leaves unfinished tasks unchanged.
