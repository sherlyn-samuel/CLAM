# CLAM

**A hand-illustrated maths game that doubles as a research instrument for studying learner data in primary mathematics.**

*CGCLMA: Competitive Gaming for Children's Learning through Mathematical Application*

Every answer a child gives is logged with the context needed to model what they know, and to ask how the game itself shapes the way they answer.

---

## Why this exists

Knowledge-tracing models generally treat logged responses as a signal of what a learner knows. In a game, responses can also reflect game design: timers, scoring, competition. CLAM is built to make that difference measurable. It combines a child-facing maths game with a structured logging pipeline, so learner models and interface design can be studied on the same data.

CLAM is a **research testbed**, not a commercial learning app. Its job is to produce clean, well-described interaction data and to host experiments on top of it.

## What it does

- **Game-based maths quiz** for children, with **original hand-drawn artwork**.
- **High-granularity interaction logging** for every question attempt (see [Telemetry](#telemetry)).
- **Misconception detection (rule-based):** wrong answers can be mapped to documented misconceptions through the chosen distractor.
- **Anonymized, session-based tracking.**
- **Response-latency capture** for every attempt.
- **Knowledge-tracing pipeline (in development):** an LSTM-based Deep Knowledge Tracing model in PyTorch.

## Telemetry

Each interaction is stored with:

| Field | Meaning |
| --- | --- |
| `timestamp` | When the attempt happened |
| `concept_id` | The concept the question targets |
| `difficulty_parameter` | The difficulty value assigned to the item |
| `response_latency` | Time taken to answer, in milliseconds |
| `distractor_id` | Which answer option was chosen, enabling wrong answers to be tied to specific misconceptions |

Responses are grouped by anonymized session so that a learner's trajectory can be reconstructed over time without personal identifiers.

## Architecture

```
Flutter client  ──►  FastAPI backend  ──►  ClickHouse
 (game + quiz)       (logging API)        (time-series storage)
                                               │
                                               ▼
                                   ML module (PyTorch)
                              knowledge tracing + evaluation
```

[TODO: confirm how the ML module reads data from ClickHouse, then adjust the diagram if needed.]

## Design rationale

| Component | Scientific purpose | Variables recorded |
| --- | --- | --- |
| Question bank | Items with known, comparable difficulty | Difficulty parameter, concept |
| Quiz loop | Repeated attempts in a game context | Response latency, correctness, distractor chosen |
| Telemetry | Longitudinal learner trajectories | Ordered response history per session |
| Knowledge-tracing module | Estimating what a learner knows over time | Predicted probability of a correct response |

Response latency is treated as a **behavioural proxy** (for example for hesitation or rapid guessing), not as a direct measure of cognitive load.

## Research directions

These are the questions the testbed is designed to support. They are not yet answered.

1. **Does game design change response behaviour?** For example, do timed or competitive elements change latency and guessing patterns compared with a non-gamified version?
2. **Do behavioural and distractor features improve prediction?** Compare knowledge-tracing models with and without latency and misconception information.
3. **Black-box versus interpretable models.** Compare an LSTM-based model against interpretable psychometric baselines such as IRT.
4. **From model output to teaching decisions.** Explore whether results can tell a teacher which misconceptions to address or which game items to revise.

## Current status

| Component | Status |
| --- | --- |
| Flutter client with hand-drawn game art | Implemented [TODO: confirm] |
| Telemetry logging (FastAPI to ClickHouse) | Implemented |
| Anonymized session tracking and latency capture | Implemented |
| Rule-based misconception detection | Implemented |
| LSTM-based DKT model (PyTorch) | In development |
| IRT baseline and RMSE/AUC evaluation scripts | Planned [TODO: update if already started] |
| Gamified vs. non-gamified comparison study | Planned |
| Competitive / multiplayer features | [TODO: state exactly what exists] |

## Data and ethics

[TODO: state this plainly. For example: whether any data collected so far is development/test data only or comes from real learners, and, if children participate, what ethics approval and parental consent are in place. Do not leave this vague.]

## Repository layout

```
ML/              Knowledge-tracing models and evaluation
backend/         FastAPI logging service
frontend/        Flutter client
android/         Android build configuration
assets/images/   Hand-drawn game artwork
```

[TODO: check descriptions against the actual contents of each folder.]

## Getting started

[TODO: add exact setup and run steps for the backend, database, and client, and verify them on a clean machine.]

## Limitations

- Knowledge tracing needs substantial longitudinal data; results will only be as strong as the data collected.
- Latency and distractor choice are indirect signals and need validation.
- Findings from one game design may not generalise to others.

## Credits

- **Design, development, and hand-drawn game artwork:** Sherlyn Samuel
- Portfolio: [sherlyn-samuel.github.io](https://sherlyn-samuel.github.io)

## License

[TODO: choose a license, including for the artwork, and add a LICENSE file.]
