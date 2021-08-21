
#Policy document defining service principles for lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    sid = "terraform"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#create some core base IAM roles for lambda and other services to re-use for logging
resource "aws_iam_role" "iam_for_logging" {
  name        = "CloudWatch-Logging-${var.app_name}-${upper(var.environment_name)}"
  description = "Base role for accessing resources needed to permit logging to CloudWatch"
  path        = "/service-role/"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = {
    App = var.app_name
    Env = var.environment_name
    Terraform = true
  }
}

//TODO: Consider tightening this up more to limit ARN to within this deployment
resource "aws_iam_policy" "cloudwatch_logging" {
  name = "CloudWatch-Logging-${var.app_name}-${upper(var.environment_name)}"
  path = "/service-role/"
  description = "IAM policy for logging to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.iam_for_logging.name
  policy_arn = aws_iam_policy.cloudwatch_logging.arn
}

#RDS roles & policies, used to allow RDS to integrate with AD
resource "aws_iam_role" "rds_directoryservice_access_role" {
  name = "IAM_ROLE_DOMAIN_RDS_DS_ACCESS-${var.app_name}-${var.environment_name}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "policy_rds_directoryservice_access" {
  name   = "IAM_POLICY_RDS_DS_ACCESS-${var.app_name}-${var.environment_name}"
  role   = aws_iam_role.rds_directoryservice_access_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ds:DescribeDirectories",
                "ds:AuthorizeApplication",
                "ds:UnauthorizeApplication",
                "ds:GetAuthorizedApplicationDetails"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF

}

#EC2 roles & policies used during launch, to permit joining AD and querying self-hosted metadata
resource "aws_iam_role" "iam_role_default_ec2_instance" {
  name = "IAM_ROLE_DEFAULT_EC2_INSTANCE-${var.app_name}-${var.environment_name}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

}

resource "aws_iam_instance_profile" "instance_profile_default_ec2_instance" {
  name = "INSTANCE_PROFILE_DEFAULT_EC2-${var.app_name}-${var.environment_name}"
  role = aws_iam_role.iam_role_default_ec2_instance.name
}

data "aws_iam_policy_document" "default_ec2_policy" {
  statement {
    actions = [
      "ssm:DescribeAssociation",
      "ssm:ListAssociations",
      "ssm:GetDocument",
      "ssm:ListInstanceAssociations",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:UpdateInstanceAssociationStatus",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "ds:CreateComputer",
      "ds:DescribeDirectories",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "s3:ListBucket",
      "s3:GetObject",      
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "policy_allow_all_ssm" {
  name = "IAM_POLICY_ALLOW_ALL_SSM-${var.app_name}-${var.environment_name}"
  role = aws_iam_role.iam_role_default_ec2_instance.id
  policy = data.aws_iam_policy_document.default_ec2_policy.json
}