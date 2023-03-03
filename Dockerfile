FROM ubuntu:22.04

RUN apt update

#http://nginx.org/en/linux_packages.html#Ubuntu
RUN apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y \
    && curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
           | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
       http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
           | tee /etc/apt/sources.list.d/nginx.list

RUN apt update
#by default it's v3, but I fix the version just to be sure
RUN apt install openssl=3.0.2-0ubuntu1.8 -y
RUN apt install nginx=1.23.3-1~jammy -y

#for production this is definitely a bad idea
RUN mkdir /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=US/O=test/CN=test" -keyout /etc/nginx/ssl/pkey.key -out /etc/nginx/ssl/cert.crt

RUN mkdir /etc/nginx/data
RUN echo "hello" > /etc/nginx/data/index.html

RUN fallocate -l 10M /etc/nginx/data/10M.html
RUN fallocate -l 1M /etc/nginx/data/1M.html
RUN fallocate -l 512kb /etc/nginx/data/512kb.html
RUN fallocate -l 10kb /etc/nginx/data/10kb.html

STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
