FROM ubuntu:latest
RUN apt-get update -y
RUN apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev mercurial wget && mkdir /docker-entrypoint.d
RUN wget http://nginx.org/download/nginx-1.21.6.tar.gz
RUN tar -zxvf nginx-1.21.6.tar.gz
RUN hg clone http://hg.nginx.org/njs
RUN ls -lah /njs/nginx/
WORKDIR /njs
RUN ./configure 
RUN make
WORKDIR $HOME/nginx-1.21.6
RUN ./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_auth_request_module --modules-path=/usr/local/nginx/modules --with-http_v2_module --add-module=/njs/nginx
RUN make
RUN make install 
COPY docker-entrypoint.sh /
COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY 30-tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]