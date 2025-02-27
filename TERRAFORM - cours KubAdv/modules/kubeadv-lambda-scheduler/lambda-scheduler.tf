# Création du rôle IAM pour la fonction Lambda
resource "aws_iam_role" "lambda_role" {
  name = "kubeadv-lambda-start-stop-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "scheduler.amazonaws.com"]
        }
      }
    ]
  })
}

# Création de la politique IAM pour arrêter toutes les instances tagguées avec app:kubeadv dans eu-central-1
resource "aws_iam_policy" "lambda_policy" {
  name        = "kubeadv-lambda-start-stop-policy"
  path        = "/"
  description = "IAM policy for kubeadv Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstanceAttribute"
        ]
        Resource = ["arn:aws:ec2:eu-central-1:*:instance/*"]
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/app" = "kubeadv"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:eu-central-1:361769567094:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:eu-central-1:361769567094:log-group:/aws/lambda/kubeadv-lambda-start-stop-function:*"
        ]
      }
    ]
  })
}

# Attachement de la politique au rôle
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Création de la fonction Lambda
resource "aws_lambda_function" "kubeadv_lambda_ec2_control" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "kubeadv-lambda-start-stop-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
  
  memory_size = 256
  timeout     = 300  # 5 minutes en secondes
}

#-----------EVENT BRIDGE-----------
# Création du rôle IAM pour les 2 scheduler event bridge
resource "aws_iam_role" "scheduler_role" {
  name = "kubeadv-scheduler-role"

  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "scheduler.amazonaws.com"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"StringEquals": {
					"aws:SourceAccount": "361769567094"
				}
			}
		}
	]
})
}

# Création de la politique IAM pour arrêter toutes les instances tagguées avec app:kubeadv dans eu-central-1
resource "aws_iam_policy" "scheduler_policy" {
  name        = "kubeadv-eventBridge-scheduler-execution-policy"
  path        = "/"
  description = "IAM policy for kubeadv Lambda function"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:eu-central-1:361769567094:function:kubeadv-lambda-start-stop-function:*",
                "arn:aws:lambda:eu-central-1:361769567094:function:kubeadv-lambda-start-stop-function"
            ]
        }
    ]
})
}

# Attachement de la politique au rôle
resource "aws_iam_role_policy_attachment" "scheduler_policy_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

resource "aws_scheduler_schedule" "kubeadv_start_instance" {
  name = "start-instance-schedule"
  description = "Démarrer les instances avec le tag app=kubeadv à 9h00"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression_timezone = "Europe/Paris"
  schedule_expression = "cron(55 8 ? * MON-FRI *)"

  target {
    arn      = aws_lambda_function.kubeadv_lambda_ec2_control.arn
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      action = "start"
    })
  }
}

resource "aws_scheduler_schedule" "kubeadv_stop_instance" {
  name = "stop-instance-schedule"
  description = "Arrêter les instances avec le tag app=kubeadv à 17h00"

  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression_timezone = "Europe/Paris"
  schedule_expression = "cron(0 21 ? * MON-FRI *)"

  target {
    arn      = aws_lambda_function.kubeadv_lambda_ec2_control.arn
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      action = "stop"
    })
  }
}

/*
resource "aws_lambda_permission" "kubeadv_role_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kubeadv_lambda_ec2_control.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_scheduler_schedule.kubeadv_start_instance.arn
}
*/

