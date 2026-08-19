# Quiz Rules

## Session

- A session contains ten rounds when at least ten playable tracks exist.
- If fewer than ten tracks exist, use every available track once.
- Random selection must not repeat a track within one session.
- A session ends after its final round.
- Replay creates a new selection (and keeps the same mode).

## Modes

- **Easy**: the player picks one of up to five options per round; the pick settles the round immediately (no Submit button).
- **Hard** (labeled "Hard Mode" on the home screen; mode `expert` internally): identical to easy — up to five options per round and the same scoring — except the song is never played from the beginning. When a round starts, a 1-second sample of one random part of the song plays **automatically and free of charge**; a **Play Sample** button above the options replays the same part, at most three times per round. The remaining plays are shown on the button ("N plays left"), reset every round, and the button locks and grays out once the three attempts are spent. Playback failure settles the round as interrupted.
- **Expert** (labeled "Expert Mode" on the home screen; mode `hard` internally): the original free-text experience with the autocomplete dropdown.
- Easy-mode options are the correct track plus up to four decoys from the full catalog, shuffled via the injected random source. Decoys whose normalized title equals the correct track's title — or duplicates another decoy's title — are excluded, so two identically labeled options never appear. A catalog smaller than five tracks yields fewer options.
- Easy-mode picks are matched by track identity (persistent media ID), never by title text, so a same-title decoy can never count as correct.
- On a wrong pick the correct option is highlighted in green with a checkmark and the picked option in red with a cross; other options dim. A correct pick highlights only the correct option. A timeout never marks a pick as wrong.
- Everything else — timer, feedback banners, reveal, skip, penalties, results, replay — is identical across modes.

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

## Answer input autocomplete

While typing, the answer field searches the full local library catalog (not just the quiz's selected tracks) and shows up to five suggestions ranked by normalized match relevance:

- exact title match, then title prefix, artist prefix, artist-title prefix, then substring matches;
- songs with equal relevance are shuffled via the injected random source (the active round's song is never favored; no alphabetical fallback).

Search is debounced 400ms after the last keystroke; clearing the input keeps the dropdown open so return can still pick the first suggestion. Songs with equal relevance — for example every song by one artist — are listed in random order (the active round's song is never favored and there is no alphabetical fallback). The quiz screen places the input field at the top and the action buttons at the bottom; the space in between is reserved for the autocomplete dropdown, which expands below the input while typing without shifting the layout. Each row shows the title in white larger text and the artist in grey smaller text.

Return-key behavior:

- non-empty field: submits the typed answer;
- empty field with the dropdown open: selects the first (top) suggestion and submits it;
- empty field with no dropdown: does nothing (never an accidental wrong answer).

Tapping a row fills the field with that track's title and submits it as the player's answer (one attempt, as usual).

The answer field auto-focuses when the quiz starts; once a round settles the keyboard dismisses so the reveal and bottom action buttons are visible.

## Answer reveal

Whenever a round ends — correct answer, wrong answer, skip, timeout, or playback interruption — the song is revealed centered in the middle of the quiz screen without a container: the title in larger white text with the artist in smaller grey text underneath.

## Scoring

For a correct answer submitted before timeout:

(10 + remaining seconds) × multiplier, where remaining seconds match the displayed countdown.

- Immediate answer earns 40 points (10 + 30 remaining) doubled to 80.
- Answering within the fast window applies a 2x multiplier (shown as "You're fast!" with a highlighted 2x badge). The window is mode-dependent: the first 5 seconds in hard mode (25 or more seconds remaining on the clock), the first 3 seconds in easy mode (27 or more seconds remaining).
- Answer at thirty seconds earns 10 points (no remaining time).
- Wrong answer: −5 points.
- Skip: −10 points.
- Timeout or playback interruption: 0 points.
- The running score never goes below 0.

Score freezes at the first terminal event.

## Edge cases

- Empty library: show setup guidance.
- Fewer than ten tracks: explain shorter session.
- Missing asset during playback: show failure and continue safely.
- Duplicate title: identify track by persistent media identifier.
- Double submit: first terminal event wins.
