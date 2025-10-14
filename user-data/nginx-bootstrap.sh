#!/bin/bash
set -eux

# Update and install nginx
yum update -y || true
if command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx
else
  amazon-linux-extras install nginx1 -y || yum install -y nginx
fi

# IMDSv2 token (fallback ok)
TOKEN="$(curl -sS -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' || true)"
mdget () {
  local path="$1"
  if [ -n "$TOKEN" ]; then
    curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254${path}" || true
  else
    curl -sS "http://169.254.169.254${path}" || true
  fi
}
REGION="$(mdget /latest/meta-data/placement/region)"
if [ -z "$REGION" ]; then
  AZ="$(mdget /latest/meta-data/placement/availability-zone)"
  [ -n "$AZ" ] && REGION="${AZ::-1}" || REGION="unknown"
fi

# Landing page
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

# Ensure default site serves our page
if [ -f /etc/nginx/nginx.conf ]; then
  grep -q "/usr/share/nginx/html" /etc/nginx/nginx.conf || true
fi

systemctl enable nginx
systemctl restart nginx
