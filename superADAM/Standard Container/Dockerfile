FROM phusion/baseimage:0.9.16

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

RUN apt-get update && \
apt-get install -y ruby2.0 build-essential perl && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD run.rb /home/algorithm/
ADD ./algorun/web/index.html /home/algorithm/algorun/web/
ADD ./algorun/web/js /home/algorithm/algorun/web/js/
ADD ./algorun/web/css /home/algorithm/algorun/web/css/
ADD ./algorun/*.rb /home/algorithm/algorun/

ENV CODE_HOME /home/algorithm/

EXPOSE 8765

ENTRYPOINT ["/usr/bin/ruby","/home/algorithm/run.rb","start"]
