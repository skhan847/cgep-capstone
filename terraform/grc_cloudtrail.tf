# Layer 1: CloudTrail into the evidence vault
# HIPAA 164.312(b) Audit controls; 164.308(a)(1)(ii)(D) Information system activity review

resource "aws_s3_bucket_policy" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.evidence.arn
      },
      {
        Sid       = "CloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.evidence.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.evidence.arn, "${aws_s3_bucket.evidence.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.evidence]
}

resource "aws_cloudtrail" "main" {
  name                          = "${local.name_prefix}-trail-${local.suffix}"
  s3_bucket_name                = aws_s3_bucket.evidence.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.evidence.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Also record every read/write of patient uploads (PHI)
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.uploads.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.evidence]
}
