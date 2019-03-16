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
}

resource "aws_ecs_task_definition" "sidebar_feed_generator" {
  family = "sidebar_feed_generator"
  container_definitions = "${file("sidebar_feed_generator.json")}"
}

resource "aws_ecs_cluster" "default" {
  name = "default"
}

resource "aws_iam_role" "stg-portfolio-site-codepipeline-iam-role" {
  "assume_role_policy" = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
  path = "/service-role/"
}

resource "aws_s3_bucket" "codepipeline-us-east-1-725352146983" {
  bucket = "codepipeline-us-east-1-725352146983"
}

resource "aws_codepipeline" "stg-portfolio-site" {
  name     = "stg.portfolio-site"
  role_arn = "${aws_iam_role.stg-portfolio-site-codepipeline-iam-role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline-us-east-1-725352146983.bucket}"
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        Owner  = "kter"
        Repo   = "portfolio-site"
        Branch = "staging"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      version         = "1"
      output_artifacts = ["BuildArtifact"]


      configuration = {
        ProjectName = "stg-prepare-s3-files"
      }
    }
  }
}


resource "aws_iam_role" "portfolio-site-codepipeline-iam-role" {
  "assume_role_policy" = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
  path = "/service-role/"
}

resource "aws_codepipeline" "portfolio-site" {
  name     = "portfolio-site"
  role_arn = "${aws_iam_role.portfolio-site-codepipeline-iam-role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline-us-east-1-725352146983.bucket}"
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        Owner  = "kter"
        Repo   = "portfolio-site"
        Branch = "master"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      version         = "1"
      output_artifacts = ["BuildArtifact"]


      configuration = {
        ProjectName = "prepare-s3-files"
      }
    }
  }
}
