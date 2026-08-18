# Design System

## Direction

Dark album-art arcade. The interface feels focused, energetic, and premium without adding visual noise.

## Brand mark

`SongRecallLogo` is the app mark: a hot-pink beamed music note on a near-black arcade tile, surrounded by two quiet return arcs. The note keeps music immediately legible; the arcs signal memory and replay. The source lives in `src/SongRecall/Resources/Assets.xcassets/SongRecallLogo.imageset/` and is kept as vector artwork for scale-independent rendering.

## Tokens

Defined in `src/SongRecall/DesignSystem/AppTheme.swift`:

- Surfaces: `background` (near-black), `surface`, `surfaceElevated`, `surfaceBorder`.
- Text: `primaryText` (off-white), `secondaryText` (muted), both high-contrast on the dark surfaces.
- Semantic: `accent` (hot arcade pink), `accentText` (near-black, ≈9:1 on accent), `success`, `danger`.
- Spacing scale: xs/sm/md/lg/xl/xxl (4/8/12/16/24/32).
- Shape: card 20, small 14, button 16.
- Motion: 0.25s ease-in-out; minimum touch target height 48.

## Visual language

- Near-black base.
- Off-white primary text.
- Album-art-derived accent gradients: `ArtworkAccent` averages artwork pixels for a radial glow behind the artwork card only; text never sits on artwork-derived colors.
- High-contrast timer and score with monospaced digits (no width jitter per tick).
- Large numeric typography.
- Rounded cards and controls via the `panel(...)` modifier.
- SF Symbols for familiar actions.

## Appearance decision

The app is intentionally dark-only (arcade look) and forces `.preferredColorScheme(.dark)`. There is no light fallback; semantic colors are tuned for the dark surfaces. Increase Contrast and Dynamic Type are supported.

## Screen priorities

- Home: one obvious Start Quiz action.
- Quiz: artwork, timer, score, progress, answer, submit.
- Results: score, accuracy, fastest answer, replay.

## Interaction

- Short transitions (route changes and feedback banners), fully disabled under Reduce Motion.
- Haptics for correct (success), wrong/timeout (error), and skip (light impact); disabled under Reduce Motion.
- Primary action visually dominant (accent-filled with near-black text).
- No gesture-only controls.

## Accessibility

- Semantic colors with sufficient contrast (accentText on accent ≈9:1; primary/secondary text on background and surface both pass WCAG AA).
- Dynamic Type supported without clipping: the quiz header uses `ViewThatFits` to fall back to a vertical layout, and an accessibility-XXXL UI test guards it.
- VoiceOver: every control has a meaningful label; artwork is labeled "Song artwork" and never exposes the song title (the answer); timer/score/round use explicit labels; results stats combine title+value.
- Touch targets: interactive elements enforce a 48pt minimum height.
- Result states never rely on color alone: feedback banners pair icon + text.
- Stable accessibility identifiers for every interactive element live in `App/AccessibilityID.swift` and are used by UI tests.
