############# Création des student et policies associées #############

resource "aws_iam_user" "student0" {
  name = "student0"
  depends_on = [
    aws_iam_policy.kubeadv_student_policy,
    aws_iam_policy.kubeadv_s3_policy
  ]
}

resource "aws_iam_access_key" "student0_key" {
  user = aws_iam_user.student0.name
}

resource "aws_iam_user" "student1" {
  name = "student1"
  depends_on = [
    aws_iam_policy.kubeadv_student_policy,
    aws_iam_policy.kubeadv_s3_policy
  ]
}

resource "aws_iam_access_key" "student1_key" {
  user = aws_iam_user.student1.name
}

resource "aws_iam_user_login_profile" "student0_profile" {
  user    = aws_iam_user.student0.name
  password_reset_required = true
}

resource "aws_iam_user_login_profile" "student1_profile" {
  user    = aws_iam_user.student1.name
  password_reset_required = true
}

# Association des 2 politiques à student0
resource "aws_iam_user_policy_attachment" "student0_kubeadv_student_policy" {
  user       = aws_iam_user.student0.name
  policy_arn = aws_iam_policy.kubeadv_student_policy.arn
}
resource "aws_iam_user_policy_attachment" "student0_kubeadv_s3_policy" {
  user       = aws_iam_user.student0.name
  policy_arn = aws_iam_policy.kubeadv_s3_policy.arn
}

# Association des 2 politiques à student1
resource "aws_iam_user_policy_attachment" "student1_kubeadv_student_policy" {
  user       = aws_iam_user.student1.name
  policy_arn = aws_iam_policy.kubeadv_student_policy.arn
}
resource "aws_iam_user_policy_attachment" "student1_kubeadv_s3_policy" {
  user       = aws_iam_user.student1.name
  policy_arn = aws_iam_policy.kubeadv_s3_policy.arn
}

# Politique d'accès aux instances en SSM et start/stop
resource "aws_iam_policy" "kubeadv_student_policy" {
  name        = "kubeadv-student-policy"
  path        = "/"
  description = "Policy for kubeadv student access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:StartSession"]
        Resource = ["arn:aws:ec2:eu-central-1:*:instance/*"]
        Condition = {
          StringLike = {
            "ssm:resourceTag/user" = ["$${aws:username}"]
          }
        }
      },
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
            "ec2:ResourceTag/user" = ["$${aws:username}"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceProperties",
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeRouteTables",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNatGateways",
          "ec2:DescribeVpnGateways",
          "ec2:DescribeInternetGateways"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-central-1"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:CreateDocument",
          "ssm:UpdateDocument",
          "ssm:GetDocument",
          "ssm:StartSession"
        ]
        Resource = "arn:aws:ssm:eu-central-1:*:document/SSM-SessionManagerRunShell"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ]
        Resource = ["arn:aws:ssm:*:*:session/$$:{aws:userid}-*"]
      },
      {
        "Effect": "Allow",
        "Action": "iam:ChangePassword",
        "Resource": "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })
}

############# Politique d'accès au bucket S3 kubeadv #############
resource "aws_iam_policy" "kubeadv_s3_policy" {
  name        = "kubeadv-S3-policy"
  path        = "/"
  description = "Policy for kubeadv S3 access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::kubeadv",
          "arn:aws:s3:::kubeadv/*"
        ]
      }
    ]
  })
}

############# Création du rôle et de l'instance profile pour toutes les instances EC2 ############
resource "aws_iam_role" "kubeadv_ec2_instance_profile" {
  name = "kubeadv-ec2-instance-profile"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kubeadv_ec2_instance_profile" {
  name = "kubeadv-ec2-instance-profile"
  role = aws_iam_role.kubeadv_ec2_instance_profile.name
}

# Création de la nouvelle politique kubeadv-LoadBalancer
resource "aws_iam_policy" "kubeadv_loadbalancer_policy" {
  name        = "kubeadv-LoadBalancer"
  path        = "/"
  description = "Allow creating service-linked role for Elastic Load Balancing"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "ec2:GetSecurityGroupsForVpc",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTrustStores",
                "elasticloadbalancing:DescribeListenerAttributes",
                "elasticloadbalancing:DescribeCapacityReservation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:ModifyListenerAttributes",
                "elasticloadbalancing:ModifyCapacityReservation"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticloadbalancing:CreateAction": [
                        "CreateTargetGroup",
                        "CreateLoadBalancer"
                    ]
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
  })
}


# Attachement de la nouvelle politique kubeadv-LoadBalancer au rôle
resource "aws_iam_role_policy_attachment" "loadbalancer_policy" {
  policy_arn = aws_iam_policy.kubeadv_loadbalancer_policy.arn
  role       = aws_iam_role.kubeadv_ec2_instance_profile.name
}


# Attachement de la politique Custom kubeadv-S3-policy (définie plus haut)
resource "aws_iam_role_policy_attachment" "s3_policy" {
  policy_arn = aws_iam_policy.kubeadv_s3_policy.arn 
  role       = aws_iam_role.kubeadv_ec2_instance_profile.name
}


# Attachement de la politique Managed AmazonSSMManagedInstanceCore 
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.kubeadv_ec2_instance_profile.name
}



