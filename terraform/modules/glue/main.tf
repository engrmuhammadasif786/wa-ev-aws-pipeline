# Glue Catalog Database
resource "aws_glue_catalog_database" "main" {
  name = var.database_name
}

# Glue Catalog Table for curated data (partitioned)
resource "aws_glue_catalog_table" "curated" {
  name          = var.table_name
  database_name = aws_glue_catalog_database.main.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  partition_keys {
    name = "model_year"
    type = "string"
  }

  partition_keys {
    name = "county"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${var.curated_bucket_name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = var.table_name
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "vin_prefix"
      type = "string"
    }
    columns {
      name = "city"
      type = "string"
    }
    columns {
      name = "state"
      type = "string"
    }
    columns {
      name = "postal_code"
      type = "string"
    }
    columns {
      name = "make"
      type = "string"
    }
    columns {
      name = "model"
      type = "string"
    }
    columns {
      name = "ev_type"
      type = "string"
    }
    columns {
      name = "cafv_eligibility"
      type = "string"
    }
    columns {
      name = "electric_range"
      type = "bigint"
    }
    columns {
      name = "base_msrp"
      type = "bigint"
    }
    columns {
      name = "legislative_district"
      type = "string"
    }
    columns {
      name = "dol_vehicle_id"
      type = "string"
    }
    columns {
      name = "vehicle_location"
      type = "string"
    }
    columns {
      name = "electric_utility"
      type = "string"
    }
    columns {
      name = "census_tract"
      type = "string"
    }
    columns {
      name = "is_bev"
      type = "boolean"
    }
    columns {
      name = "vehicle_age"
      type = "bigint"
    }
    columns {
      name = "cafv_eligibility_clean"
      type = "string"
    }
  }
}
