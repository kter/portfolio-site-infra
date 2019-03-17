/*
----------------------
Staging
----------------------
*/
resource "aws_iam_role" "stg-portfolio-site-html-updater" {
  name               = "stg-portfolio-site-html-updater"
  assume_role_policy = "${data.aws_iam_policy_document.stg-portfolio-site-html-updater.json}"
}

data "aws_iam_policy_document" "stg-portfolio-site-html-updater" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stg-portfolio-site-html-updater" {
  name   = "stg-portfolio-site-html-updater"
  role   = "${aws_iam_role.stg-portfolio-site-html-updater.id}"
  policy = "${data.aws_iam_policy_document.stg-portfolio-site-html-updater-policy.json}"
}

data "aws_iam_policy_document" "stg-portfolio-site-html-updater-policy" {
        statement {
            actions = [
                "s3:*"
            ]
            resources = [ "*" ]
        }
}

resource "aws_iam_role" "stg-ecsTaskExecutionRole" {
  name               = "stg-ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.stg-ecsTaskExecutionRole.json}"
}

data "aws_iam_policy_document" "stg-ecsTaskExecutionRole" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stg-ecsTaskExecutionRole" {
  name   = "stg-ecsTaskExecutionRole"
  role   = "${aws_iam_role.stg-ecsTaskExecutionRole.id}"
  policy = "${data.aws_iam_policy_document.stg-ecsTaskExecutionRole-policy.json}"
}

data "aws_iam_policy_document" "stg-ecsTaskExecutionRole-policy" {
    statement = {
            actions = [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
            resources = [ "*" ]
    }
}

resource "aws_ecs_task_definition" "stg_github_feed_generator" {
  family = "stg_github_feed_generator"
  container_definitions = "${file("container-definition/stg.github_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/stg-portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/stg-ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
}

resource "aws_ecs_task_definition" "stg_sidebar_feed_generator" {
  family = "stg_sidebar_feed_generator"
  container_definitions = "${file("container-definition/stg.sidebar_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/stg-portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/stg-ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
}

resource "aws_ecs_cluster" "stg-default" {
  name = "stg-default"
}

resource "aws_cloudwatch_event_rule" "stg-blog-updater" {
  name        = "stg-blog-updater"
  schedule_expression = "cron(0 * * * ? *)"
}
resource "aws_iam_role" "stg-ecs-event" {
  name               = "stg-ecs-event"
  assume_role_policy = "${data.aws_iam_policy_document.stg-ecs-event.json}"
}

data "aws_iam_policy_document" "stg-ecs-event" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stg-ecs-event" {
  name   = "stg-ecs-event"
  role   = "${aws_iam_role.stg-portfolio-site-html-updater.id}"
  policy = "${data.aws_iam_policy_document.stg-ecs-event-policy.json}"
}

data "aws_iam_policy_document" "stg-ecs-event-policy" {
  statement {
            actions = [
                "ecs:RunTask"
            ]
            resources = [
                "*"
            ]
        }
        statement {
            actions = [ "iam:PassRole" ]
            resources = [
                "*"
            ]
            condition {
                test = "StringLike"
                variable = "iam:PassedToService"
                values = [
                "ecs-tasks.amazonaws.com"
                ]
            }
        }
}

resource "aws_cloudwatch_event_target" "stg_github_feed_generator" {
  arn       = "${aws_ecs_cluster.stg-default.arn}"
  rule      = "${aws_cloudwatch_event_rule.stg-blog-updater.name}"
  role_arn  = "${aws_iam_role.stg-ecs-event.arn}"

  ecs_target = {
    task_count          = 1
    task_definition_arn = "${aws_ecs_task_definition.stg_github_feed_generator.arn}"
  }

  input = <<DOC
{
    "containerOverrides": [
        {
            "name": "stg_github_feed_generator",
            "environment": [
                {
                    "name": "BUCKET_NAME",
                    "value": "stg.tomohiko.io"
                }
            ]
        }
    ]
}
DOC

  lifecycle {
    ignore_changes = ["ecs_target"]
  }
}
resource "aws_cloudwatch_event_target" "stg_sidebar_feed_generator" {
  arn       = "${aws_ecs_cluster.stg-default.arn}"
  rule      = "${aws_cloudwatch_event_rule.stg-blog-updater.name}"
  role_arn  = "${aws_iam_role.stg-ecs-event.arn}"

  ecs_target = {
    task_count          = 1
    task_definition_arn = "${aws_ecs_task_definition.stg_sidebar_feed_generator.arn}"
  }

  input = <<DOC
{
    "containerOverrides": [
        {
            "name": "stg_sidebar_feed_generator",
            "environment": [
                {
                    "name": "BLOG_URL",
                    "value": "https://blog.tomohiko.io/feed.xml"
                },
                {
                    "name": "BUCKET_NAME",
                    "value": "stg.tomohiko.io"
                }
            ]
        }
    ]
}
DOC

  lifecycle {
    ignore_changes = ["ecs_target"]
  }
}
/*
----------------------
Production
----------------------
*/
resource "aws_iam_role" "portfolio-site-html-updater" {
  name               = "portfolio-site-html-updater"
  assume_role_policy = "${data.aws_iam_policy_document.portfolio-site-html-updater.json}"
}

data "aws_iam_policy_document" "portfolio-site-html-updater" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "portfolio-site-html-updater" {
  name   = "portfolio-site-html-updater"
  role   = "${aws_iam_role.portfolio-site-html-updater.id}"
  policy = "${data.aws_iam_policy_document.portfolio-site-html-updater-policy.json}"
}

data "aws_iam_policy_document" "portfolio-site-html-updater-policy" {
        statement {
            actions = [
                "s3:*"
            ]
            resources = [ "*" ]
        }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecsTaskExecutionRole.json}"
}

data "aws_iam_policy_document" "ecsTaskExecutionRole" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecsTaskExecutionRole" {
  name   = "ecsTaskExecutionRole"
  role   = "${aws_iam_role.ecsTaskExecutionRole.id}"
  policy = "${data.aws_iam_policy_document.ecsTaskExecutionRole-policy.json}"
}

data "aws_iam_policy_document" "ecsTaskExecutionRole-policy" {
    statement = {
            actions = [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
            resources = [ "*" ]
    }
}

resource "aws_ecs_task_definition" "github_feed_generator" {
  family = "github_feed_generator"
  container_definitions = "${file("container-definition/github_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
}

resource "aws_ecs_task_definition" "sidebar_feed_generator" {
  family = "sidebar_feed_generator"
  container_definitions = "${file("container-definition/sidebar_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
}

resource "aws_ecs_cluster" "default" {
  name = "default"
}

resource "aws_cloudwatch_event_rule" "blog-updater" {
  name        = "blog-updater"
  schedule_expression = "cron(0 * * * ? *)"
}
resource "aws_iam_role" "ecs-event" {
  name               = "ecs-event"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-event.json}"
}

data "aws_iam_policy_document" "ecs-event" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs-event" {
  name   = "ecs-event"
  role   = "${aws_iam_role.ecs-event.id}"
  policy = "${data.aws_iam_policy_document.ecs-event-policy.json}"
}

data "aws_iam_policy_document" "ecs-event-policy" {
  statement {
            actions = [
                "ecs:RunTask"
            ]
            resources = [
                "*"
            ]
        }
        statement {
            actions = [ "iam:PassRole" ]
            resources = [
                "*"
            ]
            condition {
                test = "StringLike"
                variable = "iam:PassedToService"
                values = [
                "ecs-tasks.amazonaws.com"
                ]
            }
        }
}

resource "aws_cloudwatch_event_target" "github_feed_generator" {
  arn       = "${aws_ecs_cluster.default.arn}"
  rule      = "${aws_cloudwatch_event_rule.blog-updater.name}"
  role_arn  = "${aws_iam_role.ecs-event.arn}"

  ecs_target = {
    task_count          = 1
    task_definition_arn = "${aws_ecs_task_definition.github_feed_generator.arn}"
  }

  input = <<DOC
{
    "containerOverrides": [
        {
            "name": "github_feed_generator",
            "environment": [
                {
                    "name": "BUCKET_NAME",
                    "value": "tomohiko.io"
                }
            ]
        }
    ]
}
DOC

  lifecycle {
    ignore_changes = ["ecs_target"]
  }
}
resource "aws_cloudwatch_event_target" "sidebar_feed_generator" {
  arn       = "${aws_ecs_cluster.default.arn}"
  rule      = "${aws_cloudwatch_event_rule.blog-updater.name}"
  role_arn  = "${aws_iam_role.ecs-event.arn}"

  ecs_target = {
    task_count          = 1
    task_definition_arn = "${aws_ecs_task_definition.sidebar_feed_generator.arn}"
  }

  input = <<DOC
{
    "containerOverrides": [
        {
            "name": "sidebar_feed_generator",
            "environment": [
                {
                    "name": "BLOG_URL",
                    "value": "https://blog.tomohiko.io/feed.xml"
                },
                {
                    "name": "BUCKET_NAME",
                    "value": "tomohiko.io"
                }
            ]
        }
    ]
}
DOC

  lifecycle {
    ignore_changes = ["ecs_target"]
  }
}