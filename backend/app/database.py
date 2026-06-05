import os
import redis
import clickhouse_connect


redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=6379,
    db=0,
    decode_responses=True
)

# Connect to ClickHouse 
ch_client = clickhouse_connect.get_client(
    host=os.getenv("CLICKHOUSE_HOST", "localhost"),
    port=8123,
    username="default",
    password=""
)

def get_analytics_client():
    return ch_client

def get_cache_client():
    return redis_client