#!/bin/bash

#curl -o /dev/null -s -w "%{url} %{http_code} %{time_total}\n" $line

# 要读取的 URL
url="https://raw.github.tax/wwb521/live/main/tv.m3u"

# 使用 curl 获取 URL 内容并保存到变量中
content=$(curl -s "$url")

lines=()  # 创建一个空数组

# 按行处理内容
line_index=-1

channel_name=''

time_total=9999

while IFS= read -r line; do
    line_index=$((line_index + 1))
    if [ $line_index -eq 0 ]; then
	line_index=0
	lines+=("$line")
    elif [ $line_index -eq 2 ]; then
  	line_index=0
	
	# 获取协议和主机名
	protocol=$(echo "$line" | cut -d '/' -f 1)
	protocol=$(echo "${protocol%?}")
	
	hostname=$(echo "$line" | cut -d '/' -f 3)
	
	path=$(echo "$line" | cut -d '/' -f 4-) 
	port=''
	# 判断是否包含端口
	if [[ "$hostname" =~ "]" ]]; then
		if ! [[ "$hostname" =~ "]:" ]]; then
			port=':80'
    			if [ "$protocol" = "https" ]; then
				port=':443'
    			fi

		fi
	else
		if ! [[ "$hostname" =~ ":" ]]; then
			port=':80'
    			if [ "$protocol" = "https" ]; then
				port=':443'
    			fi

		fi	

	fi

	line="$protocol://$hostname$port/$path"
	curl_line=`curl -m 5 -o /dev/null -s -w "%{url} %{http_code} %{time_total}" $line`

	if [ `echo "$curl_line" | awk '{if ($2 == 200 || $2 == 302) print "ok"}'` == "ok" ]; then
		length=${#lines[@]}
		if [ $length == "1" ] || [ "${lines[$((length-2))]}" != "$channel_name" ]; then
			lines+=("$channel_name")
			lines+=("$line")
			time_total=`echo "$curl_line" | awk '{print $3}'`
		else
			url_time_total=`echo "$curl_line" | awk '{print $3}'`
			time_ok=`awk -v num1="$time_total" -v num2="$url_time_total" 'BEGIN { if (num1 > num2) print "ok" }'`
			if [ "$time_ok" == "ok" ]; then

				lines[$((length-1))]="$line"
				time_total=$url_time_total

			fi
		fi
	fi
	
    else
	channel_name=$line
    fi
done <<< "$content"

printf "%s\n" "${lines[@]}" > /www/mytv.m3u