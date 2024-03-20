#!/bin/bash


update(){
 /usr/share/openclash/openclash_ipdb.sh
 /usr/share/openclash/openclash_geosite.sh
 /usr/share/openclash/openclash_geoip.sh
 /usr/share/openclash/openclash_chnroute.sh
 /bin/opkg update && /bin/opkg upgrade tar `/bin/opkg list-upgradable | /usr/bin/awk '{print $1}'| /usr/bin/awk BEGIN{RS=EOF}'{gsub(/\n/," ");print}'` --force-overwrite
}

path=$(dirname $(readlink -f $0))

downloadCloudflareSpeedTest(){
 latest_version_CloudflareSpeedTest=`curl --retry 10 --retry-max-time 360 -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/XIU2/CloudflareSpeedTest/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
 if [ -n "$latest_version_CloudflareSpeedTest" ] && [ ! -d $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest ]; then
    rm -fr $path/CloudflareSpeedTest*
    echo "download $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest"
    mkdir -p $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/XIU2/CloudflareSpeedTest/releases/download/$latest_version_CloudflareSpeedTest/CloudflareST_linux_arm64.tar.gz -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_arm64.tar.gz
    tar -zxf $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_arm64.tar.gz -C $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/
    rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST_linux_arm64.tar.gz    
 fi
rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ip.txt
curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ip.txt -k

rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt
curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt -k
}


install_mihomo(){
 latest_version_mihomo=`curl --retry 10 --retry-max-time 360 -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/MetaCubeX/mihomo/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
 if [ -n "$latest_version_mihomo" ] && [ ! -d $path/mihomo$latest_version_mihomo ]; then
    rm -fr $path/mihomo*
    echo "download $path/mihomo$latest_version_mihomo"
    mkdir -p $path/mihomo$latest_version_mihomo
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/MetaCubeX/mihomo/releases/download/$latest_version_mihomo/mihomo-linux-arm64-$latest_version_mihomo.gz -o $path/mihomo$latest_version_mihomo/mihomo-linux-arm64.gz
    gzip -d $path/mihomo$latest_version_mihomo/mihomo-linux-arm64.gz
    mv $path/mihomo$latest_version_mihomo/mihomo-linux-arm64 /etc/openclash/core/mihomo-linux-arm64
    chmod +x /etc/openclash/core/mihomo-linux-arm64
    chown nobody /etc/openclash/core/mihomo-linux-arm64
    if ! [ -e /etc/openclash/core/clash_meta ] ; then
       ln -s /etc/openclash/core/mihomo-linux-arm64 /etc/openclash/core/clash_meta
    fi
 fi
}

init_mihomo_config(){
    read -r -d '' mihomo_config_begin <<- 'EOF'
# port: 7890 # HTTP(S) 代理服务器端口
# socks-port: 7891 # SOCKS5 代理端口
mixed-port: 10801 # HTTP(S) 和 SOCKS 代理混合端口
#redir-port: 7892 # 透明代理端口，用于 Linux 和 MacOS

# Transparent proxy server port for Linux (TProxy TCP and TProxy UDP)
tproxy-port: 7893

allow-lan: true # 允许局域网连接
bind-address: "*" # 绑定 IP 地址，仅作用于 allow-lan 为 true，'*'表示所有地址
authentication: # http,socks入口的验证用户名，密码
  - "username:password"
skip-auth-prefixes: # 设置跳过验证的IP段
  - 127.0.0.1/8
  - ::1/128

#  find-process-mode has 3 values:always, strict, off
#  - always, 开启，强制匹配所有进程
#  - strict, 默认，由 mihomo 判断是否开启
#  - off, 不匹配进程，推荐在路由器上使用此模式
find-process-mode: strict

mode: rule

#自定义 geodata url
geox-url:
  geoip: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat"
  geosite: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat"
  mmdb: "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb"

log-level: error # 日志等级 silent/error/warning/info/debug

ipv6: true # 开启 IPv6 总开关，关闭阻断所有 IPv6 链接和屏蔽 DNS 请求 AAAA 记录

#tls:
#  certificate: string # 证书 PEM 格式，或者 证书的路径
#  private-key: string # 证书对应的私钥 PEM 格式，或者私钥路径
#  custom-certifactes:
#    - |
#      -----BEGIN CERTIFICATE-----
#      format/pem...
#      -----END CERTIFICATE-----

external-controller: 0.0.0.0:9093 # RESTful API 监听地址
#external-controller-tls: 0.0.0.0:9443 # RESTful API HTTPS 监听地址，需要配置 tls 部分配置文件
# secret: "123456" # `Authorization:Bearer ${secret}`

# tcp-concurrent: true # TCP 并发连接所有 IP, 将使用最快握手的 TCP

# 配置 WEB UI 目录，使用 http://{{external-controller}}/ui 访问
external-ui: /path/to/ui/folder/
external-ui-name: xd
external-ui-url: "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"

# interface-name: en0 # 设置出口网卡

# 全局 TLS 指纹，优先低于 proxy 内的 client-fingerprint
# 可选： "chrome","firefox","safari","ios","random","none" options.
# Utls is currently support TLS transport in TCP/grpc/WS/HTTP for VLESS/Vmess and trojan.
global-client-fingerprint: chrome

#  TCP keep alive interval
keep-alive-interval: 15

# routing-mark:6666 # 配置 fwmark 仅用于 Linux
experimental:
  # Disable quic-go GSO support. This may result in reduced performance on Linux.
  # This is not recommended for most users.
  # Only users encountering issues with quic-go's internal implementation should enable this,
  # and they should disable it as soon as the issue is resolved.
  # This field will be removed when quic-go fixes all their issues in GSO.
  # This equivalent to the environment variable QUIC_GO_DISABLE_GSO=1.
  #quic-go-disable-gso: true

# 类似于 /etc/hosts, 仅支持配置单个 IP
hosts:

EOF

    read -r -d '' mihomo_config_hosts <<- 'EOF'
# '*.mihomo.dev': 127.0.0.1
# '.dev': 127.0.0.1
# 'alpha.mihomo.dev': '::1'
# test.com: [1.1.1.1, 2.2.2.2]
# home.lan: lan # lan 为特别字段，将加入本地所有网卡的地址
# baidu.com: google.com # 只允许配置一个别名

profile: # 存储 select 选择记录
  store-selected: true

  # 持久化 fake-ip
  store-fake-ip: true

# Tun 配置
tun:
  enable: false
  stack: system # gvisor / lwip
  dns-hijack:
    - 0.0.0.0:53 # 需要劫持的 DNS
  # auto-detect-interface: true # 自动识别出口网卡
  # auto-route: true # 配置路由表
  # mtu: 9000 # 最大传输单元
  # strict-route: true # 将所有连接路由到tun来防止泄漏，但你的设备将无法其他设备被访问
  inet4-route-address: # 启用 auto_route 时使用自定义路由而不是默认路由
    - 0.0.0.0/1
    - 128.0.0.0/1
  inet6-route-address: # 启用 auto_route 时使用自定义路由而不是默认路由
    - "::/1"
    - "8000::/1"
  # endpoint-independent-nat: false # 启用独立于端点的 NAT
  # include-uid: # UID 规则仅在 Linux 下被支持，并且需要 auto_route
  # - 0
  # include-uid-range: # 限制被路由的的用户范围
  # - 1000-99999
  # exclude-uid: # 排除路由的的用户
  #- 1000
  # exclude-uid-range: # 排除路由的的用户范围
  # - 1000-99999

  # Android 用户和应用规则仅在 Android 下被支持
  # 并且需要 auto-route

  # include-android-user: # 限制被路由的 Android 用户
  # - 0
  # - 10
  # include-package: # 限制被路由的 Android 应用包名
  # - com.android.chrome
  # exclude-package: # 排除被路由的 Android 应用包名
  # - com.android.captiveportallogin

#ebpf配置
ebpf:
  auto-redir: # redirect 模式，仅支持 TCP
    - eth0
  redirect-to-tun: # UDP+TCP 使用该功能请勿启用 auto-route
    - eth0

# 嗅探域名 可选配置
sniffer:
  enable: false
  ## 对 redir-host 类型识别的流量进行强制嗅探
  ## 如：Tun、Redir 和 TProxy 并 DNS 为 redir-host 皆属于
  # force-dns-mapping: false
  ## 对所有未获取到域名的流量进行强制嗅探
  # parse-pure-ip: false
  # 是否使用嗅探结果作为实际访问，默认 true
  # 全局配置，优先级低于 sniffer.sniff 实际配置
  override-destination: false
  sniff: # TLS 和 QUIC 默认如果不配置 ports 默认嗅探 443
    QUIC:
    #  ports: [ 443 ]
    TLS:
    #  ports: [443, 8443]

    # 默认嗅探 80
    HTTP: # 需要嗅探的端口
      ports: [80, 8080-8880]
      # 可覆盖 sniffer.override-destination
      override-destination: true
  force-domain:
    - +.v2ex.com
  ## 对嗅探结果进行跳过
  # skip-domain:
  #   - Mijia Cloud
  # 需要嗅探协议
  # 已废弃，若 sniffer.sniff 配置则此项无效
  sniffing:
    - tls
    - http
  # 强制对此域名进行嗅探

  # 仅对白名单中的端口进行嗅探，默认为 443，80
  # 已废弃，若 sniffer.sniff 配置则此项无效
  port-whitelist:
    - "80"
    - "443"
    # - 8000-9999

tunnels: # one line config
  #- tcp/udp,127.0.0.1:6553,114.114.114.114:53,proxy
  #- tcp,127.0.0.1:6666,rds.mysql.com:3306,vpn
  # full yaml config
  #- network: [tcp, udp]
  #  address: 127.0.0.1:7777
  #  target: target.com
  #  proxy: proxy

# DNS配置
dns:
  cache-algorithm: arc
  enable: true # 关闭将使用系统 DNS
  prefer-h3: true # 开启 DoH 支持 HTTP/3，将并发尝试
  listen: 0.0.0.0:53 # 开启 DNS 服务器监听
  ipv6: true # false 将返回 AAAA 的空结果
  # ipv6-timeout: 300 # 单位：ms，内部双栈并发时，向上游查询 AAAA 时，等待 AAAA 的时间，默认 100ms
  # 用于解析 nameserver，fallback 以及其他DNS服务器配置的，DNS 服务域名
  # 只能使用纯 IP 地址，可使用加密 DNS
  default-nameserver:
    - 1.1.1.1
  enhanced-mode: fake-ip # or redir-host

  fake-ip-range: 198.18.0.1/16 # fake-ip 池设置

  # use-hosts: true # 查询 hosts

  # 配置不使用fake-ip的域名
  fake-ip-filter:
     - '*.lan'
     - localhost.ptlogin2.qq.com

  # DNS主要域名配置
  # 支持 UDP，TCP，DoT，DoH，DoQ
  # 这部分为主要 DNS 配置，影响所有直连，确保使用对大陆解析精准的 DNS
  nameserver:
    - https://1.1.1.1/dns-query
    - 'tcp://8.8.8.8'

  # 当配置 fallback 时，会查询 nameserver 中返回的 IP 是否为 CN，非必要配置
  # 当不是 CN，则使用 fallback 中的 DNS 查询结果
  # 确保配置 fallback 时能够正常查询
  fallback:
    - 'https://1.1.1.1/dns-query#select'
    - 'tcp://8.8.8.8#select'
# 指定 DNS 过代理查询，ProxyGroupName 为策略组名或节点名，过代理配置优先于配置出口网卡，当找不到策略组或节点名则设置为出口网卡

  # 专用于节点域名解析的 DNS 服务器，非必要配置项
  # 配置服务器若查询失败将使用 nameserver，非并发查询
  # proxy-server-nameserver:
  # - https://dns.google/dns-query
  # - tls://one.one.one.one

  # 配置 fallback 使用条件
  fallback-filter:
    geoip: true # 配置是否使用 geoip
    geoip-code: CN # 当 nameserver 域名的 IP 查询 geoip 库为 CN 时，不使用 fallback 中的 DNS 查询结果
  #   配置强制 fallback，优先于 IP 判断，具体分类自行查看 geosite 库
  #   geosite:
  #     - gfw
  #   如果不匹配 ipcidr 则使用 nameservers 中的结果
    ipcidr:
      - 240.0.0.0/4
    domain:
      - '+.facebook.com'
      - '+.google.com'
      - '+.youtube.com'
      - '+.ytimg.com'
      - '+.googlevideo.com'
      - '+.goog'
      - '+.googleapis.com'
      - '+.ggpht.com'
      - '+.googleusercontent.com'
      - '+.googleapis-cn.com'
      - '+.doubleclick.net'
      - '+.googleadservices.com'
      - '+.googlesyndication.com'
      - '+.openwrt.org'
      - '+.openai.com'
      - '+.ai.com'

  # 配置查询域名使用的 DNS 服务器
  nameserver-policy:
    #   'www.baidu.com': '114.114.114.114'
    #   '+.internal.crop.com': '10.0.0.1'
    # "geosite:cn":
    #   - dhcp://en0
    #   - 114.114.114.114
    #   - https://dns.alidns.com/dns-query
    #"geosite:category-ads-all": rcode://success
    #"www.baidu.com,+.google.cn": [223.5.5.5, https://dns.alidns.com/dns-query]
    ## global，dns 为 rule-providers 中的名为 global 和 dns 规则订阅，
    ## 且 behavior 必须为 domain/classical，当为 classical 时仅会生效域名类规则
    # "rule-set:global,dns": 8.8.8.8

proxies: 
  # vmess
  # cipher支持 auto/aes-128-gcm/chacha20-poly1305/none


EOF

    read -r -d '' mihomo_config_end <<- 'EOF'

#proxy-providers:


rules:
 # - AND,((IP-CIDR6,::/0),(NETWORK,UDP),(DST-PORT,443),(OR,((DOMAIN-KEYWORD,youtube),(DOMAIN-KEYWORD,goog)))),REJECT
  - DOMAIN-SUFFIX,cloudflare-gateway.com,DIRECT
  - DOMAIN-SUFFIX,cloudflareclient.com,DIRECT
  - DOMAIN-SUFFIX,.cn,DIRECT
  - DOMAIN-SUFFIX,baidu.com,DIRECT
  - DOMAIN-SUFFIX,taobao.com,DIRECT
  - DOMAIN-SUFFIX,apple.com,DIRECT
  - DOMAIN-SUFFIX,mzstatic.com,DIRECT
  - DOMAIN-SUFFIX,bing.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com,DIRECT
  - DOMAIN-SUFFIX,icloud-content.com,DIRECT
  - DOMAIN-SUFFIX,microsoft.com,DIRECT
  - DOMAIN-SUFFIX,live.com,DIRECT
  - DOMAIN-SUFFIX,office.com,DIRECT
  - DOMAIN-SUFFIX,google.com,select
  - DOMAIN-SUFFIX,youtube.com,select
  - DOMAIN-SUFFIX,ytimg.com,select
  - DOMAIN-SUFFIX,googlevideo.com,select
  - DOMAIN-SUFFIX,.goog,select
  - DOMAIN-SUFFIX,googleapis.com,select
  - DOMAIN-SUFFIX,ggpht.com,select
  - DOMAIN-SUFFIX,googleusercontent.com,select
  - DOMAIN-SUFFIX,googleapis-cn.com,select
  - DOMAIN-SUFFIX,doubleclick.net,select
  - DOMAIN-SUFFIX,googleadservices.com,select
  - DOMAIN-SUFFIX,googlesyndication.com,select
  - DOMAIN-SUFFIX,github.com,select
  - DOMAIN-SUFFIX,openwrt.org,select
  - DOMAIN-SUFFIX,truepeoplesearch.net,select
  - DOMAIN-SUFFIX,beenverified.com,select
  - DOMAIN-SUFFIX,openai.com,select
  - DOMAIN-SUFFIX,ai.com,select
  - DOMAIN-SUFFIX,skk.moe,REJECT
  - DOMAIN-SUFFIX,drift.com,REJECT
  - DOMAIN-SUFFIX,ad.com,REJECT
  - DOMAIN-SUFFIX,hotjar.com,REJECT
  - DOMAIN-KEYWORD,google,select
  - DOMAIN-KEYWORD,github,select
  - DOMAIN-KEYWORD,openwrt,select
  #- SRC-IP-CIDR,192.168.1.201/32,DIRECT
  # optional param "no-resolve" for IP rules (GEOIP, IP-CIDR, IP-CIDR6)
  - IP-CIDR6,::/0,DIRECT,no-resolve
  - IP-CIDR6,::/0,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - GEOIP,CN,DIRECT
  - GEOIP,US,select
  - GEOIP,DE,select
  - GEOIP,JP,select
  #- DST-PORT,80,DIRECT
  #- SRC-PORT,7777,DIRECT
  #- RULE-SET,apple,REJECT # Premium only
  #- GEOSITE,gfw,select
  #- GEOSITE,CN,DIRECT
  - MATCH,DIRECT
EOF

    read -r -d '' mihomo_config_proxy_groups <<- 'EOF'

proxy-groups:
  # load-balance: The request of the same eTLD+1 will be dial to the same proxy.
  - name: "load-balance"
    type: load-balance
    proxies:
    %proxies_ip
    url: "https://cp.cloudflare.com/generate_204"
    interval: 300
    strategy: round-robin # 可选 round-robin 和 sticky-sessions
 

  - name: "url-test"
    type: url-test
    proxies:
    %proxies_ip
    url: "https://cp.cloudflare.com/generate_204"
    tolerance: 150
    lazy: true
    interval: 300
    
  - name: select
    type: select
    disable-udp: false
    proxies:
      - load-balance
      - url-test

EOF


}


auto_mihomo_config_ip_by_CloudflareSpeedTest(){
    read -r -d '' mihomo_config_proxie_ws <<- 'EOF'

  - name: vmess-ws_%s
    type: vmess
    server: %s
    port: 443 
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

EOF

    read -r -d '' mihomo_config_proxie_grpc <<- 'EOF'

#  - name: vmess-grpc_%s
#    server: %s
#    port: 443
#    type: vmess
#    uuid: 
#    alterId: 0
#    cipher: auto
#    network: grpc
#    tls: true
#    servername: 
#    skip-cert-verify: false
#    grpc-opts:
#       grpc-service-name: ""

  - name: vmess-grpc_%s
    type: vmess
    server: %s
    port: 443
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

EOF


    if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST ]; then
      
      if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt ] ; then
        rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv6.txt
        #ulimit -v `free -k | awk 'NR==2{print $2 * 2 }'` 2>/dev/null
        #$path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST -httping -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ipv6.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv6.txt -t 2 -dn 5 -n 10
      fi
      if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ip.txt ] ; then
        rm -fr $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv4.txt
        ulimit -v `free -k | awk 'NR==2{print $2 * 2 }'` 2>/dev/null
        $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/CloudflareST -httping -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/ip.txt -o $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv4.txt -t 2 -dn 5 -n 10
      fi
      
    fi
    
    ipv6=''
    ipv4=''
    if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv6.txt ] || [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv4.txt ] ; then
      if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv6.txt ] ; then
        ipv6=`cat $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv6.txt | awk  -F',' 'NR>1 {print $1}'`
      fi
      if [ -f $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv4.txt ] ; then
        ipv4=`cat $path/CloudflareSpeedTest$latest_version_CloudflareSpeedTest/result_ipv4.txt | awk  -F',' 'NR>1 {print $1}'`
      fi
    fi


    
    if [ -n "$ipv4" ] || [ -n "$ipv6" ] ; then

      mihomo_config_proxie_ip=''
      for ip in $ipv4
      do 
          mihomo_config_proxie_ip="$mihomo_config_proxie_ip

  ${mihomo_config_proxie_ws//%s/$ip}"
      done
      for ip in $ipv6
      do 
          mihomo_config_proxie_ip="$mihomo_config_proxie_ip

  ${mihomo_config_proxie_grpc//%s/$ip}"
      done


      proxies_ip=''
      for ip in $ipv4
      do 
          proxies_ip="$proxies_ip   - vmess-ws_$ip
    "
      done
      for ip in $ipv6
      do 
          proxies_ip="$proxies_ip   - vmess-grpc_$ip
    "
      done


      echo "${mihomo_config_begin}
  ${mihomo_config_hosts}${mihomo_config_proxie_ip}

${mihomo_config_proxy_groups//%proxies_ip/$proxies_ip}

${mihomo_config_end}" > /etc/openclash/config/config.yaml

	
    fi


    if ! [ -e /www/config.yaml ] ; then                                               
       ln -s /etc/openclash/config/config.yaml /www/config.yaml
    fi
}


download_openclash(){
 latest_version_openclash=`curl --retry 10 --retry-max-time 360 -X GET  --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://api.github.com/repos/vernesong/OpenClash/tags' -s | awk '/name/{print $0; exit;}' | awk '/name/{print $0; exit;}' | awk -F '"' '{print $4}'`
 current_version_openclash="v`opkg find luci-app-openclash* | awk -F ' ' '{print $3}'`"
 echo "$latest_version_openclash $current_version_openclash"
  if [ -n "$current_version_openclash" ] && [ -n "$latest_version_openclash" ] && [ "$latest_version_openclash" != "$current_version_openclash" ]
  then
    rm -fr $path/openclashv*
    echo "download $path/openclash$latest_version_openclash"
    mkdir $path/openclash$latest_version_openclash
    curl --retry 10 --retry-max-time 360 -H "Cache-Control: no-cache" -fsSL https://github.com/vernesong/OpenClash/releases/download/$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk -o $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk
    if [ -f $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk ]; then
      /etc/init.d/openclash stop
      echo "$path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk"
      ulimit -v unlimited 2>/dev/null
      opkg install $path/openclash$latest_version_openclash/luci-app-openclash_`echo $latest_version_openclash | awk '{print substr($1,2)}'`_all.ipk
      uci -q set openclash.config.enable=1
      echo "$latest_version_openclash" > /tmp/openclash_last_version
      echo "" > /usr/share/openclash/openclash_version.sh
      echo "" > /usr/lib/lua/luci/view/openclash/developer.htm
      rm -fr /usr/share/openclash/ui/yacd
      /etc/init.d/openclash restart
    fi
  fi

  begin_line=`awk '/^start_run_core()/{print NR; exit;}' /etc/init.d/openclash`
  end_line=`awk 'NR>'$begin_line' && /^}/ {print NR; exit;}' /etc/init.d/openclash`

  ulimit_v=0
  if [ "`awk 'NR=='$begin_line'+4 {print $0}' /etc/init.d/openclash`" = "   ulimit -v unlimited 2>/dev/null" ]; then
    sed -i ''$begin_line','$end_line' s/ulimit -v unlimited 2>\/dev\/null/ulimit -v `free -k | awk '"'NR==2{print \$2 * 1.5}'"'` 2>\/dev\/null/' /etc/init.d/openclash

    ulimit_v=1
  fi

  add_oom=0
  if [ "`awk 'NR=='$end_line'-2 {print $0}' /etc/init.d/openclash`" = "   uci -q set openclash.config.config_reload=1" ] && [ "`awk 'NR=='$end_line'-3 {print $0}' /etc/init.d/openclash`" = "   fi" ]; then
    add_line=$(($end_line-2))
    sed -i ''$add_line' i\   LOG_OUT "Step 4.1: clash_pid:\$clash_pid oom_score_adj:\$oom_score_adj_value"' /etc/init.d/openclash
    sed -i ''$add_line' i\   oom_score_adj_value=`cat /proc/\$clash_pid/oom_score_adj`' /etc/init.d/openclash
    sed -i ''$add_line' i\   echo "-1000" > /proc/\$clash_pid/oom_score_adj' /etc/init.d/openclash
    sed -i ''$add_line' i\   clash_pid=`ps |grep \$CLASH | grep nobody | grep -v '"'grep'"'  | awk '"'{print \$1}'"' | tr "\\n" " "|sed '"'s/.$//'"'`' /etc/init.d/openclash

    add_oom=1
  fi
  if [ $ulimit_v = 1 ] && [ $add_oom = 1 ]; then
    uci -q set openclash.config.enable=1
    /etc/init.d/openclash restart
    end_line=`awk 'NR>'$begin_line' && /^}/ {print NR; exit;}' /etc/init.d/openclash`
  fi
  
  awk 'NR>'$begin_line'&&NR<'$end_line'+1{print $0}' /etc/init.d/openclash

}

update
init_mihomo_config
downloadCloudflareSpeedTest
install_mihomo
/etc/init.d/openclash stop
auto_mihomo_config_ip_by_CloudflareSpeedTest
/etc/init.d/openclash restart
download_openclash

#ulimit -v `free -k | awk 'NR==2{print $2 * 1.5 }'` 2>/dev/null
#clash_pid=`ps |grep $CLASH | grep nobody | grep -v 'grep'  | awk '{print $1}' | tr "\\n" " "|sed 's/.$//'`
#echo "-1000" > /proc/$clash_pid/oom_score_adj
#oom_score_adj_value=`cat /proc/$clash_pid/oom_score_adj`
#LOG_OUT "Step 4.1: clash_pid:$clash_pid oom_score_adj:$oom_score_adj_value"
#opkg update
#opkg remove dnsmasq wpad-basic-wolfssl
#opkg install kmod-tcp-bbr  wpad-openssl tar
#0 20 * * * /root/openclash_auto_config/openclash_mihomo_auto_config.sh > /root/openclash_auto_config/start.log 2>&1
