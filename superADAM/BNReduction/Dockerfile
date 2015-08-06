# Fill files in algorun_info folder and put your source code in src folder
# Don't change the following three lines
FROM algorun/algorun
ADD ./algorun_info /home/algorithm/web/algorun_info/
ADD ./src /home/algorithm/src/
ADD Macaulay2-key /home/algorithm/

# Install any algorithm dependencies here
RUN apt-get update && \
apt-get install -y wget && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
echo "deb http://www.math.uiuc.edu/Macaulay2/Repositories/Ubuntu trusty main" >> /etc/apt/sources.list && \
apt-key add /home/algorithm/Macaulay2-key && \
apt-get update -q && \
apt-get install -y -q macaulay2 && \
wget -O /home/algorithm/src/boost_1_55_0.tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.bz2 && \
tar --bzip2 -xf /home/algorithm/src/boost_1_55_0.tar.bz2 -C /home/algorithm/src/ && \
rm /home/algorithm/src/boost_1_55_0.tar.bz2 && \
make -C /home/algorithm/src/ clean && \
make -C /home/algorithm/src/ install && \
rm -r /home/algorithm/src/boost_1_55_0/
RUN apt-get install -y ruby2.0

# [Optional] Sign your image
MAINTAINER Abdelrahman Hosny <abdelrahman.hosny@hotmail.com>
