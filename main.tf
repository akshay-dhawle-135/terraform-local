provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}


resource "aws_iam_role" "eventbridge_invocation_role" {
  name = "eventbridge-invocation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_invocation_policy" {
  name        = "eventbridge-invocation-policy"
  description = "Policy to allow EventBridge to invoke API destinations"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "events:InvokeApiDestination",
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_event_api_destination.identity_api_destination.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_invocation_policy_attachment" {
  policy_arn = aws_iam_policy.eventbridge_invocation_policy.arn
  role       = aws_iam_role.eventbridge_invocation_role.name
}

resource "aws_cloudwatch_event_bus" "identity_event_bus" {
  name = "test-event-bus"
}

resource "aws_cloudwatch_event_connection" "identity_connection" {
  name               = local.identity_connection.name
  description        = local.identity_connection.description
  authorization_type = "OAUTH_CLIENT_CREDENTIALS"

  auth_parameters {
    oauth {
      
      authorization_endpoint = local.identity_connection.authorization_endpoint
      http_method            = local.identity_connection.http_method

      client_parameters {
        client_id     = "client_id"
        client_secret = "client_secret"
      }

      oauth_http_parameters {
        body {
          key   = "grant_type"
          value = "client_credentials"
        }
        body {
          key   = "scope"
          value = "cdp-google-ads/write"
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "identity_api_destination" {
  name                             = local.identity_api_destination.name
  description                      = local.identity_api_destination.description
  invocation_endpoint              = local.identity_api_destination.endpoint
  http_method                      = local.identity_api_destination.http_method
  invocation_rate_limit_per_second = local.identity_api_destination.invocation_rate_limit_per_second
  connection_arn                   = aws_cloudwatch_event_connection.identity_connection.arn
}

resource "aws_cloudwatch_event_rule" "identity_create_rule" {
  name           = local.rule_identity_create.name
  event_bus_name = aws_cloudwatch_event_bus.identity_event_bus.name
  event_pattern = jsonencode({
    "detail-type" = local.rule_identity_create.event_pattern.detail_type
  })
}

resource "aws_cloudwatch_event_target" "identity_create_rule_target" {
  event_bus_name = aws_cloudwatch_event_bus.identity_event_bus.name
  arn            = aws_cloudwatch_event_api_destination.identity_api_destination.arn
  rule           = aws_cloudwatch_event_rule.identity_create_rule.name
  role_arn       = aws_iam_role.eventbridge_invocation_role.arn
}
