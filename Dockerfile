FROM nginx:latest

RUN apt-get update -y && apt upgrade -y && apt-get install -y curl bash unzip openssl procps


COPY bin /usr/app/bin
COPY lib /usr/app/lib
EXPOSE 8080
CMD /bin/bash -c "cat /usr/app/bin/start.sh | tr -d '\r'  | sh" \
    && nginx -g 'daemon off;'
