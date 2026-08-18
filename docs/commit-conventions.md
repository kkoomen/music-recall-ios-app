# Commit Conventions

## Format

type(scope): imperative summary

Examples:

- feat(quiz): add timed round state
- fix(audio): stop playback after timeout
- test(scoring): cover timeout boundary
- docs(roadmap): mark media catalog complete
- build(project): configure iOS target

## Rules

- Use one logical change per commit.
- Keep subject concise.
- Use imperative wording.
- Explain why in body when intent is not obvious.
- Do not commit failing tests or builds unless explicitly recording a known blocked state.
- Do not claim files not present in the diff.

## Commit agent

Inspect status and diff first. Check roadmap state and tests. Propose the message from actual changes. Do not rewrite unrelated user changes.
