variable "github_token" {}

provider "aws" {
  profile = "private"
  region = "us-east-1"
}

resource "aws_iam_role" "stg-portfolio-site-codepipeline-iam-role" {
  name               = "stg-portfolio-site-codepipeline-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.stg-portfolio-site-codepipeline-iam-role.json}"
  path = "/service-role/"
}

data "aws_iam_policy_document" "stg-portfolio-site-codepipeline-iam-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "stg-portfolio-site-codepipeline-iam-role" {
  name   = "stg-portfolio-site-codepipeline-iam-role"
  role   = "${aws_iam_role.stg-portfolio-site-codepipeline-iam-role.id}"
  policy = "${file("iam/stg-portfolio-site-codepipeline-iam-role-policy.json")}"
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
        OAuthToken = "${var.github_token}"
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

resource "aws_codebuild_project" "stg-prepare-s3-files" {
  # service_role = "arn:aws:iam::*:role/service-role/codebuild-stg-prepare-s3-files-service-role"
  service_role   = "${aws_iam_role.codebuild-stg-prepare-s3-files-service-role.arn}"
  name = "stg-prepare-s3-files"
  
  artifacts {
    encryption_disabled = false
    location = ""
    name = "stg-prepare-s3-files"
    packaging = "NONE"
    path = ""
    type = "CODEPIPELINE"
  }
  
  cache {
    type = "NO_CACHE"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/python:3.7.1"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = false
    type = "LINUX_CONTAINER"
  }
  
  source {
    buildspec = "${file("buildspec/prd-prepare-s3-files.yml")}"
    git_clone_depth = 0
    insecure_ssl = false
    report_build_status = false
    type = "CODEPIPELINE"
  }
}

# --------------
# CodeBuild IAM
# --------------

resource "aws_iam_role_policy" "codebuild-stg-prepare-s3-files-service-role" {
  name   = "codebuild-stg-prepare-s3-files-service-role"
  role   = "${aws_iam_role.codebuild-stg-prepare-s3-files-service-role.id}"
  policy = "${file("iam/codebuild-stg-prepare-s3-files-service-role-policy.json")}"
}

resource "aws_iam_role" "codebuild-stg-prepare-s3-files-service-role" {
  name               = "codebuild-stg-prepare-s3-files-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild-stg-prepare-s3-files-service-role-policy-document.json}"
  # path = "/service-role/"
}

data "aws_iam_policy_document" "codebuild-stg-prepare-s3-files-service-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# --------------
# CodeBuild IAM
# --------------

resource "aws_iam_role" "portfolio-site-codepipeline-iam-role" {
  name               = "portfolio-site-codepipeline-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.portfolio-site-codepipeline-iam-role.json}"
  path = "/service-role/"
}

data "aws_iam_policy_document" "portfolio-site-codepipeline-iam-role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "portfolio-site-codepipeline-iam-role" {
  name   = "portfolio-site-codepipeline-iam-role"
  role   = "${aws_iam_role.portfolio-site-codepipeline-iam-role.name}"
  policy = "${file("iam/portfolio-site-codepipeline-iam-role-policy.json")}"
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
        OAuthToken = "${var.github_token}"
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
        ProjectName = "prd-prepare-s3-files"
      }
    }
  }
}

resource "aws_codebuild_project" "prd-prepare-s3-files" {
  service_role   = "${aws_iam_role.codebuild-prd-prepare-s3-files-service-role.arn}"
  name = "prd-prepare-s3-files"
  
  artifacts {
    encryption_disabled = false
    location = ""
    name = "prd-prepare-s3-files"
    packaging = "NONE"
    path = ""
    type = "CODEPIPELINE"
  }
  
  cache {
    type = "NO_CACHE"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/python:3.7.1"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = false
    type = "LINUX_CONTAINER"
  }
  
  source {
    buildspec = "${file("buildspec/stg-prepare-s3-files.yml")}"
    git_clone_depth = 0
    insecure_ssl = false
    report_build_status = false
    type = "CODEPIPELINE"
  }
}

# --------------
# CodeBuild IAM
# --------------

resource "aws_iam_role_policy" "codebuild-prd-prepare-s3-files-service-role" {
  name   = "codebuild-prd-prepare-s3-files-service-role"
  role   = "${aws_iam_role.codebuild-prd-prepare-s3-files-service-role.id}"
  policy = "${file("iam/codebuild-prd-prepare-s3-files-service-role-policy.json")}"
}

resource "aws_iam_role" "codebuild-prd-prepare-s3-files-service-role" {
  name               = "codebuild-prd-prepare-s3-files-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild-prd-prepare-s3-files-service-role-policy-document.json}"
  # path = "/service-role/"
}

data "aws_iam_policy_document" "codebuild-prd-prepare-s3-files-service-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# --------------
# CodeBuild IAM
# --------------
