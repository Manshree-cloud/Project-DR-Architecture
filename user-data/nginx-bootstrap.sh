#!/bin/bash
set -eux

# Update and install nginx
yum update -y || true
# Amazon Linux 2 vs 2023 handling
if command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx
else
  amazon-linux-extras install nginx1 -y || yum install -y nginx
fi

# Detect region (fallback if IMDS v2 problems)
REGION="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' || echo unknown)"

# Simple landing page
mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>DR Hello</title></head>
  <body style="font-family: system-ui, sans-serif; text-align:center; margin-top: 10vh;">
    <h1>Hello from ${REGION}</h1>
    <p>Auto-scaled via Launch Template + ASG behind an ALB.</p>
  </body>
</html>
HTML

# Start nginx
systemctl enable nginx
systemctl restart nginx
