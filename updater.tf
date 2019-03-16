/*
----------------------
Staging
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
  container_definitions = "${file("github_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_task_definition" "sidebar_feed_generator" {
  family = "sidebar_feed_generator"
  container_definitions = "${file("sidebar_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_cluster" "default" {
  name = "default"
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
  container_definitions = "${file("github_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_task_definition" "sidebar_feed_generator" {
  family = "sidebar_feed_generator"
  container_definitions = "${file("sidebar_feed_generator.json")}"
  task_role_arn = "arn:aws:iam::848738341109:role/portfolio-site-html-updater"
  execution_role_arn = "arn:aws:iam::848738341109:role/ecsTaskExecutionRole"
  cpu = "256"
  memory = "512"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_cluster" "default" {
  name = "default"
}