FROM phusion/baseimage:0.9.16

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

ADD run.rb /home/cyclone/
ADD CMakeLists.txt /home/cyclone/
ADD ./algorun/web/index.html /home/cyclone/algorun/web/
ADD ./algorun/web/js /home/cyclone/algorun/web/js/
ADD ./algorun/web/css /home/cyclone/algorun/web/css/
ADD ./algorun/*.rb /home/cyclone/algorun/
ADD ./src /home/cyclone/src/

RUN apt-get update && \
apt-get install -y ruby2.0 build-essential perl && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get update -q && \
apt-get install -y wget
RUN wget http://www.cmake.org/files/v2.8/cmake-2.8.3.tar.gz && \
tar -xf cmake-2.8.3.tar.gz
RUN cd cmake-2.8.3 && \
./bootstrap && \
make -C /cmake-2.8.3/ && \
make -C /cmake-2.8.3/ install && \
cmake /home/cyclone/CMakeLists.txt && \
make -C /home/cyclone/ clean && \
make -C /home/cyclone/ install

ENV CODE_HOME /home/cyclone/

EXPOSE 8765

ENTRYPOINT ["/usr/bin/ruby","/home/cyclone/run.rb","start"]
