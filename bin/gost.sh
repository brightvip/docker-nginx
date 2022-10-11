#!/bin/bash

#根目录
path='/usr/app/lib/gost/bin/'



conf(){
 mkdir -p /usr/app/lib/gost/
 

 sed -e 's/serverName/gost/' -e 's/serverPass/127.0.0.1:9200/' /usr/app/lib/nginx/upstream_server.conf.template > /usr/app/lib/gost/gost.us
 cat /usr/app/lib/gost/gost.us >> /etc/nginx/conf.d/upstream.conf
 sed -e 's:path:'"${WSPATH}/g"':' -e 's/proxyPass/http:\/\/gost/' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/gost/gost.ws
 sed -i '35 r /usr/app/lib/gost/gost.ws' /etc/nginx/conf.d/default.conf
 
}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/ginuerzh/gost/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/ginuerzh/gost/releases/download/";
        file="/gost-linux-amd64-`echo $latest_version | awk '{print substr($1,2)}'`.gz";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/gost-linux-amd64-`echo $latest_version | awk '{print substr($1,2)}'`.gz
        gzip -d $path$latest_version/gost-linux-amd64-`echo $latest_version | awk '{print substr($1,2)}'`.gz
        mv $path$latest_version/gost-linux-amd64-`echo $latest_version | awk '{print substr($1,2)}'` $path$latest_version/gost
        chmod +x $path$latest_version/gost
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
        
        nohup $path$latest_version/gost -L "relay+ws://${CLIENTSID}:${CLIENTSID}@:9200?path=${WSPATH}/g&rbuf=4096&wbuf=4096&compression=true" > /dev/null 2>&1 &

        echo `date`"-"$latest_version > /usr/app/lib/nginx/html/gostversion.html
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
