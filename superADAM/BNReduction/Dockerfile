FROM phusion/baseimage:0.9.16

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

RUN apt-get update
RUN apt-get install -y ruby2.0 build-essential
RUN apt-get install perl
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Lines to install Macaulay2
RUN echo "deb http://www.math.uiuc.edu/Macaulay2/Repositories/Ubuntu trusty main" >> /etc/apt/sources.list
ADD Macaulay2-key /home/BNReduction/
RUN apt-key add /home/BNReduction/Macaulay2-key
RUN apt-get update -q
RUN apt-get install -y -q macaulay2

# Lines to add BNReduction algorithm
ADD run.rb /home/BNReduction/
ADD ./algorun/*.rb /home/BNReduction/algorun/
ADD ./algorun/web/index.html /home/BNReduction/algorun/web/
ADD ./algorun/web/js /home/BNReduction/algorun/web/js/
ADD ./algorun/web/css /home/BNReduction/algorun/web/css/
ADD ./src /home/BNReduction/src/

# Download boost library
RUN apt-get install -y wget
RUN wget -O /home/BNReduction/src/boost_1_55_0.tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2
RUN tar --bzip2 -xf /home/BNReduction/src/boost_1_55_0.tar.bz2 -C /home/BNReduction/src/
RUN rm /home/BNReduction/src/boost_1_55_0.tar.bz2

RUN make -C /home/BNReduction/src/ clean
RUN make -C /home/BNReduction/src/ install

ENV CODE_HOME /home/BNReduction/

EXPOSE 8765

ENTRYPOINT ["/usr/bin/ruby","/home/BNReduction/run.rb","start"]
