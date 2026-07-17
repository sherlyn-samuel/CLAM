# CLAM: An Open-Source Testbed for Longitudinal Knowledge Tracing in Primary Mathematics

## Project Description
CLAM is a research-grade infrastructure designed to capture high-granularity learner interaction data. Unlike commercial learning apps, CLAM is built as a **Research Testbed** to host controlled experiments in cognitive load, misconception detection, and knowledge tracing. It provides a structured environment where learning interventions can be deployed, measured, and analyzed through a standardized telemetry pipeline.

## Core Research Objectives
* **Longitudinal Cognitive Modeling:** To track learner progression over time using standardized item parameters.
* **Misconception Identification:** To map specific student response patterns (distractor selection) to documented mathematical misconceptions.
* **Algorithmic Transparency:** To compare black-box Deep Learning models (e.g., LSTMs) against interpretable psychometric models (e.g., IRT) in real-world educational settings.

## System Architecture & Instrumentation
* **Data Collection (The "Instrument"):** Every interaction is logged with precise metadata: `timestamp`, `concept_id` (Bloom’s Taxonomy), `difficulty_parameter`, `response_latency` (ms), and `distractor_id`.
* **Telemetry Pipeline:** FastAPI backend ensures atomic logging to ClickHouse, optimized for high-frequency time-series educational data.
* **Evaluation Baseline:** The ML module is designed to support A/B testing between models, with built-in evaluation scripts that calculate RMSE and AUC against standard IRT baselines.

## Research Design Document (RDD)
*Keep this document alongside your code. It justifies your design decisions to any PI or reviewer.*

| Component | Scientific Purpose | Measurement/Variable |
| :--- | :--- | :--- |
| **Question Bank** | Standardized Item Calibration | Difficulty ($b$), Discrimination ($a$) |
| **Quiz Loop** | Cognitive Load Manipulation | Latency (ms), Error rate |
| **Telemetry** | Longitudinal Trajectory | Response History ($x_{1}, x_{2}, \dots, x_{t}$) |
| **DKT Engine** | Ability Estimation | Predicted Probability ($p$) |

## 4-Step Implementation Roadmap
1. **Define the Ontology (The "What"):** Before coding, create a JSON schema for your questions that includes `concept_tags` (e.g., "fractions-addition") and `misconception_tags` (e.g., "common-error-denominator-addition"). Your app should be able to query questions based on these tags.
2. **Standardize the Data Dictionary:** Ensure every database column has a formal definition. *Example:* `response_time_ms` is defined as the interval between "question render" and "user click event."
3. **Implement IRT Baselines:** Do not rely solely on the LSTM. Refactor your `ml/` folder to include a script that runs a 1-Parameter Logistic (Rasch) Model on your data. This is your "sanity check"—if your Deep Learning model doesn't beat the baseline, it isn't ready for a publication.
4. **Formalize Documentation:** Adopt a consistent README format that lists your contact info, data usage agreement (or license), and version history. This makes the testbed usable by other researchers.

---
*Maintained as an Open-Source Testbed for Educational Informatics.*