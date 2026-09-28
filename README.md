# 🦪 CLAM (Continuous Learning Analytics & Modeling)

A research-oriented backend testbed for educational informatics. CLAM is designed to handle high-throughput telemetry logging, detect student misconceptions in real-time, and run dynamic student knowledge modeling. It serves as the analytical engine for interactive learning environments.

## Core Features

* **Deep Knowledge Tracing (DKT):** A PyTorch-based neural student modeling pipeline that evaluates concept mastery probabilities and models individual learning trajectories over time.
* **Telemetry & Interaction Logging:** A high-throughput data ingestion pipeline capturing continuous user interactions, tracking response latency, and identifying behavioral anomalies like rapid guessing or cognitive fatigue.
* **Misconception Detection:** Rule-based engine that maps incorrect student responses against a predefined taxonomy of common misconceptions.
* **Automated Content Generation:** FastAPI-driven integration with the Gemini API for adaptive question synthesis and dynamic content scaling.

## Architecture & Tech Stack

* **Backend API Framework:** Python & FastAPI
* **Server:** Uvicorn (ASGI web server)
* **Machine Learning Engine:** PyTorch (Sequence modeling and DKT implementation)
* **LLM Engine:** Gemini API 
* **Data & Telemetry Layer:** ClickHouse (Optimized columnar database for high-volume, time-series interaction logging and rapid analytical queries)

## Project Structure

```text
CLAM/
├── api/
│   ├── routes_telemetry.py   # Ingestion endpoints for interaction logs
│   ├── routes_dkt.py         # Endpoints for mastery prediction
│   └── routes_generation.py  # Gemini LLM integration for questions
├── core/
│   ├── clickhouse_client.py  # Database connection and query execution
│   └── misconception_map.py  # Rule engine for error state mapping
├── models/
│   ├── dkt_model.py          # PyTorch LSTM architecture for knowledge tracing
│   └── train.py              # Training script for the DKT model
├── requirements.txt
├── main.py                   # FastAPI application entry point
└── README.md

## System Setup

### Prerequisites
* Python 3.10+
* ClickHouse Instance (running locally or via Docker)

### Installation & Execution

1. **Clone the repository and set up the virtual environment:**
   ```bash
   git clone [https://github.com/sherlyn-samuel/CLAM.git](https://github.com/sherlyn-samuel/CLAM.git)
   cd CLAM
   python -m venv venv
   source venv/bin/activate  # On Windows use: venv\Scripts\activate

## Research Context
This repository is a work in progress
