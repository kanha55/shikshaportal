# frozen_string_literal: true

# Cloudflare R2 rejects requests that carry more than one checksum:
#   Aws::S3::Errors::InvalidRequest: You can only specify one non-default
#   checksum at a time.
#
# Recent aws-sdk-s3 versions (>= ~1.178) default to adding a CRC32 checksum
# in addition to the legacy Content-MD5 on uploads, which R2 does not allow.
# Restrict checksum calculation/validation to when the S3 operation actually
# requires it so Active Storage uploads to R2 succeed.
#
# aws-sdk-core reads these environment variables when the S3 client is built
# (lazily, on first Active Storage use — after initializers run), so setting
# defaults here is sufficient. We only set defaults and never override values
# already provided by the platform. This avoids referencing the `Aws` constant
# directly, which is only defined when the S3/R2 service is actually loaded.
ENV["AWS_REQUEST_CHECKSUM_CALCULATION"] ||= "when_required"
ENV["AWS_RESPONSE_CHECKSUM_VALIDATION"] ||= "when_required"
