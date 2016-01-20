# Fill files in algorun_info folder and put your source code in src folder
# Don't change the following three lines
FROM algorun/algorun
ADD ./algorun_info /home/algorithm/web/algorun_info/
ADD ./src /home/algorithm/src/

ADD Macaulay2-key /home/algorithm/
RUN echo "deb http://www.math.uiuc.edu/Macaulay2/Repositories/Ubuntu trusty main" >> /etc/apt/sources.list && \
apt-key add /home/algorithm/Macaulay2-key && \
apt-get update -q && \
apt-get install -y -q macaulay2
RUN apt-get update
RUN apt-get install -y ruby
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo M2 --script \"\$\@\" > /usr/bin/M2script
RUN chmod +x /usr/bin/M2script
ENV ADAM_ROOT /home/M2/adam/
ENV PATH /home/M2:$ADAM_ROOT/superADAM/share:$PATH
ADD share/ /home/M2/adam/superADAM/share/

# [Optional] Sign your image
MAINTAINER Abdelrahman Hosny <abdelrahman.hosny@hotmail.com>
