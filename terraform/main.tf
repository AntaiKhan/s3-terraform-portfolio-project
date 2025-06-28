#Creating S3 Bucket

resource "aws_s3_bucket" "sitebucket" {
  bucket = var.bucketname
}

# Configuring Bucket Ownership for S3 Bucket Created.

resource "aws_s3_bucket_ownership_controls" "objectOwner" {
  bucket = aws_s3_bucket.sitebucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Making S3 Bucket Public

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.sitebucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucketacl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.objectOwner,
    aws_s3_bucket_public_access_block.public,
  ]

  bucket = aws_s3_bucket.sitebucket.id
  acl    = "public-read"
}

# Uploading Site Files

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitebucket.id
  key          = "index.html"
  source       = "../index.html"
  acl          = "public-read"
  content_type = "text/html"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]

}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.sitebucket.id
  key          = "error.html"
  source       = "../index.html"
  acl          = "public-read"
  content_type = "text/html"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]

}

resource "aws_s3_object" "profilepic" {
  bucket = aws_s3_bucket.sitebucket.id
  key    = "linkedin-profile-pic.jpeg"
  source = "../linkedin-profile-pic.jpeg"
  acl    = "public-read"

  depends_on = [ aws_s3_bucket_acl.bucketacl ]
}

# Enabling Static Website Hosting on S3 Bucket
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.sitebucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [aws_s3_bucket_acl.bucketacl]

}