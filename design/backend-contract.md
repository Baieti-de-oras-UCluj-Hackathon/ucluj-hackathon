# UmbraRo Backend Contract

## 1. Backend Purpose

The backend powers the UmbraRo mobile app by serving:
- baseline win probability
- optimized win probability
- probability uplift
- key drivers
- tactical blueprint targets
- tactical diagnosis summary
- fixture context

## 2. Data Scope

The backend is based on Romanian Superliga match data across multiple seasons.

Supported pre-match feature families:
- computed Elo difference / team strength context
- head-to-head context
- rest days
- 5-match rolling tactical aggregates:
  - possession
  - shots
  - shots on target
  - corners
  - goals scored
  - goals conceded

## 3. Unsupported Features

Do not invent or expose unsupported features such as:
- biometrics
- GPS tracking
- player wearables
- player-level running load
- heart-rate data
- xThreat
- pass networks
- tracking-camera-derived metrics
- fake advanced tactical dimensions

## 4. Target Variable

The target is strictly:

**Binary Classification = Home Win vs Not Home Win**

All product-facing default probabilities refer to the probability of a home win.

Do not redesign this as:
- home / draw / away
- betting odds output
- 3-way probability prediction

## 5. Model Positioning

### Logistic Regression
Use only as:
- interpretable predictive baseline
- benchmark model for pure forecasting discussion

### CatBoost
CatBoost is the final production model.

Reason:
- better handles non-linear tactical interactions
- smoother in optimization loops
- more realistic for prescriptive tactical blueprint generation

## 6. Prescriptive Layer

UmbraRo includes a constrained Monte Carlo optimization layer.

Its job is to:
- generate realistic tactical permutations
- evaluate them using the production model
- preserve football plausibility
- return the best valid tactical blueprint

## 7. Tactical Blueprint Output

A valid tactical blueprint may include:
- baseline probability
- optimized probability
- uplift
- target possession
- target shots
- target shots on target
- target corners
- target goals
- target conceded
- concise tactical diagnosis
- optional rationale summary

## 8. Explanation Layer

Valid explanation sources include:
- Elo difference
- head-to-head context
- rest days
- rolling possession
- rolling shots
- rolling shots on target
- rolling corners
- rolling goals scored
- rolling goals conceded

The backend may expose:
- top positive drivers
- top risks
- comparison versus opponent
- plain-English tactical summary

## 9. Suggested Endpoint Directions

Endpoint names may evolve, but the backend will likely support:
- dashboard data
- fixture detail
- predict
- optimize
- explain
- standings
- chat query

## 10. Non-Negotiables

- Do not expose fantasy outputs that the notebook cannot support.
- Do not invent unsupported fields just to fill the UI.
- Keep all outputs tied to the actual thesis methodology.