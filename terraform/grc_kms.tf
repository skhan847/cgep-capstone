# Layer 1: customer-managed key for PHI
# HIPAA 164.312(a)(2)(iv) Encryption and decryption

resource "aws_kms_key" "phi" {
  description             = "Acme Health PHI key (intake bucket + table)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "phi" {
  name          = "alias/acme-health-phi"
  target_key_id = aws_kms_key.phi.key_id
}

# GAP-01: uploads bucket uses SSE-KMS with our key
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.phi.arn
    }
    bucket_key_enabled = true
  }
}
