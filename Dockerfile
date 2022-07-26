FROM ubuntu:latest

# Information Labels
LABEL org.opencontainers.image.authors="hello@anky.it"
LABEL version="0.1"
LABEL description="Docker image to test latest version of the njs with nginx"
LABEL org.opencontainers.image.source = "https://github.com/ankyit/nginx-njs-compiled"

#Nginx Version as Argument
ARG NGINX_VER=1.22.0

#Create Nginx User 
RUN addgroup --system --gid 101 nginx
RUN adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx

#Update and install dependencies 
RUN apt-get update -y
RUN apt-get install -y --no-install-recommends build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev mercurial wget && mkdir /docker-entrypoint.d && rm -rf /var/lib/apt/lists/* && mkdir -p /usr/local/nginx/modules

#Set workdirectory to /tmp, download nginx source and extract 
WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
RUN tar -zxvf nginx-${NGINX_VER}.tar.gz

#Pull latest version of the njs from mercurial 
RUN hg clone http://hg.nginx.org/njs

#Set work dir to /tmp/njs and Compile the njs 
WORKDIR /tmp/njs
RUN ./configure && make

#Set workdir to /tmp/nginx-version, compile and install nginx 
WORKDIR /tmp/nginx-${NGINX_VER}
RUN ./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_auth_request_module --modules-path=/usr/local/nginx/modules --with-http_v2_module --add-dynamic-module=/tmp/njs/nginx
RUN make && make install && rm -rf /tmp/njs && rm -rf /tmp/nginx-${NGINX_VER}

#Copy best practices nginx files to the image 
COPY docker-entrypoint.sh /
COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY 30-tune-worker-processes.sh /docker-entrypoint.d

#Make shell scripts executable  
RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
RUN chmod +x /docker-entrypoint.d/20-envsubst-on-templates.sh
RUN chmod +x /docker-entrypoint.d/30-tune-worker-processes.sh

COPY njs/get_versions.js /etc/nginx/njs/get_versions.js
COPY nginx/default.conf /etc/nginx/nginx.conf

#Set entrypoint 
ENTRYPOINT ["bash","/docker-entrypoint.sh"]

#expose Port 
EXPOSE 80

#Avoid dropped connections (https://ubuntu.com/blog/avoiding-dropped-connections-in-nginx-containers-with-stopsignal-sigquit)
STOPSIGNAL SIGQUIT

#Run Nginx without halt 
CMD ["nginx", "-g", "daemon off;"]
