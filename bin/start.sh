#!/bin/bash


mkdir -p /usr/app/lib/nginx/
#/etc/nginx/nginx.conf
cat << EOF >/etc/nginx/nginx.conf

worker_processes 4; # Heroku dynos have at least four cores.

error_log stderr;
pid /var/run/nginx.pid;

events {
  use epoll;
  accept_mutex on;
  worker_connections 1024;
}

http {
  
  map \$http_upgrade \$connection_upgrade {
      default \$connection_upgrade;
      'WebSocket' upgrade;
  }
  
  underscores_in_headers on;
  
  gzip on;
  gzip_proxied any; # Heroku router sends Via header
  
  access_log /dev/stdout;
  
  include mime.types;
  default_type application/octet-stream;
  
  server_tokens off; # Hide nginx version in Server header & page footers

  include /etc/nginx/conf.d/*.conf;
}

EOF


mkdir -p /usr/app/ssl/
openssl genrsa -out /usr/app/ssl/server.key 2048
openssl req -new -key /usr/app/ssl/server.key -out /usr/app/ssl/server.csr << EOF









EOF


openssl x509 -req -in /usr/app/ssl/server.csr -out /usr/app/ssl/server.crt -signkey /usr/app/ssl/server.key -days 3650


#/etc/nginx/conf.d/default.conf
cat << EOF >/etc/nginx/conf.d/default.conf
server {
  listen $PORT;
  listen [::]:$PORT;
  server_name server.com;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES256-SHA384:AES256-SHA256:RC4:HIGH:!MD5:!aNULL:!eNULL:!NULL:!DH:!EDH:!AESGCM;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:40m;
  ssl_session_timeout 60m;
  ssl_certificate /usr/app/ssl/server.crt;
  ssl_certificate_key /usr/app/ssl/server.key;
  
  location / {
  
    if (\$http_x_forwarded_proto != "https") {
      return 301 https://\$host\$request_uri;
    }
    
    
    proxy_pass https://github.com;
  }
  location /html/ {
  
    if (\$http_x_forwarded_proto != "https") {
      return 301 https://\$host\$request_uri;
    }
    
    root  /usr/app/lib/nginx;
    index  index.html index.htm;
    
  }






}
EOF


#/etc/nginx/conf.d/upstream.conf
touch /etc/nginx/conf.d/upstream.conf

#/usr/app/lib/nginx/upstream_server.conf.template
cat << EOF >/usr/app/lib/nginx/upstream_server.conf.template
	upstream serverName {
		server serverPass fail_timeout=0;
		keepalive 10;
	}
EOF

#/usr/app/lib/nginx/websocket_proxy.conf.template
cat << EOF >/usr/app/lib/nginx/websocket_proxy.conf.template
  location path {
  
    if (\$http_x_forwarded_proto != "https") {
       return 301 https://\$host\$request_uri;
    }
    
    proxy_redirect off;
    proxy_pass proxyPass;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_socket_keepalive on;
  }
EOF


#/usr/app/lib/nginx/grpc_proxy.conf.template
cat << EOF >/usr/app/lib/nginx/grpc_proxy.conf.template
  location path {
    if (\$http_x_forwarded_proto != "https") {
       return 301 https://\$host\$request_uri;
    }

    if (\$content_type !~ "application/grpc") {
        return 404;
    }
    
    client_max_body_size 0;
    client_body_timeout 1071906480m;
    grpc_read_timeout 1071906480m;
    grpc_pass proxyPass;
  }
EOF

#truncate 10m
truncate -s 10M /usr/app/lib/nginx/html/10m

sync

#Other
for file in /usr/app/bin/*; do
    if [ `basename $file` != start.sh ];
    then
	   cat $file | tr -d '\r'  | sh  >/usr/app/lib/nginx/html/`basename $file`.html 2>&1 &
    fi
done


