# UmbraRo Screen Map

## 1. Dashboard / Home

### Purpose
Provide the main tactical overview for the next fixture.

### Key Content
- hero win probability
- fixture identity
- competition and venue
- key drivers
- recent / next / upcoming fixtures
- quick metrics
- trend or standings snapshot

### Typical UI Language
- win probability
- key drivers
- fixture analysis
- squad load
- efficiency

---

## 2. Standings

### Purpose
Show the league table in a premium editorial format.

### Key Content
- ranked table
- highlighted club row
- points
- played
- wins / draws / losses
- goal difference
- contextual summary cards

### Typical UI Language
- league standings
- points to top
- goal differential efficiency
- form

---

## 3. Match Intelligence

### Purpose
Show detailed pre-match intelligence.

### Key Content
- baseline probability
- AI-optimized probability
- uplift
- fixture metadata
- tactical target summary
- recommendation actions

### Typical UI Language
- win probability optimization
- tactical blueprint
- tactical diagnosis
- generate detailed brief
- full AI simulation

---

## 4. Tactical Blueprint

### Purpose
Show the optimizer’s recommended target tactical profile.

### Key Content
- exact target values
- probability uplift
- compact diagnosis
- optional rationale

### Supported Target Fields
- possession
- shots
- shots on target
- corners
- goals
- conceded

---

## 5. Analytics

### Purpose
Show key analytical interpretation and tactical trend context.

### Key Content
- key drivers
- top risks
- form trends
- active recommendation
- tactical summary

### Typical UI Language
- active recommendation
- tactical form
- xG delta
- pass chain
- vertical index
- recovery phase

Note: if a metric is shown in UI but not yet backed by the real backend, mark it clearly as placeholder or remove it until supported.

---

## 6. Command Chat

### Purpose
Provide a staff-facing tactical communication interface.

### Key Content
- tactical conversation
- staff-like message flow
- file / brief attachment support
- tactical prompt entry

### Typical Prompt Types
- explain win probability
- generate tactical brief
- summarize key drivers
- explain uplift
- summarize rest-day impact

### Tone
- direct
- concise
- professional
- operational

---

## 7. Team / Squad

### Purpose
Provide squad-facing summary information where appropriate.

### Constraint
Do not invent unsupported player-level backend data.

If shown, team/squad screens must remain visually aligned with the design system but honest about current backend support.

---

## 8. Global Navigation

Bottom navigation should support:
- Dashboard
- Standings
- Chat
- Analytics
- Team

Navigation labels should remain concise and premium.