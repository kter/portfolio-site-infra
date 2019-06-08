terraform {
  backend "s3" {
    bucket = "terraform.tomohiko.io"
    key = "terraform.tfstate"
    region = "us-east-1"
    profile = "private"
  }
}
