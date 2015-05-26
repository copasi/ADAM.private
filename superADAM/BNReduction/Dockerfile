FROM phusion/baseimage:0.9.16

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

# Lines to add BNReduction algorithm
ADD Macaulay2-key /home/BNReduction/
ADD run.rb /home/BNReduction/
ADD ./algorun/*.rb /home/BNReduction/algorun/
ADD ./algorun/web/index.html /home/BNReduction/algorun/web/
ADD ./algorun/web/js /home/BNReduction/algorun/web/js/
ADD ./algorun/web/css /home/BNReduction/algorun/web/css/
ADD ./src /home/BNReduction/src/


# Lines to install Macaulay2 and download Boost library
RUN apt-get update && \
apt-get install -y ruby2.0 build-essential perl && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
echo "deb http://www.math.uiuc.edu/Macaulay2/Repositories/Ubuntu trusty main" >> /etc/apt/sources.list && \
apt-key add /home/BNReduction/Macaulay2-key && \
apt-get update -q && \
apt-get install -y -q macaulay2 && \
apt-get install -y wget && \
wget -O /home/BNReduction/src/boost_1_55_0.tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2 && \
tar --bzip2 -xf /home/BNReduction/src/boost_1_55_0.tar.bz2 -C /home/BNReduction/src/ && \
rm /home/BNReduction/src/boost_1_55_0.tar.bz2 && \
make -C /home/BNReduction/src/ clean && \
make -C /home/BNReduction/src/ install && \
rm -r /home/BNReduction/src/boost_1_55_0/

ENV CODE_HOME /home/BNReduction/

EXPOSE 8765

ENTRYPOINT ["/usr/bin/ruby","/home/BNReduction/run.rb","start"]
