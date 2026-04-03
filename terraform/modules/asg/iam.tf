resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-app-role"
  }
}

# Standard SSM Managed Instance Core policy (for Session Manager & basic SSM access)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy to allow reading the TaskFlow SSM parameters
resource "aws_iam_policy" "ssm_read_params" {
  name        = "${var.project_name}-ssm-read-params"
  description = "Allows EC2 instances to read TaskFlow SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/taskflow/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_read_params_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.ssm_read_params.arn
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_role.name
}
