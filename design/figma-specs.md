# UmbraRo Figma Specs

## Purpose

This file contains implementation notes from the Figma screens.

Use this file to reduce guessing when recreating the UI in Flutter.

If a dimension is known from Figma, use it.
If not, match the visual hierarchy and spacing as closely as possible.

---

## 1. Global Visual Rules

- Background is deep midnight blue.
- Accent color is muted gold.
- Text is soft off-white.
- Negative metrics use flat terracotta.
- Cards and modules use sharp corners only.
- No gradients.
- No glow.
- No drop shadows.
- Depth comes from tonal layering only.

---

## 2. Layout Rules

- Use strong vertical spacing between major sections.
- Keep long-form text left-aligned.
- Use oversized hero metrics.
- Use all-caps for section labels where appropriate.
- Bottom navigation stays compact and fixed.
- Prefer large hero zones followed by structured modules.

---

## 3. Dashboard Notes

Observed design patterns:
- oversized probability ring / hero metric
- fixture name centered and dominant
- compact competition + venue line
- key drivers shown as structured rows
- fixture cards stacked vertically
- quick metrics near the bottom
- bottom nav fixed

Implementation guidance:
- keep the hero section visually dominant
- preserve negative space around the probability display
- use gold sparingly for emphasis
- keep cards flat and rectilinear

---

## 4. Standings Notes

Observed design patterns:
- oversized editorial title
- tab-like filters near the top
- clean table layout
- highlighted team row
- summary cards below standings
- fixed bottom nav

Implementation guidance:
- make the highlighted row visually distinct using tonal layering, not shadow
- preserve the strong table rhythm
- keep headers compact and uppercase

---

## 5. Match Intelligence Notes

Observed design patterns:
- fixture header with large typography
- baseline vs optimized probability comparison
- horizontal progress / probability emphasis
- tactical blueprint in a grid-like card layout
- diagnosis box with concise insight
- bold action buttons near bottom

Implementation guidance:
- make uplift easy to scan
- preserve hierarchy between baseline and optimized states
- keep tactical targets compact and clear

---

## 6. Chat Notes

Observed design patterns:
- looks like a tactical command interface, not a social chat
- large title area
- timestamped messages
- message rhythm is professional and sparse
- input area is flat and sharp-edged

Implementation guidance:
- avoid chat bubbles if they make it look casual
- keep spacing disciplined
- preserve staff-room / command-channel tone

---

## 7. Analytics Notes

Observed design patterns:
- oversized probability / performance metrics
- trend lines and compact summaries
- recommendation card
- large summary numbers
- dense but controlled layout

Implementation guidance:
- maintain strong contrast between hero metrics and body labels
- use modules to chunk analytics clearly
- do not overload with decorative elements

---

## 8. Team Notes

Observed design patterns:
- large season summary hero
- player / squad blocks stacked vertically
- status labels and load indicators
- strong CTA card near bottom

Implementation guidance:
- if real backend support is missing, keep this screen as a visual placeholder or limited summary
- do not invent fake player science

---

## 9. Export Instructions

For each Figma screen, export:
- one full-frame PNG at 2x or 3x
- optional cropped images for major sections:
  - header
  - hero
  - key cards
  - bottom nav

Store them under:
`design/figma_exports/`

Example:
- design/figma_exports/dashboard.png
- design/figma_exports/standings.png
- design/figma_exports/chat.png

---

## 10. Source Priority

When exact values are available from Figma, prefer them.
When exact values are not available, match:
1. hierarchy
2. spacing rhythm
3. typography scale
4. tonal layering
5. geometry