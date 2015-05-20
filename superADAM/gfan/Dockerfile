FROM mikestillman/macaulay2:1.7-0
MAINTAINER Mike Stillman <mikestillman1@gmail.com>
RUN apt-get update
RUN apt-get install -y ruby2.0 build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo M2 --script \"\$\@\" > /usr/bin/M2script
RUN chmod +x /usr/bin/M2script
ENV ADAM_ROOT /home/M2/adam/
ENV PATH /home/M2:$ADAM_ROOT/superADAM/share:$PATH
ADD share/ /home/M2/adam/superADAM/share/

ADD gfan/src/gfan /home/M2/
ADD gfan/src/gfan.m2 /home/M2/
ADD gfan/test/* /home/M2/test/
