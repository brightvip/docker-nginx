FROM nginx:latest

RUN apt-get update -y && apt upgrade -y && apt-get install -y curl bash unzip openssl procps


COPY bin /usr/app/bin
COPY lib /usr/app/lib

CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" \
    && sync /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
