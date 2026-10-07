"""
Streamlit Dashboard for Washington EV Population Data.

Connects to Athena to visualize:
1. Categorical distribution: EV Count by Make
2. Temporal distribution: EV Registrations by Model Year
"""

import os

import pandas as pd
import plotly.express as px
import streamlit as st
from pyathena import connect

st.set_page_config(
    page_title="Washington EV Dashboard",
    page_icon="🚗",
    layout="wide",
    initial_sidebar_state="expanded",
)

AWS_REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
S3_STAGING_DIR = os.environ.get("ATHENA_S3_STAGING_DIR", "")
ATHENA_DATABASE = os.environ.get("ATHENA_DATABASE", "wa_ev_db")
ATHENA_TABLE = os.environ.get("ATHENA_TABLE", "curated_ev_data")
ATHENA_WORKGROUP = os.environ.get("ATHENA_WORKGROUP", "primary")
DASHBOARD_EXCEPTIONS = (
    AttributeError,
    OSError,
    TypeError,
    ValueError,
    pd.errors.EmptyDataError,
)

if not S3_STAGING_DIR:
    # Derive from curated bucket if available
    curated = os.environ.get("S3_CURATED_BUCKET", "wa-ev-curated-data")
    S3_STAGING_DIR = f"s3://{curated}/athena-query-results/"


def get_athena_connection():
    """Create Athena connection via PyAthena."""
    return connect(
        region_name=AWS_REGION,
        s3_staging_dir=S3_STAGING_DIR,
        work_group=ATHENA_WORKGROUP,
        schema_name=ATHENA_DATABASE,
    )


@st.cache_data(ttl=3600)
def run_query(query: str) -> pd.DataFrame:
    """Execute Athena query and return DataFrame."""
    conn = get_athena_connection()
    df = pd.read_sql(query, conn)
    return df


def get_ev_count_by_make(limit: int = 20) -> pd.DataFrame:
    query = f"""
    SELECT make, COUNT(*) as ev_count
    FROM {ATHENA_TABLE}
    WHERE make IS NOT NULL AND make != 'Unknown'
    GROUP BY make
    ORDER BY ev_count DESC
    LIMIT {limit}
    """
    return run_query(query)


def get_ev_by_model_year() -> pd.DataFrame:
    query = f"""
    SELECT model_year, COUNT(*) as ev_count
    FROM {ATHENA_TABLE}
    WHERE model_year IS NOT NULL
    GROUP BY model_year
    ORDER BY model_year ASC
    """
    return run_query(query)


def get_top_counties(limit: int = 15) -> pd.DataFrame:
    query = f"""
    SELECT county, COUNT(*) as ev_count
    FROM {ATHENA_TABLE}
    WHERE county IS NOT NULL
    GROUP BY county
    ORDER BY ev_count DESC
    LIMIT {limit}
    """
    return run_query(query)


def get_ev_type_distribution() -> pd.DataFrame:
    query = f"""
    SELECT ev_type, COUNT(*) as ev_count
    FROM {ATHENA_TABLE}
    WHERE ev_type IS NOT NULL
    GROUP BY ev_type
    ORDER BY ev_count DESC
    """
    return run_query(query)


# Sidebar
st.sidebar.title("Washington EV Dashboard")
st.sidebar.markdown("---")
st.sidebar.info(
    "Data sourced from [data.wa.gov](https://data.wa.gov/Transportation/Electric-Vehicle-Population-Data/f6w7-q2d2). "
    "Updated monthly."
)

# Title
st.title("🚗 Washington Electric Vehicle Population Dashboard")
st.markdown(
    "This dashboard visualizes the distribution of electric vehicles registered in Washington State. "
    "Use the filters below to explore the data."
)

# Summary metrics
try:
    total_query = f"SELECT COUNT(*) as total FROM {ATHENA_TABLE}"
    total_df = run_query(total_query)
    total_ev = int(total_df["total"].iloc[0]) if not total_df.empty else 0

    bev_query = f"SELECT COUNT(*) as bev_total FROM {ATHENA_TABLE} WHERE is_bev = true"
    bev_df = run_query(bev_query)
    bev_total = int(bev_df["bev_total"].iloc[0]) if not bev_df.empty else 0

    phev_total = total_ev - bev_total

    col1, col2, col3 = st.columns(3)
    col1.metric("Total EVs", f"{total_ev:,}")
    col2.metric("Battery EVs (BEV)", f"{bev_total:,}")
    col3.metric("Plug-in Hybrids (PHEV)", f"{phev_total:,}")
except DASHBOARD_EXCEPTIONS as e:
    st.error(f"Failed to load summary metrics: {e}")
    total_ev = 0

st.markdown("---")

# Row 1: Categorical distributions
st.subheader("Categorical Distributions")
col_left, col_right = st.columns(2)

with col_left:
    st.markdown("#### Top EV Manufacturers")
    try:
        make_df = get_ev_count_by_make(limit=20)
        if not make_df.empty:
            fig = px.bar(
                make_df,
                x="ev_count",
                y="make",
                orientation="h",
                color="ev_count",
                color_continuous_scale="Greens",
                labels={"ev_count": "Number of EVs", "make": "Manufacturer"},
                title="EV Count by Make",
            )
            fig.update_layout(yaxis={"categoryorder": "total ascending"}, height=500)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No data available for make distribution.")
    except DASHBOARD_EXCEPTIONS as e:
        st.error(f"Error loading make distribution: {e}")

with col_right:
    st.markdown("#### EV Type Distribution")
    try:
        type_df = get_ev_type_distribution()
        if not type_df.empty:
            fig = px.pie(
                type_df,
                names="ev_type",
                values="ev_count",
                hole=0.4,
                color_discrete_sequence=px.colors.sequential.Greens_r,
                title="Battery EV vs Plug-in Hybrid",
            )
            fig.update_traces(textposition="inside", textinfo="percent+label")
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No data available for EV type distribution.")
    except DASHBOARD_EXCEPTIONS as e:
        st.error(f"Error loading EV type distribution: {e}")

st.markdown("---")

# Row 2: Temporal and geographic
st.subheader("Temporal & Geographic Trends")
col_left2, col_right2 = st.columns(2)

with col_left2:
    st.markdown("#### EV Registrations by Model Year")
    try:
        year_df = get_ev_by_model_year()
        if not year_df.empty:
            year_df["model_year"] = pd.to_numeric(
                year_df["model_year"], errors="coerce"
            )
            year_df = year_df.dropna(subset=["model_year"])
            year_df = year_df.sort_values("model_year")

            fig = px.line(
                year_df,
                x="model_year",
                y="ev_count",
                markers=True,
                labels={"model_year": "Model Year", "ev_count": "Number of EVs"},
                title="EV Registrations Over Time",
            )
            fig.update_traces(line_color="#2ca02c", marker={"size": 8})
            fig.update_layout(height=450)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No data available for model year distribution.")
    except DASHBOARD_EXCEPTIONS as e:
        st.error(f"Error loading model year distribution: {e}")

with col_right2:
    st.markdown("#### Top Counties by EV Count")
    try:
        county_df = get_top_counties(limit=15)
        if not county_df.empty:
            fig = px.bar(
                county_df,
                x="county",
                y="ev_count",
                color="ev_count",
                color_continuous_scale="Blues",
                labels={"ev_count": "Number of EVs", "county": "County"},
                title="EV Count by County",
            )
            fig.update_layout(height=450)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No data available for county distribution.")
    except DASHBOARD_EXCEPTIONS as e:
        st.error(f"Error loading county distribution: {e}")

st.markdown("---")
st.caption(
    "Built with Streamlit | Data: Washington State Department of Licensing | "
    "Pipeline: AWS Step Functions + Glue + Athena + S3"
)
