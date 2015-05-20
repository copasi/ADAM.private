FROM mikestillman/macaulay2:1.7-0
MAINTAINER Mike Stillman <mikestillman1@gmail.com>
RUN apt-get update
RUN apt-get install -y ruby2.0 build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER M2
ADD ../share/* /home/M2/adam/superADAM/share/
ADD ./src/* /home/M2/adam/superADAM/basicRevEng/src/
ADD ./test/* /home/M2/adam/superADAM/basicRevEng/test/
ENV ADAM_ROOT /home/M2/adam
ENV PATH $ADAM_ROOT/superADAM/share:$PATH
