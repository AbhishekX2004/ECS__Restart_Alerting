data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_ecs_cluster" "existing" {
  count        = var.use_existing_cluster ? 1 : 0
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_service" "existing" {
  count        = var.use_existing_service ? 1 : 0
  cluster_arn  = local.ecs_cluster_id
  service_name = var.ecs_service_name
}
