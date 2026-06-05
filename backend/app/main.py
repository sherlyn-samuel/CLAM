from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from uuid import UUID
import uuid
import os
from .database import get_analytics_client, get_cache_client

app = FastAPI(title="CLAM Advanced Analytics Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ch_client = get_analytics_client()
redis_client = get_cache_client()


class GameplayLog(BaseModel):
    session_id: UUID
    user_id: str
    game_type: str
    level: int = Field(..., ge=1)
    is_correct: int = Field(..., ge=0, le=1)
    response_time_ms: int


@app.post("/api/v1/telemetry")
async def log_telemetry(data: GameplayLog):
    try:
        ch_client.insert(
            'clam_db.gameplay_logs',
            [[
                data.session_id, 
                data.user_id, 
                data.game_type, 
                data.level, 
                data.is_correct, 
                data.response_time_ms
            ]],
            column_names=['session_id', 'user_id', 'game_type', 'level', 'is_correct', 'response_time_ms']
        )
        
        redis_key = f"user:{data.user_id}:consecutive_failures"
        if data.is_correct == 0:
            consecutive_fails = redis_client.incr(redis_key)
        else:
            redis_client.set(redis_key, 0)
            consecutive_fails = 0

        query = """
        SELECT 
            groupArray(response_time_ms) as last_times,
            groupArray(is_correct) as last_results
        FROM (
            SELECT response_time_ms, is_correct
            FROM clam_db.gameplay_logs
            WHERE user_id = {user_id:String} AND game_type = {game_type:String}
            ORDER BY timestamp DESC
            LIMIT 5
        )
        """
        result = ch_client.query(query, parameters={
            "user_id": data.user_id,
            "game_type": data.game_type
        })
        
        anomaly_detected = False
        anomaly_reason = "None"
        
        if result.result_rows:
            last_times = result.result_rows[0][0]
            last_results = result.result_rows[0][1]
            
            if len(last_times) >= 4 and all(t < 500 for t in last_times[:4]) and sum(last_results[:4]) == 0:
                anomaly_detected = True
                anomaly_reason = "Rapid Guessing / Input Spamming Detected"
            
            elif consecutive_fails >= 5 and len(last_times) >= 5 and sum(last_times) / len(last_times) > 4000:
                anomaly_detected = True
                anomaly_reason = "Cognitive Fatigue / Extreme Challenge Wall"

        return {
            "status": "success",
            "telemetry_synced": True,
            "metrics_evaluation": {
                "consecutive_failures": consecutive_fails,
                "anomaly_triggered": data.is_correct == 0 and anomaly_detected,
                "profile_flag": anomaly_reason if data.is_correct == 0 else "None"
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/health")
async def health_check():
    return {"status": "healthy", "engine": "FastAPI + ClickHouse + Redis"}