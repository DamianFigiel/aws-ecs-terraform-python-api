##################################################################################
# CLOUDWATCH LOGS
##################################################################################

resource "aws_cloudwatch_log_group" "log_group_cluster_performace" {
  name              = "/aws/ecs/containerinsights/${var.cluster_name}/performance"
  retention_in_days = 1

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-ecs-cluster-performance"
  })
}

resource "aws_cloudwatch_log_group" "log_group_ecs_task" {
  name = "/ecs/${var.project}-task"

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-ecs-cluster-task"
  })
}