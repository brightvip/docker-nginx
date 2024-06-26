#!/bin/bash

#根目录
path='/usr/app/lib/Xray/bin/'



conf(){
 mkdir -p /usr/app/lib/Xray/
 
cat << EOF >/usr/app/lib/Xray/configws.json.template
{
  "log": {
    "access": "none",
    "error": "none",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": Xrayport,
      "listen": "Xlisten",
      "protocol": "Xrayprotocol",
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
          "earlyDataHeaderName": "Sec-WebSocket-Protocol",
          "acceptProxyProtocol": false
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

cat << EOF >/usr/app/lib/Xray/confighttpu.json.template
{
  "log": {
    "access": "none",
    "error": "none",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": Xrayport,
      "listen": "Xlisten",
      "protocol": "Xrayprotocol",
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
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "WSPATH",
          "acceptProxyProtocol": false
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

 sed -e 's/serverName/Xray/' -e 's/serverPass/127.0.0.1:9300/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/Xray/Xray.us
 cat /usr/app/lib/Xray/Xray.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}"':' -e 's/proxyPass/http:\/\/Xray/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/Xray/Xrayl.ws
 sed -i '35 r /usr/app/lib/Xray/Xrayl.ws' /etc/nginx/conf.d/default.conf
 sed -e 's/Xrayport/9300/'  -e 's/Xrayprotocol/vless/' -e 's/Xlisten/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${WSPATH}"':' /usr/app/lib/Xray/configws.json.template > /usr/app/lib/Xray/Xrayl.ws.json

 sync

 sed -e 's/serverName/Xrayhttpu/' -e 's/serverPass/127.0.0.1:9302/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/Xray/Xrayhttpu.us
 cat /usr/app/lib/Xray/Xrayhttpu.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}/httpu"':' -e 's/proxyPass/http:\/\/Xrayhttpu/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/Xray/Xraylhttpu.ws
 sed -i '35 r /usr/app/lib/Xray/Xraylhttpu.ws' /etc/nginx/conf.d/default.conf
 sed -e 's/Xrayport/9302/'  -e 's/Xrayprotocol/vless/' -e 's/Xlisten/127.0.0.1/' -e 's:CLIENTSID:'"${CLIENTSID}"':'  -e 's:WSPATH:'"${WSPATH}/httpu"':' /usr/app/lib/Xray/confighttpu.json.template > /usr/app/lib/Xray/Xrayl.httpu.json

}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/XTLS/Xray-core/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ -n "$latest_version" ] && [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/XTLS/Xray-core/releases/download/";
        file="/Xray-linux-64.zip";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/Xray-linux-64.zip
        unzip -q $path$latest_version/Xray-linux-64.zip -d $path$latest_version/
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

        nohup $path$latest_version/xray run -c /usr/app/lib/Xray/Xrayl.ws.json  >/usr/app/lib/nginx/html/config.html 2>&1 & 
        nohup $path$latest_version/xray run -c /usr/app/lib/Xray/Xrayl.httpu.json  >/usr/app/lib/nginx/html/confighttpu.html 2>&1 &

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
