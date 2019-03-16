/*
----------------------
Staging
----------------------
*/
resource "aws_iam_role" "stg-portfolio-site-html-updater" {
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  description = "Allows ECS tasks to call AWS services on your behalf."
}

resource "aws_iam_role" "stg-ecsTaskExecutionRole" {
  assume_role_policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
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
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
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
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  description = "Allows ECS tasks to call AWS services on your behalf."
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  assume_role_policy = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
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
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
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