#!/bin/bash

path=`pwd`

downloadCloudflareSpeedTest(){
 latest_version_CloudflareSpeedTest=`curl --retry 10 --retry-max-time 360 -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/XIU2/CloudflareSpeedTest/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
 if [ -n "$latest_version_CloudflareSpeedTest" ] && [ ! -d $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest ]; then
    rm -fr $path/CloudflareSpeedTest*
    echo "download $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest"
    mkdir -p $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/XIU2/CloudflareSpeedTest/releases/download/$latest_version_CloudflareSpeedTest/CloudflareST_linux_mipsle.tar.gz -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_mipsle.tar.gz
    tar -zxf $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_mipsle.tar.gz -C $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/
    rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_mipsle.tar.gz    
 fi
 rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt
 curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt -k
}

download_ip_scanner(){
 mkdir -p $path/ip_scanner
 curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://codeload.github.com/ip-scanner/cloudflare/zip/refs/heads/daily -o $path/ip_scanner/cloudflare-daily.zip
 unzip -q $path/ip_scanner/cloudflare-daily.zip  -d $path/ip_scanner/
 cat $path/ip_scanner/cloudflare-daily/*中国*.txt > $path/ip_scanner/ip_scanner.ip
 rm -fr $path/ip_scanner/cloudflare-daily/ $path/ip_scanner/cloudflare-daily.zip
}

install_clash(){
 latest_version_clash=`curl --retry 10 --retry-max-time 360 -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/Dreamacro/clash/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
 if [ -n "$latest_version_clash" ] && [ ! -d $path/clash$latest_version_clash ]; then
    rm -fr $path/clash*
    echo "download $path/clash$latest_version_clash"
    mkdir -p $path/clash$latest_version_clash
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/Dreamacro/clash/releases/download/$latest_version_clash/clash-linux-mipsle-softfloat-$latest_version_clash.gz -o $path/clash$latest_version_clash/clash-linux-mipsle-softfloat.gz
    gzip -d $path/clash$latest_version_clash/clash-linux-mipsle-softfloat.gz
    mv $path/clash$latest_version_clash/clash-linux-mipsle-softfloat /etc/openclash/core/clash
    chmod +x /etc/openclash/core/clash
    chown nobody /etc/openclash/core/clash
 fi
}

init_clash_config(){
    read -r -d '' clash_config_begin <<- 'EOF'
# Port of HTTP(S) proxy server on the local end
port: 7890

# Port of SOCKS5 proxy server on the local end
socks-port: 7891

# Transparent proxy server port for Linux and macOS (Redirect TCP and TProxy UDP)
redir-port: 7892

# Transparent proxy server port for Linux (TProxy TCP and TProxy UDP)
tproxy-port: 7893

# HTTP(S) and SOCKS4(A)/SOCKS5 server on the same port
mixed-port: 7890

# authentication of local SOCKS5/HTTP(S) server
# authentication:
#  - "user1:pass1"
#  - "user2:pass2"

# Set to true to allow connections to the local-end server from
# other LAN IP addresses
allow-lan: false

# This is only applicable when `allow-lan` is `true`
# '*': bind all IP addresses
# 192.168.122.11: bind a single IPv4 address
# "[aaaa::a8aa:ff:fe09:57d8]": bind a single IPv6 address
bind-address: '*'

# Clash router working mode
# rule: rule-based packet routing
# global: all packets will be forwarded to a single endpoint
# direct: directly forward the packets to the Internet
mode: rule

# Clash by default prints logs to STDOUT
# info / warning / error / debug / silent
log-level: error

# When set to false, resolver won't translate hostnames to IPv6 addresses
ipv6: true

# RESTful web API listening address
external-controller: 127.0.0.1:9090

# A relative path to the configuration directory or an absolute path to a
# directory in which you put some static web resource. Clash core will then
# serve it at `http://{{external-controller}}/ui`.
#external-ui: folder

# Secret for the RESTful API (optional)
# Authenticate by spedifying HTTP header `Authorization: Bearer ${secret}`
# ALWAYS set a secret if RESTful API is listening on 0.0.0.0
# secret: ""

# Outbound interface name
#interface-name: en0

# fwmark on Linux only
routing-mark: 6666

# Static hosts for DNS server and connection establishment (like /etc/hosts)
#
# Wildcard hostnames are supported (e.g. *.clash.dev, *.foo.*.example.com)
# Non-wildcard domain names have a higher priority than wildcard domain names
# e.g. foo.example.com > *.example.com > .example.com
# P.S. +.foo.com equals to .foo.com and foo.com
hosts:
  # '*.clash.dev': 127.0.0.1
  # '.dev': 127.0.0.1
  # 'alpha.clash.dev': '::1'

profile:
  # Store the `select` results in $HOME/.config/clash/.cache
  # set false If you don't want this behavior
  # when two different configurations have groups with the same name, the selected values are shared
  store-selected: true

  # persistence fakeip
  store-fake-ip: true

# DNS server settings
# This section is optional. When not present, the DNS server will be disabled.
dns:
  enable: true
  listen: 0.0.0.0:53
  ipv6: false # when the false, response to AAAA questions will be empty

  # These nameservers are used to resolve the DNS nameserver hostnames below.
  # Specify IP addresses only
  default-nameserver:
    - 1.1.1.1
    - 114.114.114.114
  enhanced-mode: redir-host #redir-host  or fake-ip
  fake-ip-range: 198.18.0.1/16 # Fake IP addresses pool CIDR
  use-hosts: true # lookup hosts and return IP record
  
  # Hostnames in this list will not be resolved with fake IPs
  # i.e. questions to these domain names will always be answered with their
  # real IP addresses
  fake-ip-filter:
     - '*.lan'
     - localhost.ptlogin2.qq.com
  
  # Supports UDP, TCP, DoT, DoH. You can specify the port to connect to.
  # All DNS questions are sent directly to the nameserver, without proxies
  # involved. Clash answers the DNS question with the first result gathered.
  nameserver:
    - 'tcp://8.8.8.8'
    - https://1.1.1.1/dns-query
    - 114.114.114.114
    #- dhcp://en0 # dns from dhcp

  # When `fallback` is present, the DNS server will send concurrent requests
  # to the servers in this section along with servers in `nameservers`.
  # The answers from fallback servers are used when the GEOIP country
  # is not `CN`.
  fallback:
    - 'tcp://8.8.8.8'
    - https://1.1.1.1/dns-query
    
  # If IP addresses resolved with servers in `nameservers` are in the specified
  # subnets below, they are considered invalid and results from `fallback`
  # servers are used instead.
  #
  # IP address resolved with servers in `nameserver` is used when
  # `fallback-filter.geoip` is true and when GEOIP of the IP address is `CN`.
  #
  # If `fallback-filter.geoip` is false, results from `nameserver` nameservers
  # are always used if not match `fallback-filter.ipcidr`.
  #
  # This is a countermeasure against DNS pollution attacks.
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4
    domain:
      - '+.google.com'
      - '+.facebook.com'
      - '+.youtube.com'
      - '+.ytimg.com'
      - '+.googlevideo.com'
      - '+.openwrt.org'

  # Lookup domains via specific nameservers
  nameserver-policy:
    '+.internal.crop.com': '10.0.0.1'
    
proxies:
  # Shadowsocks
  # The supported ciphers (encryption methods):
  #   aes-128-gcm aes-192-gcm aes-256-gcm
  #   aes-128-cfb aes-192-cfb aes-256-cfb
  #   aes-128-ctr aes-192-ctr aes-256-ctr
  #   rc4-md5 chacha20-ietf xchacha20
  #   chacha20-ietf-poly1305 xchacha20-ietf-poly130

  # vmess
  # cipher support auto/aes-128-gcm/chacha20-poly1305/none


EOF

    read -r -d '' clash_config_end <<- 'EOF'

proxy-providers:

rules:
  - IP-CIDR6,::/0,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - DOMAIN,apple.com,DIRECT
  - DOMAIN,bing.com,DIRECT
  - DOMAIN,icloud.com,DIRECT
  - DOMAIN,microsoft.com,DIRECT
  - DOMAIN,google.com,select
  - DOMAIN,openwrt.org,select
  - DOMAIN-SUFFIX,.cn,DIRECT
  - DOMAIN-SUFFIX,.com.cn,DIRECT
  - DOMAIN-SUFFIX,apple.com,DIRECT
  - DOMAIN-SUFFIX,bing.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com,DIRECT
  - DOMAIN-SUFFIX,microsoft.com,DIRECT
  - DOMAIN-SUFFIX,live.com,DIRECT
  - DOMAIN-SUFFIX,office.com,DIRECT
  - DOMAIN-SUFFIX,google.com,select
  - DOMAIN-SUFFIX,github.com,select
  - DOMAIN-SUFFIX,openwrt.org,select
  - DOMAIN-SUFFIX,truepeoplesearch.net,select
  - DOMAIN-SUFFIX,beenverified.com,select
  - DOMAIN-SUFFIX,herokudns.com,REJECT
  - DOMAIN-SUFFIX,skk.moe,REJECT
  - DOMAIN-SUFFIX,drift.com,REJECT
  - DOMAIN-SUFFIX,ad.com,REJECT
  - DOMAIN-SUFFIX,hotjar.com,REJECT
  - DOMAIN-KEYWORD,cdn,DIRECT
  - DOMAIN-KEYWORD,google,select
  - DOMAIN-KEYWORD,github,select
  - DOMAIN-KEYWORD,openwrt,select
  - SRC-IP-CIDR,192.168.1.201/32,DIRECT
  # optional param "no-resolve" for IP rules (GEOIP, IP-CIDR, IP-CIDR6)
  - GEOIP,CN,DIRECT
  - GEOIP,US,select
  - GEOIP,DE,select
  - GEOIP,JP,select
  - DST-PORT,80,DIRECT
  - SRC-PORT,7777,DIRECT
  #- RULE-SET,apple,REJECT # Premium only
  - MATCH,DIRECT
EOF

    read -r -d '' clash_config_proxy_groups <<- 'EOF'

proxy-groups:
  # load-balance: The request of the same eTLD+1 will be dial to the same proxy.
  - name: "load-balance"
    type: load-balance
    proxies:
    %proxies_ip
    url: 'http://www.gstatic.com/generate_204'
    tolerance: 150
    lazy: true
    interval: 600
    strategy: round-robin #consistent-hashing or round-robin
 

  - name: "url-test"
    type: url-test
    proxies:
    %proxies_ip
    url: 'http://www.gstatic.com/generate_204'
    tolerance: 150
    lazy: true
    interval: 600
    
  - name: select
    type: select
    disable-udp: false
    proxies:
      - load-balance
      - url-test

EOF


}


auto_clash_config_ip_by_CloudflareSpeedTest(){
    read -r -d '' clash_config_proxie <<- 'EOF'

  - name: "vip2-vmess-ws_%s"
    type: vmess
    server: %s
    port: 
    uuid: 
    alterId: 0
    cipher: auto
    udp: true
    tls: true
    skip-cert-verify: false
    servername: 
    network: ws
    ws-opts:
       path: 
       headers:
           Host: 
       #max-early-data: 1024
       #early-data-header-name: Sec-WebSocket-Protocol

  - name: vip2-vmess-grpc_%s
    server: %s
    port: 
    type: vmess
    uuid: 
    alterId: 0
    cipher: auto
    network: grpc
    tls: true
    servername: 
    skip-cert-verify: false
    grpc-opts:
       grpc-service-name: ""


EOF


    if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST ]; then
      if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt ] && [ -f $path/ip_scanner/ip_scanner.ip ] ; then
        sed -i '1r '"${path}"'/ip_scanner/ip_scanner.ip' $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt
      fi
      $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST -httping -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result.txt -t 2 -dn 10 -n 100
    fi
    
    ips=''
    if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result.txt ]; then
      ips=`cat $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result.txt | awk  -F',' 'NR>1 {print $1}'`
    elif [ -f $path/ip_scanner/ip_scanner.ip ]; then
      ips=`cat $path/ip_scanner/ip_scanner.ip`
    else
      ips='1.1.1.1'
    fi
    

    clash_config_proxie_ip=''
    for ip in $ips
    do 
        clash_config_proxie_ip="$clash_config_proxie_ip

  ${clash_config_proxie//%s/$ip}"
    done


    proxies_ip=''
    for ip in $ips
    do 
        proxies_ip="$proxies_ip   - vip2-vmess-ws_$ip
    "
    done
    for ip in $ips
    do 
        proxies_ip="$proxies_ip   - vip2-vmess-grpc_$ip
    "
    done



    echo "${clash_config_begin}${clash_config_proxie_ip}

${clash_config_proxy_groups//%proxies_ip/$proxies_ip}

${clash_config_end}" > /etc/openclash/config/config.yaml
}


init_clash_config
downloadCloudflareSpeedTest
download_ip_scanner
install_clash
/etc/init.d/openclash stop
auto_clash_config_ip_by_CloudflareSpeedTest
/etc/init.d/openclash restart





#0 17 * * * /bin/opkg update && /bin/opkg upgrade kmod-tcp-bbr `/bin/opkg list-upgradable | /usr/bin/awk '{print $1}'| /usr/bin/awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}'` --force-overwrite
#0 20 * * * /root/openclash_auto_config/openclash_auto_config.sh > /root/openclash_auto_config/start.log 2>&1
#
#ulimit -v `free -k | awk 'NR==2{print $2}'` 2>/dev/null
#
#clash_pid=`ps |grep $CLASH | grep nobody | grep -v 'grep'  | awk '{print $1}' | tr "\n" " "|sed 's/.$//'`
#echo "-1000" > /proc/$clash_pid/oom_score_adj
#oom_score_adj_value=`cat /proc/$clash_pid/oom_score_adj`
#LOG_OUT "Step 4.1: clash_pid:$clash_pid oom_score_adj:$oom_score_adj_value"
