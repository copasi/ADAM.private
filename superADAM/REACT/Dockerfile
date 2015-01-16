FROM phusion/baseimage:0.9.15
MAINTAINER Thibauld Favre <thibauld@fastmail.com>
RUN apt-get update
RUN apt-get install -y ruby2.0 aptitude
RUN aptitude -y install build-essential
ADD run.rb /home/REACT/
ADD ./src /home/REACT/src/
ADD ./algorun /home/REACT/algorun/
RUN cd /home/REACT/
ENV REACT_HOME /home/REACT/
RUN ["/usr/bin/ruby","/home/REACT/run.rb","make"]
EXPOSE 31331
ENTRYPOINT ["/usr/bin/ruby","/home/REACT/run.rb","start"]
