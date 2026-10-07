"""
Washington EV Population Data Ingestion Script.

Fetches data from data.wa.gov SODA API and uploads to S3.
Can run locally or inside an ECS Fargate task.
"""

import argparse
import csv
import io
import json
import logging
import os
import sys
import time
import traceback
from datetime import UTC, datetime
from typing import Any

import boto3
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

API_ENDPOINT = "https://data.wa.gov/resource/f6w7-q2d2.json"
APP_TOKEN = os.environ.get("WADATA_APP_TOKEN", "")
DEFAULT_LIMIT = 10000  # Reduced from 50000 for reliability
MAX_RETRIES = 5
REQUEST_TIMEOUT = 180  # Increased from 120


def _create_session() -> requests.Session:
    """Create a requests session with retry logic."""
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        backoff_factor=2,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "OPTIONS"],
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def fetch_page(
    session: requests.Session,
    offset: int,
    limit: int,
    max_retries: int = MAX_RETRIES,
) -> list[dict]:
    """Fetch a single page from the SODA API with manual retry logic."""
    headers = {}
    if APP_TOKEN:
        headers["X-App-Token"] = APP_TOKEN

    params = {
        "$limit": limit,
        "$offset": offset,
        "$order": ":id",
    }

    for attempt in range(1, max_retries + 1):
        logger.info(
            f"Fetching offset={offset}, limit={limit} (attempt {attempt}/{max_retries})"
        )
        try:
            response = session.get(
                API_ENDPOINT,
                headers=headers,
                params=params,
                timeout=REQUEST_TIMEOUT,
            )
            response.raise_for_status()

            try:
                records = response.json()
            except json.JSONDecodeError as exc:
                logger.error(
                    f"Failed to decode JSON: {exc}. Response text: {response.text[:500]}"
                )
                if attempt == max_retries:
                    raise
                time.sleep(2**attempt)
                continue

            logger.info(f"Retrieved {len(records)} records")
            return records

        except requests.exceptions.Timeout as exc:
            logger.warning(f"Request timed out: {exc}")
            if attempt == max_retries:
                logger.error("Max retries exceeded for timeout")
                raise
            wait_time = 2**attempt
            logger.info(f"Retrying in {wait_time}s...")
            time.sleep(wait_time)

        except requests.exceptions.HTTPError as exc:
            logger.warning(f"HTTP error: {exc} (status: {exc.response.status_code})")
            if exc.response.status_code == 404:
                logger.error("Dataset not found (404)")
                raise
            if attempt == max_retries:
                logger.error("Max retries exceeded for HTTP error")
                raise
            wait_time = 2**attempt
            logger.info(f"Retrying in {wait_time}s...")
            time.sleep(wait_time)

        except requests.exceptions.RequestException as exc:
            logger.error(f"Request failed: {exc}")
            if attempt == max_retries:
                logger.error("Max retries exceeded")
                raise
            wait_time = 2**attempt
            logger.info(f"Retrying in {wait_time}s...")
            time.sleep(wait_time)

    return []


def fetch_ev_data(
    limit: int = DEFAULT_LIMIT,
    offset: int = 0,
    max_records: int | None = None,
) -> list[dict]:
    """Fetch EV data from SODA API with pagination and retries."""
    session = _create_session()
    all_records = []
    current_offset = offset

    while True:
        try:
            records = fetch_page(session, current_offset, limit)
        except (
            requests.exceptions.RequestException,
            ValueError,
            TypeError,
            RuntimeError,
        ) as exc:
            logger.error(f"Fatal error fetching page at offset {current_offset}: {exc}")
            logger.error(traceback.format_exc())
            raise

        if not records:
            break

        all_records.extend(records)
        logger.info(f"Total records so far: {len(all_records)}")

        if max_records and len(all_records) >= max_records:
            all_records = all_records[:max_records]
            logger.info(f"Reached max_records limit ({max_records})")
            break

        if len(records) < limit:
            break

        current_offset += limit

    logger.info(f"Total records fetched: {len(all_records)}")
    return all_records


def upload_to_s3(
    records: list[dict],
    bucket: str,
    prefix: str = "",
    s3_client: Any | None = None,
) -> str:
    """Serialize records to CSV and upload to S3."""
    if not records:
        raise ValueError("No records to upload")

    if s3_client is None:
        s3_client = boto3.client("s3")

    today = datetime.now(UTC).strftime("%Y-%m-%d")
    key = (
        f"{prefix}ingest_date={today}/ev_data.csv"
        if prefix
        else f"ingest_date={today}/ev_data.csv"
    )

    # Normalize records to ensure all rows have same columns
    all_keys = set()
    for r in records:
        all_keys.update(r.keys())
    fieldnames = sorted(all_keys)

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(records)

    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=output.getvalue().encode("utf-8"),
        ContentType="text/csv",
    )

    s3_uri = f"s3://{bucket}/{key}"
    logger.info(f"Uploaded {len(records)} records to {s3_uri}")
    return s3_uri


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingest WA EV data to S3")
    parser.add_argument("--bucket", required=True, help="S3 bucket name for raw data")
    parser.add_argument("--prefix", default="", help="S3 key prefix")
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="API page size (default: 10000)",
    )
    parser.add_argument(
        "--max-records",
        type=int,
        default=None,
        help="Max total records to fetch (for testing)",
    )
    args = parser.parse_args()

    try:
        records = fetch_ev_data(limit=args.limit, max_records=args.max_records)
        s3_uri = upload_to_s3(records, bucket=args.bucket, prefix=args.prefix)
        print(f"SUCCESS:{s3_uri}")
    except (
        ValueError,
        OSError,
        requests.exceptions.RequestException,
        RuntimeError,
    ) as exc:
        logger.error(f"Pipeline failed: {exc}")
        logger.error(traceback.format_exc())
        sys.exit(1)


if __name__ == "__main__":
    main()
