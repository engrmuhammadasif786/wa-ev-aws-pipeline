"""Unit tests for WA EV ingestion module."""

from unittest.mock import MagicMock, patch

import pytest

from src.ingestion.fetch_ev_data import fetch_ev_data, upload_to_s3


class TestFetchEvData:
    @patch("src.ingestion.fetch_ev_data._create_session")
    def test_fetch_ev_data_success(self, mock_create_session):
        mock_get = mock_create_session.return_value.get
        mock_get.return_value.json.return_value = [
            {"vin_1_10": "ABC", "make": "TESLA", "model_year": "2022"},
            {"vin_1_10": "DEF", "make": "NISSAN", "model_year": "2021"},
        ]
        mock_get.return_value.raise_for_status = MagicMock()

        records = fetch_ev_data(limit=10)
        assert len(records) == 2
        assert records[0]["make"] == "TESLA"

    @patch("src.ingestion.fetch_ev_data._create_session")
    def test_fetch_ev_data_pagination(self, mock_create_session):
        # First call returns 2 records, second call returns empty
        mock_get = mock_create_session.return_value.get
        mock_get.return_value.json.side_effect = [
            [{"vin_1_10": "ABC", "make": "TESLA"}],
            [],
        ]
        mock_get.return_value.raise_for_status = MagicMock()

        records = fetch_ev_data(limit=1)
        assert len(records) == 1

    @patch("src.ingestion.fetch_ev_data._create_session")
    def test_fetch_ev_data_api_failure(self, mock_create_session):
        from requests.exceptions import HTTPError

        response = MagicMock(status_code=500)
        mock_get = mock_create_session.return_value.get
        mock_get.return_value.raise_for_status.side_effect = HTTPError(
            "500 Error", response=response
        )

        with (
            patch("src.ingestion.fetch_ev_data.time.sleep"),
            pytest.raises(HTTPError),
        ):
            fetch_ev_data(limit=10)


class TestUploadToS3:
    def test_upload_to_s3_success(self):
        mock_s3 = MagicMock()
        records = [
            {"vin_1_10": "ABC", "make": "TESLA"},
            {"vin_1_10": "DEF", "make": "NISSAN"},
        ]
        uri = upload_to_s3(records, bucket="test-bucket", s3_client=mock_s3)
        assert "s3://test-bucket/" in uri
        mock_s3.put_object.assert_called_once()

    def test_upload_to_s3_empty_records(self):
        mock_s3 = MagicMock()
        with pytest.raises(ValueError):
            upload_to_s3([], bucket="test-bucket", s3_client=mock_s3)
