---
name: carousel-design-system
description: Use when the user asks for a carousel, multi-slide social post, swipe post, or "slides" for Instagram/LinkedIn/TikTok/Threads/Pinterest — instead of designing each slide as a one-off, this skill builds a small reusable graphic system (grid, type scale, color tokens, slide archetypes, continuity motif) first, then generates every slide from it. Trigger on phrases like "carousel", "swipe post", "slide deck for Instagram", "make it look like a system/on-brand across slides", or when a user complains that generated slides "don't feel like one thing."
---

# Carousel Design System

## The problem this skill solves

Asked for a carousel, the lazy path is: generate slide 1 as a nice standalone graphic, generate slide 2 as another nice standalone graphic, repeat. Each slide looks fine in isolation and the set looks like six different designers made it — inconsistent margins, drifting type sizes, a different accent color per slide, no visual signal that swiping continues "the same thing."

**A carousel is one artifact with N views, not N artifacts.** The fix is to design the *system* before touching slide content: fixed grid, fixed type scale, fixed color tokens, a small set of slide archetypes (skeletons), and one continuity motif that repeats on every slide. Every slide is then an instance of a template with content swapped in — never a fresh design decision.

Do this even for a 4-slide carousel. The overhead is the same five decisions whether there are 4 slides or 12; skipping it is what produces the "six different designers" result.

## Workflow

### Step 1 — Lock the brief before designing anything

Get (or infer and confirm in one line, don't interrogate the user):

- **Platform + aspect ratio**: Instagram/LinkedIn feed carousel → 4:5 (1080×1350) or 1:1 (1080×1080); Stories/Reels-style → 9:16. The ratio decides how much vertical room text has — pick it before the type scale.
- **Slide count and arc**: hook → 3-6 content beats → CTA/closing is the default arc. Count the beats in the user's content; don't pad or cram to hit a round number.
- **Voice**: one adjective pair (e.g. "bold/editorial" vs "calm/technical") is enough to drive type and color choices below.
- **Existing brand constraints**: logo, brand colors/fonts to reuse. If none given, you are choosing the system, not the user — say so in one line rather than asking.

### Step 2 — Define the tokens (write these down explicitly, don't wing it slide-by-slide)

**Grid**: one margin value on all four edges, one baseline/column count. Every slide obeys it — nothing ever touches the edge except intentional full-bleed imagery.

**Safe zone**: platform UI (profile row, caption, like/comment bar) covers the top ~12% and bottom ~20% of a feed carousel. Keep the slide's hook line and any CTA button inside the safe zone, not flush against the true edge.

**Type scale** — exactly three or four sizes, reused on every slide, never picked ad hoc per slide:

| Role | Example | Used for |
|---|---|---|
| Display | 64–96px, tightest tracking | Cover hook, single big number/stat |
| Heading | 36–48px | Per-slide title |
| Body | 20–28px | Supporting sentence, list items |
| Caption/eyebrow | 14–16px, uppercase or muted | Slide label, source, page count |

Pick one display font (personality) and one body font (readability); at most two families total. Fix weights per role (e.g. heading is always semibold, body is always regular) so weight doesn't drift slide to slide.

**Color tokens** — background, foreground/text, one accent, one muted/secondary. Four tokens, reused everywhere. A second background (e.g. inverted slide for the CTA) is allowed but must still draw from the same four values — never introduce a new hue for "just this slide."

**Spacing scale**: one base unit (e.g. 8px) and 3–4 multiples of it for all gaps. If a slide needs a gap, it's one of these four numbers, not a new one.

**Shape language**: one corner radius value, one stroke width for icons/dividers, one shadow style (or none). Applied identically everywhere an icon, card, or button appears.

### Step 3 — Define slide archetypes (the skeletons content slots into)

Don't design each slide's layout freshly. Pick from a small fixed set of archetypes and assign each content beat to one:

1. **Cover/hook** — display-size line, minimal else, states the payoff or the tension. Strongest slide in the set; do this one last so it can be tuned against what the rest actually says.
2. **Content/point** — eyebrow label + heading + short body, one idea per slide.
3. **List/steps** — heading + 3–5 short items, consistent bullet or number treatment.
4. **Stat/quote** — one big display-scale number or short quote, minimal chrome.
5. **Comparison/before-after** — two-column or stacked contrast, same divider style every time it's used.
6. **CTA/closing** — inverted or accent background (still from the token set) + one action line ("Save this", "Follow for more", a link/handle).

Every slide in the carousel must map to one of these — if content doesn't fit an archetype, that's a sign the content beat is unclear, not a reason to invent a one-off layout.

### Step 4 — Build the system once, then generate slides from it

Implement the tokens and archetypes as one reusable template before producing slide 1:

- **Code output** (HTML/CSS artifact, canvas design, SVG): define CSS custom properties for every token in Step 2 (`--color-bg`, `--color-accent`, `--space-1..4`, `--font-display`, etc.) and one class/component per archetype in Step 3. Each slide is then a short content-only diff against a shared base — if you find yourself overriding a token's *value* per slide, stop and fix the token instead.
- **Canva/PPTX output**: build slide 1 fully, then duplicate it for every subsequent slide and edit only text/image content and which elements are hidden — never rebuild a slide's structure from a blank canvas.
- Use the `theme-factory` skill for the token/palette layer if the output is an HTML or slide artifact and a ready theme fits; use `canvas-design` for illustrative/poster-style slides; use Canva MCP tools when the user has a Canva account and wants an editable native file. This skill decides *what the system is*; those handle *rendering* it.

### Step 5 — Continuity motif (the thing that makes it read as one object)

Pick exactly one recurring element that appears, unchanged, on every slide:

- A slide-index indicator (dots, "3/8", or a progress bar) in the same corner every time.
- A consistent corner mark (logo, wordmark, or icon) in the same position and size.
- A repeating background shape/gradient direction that only shifts predictably (e.g. rotates one step per slide).

One motif is enough — more than one competes for attention. Skipping this step is the single most common reason a finished carousel still reads as disconnected slides even when colors and fonts match.

### Step 6 — QA pass before delivering

Check across the whole set at once (view all slides together, not one at a time):

- [ ] Same margins on every slide, no exceptions
- [ ] Only the tokens from Step 2 appear anywhere — no stray color, font size, or spacing value
- [ ] Continuity motif present and unchanged in position/size across all slides
- [ ] Text contrast passes at a glance against every background used (including the inverted CTA slide)
- [ ] Hook (slide 1) and CTA (last slide) are the two strongest slides — spend the extra polish there
- [ ] Nothing important sits in the platform safe zone (top/bottom per Step 1)
- [ ] Reading the slide titles alone, in order, tells a coherent story

If any box fails, fix the token or archetype, not the individual slide — a one-slide patch is exactly the drift this skill exists to prevent.

## Quick contrast

| One-off slides (avoid) | Design system (do this) |
|---|---|
| Pick a nice color per slide | Four fixed color tokens, reused everywhere |
| Size text to "look right" each time | Fixed 3–4 step type scale |
| Freehand layout per slide | Slide is an instance of one of ~6 archetypes |
| Nothing ties the set together | One continuity motif, unchanged, every slide |
| Review slides one at a time | Review the whole set side by side before delivering |
