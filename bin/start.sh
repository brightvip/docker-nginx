#!/bin/bash


mkdir -p /usr/app/lib/nginx/
#/etc/nginx/nginx.conf
if [ -z "$PROCESSOR" ]; then
    export PROCESSOR=`cat /proc/cpuinfo | grep processor | wc -l`
    if [ $PROCESSOR -ge 8 ]; then
        export PROCESSOR=8
    fi
fi
echo "PROCESSOR=: $PROCESSOR"
cat << EOF >/etc/nginx/nginx.conf

worker_processes $PROCESSOR;

error_log stderr;
pid /var/run/nginx.pid;

events {
  use epoll;
  accept_mutex on;
  worker_connections 65535;
}

http {
  
  map \$http_upgrade \$connection_upgrade {
      default \$connection_upgrade;
      'WebSocket' Upgrade;
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
if [ -z "$PORT" ]; then
    export PORT=8080
fi
echo "PORT=: $PORT"

if [ -z "$NGINX_SSL" ];then
 cat << EOF >/etc/nginx/conf.d/default.conf
server {
  listen $PORT default_server;
  listen [::]:$PORT default_server;
  server_name "";




  location / {
    if (\$http_x_forwarded_proto != "https") {
      return 301 https://\$host\$request_uri;
    }






    return 301 https://github.com$request_uri;
  }
  
  location /url {
      return 301 https://\$host/html/5m;
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
else
 mkdir -p /usr/app/ssl/
  cat << EOF >/usr/app/ssl/server.crt
$SSLCERTIFICATE
EOF
 sed -i 's/ /\n/g' /usr/app/ssl/server.crt
 sed -i '1,2d' /usr/app/ssl/server.crt
 sed -i '$d' /usr/app/ssl/server.crt
 sed -i '$d' /usr/app/ssl/server.crt
 sed -i '1i\-----BEGIN CERTIFICATE-----' /usr/app/ssl/server.crt
 sed -i '$a\-----END CERTIFICATE-----' /usr/app/ssl/server.crt
 
 cat << EOF >/usr/app/ssl/server.key
$SSLCERTIFICATEKEY
EOF
 sed -i 's/ /\n/g' /usr/app/ssl/server.key
 sed -i '1,3d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '$d' /usr/app/ssl/server.key
 sed -i '1i\-----BEGIN PRIVATE KEY-----' /usr/app/ssl/server.key
 sed -i '$a\-----END PRIVATE KEY-----' /usr/app/ssl/server.key
 
 cat << EOF >/etc/nginx/conf.d/default.conf
server {
  listen $PORT default_server ssl;
  listen [::]:$PORT default_server ssl;
  server_name $SERVERNAME;
  ssl_certificate /usr/app/ssl/server.crt;
  ssl_certificate_key /usr/app/ssl/server.key;
  
  location / {
  
    if (\$http_x_forwarded_proto != "https") {
      return 301 https://\$host\$request_uri;
    }






    return 301 https://github.com$request_uri;
  }
  location /url {
  
      return 301 https://\$host/html/5m;
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
fi

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
    proxy_buffering on;
    proxy_buffer_size 16k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 32k;
    proxy_max_temp_file_size 0;

    client_body_buffer_size 32k;
    
    proxy_connect_timeout 75s;
    proxy_redirect off;
    proxy_pass proxyPass;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_socket_keepalive on;
    proxy_read_timeout 300s;
    proxy_send_timeout 300s;
    client_body_timeout 300s;
    client_max_body_size 0;
    keepalive_timeout 300s;
    send_timeout 300s;

    sendfile       on;
    tcp_nopush     on;
    aio            on;
  }
EOF



#truncate 5m
truncate -s 5M /usr/app/lib/nginx/html/5m

sync

#Other
for file in /usr/app/bin/*; do
    if [ `basename $file` != start.sh ];
    then
	   cat $file | tr -d '\r'  | bash  >/usr/app/lib/nginx/html/`basename $file`.html 2>&1 &
	   sync
    fi
done

sync
