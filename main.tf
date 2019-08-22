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
  policy = "${data.aws_iam_policy_document.stg-portfolio-site-codepipeline-iam-role-policy.json}"
}

data "aws_iam_policy_document" "stg-portfolio-site-codepipeline-iam-role-policy" {
        statement {
            actions = [
                "iam:PassRole"
            ]
            resources = [ "*" ]
            condition {
                test = "StringEqualsIfExists"
                variable = "iam:PassedToService"
                values = [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        statement {
            actions = [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "cloudformation:ValidateTemplate"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "ecr:DescribeImages"
            ]
            resources = [ "*" ]
        }
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
    buildspec = "version: 0.2\n\nenv:\n  variables:\n     BUCKET_NAME: \"stg.tomohiko.io\"\n  #parameter-store:\n     # key: \"value\"\n     # key: \"value\"\n\nphases:\n  #install:\n    #commands:\n      # - command\n      # - command\n  #pre_build:\n    #commands:\n      # - command\n      # - command\n  build:\n    commands:\n        - aws s3 cp index.html s3://$BUCKET_NAME\n        - aws s3 cp css/main.css s3://$BUCKET_NAME/css\n        - aws s3 cp robots.txt s3://$BUCKET_NAME\n  #post_build:\n    #commands:\n      # - command\n#artifacts:\n  #files:\n    # - location\n    # - location\n  #name: $(date +%Y-%m-%d)\n  #discard-paths: yes\n  #base-directory: location\n#cache:\n  #paths:\n    # - paths\n"
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
  policy = "${data.aws_iam_policy_document.codebuild-stg-prepare-s3-files-service-role-policy.json}"
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

data "aws_iam_policy_document" "codebuild-stg-prepare-s3-files-service-role-policy" {

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
        "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/stg-prepare-s3-files:log-stream:*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
                    "codedeploy:CreateDeployment",
                    "codedeploy:GetApplicationRevision",
                    "codedeploy:GetDeployment",
                    "codedeploy:GetDeploymentConfig",
                    "codedeploy:RegisterApplicationRevision"
    ]

    resources = [
      "*"
    ]
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
  policy = "${data.aws_iam_policy_document.portfolio-site-codepipeline-iam-role-policy.json}"
}

data "aws_iam_policy_document" "portfolio-site-codepipeline-iam-role-policy" {
        statement {
            actions = [
                "iam:PassRole"
            ]
            resources = [ "*" ]
            condition {
                test = "StringEqualsIfExists"
                variable = "iam:PassedToService"
                values = [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        statement {
            actions = [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "cloudformation:ValidateTemplate"
            ]
            resources = [ "*" ]
        }
        statement {
            actions = [
                "ecr:DescribeImages"
            ]
            resources = [ "*" ]
        }
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
    buildspec = "version: 0.2\n\nenv:\n  variables:\n     BUCKET_NAME: \"tomohiko.io\"\n  #parameter-store:\n     # key: \"value\"\n     # key: \"value\"\n\nphases:\n  #install:\n    #commands:\n      # - command\n      # - command\n  #pre_build:\n    #commands:\n      # - command\n      # - command\n  build:\n    commands:\n        - aws s3 cp index.html s3://$BUCKET_NAME\n        - aws s3 cp css/main.css s3://$BUCKET_NAME/css\n        \n  #post_build:\n    #commands:\n      # - command\n#artifacts:\n  #files:\n    # - location\n    # - location\n  #name: $(date +%Y-%m-%d)\n  #discard-paths: yes\n  #base-directory: location\n#cache:\n  #paths:\n    # - paths\n#08221135"
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
  policy = "${data.aws_iam_policy_document.codebuild-prd-prepare-s3-files-service-role-policy.json}"
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

data "aws_iam_policy_document" "codebuild-prd-prepare-s3-files-service-role-policy" {

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
        "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/prd-prepare-s3-files:log-stream:*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
                    "codedeploy:CreateDeployment",
                    "codedeploy:GetApplicationRevision",
                    "codedeploy:GetDeployment",
                    "codedeploy:GetDeploymentConfig",
                    "codedeploy:RegisterApplicationRevision"
    ]

    resources = [
      "*"
    ]
  }
}

# --------------
# CodeBuild IAM
# --------------
