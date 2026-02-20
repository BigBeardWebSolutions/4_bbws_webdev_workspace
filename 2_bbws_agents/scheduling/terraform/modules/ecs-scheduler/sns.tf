resource "aws_sns_topic" "notifications" {
  name = "${local.prefix}-notifications"
  tags = local.default_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.notification_emails)
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_emails[count.index]
}
