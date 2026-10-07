"""
AWS Glue Python Shell job for transforming WA EV data.

Reads raw CSV from S3, cleans and enriches data, writes partitioned Parquet.
Designed to run as a Glue Python Shell job (0.0625 DPU).
"""

import argparse
import logging
import sys
from datetime import UTC, datetime

import awswrangler as wr
import pandas as pd

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# Column mapping from raw API names to clean names
COLUMN_MAP = {
    "vin_1_10": "vin_prefix",
    "county": "county",
    "city": "city",
    "state": "state",
    "zip_code": "postal_code",
    "model_year": "model_year",
    "make": "make",
    "model": "model",
    "ev_type": "ev_type",
    "cafv_type": "cafv_eligibility",
    "electric_range": "electric_range",
    "base_msrp": "base_msrp",
    "legislative_district": "legislative_district",
    "dol_vehicle_id": "dol_vehicle_id",
    "vehicle_location": "vehicle_location",
    "electric_utility": "electric_utility",
    "census_tract_2020": "census_tract",
}

INTEGER_COLS = ["model_year", "electric_range", "base_msrp"]
STRING_COLS = [
    "vin_prefix",
    "county",
    "city",
    "state",
    "postal_code",
    "make",
    "model",
    "ev_type",
    "cafv_eligibility",
]


def read_raw_data(s3_path: str) -> pd.DataFrame:
    """Read raw CSV from S3 using awswrangler."""
    logger.info(f"Reading raw data from {s3_path}")
    df = wr.s3.read_csv(
        path=s3_path,
        path_suffix=".csv",
        dtype=str,
        keep_default_na=False,
        ignore_empty=True,
        on_bad_lines="skip",
    )

    if df.empty and len(df.columns) == 0:
        raise ValueError(
            f"No CSV data was found at {s3_path}. "
            "Check that the raw path points to the generated ev_data.csv object, not the bucket root or a Python source file."
        )

    df.columns = [str(col).strip().strip('"') for col in df.columns]
    df = df.dropna(axis=1, how="all")
    logger.info(f"Loaded {len(df)} rows, {len(df.columns)} columns")
    return df


def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """Rename, type-cast, and clean the raw dataframe."""
    # Rename columns (handle missing keys gracefully)
    rename_map = {k: v for k, v in COLUMN_MAP.items() if k in df.columns}
    df = df.rename(columns=rename_map)

    required_cols = {"model_year", "county", "ev_type", "make", "model"}
    missing = sorted(required_cols - set(df.columns))
    if missing:
        raise ValueError(
            f"Raw CSV schema mismatch. Missing required columns: {missing}. "
            f"Loaded columns: {list(df.columns[:20])}. "
            "This usually means the read path is pointing at the wrong S3 object or a non-data file."
        )

    # Ensure expected columns exist
    for col in STRING_COLS:
        if col not in df.columns:
            df[col] = ""
        df[col] = df[col].astype(str).replace({"": None, "nan": None, "NaN": None})

    for col in INTEGER_COLS:
        if col not in df.columns:
            df[col] = pd.NA
        df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")

    # Derive is_bev flag
    df["is_bev"] = df["ev_type"].str.contains(
        "Battery Electric Vehicle", case=False, na=False
    )

    # Calculate vehicle age (current year - model year)
    current_year = datetime.now(UTC).year
    df["vehicle_age"] = current_year - df["model_year"]
    df["vehicle_age"] = df["vehicle_age"].where(df["vehicle_age"] >= 0, pd.NA)

    # Standardize CAFV eligibility
    df["cafv_eligibility_clean"] = df["cafv_eligibility"].apply(
        lambda x: (
            "Eligible"
            if isinstance(x, str) and "eligible" in x.lower() and "not" not in x.lower()
            else (
                "Not Eligible"
                if isinstance(x, str) and "not eligible" in x.lower()
                else "Unknown"
            )
        )
    )

    # Drop rows with no model_year or county (critical partition columns)
    before = len(df)
    df = df.dropna(subset=["model_year", "county"])
    after = len(df)
    if before != after:
        logger.warning(
            f"Dropped {before - after} rows with missing model_year or county"
        )

    # Fill remaining nulls for safe Parquet writing
    df["make"] = df["make"].fillna("Unknown")
    df["model"] = df["model"].fillna("Unknown")
    df["ev_type"] = df["ev_type"].fillna("Unknown")

    logger.info(f"Cleaned dataframe: {len(df)} rows, columns: {list(df.columns)}")
    return df


def write_curated_data(
    df: pd.DataFrame, s3_path: str, database: str, table: str
) -> None:
    """Write curated data as partitioned Parquet and update Glue Catalog."""
    logger.info(f"Writing curated data to {s3_path}")

    # Ensure partition columns are strings for consistent paths
    df["model_year"] = df["model_year"].astype(str)
    df["county"] = df["county"].astype(str)

    wr.s3.to_parquet(
        df=df,
        path=s3_path,
        dataset=True,
        database=database,
        table=table,
        partition_cols=["model_year", "county"],
        mode="append",
        compression="snappy",
        boto3_session=None,
    )
    logger.info("Write complete")


def main() -> None:
    parser = argparse.ArgumentParser(description="Transform WA EV data in Glue")
    parser.add_argument("--raw-path", required=True, help="S3 path to raw CSV data")
    parser.add_argument(
        "--curated-path", required=True, help="S3 path for curated output"
    )
    parser.add_argument("--database", default="wa_ev_db", help="Glue catalog database")
    parser.add_argument("--table", default="curated_ev_data", help="Glue catalog table")
    args = parser.parse_args()

    df = read_raw_data(args.raw_path)
    df = clean_dataframe(df)
    write_curated_data(df, args.curated_path, args.database, args.table)
    print("SUCCESS")


if __name__ == "__main__":
    main()
