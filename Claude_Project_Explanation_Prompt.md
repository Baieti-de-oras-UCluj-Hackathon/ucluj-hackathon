# Claude Prompt: Full Project Explanation (UmbraRo)

You are a senior software architect and technical writer.  
I want a full, accurate, project-level explanation of this codebase for a stakeholder handoff.

## Project to analyze

UmbraRo (Flutter + FastAPI + Firebase hybrid migration)

## What I need from you

Give me a detailed but structured report that explains:

1. **Project purpose**
   - What problem it solves
   - Target users
   - Product scope and non-goals
   - Why this architecture exists

2. **Current system behavior (as-is, today)**
   - What works right now end-to-end
   - What is partially implemented
   - What is disabled or blocked
   - Runtime modes (legacy vs Firebase mode)

3. **Architecture overview**
   - Frontend (Flutter) responsibilities
   - Backend (FastAPI) responsibilities
   - Firebase responsibilities (Auth + Firestore)
   - Data/control flow between all components

4. **Authentication/session flow**
   - Legacy flow
   - Firebase flow
   - Token exchange logic
   - Session restore behavior
   - Logout behavior
   - Failure cases and fallbacks

5. **Data model and persistence**
   - What is stored locally
   - What is stored in Firestore
   - What remains backend source-of-truth
   - Any migration/backfill logic

6. **Security posture**
   - Firestore rules interpretation
   - Backend token verification model
   - Secret handling
   - Known risks (if any)

7. **Environment and deployment model**
   - How local run works
   - Env vars and `dart-define` flags
   - Dev/staging/prod separation strategy
   - What is still manual

8. **Testing and quality**
   - Existing tests and what they cover
   - Missing test coverage
   - Key technical debt

9. **Operational status**
   - What commands are used to run backend/app
   - Typical local URLs/ports
   - Common failure modes and quick diagnostics

10. **Roadmap / next steps**
    - Immediate next tasks (short-term)
    - Hardening tasks (medium-term)
    - Production-readiness checklist

## Output format

- Start with a 10-bullet executive summary
- Then provide sections `## 1 ... ## 10` matching the list above
- Include concrete file/path references where relevant
- Be explicit about assumptions vs confirmed facts
- End with:
  - Top 5 risks right now
  - Top 5 highest-impact next actions

## Important constraints

- Do not invent capabilities not present in the code.
- Keep ML framing accurate: backend remains source of truth.
- Keep target framing accurate: binary Home Win vs Not Home Win.
- Be precise and technical, not marketing-style.

