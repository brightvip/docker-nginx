#!/bin/bash

#根目录
path='/usr/app/lib/trojan-go/bin/'



conf(){
 mkdir -p /usr/app/lib/trojan-go

cat << EOF >/usr/app/lib/trojan-go/configws.json.template
{
  "run_type": "server",
  "local_addr": "localtrojanaddr",
  "local_port": localtrojanport,
  "remote_addr": "127.0.0.1",
  "remote_port": remotetrojanport,
  "password": ["CLIENTSID"],
  "log_level": 5,
  "ssl": {
    "verify": false,
    "verify_hostname": false,
    "cert":"/usr/app/lib/trojan-go/server.crt",
    "key":"/usr/app/lib/trojan-go/server.key",
    "key_password": "",
    "sni": "",
    "alpn": [
      "http/1.1"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "",
    "fallback_addr": "",
    "fallback_port": 0,
    "fingerprint": ""
  },
  "websocket": {
    "enabled": true,
    "path": "WSPATH"
  }
}
EOF

 openssl genrsa -out /usr/app/lib/trojan-go/server.key 1024
openssl req -new -key /usr/app/lib/trojan-go/server.key -out /usr/app/lib/trojan-go/server.csr << EOF









EOF
 openssl x509 -req -in /usr/app/lib/trojan-go/server.csr -out /usr/app/lib/trojan-go/server.crt -signkey /usr/app/lib/trojan-go/server.key -days 3650


 sed -e 's/serverName/trojan/' -e 's/serverPass/127.0.0.1:9200/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/trojan-go/trojan.us
 cat /usr/app/lib/trojan-go/trojan.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}/t"':' -e 's/proxyPass/https:\/\/trojan/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/trojan-go/trojan.ws
 sed -i '27 r /usr/app/lib/trojan-go/trojan.ws' /etc/nginx/conf.d/default.conf
 sed -e 's/localtrojanaddr/127.0.0.1/' -e 's/localtrojanport/9200/'   -e 's:remotetrojanport:'"${PORT}"':'   -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${WSPATH}/t"':' /usr/app/lib/trojan-go/configws.json.template > /usr/app/lib/trojan-go/trojan.ws.json
 
 sleep 10s
 nginx  -s reload
}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/p4gefau1t/trojan-go/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/p4gefau1t/trojan-go/releases/download/";
        file="/trojan-go-linux-amd64.zip";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/trojan-go-linux-amd64.zip
        unzip -q $path$latest_version/trojan-go-linux-amd64.zip -d $path$latest_version/
            #循环删除其他版本
            for vfile in ` ls $path | grep -v $latest_version`
            do
                
                vfilepid=`ps -ef |grep $vfile | grep -v 'grep'  | awk '{print $1}' | tr "\n" " "`
                if [ ! -z "$vfilepid" ]; then  
                    echo $vfilepid
                    kill -9 $vfilepid
                fi 
                rm -fr $path$vfile
            
            done

        nohup $path$latest_version/trojan-go -config /usr/app/lib/trojan-go/trojan.ws.json  >/usr/app/lib/nginx/html/configt.html 2>&1 &
        echo `date`"-"$latest_version > /usr/app/lib/nginx/html/trojan-goversion.html
    fi
}
start


#由于不支持crontab 改用 while
#由于容器长时间无连接会被销毁 有新连接时会被创建
#基本不会通过while进行更新会在每次容器创建时更新
while true
do
    sleep 1d
    echo start
    start
    
done
