output "instance_profile_default_ec2_instance_name" {
  value = aws_iam_instance_profile.instance_profile_default_ec2_instance.name
}

output "rds_directoryservice_access_role_name" {
  value = aws_iam_role.rds_directoryservice_access_role.name
}

output "lambda_base_iam_arn" {
  value = aws_iam_role.iam_for_logging.arn
}

output "lambda_iam_policy_logging_arn" {
  value = aws_iam_policy.cloudwatch_logging.arn
}
