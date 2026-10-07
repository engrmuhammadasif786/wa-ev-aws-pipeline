"""Unit tests for WA EV transformation module."""

import pandas as pd

from src.transform.glue_ev_transform import clean_dataframe


class TestCleanDataframe:
    def test_basic_cleaning(self):
        df = pd.DataFrame(
            {
                "vin_1_10": ["ABC", "DEF"],
                "county": ["King", "Pierce"],
                "city": ["Seattle", "Tacoma"],
                "model_year": ["2022", "2021"],
                "make": ["TESLA", "NISSAN"],
                "model": ["Model 3", "LEAF"],
                "ev_type": [
                    "Battery Electric Vehicle (BEV)",
                    "Plug-in Hybrid Electric Vehicle (PHEV)",
                ],
                "cafv_type": ["Clean Alternative Fuel Vehicle Eligible", None],
                "electric_range": ["358", "149"],
                "base_msrp": ["45000", "32000"],
            }
        )

        result = clean_dataframe(df)

        assert len(result) == 2
        assert "is_bev" in result.columns
        assert result["is_bev"].iloc[0] == True
        assert result["is_bev"].iloc[1] == False
        assert "vehicle_age" in result.columns
        assert "cafv_eligibility_clean" in result.columns
        assert result["model_year"].dtype.name == "Int64"

    def test_drop_missing_partitions(self):
        df = pd.DataFrame(
            {
                "vin_1_10": ["ABC", "DEF", "GHI"],
                "county": ["King", None, "Pierce"],
                "model_year": ["2022", "2021", None],
                "make": ["TESLA", "NISSAN", "CHEVY"],
                "model": ["Model 3", "LEAF", "Bolt"],
                "ev_type": ["BEV", "PHEV", "BEV"],
            }
        )

        result = clean_dataframe(df)
        assert len(result) == 1  # Only King/2022 has both partition keys

    def test_standardize_cafv(self):
        df = pd.DataFrame(
            {
                "county": ["King"],
                "model_year": ["2022"],
                "make": ["TESLA"],
                "model": ["Model 3"],
                "ev_type": ["BEV"],
                "cafv_type": ["Not eligible due to low battery range"],
            }
        )

        result = clean_dataframe(df)
        assert result["cafv_eligibility_clean"].iloc[0] == "Not Eligible"
