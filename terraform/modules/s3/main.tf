# Raw data bucket
resource "aws_s3_bucket" "raw" {
  bucket = var.raw_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"
    filter {
      prefix = "intelligent-tiering/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Curated data bucket
resource "aws_s3_bucket" "curated" {
  bucket = var.curated_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "curated" {
  bucket = aws_s3_bucket.curated.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "curated" {
  bucket = aws_s3_bucket.curated.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"
    filter {
      prefix = "intelligent-tiering/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "curated" {
  bucket = aws_s3_bucket.curated.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
