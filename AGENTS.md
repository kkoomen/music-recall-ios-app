# Song Recall Agent Instructions

## Read order

Before any task, read:

1. this file;
2. docs/ROADMAP.md;
3. docs/agent-workflow.md;
4. docs relevant to assigned feature;
5. the assigned file in .pi/agents/.

docs/ROADMAP.md is canonical. ORCHESTRATOR.md and every agent must follow its order, dependencies, checklists, and acceptance gates.

## Product goal

Song Recall is a private iPhone music-memory quiz. It reads locally available songs from the user's Apple Music library, plays each selected song from the beginning, accepts a free-text guess, and awards more points for faster correct answers.

## Hard constraints

- iOS only.
- iOS 26+.
- Swift and SwiftUI only for app implementation.
- Apple frameworks only. No third-party packages.
- MediaPlayer for the user's Music library.
- AVFoundation for local playback.
- No Spotify, streaming, catalog, lyrics, recognition, analytics, cloud, or external music API.
- Do not read or upload song audio outside the device.
- Do not add Swift implementation until ROADMAP foundation gates permit it.

## Repository rules

- Keep feature code under src/.
- Keep tests under tests/.
- Keep project and build setup at repository root.
- Keep written project knowledge under docs/.
- Keep Pi role instructions under .pi/agents/.
- Do not put Swift source in docs, .pi/agents, or temporary structure placeholders.
- Prefer small, focused files.
- Keep domain logic independent from MediaPlayer, AVFoundation, and SwiftUI.
- Inject time, randomness, media access, and playback for tests.
- Every behavior change needs matching tests and relevant Markdown updates.

## Agent workflow

The orchestrator owns sequencing. Agents work only inside their role boundaries.

1. Inspect current state.
2. Select the next unchecked ROADMAP section.
3. Implement one bounded feature.
4. Add or update tests.
5. Run build and test checks.
6. Run code review, accessibility review, and product QA where ROADMAP requires.
7. Update Markdown documentation.
8. Mark ROADMAP tasks complete only when acceptance gates pass.
9. Prepare a Conventional Commit.

Documentation agent may edit only:

- AGENTS.md;
- ORCHESTRATOR.md;
- docs/**/*.md;
- .pi/agents/**/*.md.

Documentation agent must never edit Swift, tests, project files, assets, or code comments.

## Done definition

A feature is done only when its ROADMAP checklist is checked, required tests pass, build passes, required reviews pass, and docs describe the shipped behavior. Then change the section heading from [ ] to [x] and append (Completed).

## Commit rule

Use Conventional Commits. Commit agent must inspect the actual diff and never claim work that is not present.
