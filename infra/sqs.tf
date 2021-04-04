locals {
  ws = terraform.workspace
}

resource "aws_sqs_queue" "sample_queue" {
  name                      = "${var.app_name}-${local.ws}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  # TODO: add redrive_policy and deadletter queue in production
}

resource "aws_sqs_queue_policy" "sample_queue_policy" {
  queue_url = aws_sqs_queue.sample_queue.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "${var.app_name}-${local.ws}-sqspolicy",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.sample_queue.arn}"
    }
  ]
}
EOF
}