# Quiz Rules

## Session

- A session contains ten rounds when at least ten playable tracks exist.
- If fewer than ten tracks exist, use every available track once.
- Random selection must not repeat a track within one session.
- A session ends after its final round.
- Replay creates a new selection.

## Round

1. Select one track.
2. Start playback from the beginning.
3. Start a monotonic thirty-second timer.
4. Accept one answer.
5. Stop playback on answer, skip, reveal, timeout, or interruption.
6. Record result and advance.

## Answer

Normalize case, whitespace, punctuation, and diacritics. Accept an exact normalized title or exact normalized artist-title form. Do not use network matching or external recognition.

Wrong answer ends the round. Skip, reveal, and timeout end the round with zero points.

## Scoring

For a correct answer submitted before timeout:

max(100, 1000 - floor(elapsed seconds × 30))

Immediate answer earns 1,000. Answer at thirty seconds earns 100. Wrong answer, skip, reveal, or timeout earns 0. Score freezes at the first terminal event.

## Edge cases

- Empty library: show setup guidance.
- Fewer than ten tracks: explain shorter session.
- Missing asset during playback: show failure and continue safely.
- Duplicate title: identify track by persistent media identifier.
- Double submit: first terminal event wins.
