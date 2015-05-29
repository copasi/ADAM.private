# FROM mikestillman/macaulay2:1.7-0
FROM ubuntu:14.04

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

RUN apt-get update
RUN apt-get install -y ruby2.0 build-essential
RUN apt-get install gcc -y
RUN apt-get install g++
RUN apt-get install perl
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Lines to install Macaulay2
RUN echo "deb http://www.math.uiuc.edu/Macaulay2/Repositories/Ubuntu trusty main" >> /etc/apt/sources.list
ADD Macaulay2-key /home/BNReduction/
RUN apt-key add /home/BNReduction/Macaulay2-key
RUN apt-get update -q
RUN apt-get install -y -q macaulay2
RUN cd ~

ADD run.rb /home/BNReduction/
ADD ./algorun/*.rb /home/BNReduction/algorun/
ADD ./algorun/web/index.html /home/BNReduction/algorun/web/
ADD ./algorun/web/js /home/BNReduction/algorun/web/js/
ADD ./algorun/web/css /home/BNReduction/algorun/web/css/
ADD ./src /home/BNReduction/src/

RUN make -C /home/BNReduction/src/ clean
RUN make -C /home/BNReduction/src/ install

EXPOSE 8765
ENTRYPOINT ["/usr/bin/ruby","/home/BNReduction/run.rb","start"]
