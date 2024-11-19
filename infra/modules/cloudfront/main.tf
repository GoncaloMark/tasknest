resource "aws_cloudfront_distribution" "tasknest_distribution" {
    enabled             = true
    default_root_object = "index.html"
    
    # Origin for the web app frontend (ALB)
    origin {
        domain_name = var.alb_dns
        origin_id   = "ALBOrigin"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    # Origin for the API Gateway
    origin {
        domain_name = replace(var.api_gw, "/^https?://([^/]*).*/", "$1")
        origin_id   = "api_gw"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "https-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    # Default cache behavior for the web app frontend
    default_cache_behavior {
        target_origin_id       = "ALBOrigin"
        viewer_protocol_policy = "redirect-to-https"
        
        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods  = ["GET", "HEAD"]
        
        forwarded_values {
            query_string = true
            
            cookies {
                forward = "all"
            }
        }

        min_ttl     = 0
        default_ttl = 3600
        max_ttl     = 86400
    }

    ordered_cache_behavior {
        path_pattern     = "/api/*"
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "api_gw"

        default_ttl = 0
        min_ttl     = 0
        max_ttl     = 0

        forwarded_values {
            query_string = true
            headers      = [
                "Authorization",
                "Origin",
                "Access-Control-Request-Headers",
                "Access-Control-Request-Method",
                "X-User-ID"
            ]
            cookies {
                forward = "all"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
    }

    # Viewer Certificate for HTTPS
    viewer_certificate {
        cloudfront_default_certificate = true
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    tags = {
        Name = "Web App Distribution"
    }
}