##################################################################################
# IAM
##################################################################################

resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "code_pipeline_role" {
  path               = "/service-role/"
  name               = aws_iam_policy.code_pipeline_policy.name
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF

tags = local.common_tags
}

resource "aws_iam_role" "github_upload_images_to_ECR" {
  path               = "/"
  name               = "AllowGithubUploadImagesToECR"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${aws_iam_openid_connect_provider.github_oidc_provider.arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": { 
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud":"sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub":"repo:${var.github_account}/*:*"
                }
            }
        }
    ]
}
    EOF

  tags = local.common_tags
}

resource "aws_iam_role" "ecs_code_deploy_role" {
  path               = "/"
  name               = "ecsCodeDeployRole"
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "codedeploy.amazonaws.com",
                    "ecs.amazonaws.com"
                    ]
                },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF

tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_code_deploy_role_attachment" {
  role       = aws_iam_role.ecs_code_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_iam_role" "cloud_watch_events_role" {
  path               = "/service-role/"
  name               = "cwe-role-us-east-2-${var.project}-pipeline"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        { 
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF

  tags = local.common_tags
}

resource "aws_iam_role" "ecs_instance_role" {
  path               = "/"
  name               = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF

tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "container_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloud_watch_agent_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  path               = "/"
  name               = "ecsTaskExecutionRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        { 
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF

tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_service_linked_role" "ecs_service_role" {
  aws_service_name = "ecs.amazonaws.com"
  description      = "Role to enable Amazon ECS to manage your cluster."
}

resource "aws_iam_service_linked_role" "elb_service_role" {
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  description      = "Allows ELB to call AWS services on your behalf."
}

resource "aws_iam_instance_profile" "instance_profile" {
  path = "/"
  name = aws_iam_role.ecs_instance_role.name
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_policy" "start_pipeline_execution" {
  name   = "start-pipeline-execution-us-east-2-${var.project}-pipeline"
  path   = "/service-role/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "arn:aws:codepipeline:us-east-2:450040323579:${var.project}-pipeline"
            ]
        }
    ]
}
    EOF
}

resource "aws_iam_role_policy_attachment" "start_pipeline_execution_attachment" {
  role       = aws_iam_role.cloud_watch_events_role.name
  policy_arn = aws_iam_policy.start_pipeline_execution.arn
}

resource "aws_iam_policy" "code_pipeline_policy" {
  name   = "AWSCodePipelineServiceRole-us-east-2-${var.project}-pipeline"
  path   = "/service-role/"
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
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
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
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
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
    EOF
}

resource "aws_iam_role_policy_attachment" "code_pipeline_policy_attachment" {
  role       = aws_iam_role.code_pipeline_role.name
  policy_arn = aws_iam_policy.code_pipeline_policy.arn
}

resource "aws_iam_role_policy" "github_upload_images_to_ECR" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:PutImage*",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetAuthorizationToken",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}
    EOF
  role   = aws_iam_role.github_upload_images_to_ECR.name
}