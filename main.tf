
resource "aws_iam_role" "stg-portfolio-site-codepipeline-iam-role" {
  "assume_role_policy" = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"codepipeline.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
  path = "/service-role/"
}

resource "aws_s3_bucket" "stg-portfolio-site-s3-artifact" {

}

resource "aws_codepipeline" "stg-portfolio-site" {
  name     = "stg.portfolio-site"
  role_arn = "${aws_iam_role.stg-portfolio-site-codepipeline-iam-role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.stg-portfolio-site-s3-artifact.bucket}"
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
      output_artifacts = ["test"]

      configuration = {
        Owner  = "my-organization"
        Repo   = "test"
        Branch = "master"
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
      input_artifacts = ["test"]
      version         = "1"

      configuration = {
        ProjectName = "test"
      }
    }
  }
}
