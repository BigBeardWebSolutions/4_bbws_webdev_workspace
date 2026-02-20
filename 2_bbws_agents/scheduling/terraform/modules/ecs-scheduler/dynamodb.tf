resource "aws_dynamodb_table" "state" {
  name         = "${local.prefix}-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service_arn"

  attribute {
    name = "service_arn"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = local.default_tags
}
