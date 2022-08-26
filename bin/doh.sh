#!/bin/bash





conf(){
 mkdir -p /usr/app/lib/nginx/


cat << EOF >/usr/app/lib/nginx/doh.hp.conf.template
  location path {
  
    if (\$http_x_forwarded_proto != "https") {
      return 301 https://\$host\$request_uri;
    }
    
    
    proxy_pass proxyPass;
  }
EOF


 sed -e 's:path:'"${WSPATH}/dns-query"':' -e 's/proxyPass/https:\/\/dns.google\/dns-query/' /usr/app/lib/nginx/doh.hp.conf.template > /usr/app/lib/nginx/doh.hp.g
 sed -i '35 r /usr/app/lib/nginx/doh.hp.g' /etc/nginx/conf.d/default.conf
 
 
 sleep 10s
 nginx  -s reload
}
conf
