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
  
  access_log off;
  #access_log /dev/stdout;
  
  include mime.types;
  default_type application/octet-stream;
  
  server_tokens off; # Hide nginx version in Server header & page footers

  include /etc/nginx/conf.d/*.conf;
}

EOF


#/etc/nginx/conf.d/default.conf
cat << EOF >/etc/nginx/conf.d/default.conf
server {
  listen $PORT;
  listen [::]:$PORT;
  server_name server.com;








  
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
		keepalive_timeout 300s;
	}
EOF

#/usr/app/lib/nginx/websocket_proxy.conf.template
cat << EOF >/usr/app/lib/nginx/websocket_proxy.conf.template
  location path {
  
    if (\$http_x_forwarded_proto != "https") {
       return 301 https://\$host\$request_uri;
    }
    #proxy_buffering on;
    #proxy_buffer_size 1024k;
    #proxy_buffers 1024k;
    #proxy_busy_buffers_size 1024k;
    
    #client_body_buffer_size 1024k;
    #client_header_buffer_size 16k;
    
    proxy_connect_timeout 75s;
    proxy_redirect off;
    proxy_pass proxyPass;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_socket_keepalive on;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;
    client_body_timeout 300s;
    client_max_body_size 0;
    keepalive_timeout 300s;
    send_timeout 300s;
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
    
    #client_body_buffer_size 1024k;
    #client_header_buffer_size 16k;   
    
    client_body_timeout 300s;
    client_max_body_size 0;
    keepalive_timeout 300s;
    send_timeout 300s;
    grpc_connect_timeout 75s;
    grpc_read_timeout 300s;
    grpc_send_timeout 300s;
    grpc_socket_keepalive on;
    #grpc_buffer_size 1024k;
    grpc_pass proxyPass;
  }
EOF

#truncate 200m
truncate -s 200M /usr/app/lib/nginx/html/200m

sync

#Other
for file in /usr/app/bin/*; do
    if [ `basename $file` != start.sh ];
    then
	   cat $file | tr -d '\r'  | sh  >/usr/app/lib/nginx/html/`basename $file`.html 2>&1 &
    fi
done


