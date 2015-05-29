FROM phusion/baseimage:0.9.16

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

RUN apt-get update && \
apt-get install -y ruby2.0 && \
apt-get clean

ADD Server.rb /home/controller/
ADD ./web /home/controller/web

ENV CODE_HOME /home/controller/

EXPOSE 8765

ENTRYPOINT ["/usr/bin/ruby","/home/controller/Server.rb"]
