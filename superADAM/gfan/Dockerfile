FROM mikestillman/macaulay2:1.7-0
MAINTAINER Mike Stillman <mikestillman1@gmail.com>
RUN apt-get update
RUN apt-get install -y ruby2.0
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo M2 --script \"\$\@\" > /usr/bin/M2script
RUN chmod +x /usr/bin/M2script
ENV ADAM_ROOT /home/M2/adam/
ENV PATH /home/M2/src:$ADAM_ROOT/superADAM/share:$PATH
ADD share/ /home/M2/adam/superADAM/share/

ADD gfan/run.rb /home/M2/
ADD gfan/algorun/*.rb /home/M2/algorun/
ADD gfan/algorun/web/index.html /home/M2/algorun/web/
ADD gfan/algorun/web/js /home/M2/algorun/web/js/
ADD gfan/algorun/web/css /home/M2/algorun/web/css/
ADD gfan/src/* /home/M2/src/
ADD gfan/test/* /home/M2/test/

ENV CODE_HOME /home/M2
EXPOSE 8765
ENTRYPOINT ["/usr/bin/ruby","/home/M2/run.rb","start"]
