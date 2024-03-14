resource "aws_security_group" "elasticsearch-alb-sg" {
  name        = "${var.es_cluster}-alb-sg"
  description = "ElasticSearch Ports for ALB Access"
  vpc_id      = var.vpc_id
}

# allow ES port access
resource "aws_security_group_rule" "elasticsearch-alb-sg-ingress-rule-es" {
  type        = "ingress"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 9200
  to_port     = 9200

  security_group_id = aws_security_group.elasticsearch-alb-sg.id
}

# allow egress
resource "aws_security_group_rule" "elasticsearch-alb-sg-egress-rule-all" {
  type        = "egress"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 0

  security_group_id = aws_security_group.elasticsearch-alb-sg.id
}

# allow Kibana port access
resource "aws_security_group_rule" "elasticsearch-alb-sg-ingress-rule-kibana" {
  count    = length(keys(var.clients_count)) > 0 || local.singlenode_mode ? 1 : 0
  type        = "ingress"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 5601
  to_port     = 5601

  security_group_id = aws_security_group.elasticsearch-alb-sg.id
}

# Target Groups
#-----------------------------------------------------

resource "aws_lb_target_group" "esearch-p9200-tg" {
  name     = "${var.es_cluster}-p9200-tg"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 9200
    interval            = 15
    matcher             = "401"
  }
}

resource "aws_lb_target_group" "kibana-p5601-tg" {
  count    = length(keys(var.clients_count)) > 0 || local.singlenode_mode ? 1 : 0
  name     = "${var.es_cluster}-p5601-tg"
  port     = 5601
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    port                = 5601
    interval            = 15
    matcher             = "302"
  }
}

resource "aws_lb" "elasticsearch-alb" {
  name               = "${var.es_cluster}-alb"
  internal           = ! var.public_facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elasticsearch-alb-sg.id]
  subnets            = coalescelist(var.alb_subnets, tolist(data.aws_subnets.all-subnets.ids))

  enable_deletion_protection = false
}

#-----------------------------------------------------

# ALB Listeners and Listener Rules
#-----------------------------------------------------

resource "aws_lb_listener" "esearch" {
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  port              = "9200"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.esearch-p9200-tg.arn
  }
}

resource "aws_lb_listener" "kibana" {
  count    = length(keys(var.clients_count)) > 0 || local.singlenode_mode ? 1 : 0
  load_balancer_arn = aws_lb.elasticsearch-alb.arn
  port              = "5601"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana-p5601-tg[0].arn
  }
}
