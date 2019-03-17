variable "github_token" {}

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
  role   = "${aws_iam_role.portfolio-site-codepipeline-iam-role.id}"
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
        ProjectName = "prepare-s3-files"
      }
    }
  }
}
