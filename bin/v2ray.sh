#!/bin/bash

#根目录
path='/usr/app/lib/v2ray/bin/'



conf(){
 mkdir -p /usr/app/lib/v2ray/
 
cat << EOF >/usr/app/lib/v2ray/configws.json.template
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": v2rayport,
      "listen": "v2listen",
      "protocol": "v2rayprotocol",
      "settings": {
        "clients": [
          {
            "id": "CLIENTSID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "WSPATH",
          "maxEarlyData": 1024,
          "earlyDataHeaderName":"Sec-WebSocket-Protocol"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

cat << EOF >/usr/app/lib/v2ray/configgun.json.template
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": v2rayport,
      "listen": "v2listen",
      "protocol": "v2rayprotocol",
      "settings": {
        "clients": [
          {
            "id": "CLIENTSID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "gun",
        "security": "none",
        "grpcSettings": {
              "serviceName": "GUNSERVICENAME"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

 sed -e 's/serverName/v2ray/' -e 's/serverPass/127.0.0.1:9300/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/v2ray/v2ray.us
 cat /usr/app/lib/v2ray/v2ray.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}"':' -e 's/proxyPass/http:\/\/v2ray/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/v2ray/v2rayl.ws
 sed -i '35 r /usr/app/lib/v2ray/v2rayl.ws' /etc/nginx/conf.d/default.conf
 sed -e 's/v2rayport/9300/'  -e 's/v2rayprotocol/vless/' -e 's/v2listen/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${WSPATH}"':' /usr/app/lib/v2ray/configws.json.template > /usr/app/lib/v2ray/v2rayl.ws.json
 
 
 sed -e 's/serverName/v2raym/' -e 's/serverPass/127.0.0.1:9301/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/v2ray/v2raym.us
 cat /usr/app/lib/v2ray/v2raym.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}/m"':' -e 's/proxyPass/http:\/\/v2raym/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/v2ray/v2raym.ws
 sed -i '35 r /usr/app/lib/v2ray/v2raym.ws' /etc/nginx/conf.d/default.conf
 sed -e 's/v2rayport/9301/'  -e 's/v2rayprotocol/vmess/' -e 's/v2listen/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${WSPATH}/m"':' /usr/app/lib/v2ray/configws.json.template > /usr/app/lib/v2ray/v2raym.ws.json
 

 sed -e 's/serverName/v2raygun/' -e 's/serverPass/127.0.0.1:9302/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/v2ray/v2raygun.us
 cat /usr/app/lib/v2ray/v2raygun.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}gun"':' -e 's/proxyPass/grpc:\/\/v2raygun/' /usr/app/lib/nginx/grpc_proxy.conf.template > /usr/app/lib/v2ray/v2rayl.gun
 sed -i '35 r /usr/app/lib/v2ray/v2rayl.gun' /etc/nginx/conf.d/default.conf
 sed -e 's/v2rayport/9302/'  -e 's/v2rayprotocol/vless/' -e 's/v2listen/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:GUNSERVICENAME:'"$(echo $WSPATH | awk '{ string=substr($0,2); print string; }')gun"':' /usr/app/lib/v2ray/configgun.json.template > /usr/app/lib/v2ray/v2rayl.gun.json
 

 sed -e 's/serverName/v2raymgun/' -e 's/serverPass/127.0.0.1:9303/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/v2ray/v2raymgun.us
 cat /usr/app/lib/v2ray/v2raymgun.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}mgun"':' -e 's/proxyPass/grpc:\/\/v2raymgun/' /usr/app/lib/nginx/grpc_proxy.conf.template > /usr/app/lib/v2ray/v2raym.gun
 sed -i '35 r /usr/app/lib/v2ray/v2raym.gun' /etc/nginx/conf.d/default.conf
 sed -e 's/v2rayport/9303/'  -e 's/v2rayprotocol/vmess/' -e 's/v2listen/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:GUNSERVICENAME:'"$(echo $WSPATH | awk '{ string=substr($0,2); print string; }')mgun"':' /usr/app/lib/v2ray/configgun.json.template > /usr/app/lib/v2ray/v2raym.gun.json
 
 
 sleep 10s
 nginx  -s reload
}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/v2fly/v2ray-core/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/v2fly/v2ray-core/releases/download/";
        file="/v2ray-linux-64.zip";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/v2ray-linux-64.zip
        unzip -q $path$latest_version/v2ray-linux-64.zip -d $path$latest_version/
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

        nohup $path$latest_version/v2ray -config /usr/app/lib/v2ray/v2rayl.ws.json  >/usr/app/lib/nginx/html/config.html 2>&1 & 
        nohup $path$latest_version/v2ray -config /usr/app/lib/v2ray/v2raym.ws.json  >/usr/app/lib/nginx/html/configm.html 2>&1 &
        nohup $path$latest_version/v2ray -config /usr/app/lib/v2ray/v2rayl.gun.json  >/usr/app/lib/nginx/html/configgun.html 2>&1 &
        nohup $path$latest_version/v2ray -config /usr/app/lib/v2ray/v2raym.gun.json  >/usr/app/lib/nginx/html/configmgun.html 2>&1 &

        echo `date`"-"$latest_version > /usr/app/lib/nginx/html/v2rayversion.html
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
