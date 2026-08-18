# Testing

## Test layers

### Domain unit tests

Cover answer normalization, scoring boundaries, round transitions, duplicate prevention, fewer-than-ten behavior, timeout, skip, and duplicate submissions.

### Service tests

Use fakes for media library, audio player, clock, and random source. Verify mapping and playback event order without Apple Music data.

### UI tests

Cover permission, denied state, empty library, start quiz, correct answer, wrong answer, timeout, results, replay, and accessibility identifiers.

### Device tests

Run on a real iPhone with local Music-library tracks. Verify authorization, speaker and headphone playback, interruptions, route changes, and unavailable assets.

## Test rules

- Tests must be deterministic.
- Do not use wall-clock sleeps for timing logic.
- Prefer injected clock advancement.
- Do not make simulator tests depend on personal media.
- Add a regression test for every fixed bug.
- Keep UI selectors stable through accessibility identifiers.

## Completion

Testing agent reports commands, pass/fail result, coverage of changed behavior, and unresolved device-only checks.
