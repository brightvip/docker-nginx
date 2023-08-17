#!/bin/bash

#根目录
path='/usr/app/lib/ttyd/bin/'



conf(){
 mkdir -p /usr/app/lib/ttyd
 sed -e 's:path:'"${WSPATH}"/ttyd':' -e 's/proxyPass/http:\/\/127.0.0.1:9400\//' /usr/app/lib/nginx/websocket_proxy.conf.template > /usr/app/lib/ttyd/ttyd.ws
 sed -i '35 r /usr/app/lib/ttyd/ttyd.ws' /etc/nginx/conf.d/default.conf
 
}
conf

#获取最新版本
get_latest_version(){
 latest_version=`curl -X HEAD -I --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0" 'https://github.com/tsl0922/ttyd/releases/latest' -s  | grep  'location: ' | awk -F "/" '{print $NF}'  | tr '\r' ' ' | awk '{print $1}'`
}

#运行程序
start(){
    #获取最新版本
    get_latest_version
    #判断文件夹是否存在
    if [ -n "$latest_version" ] && [ ! -d $path$latest_version ]; then
        #下载地址
        download="https://github.com/tsl0922/ttyd/releases/download/";
        file="/ttyd.x86_64";
        echo $download$latest_version$file
        
        #文件夹不存在
        mkdir -p $path$latest_version
        #下载文件
        curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL $download$latest_version$file -o $path$latest_version/ttyd.x86_64
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
         
        chmod +x $path$latest_version/ttyd.x86_64
        $path$latest_version/ttyd.x86_64 -p 9400 bash
        
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
