##################################################################################
# CICD
##################################################################################

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "codepipeline-${var.aws_region}-${var.project}-${random_integer.rand.result}"
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
      {
        "Sid": "DenyUnEncryptedObjectUploads",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.s3_bucket.arn}/*",
        "Condition": {
          "StringNotEquals": {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      },
      {
        "Sid": "DenyInsecureConnections",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": "${aws_s3_bucket.s3_bucket.arn}/*",
        "Condition": {
          "Bool": {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  }
  EOF
}

resource "aws_codecommit_repository" "code_commit_repository" {
  repository_name = "pipeline-files"
}

resource "aws_codedeploy_app" "code_deploy_application" {
  name             = "${var.project}-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
  app_name               = aws_codedeploy_app.code_deploy_application.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.project}-dg"
  service_role_arn       = aws_iam_role.ecs_code_deploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.elastic_load_balancer_listener_80.arn]
      }

      target_group {
        name = aws_lb_target_group.elb_target_group_80.name
      }

      target_group {
        name = aws_lb_target_group.elb_target_group_8080.name
      }
    }
  }
}

resource "aws_codepipeline" "code_pipeline_pipeline" {
  name     = "${var.project}-pipeline"
  role_arn = aws_iam_role.code_pipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.s3_bucket.id
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      configuration = {
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "true"
        RepositoryName       = "pipeline-files"
      }
      provider = "CodeCommit"
      version  = "1"
      output_artifacts = [
        "SourceArtifact"
      ]
      run_order = 1
    }
    action {
      name     = "Image"
      category = "Source"
      owner    = "AWS"
      configuration = {
        RepositoryName = "${var.project}"
      }
      provider = "ECR"
      version  = "1"
      output_artifacts = [
        "${var.project}-image"
      ]
      run_order = 1
    }
  }
  stage {
    name = "Deploy"
    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      configuration = {
        AppSpecTemplateArtifact        = "SourceArtifact"
        AppSpecTemplatePath            = "appspec.yaml"
        ApplicationName                = aws_codedeploy_app.code_deploy_application.name
        DeploymentGroupName            = "${var.project}-dg"
        Image1ArtifactName             = "${var.project}-image"
        Image1ContainerName            = "IMAGE1_NAME"
        TaskDefinitionTemplateArtifact = "SourceArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
      }
      input_artifacts = [
        "SourceArtifact",
        "${var.project}-image"
      ]
      provider  = "CodeDeployToECS"
      version   = "1"
      run_order = 1
    }
  }
}

resource "aws_cloudwatch_event_rule" "events_rule" {
  name          = "codepipeline-new-image-${var.project}-rule"
  description   = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the Amazon ECR image tag."
  event_pattern = <<EOF
  {
    "source": ["aws.ecr"],
    "detail": {
      "action-type": ["PUSH"],
      "image-tag": ["latest"],
      "repository-name": ["${var.project}"],
      "result": ["SUCCESS"]
    },
    "detail-type": ["ECR Image Action"]
  }
  EOF
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  rule     = aws_cloudwatch_event_rule.events_rule.name
  arn      = aws_codepipeline.code_pipeline_pipeline.arn
  role_arn = aws_iam_role.cloud_watch_events_role.arn
}

resource "aws_service_discovery_http_namespace" "service_discovery_http_namespace" {
  name = "apis"
}

