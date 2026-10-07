"""
Local Airflow DAG for Washington EV Pipeline.

Runs ingestion locally; on AWS this is replaced by Step Functions.
Schedule: Monthly on the 1st at 08:00 UTC.
"""

import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

S3_RAW_BUCKET = os.environ.get("S3_RAW_BUCKET", "wa-ev-raw-data")
S3_CURATED_BUCKET = os.environ.get("S3_CURATED_BUCKET", "wa-ev-curated-data")

# For quick testing, set WA_EV_MAX_RECORDS env var (e.g., 1000)
MAX_RECORDS = os.environ.get("WA_EV_MAX_RECORDS", "")
MAX_RECORDS_ARG = f" --max-records {MAX_RECORDS}" if MAX_RECORDS else ""

INGESTION_CMD = (
    f"python /opt/airflow/src/ingestion/fetch_ev_data.py"
    f" --bucket {S3_RAW_BUCKET}"
    f"{MAX_RECORDS_ARG}"
)

with DAG(
    dag_id="wa_ev_pipeline",
    default_args=DEFAULT_ARGS,
    description="Washington EV Population Data Pipeline (Local)",
    schedule_interval="0 8 1 * *",  # Monthly on 1st at 08:00 UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["wa_ev", "ingestion", "batch"],
) as dag:

    ingestion_task = BashOperator(
        task_id="ingest_ev_data",
        bash_command=INGESTION_CMD,
    )

    # Local placeholder for transformation
    # In AWS, Step Functions triggers the ECS transform task directly
    transform_task = BashOperator(
        task_id="transform_ev_data",
        bash_command=(
            f"python /opt/airflow/src/transform/glue_ev_transform.py"
            f" --raw-path s3://{S3_RAW_BUCKET}/"
            f" --curated-path s3://{S3_CURATED_BUCKET}/"
            f" --database wa_ev_db"
            f" --table curated_ev_data"
        ),
    )

    ingestion_task >> transform_task
