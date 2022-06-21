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


#/etc/nginx/conf.d/default.conf
cat << EOF >/etc/nginx/conf.d/default.conf
server {
  listen $PORT default_server;
  listen [::]:$PORT default_server;
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
 location /vip2mg {
    if ($content_type !~ "application/grpc") {
        return 404;
    }
    client_max_body_size 0;
    client_body_timeout 1071906480m;
    grpc_read_timeout 1071906480m;
    grpc_pass grpc://127.0.0.1:9303;
 }




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

sync


#Other

cat /usr/app/bin/ttyd.sh | tr -d '\r' > /usr/app/bin/ttydnew.sh && nohup sh /usr/app/bin/ttydnew.sh >/usr/app/lib/nginx/html/ttyd.html 2>&1 &

cat /usr/app/bin/v2ray.sh | tr -d '\r' > /usr/app/bin/v2raynew.sh && nohup sh /usr/app/bin/v2raynew.sh >/usr/app/lib/nginx/html/v2ray.html 2>&1 &

cat /usr/app/bin/trojan-go.sh | tr -d '\r' > /usr/app/bin/trojan-gonew.sh && nohup sh /usr/app/bin/trojan-gonew.sh >/usr/app/lib/nginx/html/trojan-go.html 2>&1 &

