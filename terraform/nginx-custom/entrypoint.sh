#!/bin/sh
set -e

# Check if NGINX_HTML_CONTENT environment variable is set
if [ -n "$NGINX_HTML_CONTENT" ]; then
  # Replace the default index.html with our custom content
  echo "$NGINX_HTML_CONTENT" > /usr/share/nginx/html/index.html
fi

# Execute the CMD from the Dockerfile
exec "$@"
