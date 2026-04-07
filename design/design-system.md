# Design System: Modern Athletic Heritage & Data Minimalism

## 1. Overview & Creative North Star
The Creative North Star for this system is **"The Stoic Analyst."** This is a high-performance environment designed for elite football coaching, where the prestige of heritage meets the cold precision of modern biometrics. 

To break away from "template" app design, this system rejects rounded corners and soft glows in favor of **Brutalist Precision**. We use intentional asymmetry and extreme typographic scale—placing massive, condensed data points against expansive negative space—to create an editorial feel that mimics high-end athletic journals. The interface should feel like a custom-machined tool: sharp, utilitarian, and expensive.

## 2. Colors & Surface Architecture
The palette is rooted in the deep shadows of the stadium tunnel, punctuated by the "Trophy Gold" of championship legacy.

### Color Tokens
*   **Surface (Background):** `#00132e` (Deep Midnight Blue)
*   **Primary (Accent):** `#f2ca50` (Muted Gold)
*   **On-Surface (Primary Text):** `#d6e3ff` (Soft Off-White)
*   **Tertiary (Negative Data):** `#ffbfb2` (Flat Terracotta)
*   **Success (Positive Data):** Subdued Green (Derived from `primary-fixed-dim` logic)

### The Layering Principle (Depth without Shadows)
We prohibit the use of elevation shadows or glows. Depth is achieved strictly through **Tonal Layering**.
*   **Base Layer:** `surface` (#00132e).
*   **Secondary Sections:** Use `surface_container_low` (#001b3d) to define large content areas.
*   **High-Priority Data Cards:** Use `surface_container_high` (#122a4c) to create a "lifted" effect through color contrast alone.
*   **The "No-Line" Rule:** Do not use borders to define containers. A change in the surface token is the only permissible way to denote a new section.

## 3. Typography
The typographic system relies on the tension between the aggressive, condensed energy of the pitch and the neutral clarity of the tactics board.

*   **Display & Headline (Epilogue/Athletic Sans):** Used for massive data points (e.g., Win %) and section headers. These should be set in All-Caps with tight tracking (-2% to -5%) to evoke a sense of "Modern Athletic Heritage."
*   **Body & Labels (Inter):** Used for all instructional text, player names, and descriptions. Inter provides the "Whoop-style" utility, ensuring that even dense tactical data remains legible.
*   **Scale Contrast:** To achieve an editorial look, a Headline-LG (2rem) should often sit immediately adjacent to a Label-SM (0.6875rem). This high-contrast pairing eliminates the "mid-tier" visual clutter common in generic apps.

## 4. Elevation & Precision
In this system, "Elevation" is a misnomer. We utilize **Planar Precision**.

*   **Sharp Edges Only:** Every component—from buttons to cards—must use a `0px` border radius. This communicates military-grade discipline.
*   **The 1px Hairline:** While sectioning is done via color shifts, internal list items (e.g., a roster of 22 players) may use a `1px` hairline divider using the `outline_variant` (#4d4635) at 30% opacity. It should feel like a surgical incision, not a structural wall.
*   **Negative Space as a Component:** Treat white space as a functional element. "Data Minimalism" requires that for every dense cluster of statistics, there is an equivalent "breathing zone" of pure `surface` color to prevent cognitive overload.

## 5. Components

### Buttons
*   **Primary:** Solid `primary_container` (#d4af37) with `on_primary` text. No rounded corners. Text is All-Caps Inter Bold.
*   **Secondary:** Ghost style. No background. `1px` border using `outline`.
*   **Tertiary:** Text-only. Muted Gold, underlined with a 1px offset.

### Data Chips (Pill-Shaped)
The *only* exception to the sharp-edge rule. Tags for player positions (e.g., "CDM", "ST") or status must be fully pill-shaped. This provides a "tactical magnet" feel, as if these elements can be moved across a whiteboard. Use `surface_variant` with `on_surface_variant` text.

### Statistics & Performance Metrics
*   **Growth (+):** Subdued Green text, no icons. Use `body-lg` for the value.
*   **Decline (-):** `tertiary` (#ffbfb2). 
*   **The Hero Metric:** Large-scale `display-lg` numbers. These should be the largest element on the screen, often pushed to the far left or right to create asymmetrical tension.

### Inputs & Forms
*   **Fields:** Flat `surface_container_lowest`. No borders on three sides; only a bottom `1px` hairline in `outline_variant`.
*   **Focus State:** The bottom hairline transitions to `primary` (Muted Gold).

## 6. Do’s and Don’ts

### Do
*   **Do** use extreme vertical margins (using spacing `16` or `20`) to separate distinct data modules.
*   **Do** use "Ghost Borders" (low-opacity `outline_variant`) for accessibility only when tonal shifts are insufficient.
*   **Do** keep all icons (if used) strictly 1px stroke weight, sharp corners, no fills.

### Don't
*   **Don't** use border-radius, even for "softness." This app is about the rigors of professional football.
*   **Don't** use gradients, glows, or drop shadows. These are "consumer" tropes; this system is a professional tool.
*   **Don't** center-align long-form data. Use left-aligned "Editorial" grids to maintain a high-end feel.