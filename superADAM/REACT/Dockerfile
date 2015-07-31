FROM ahosny/algorun:0.9.2

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

# Don't forget to fill files in algorun_info folder and put your source code in src folder
# ADD ./algorun_info /home/algorithm/web/algorun_info/
# ADD ./src /home/algorithm/src/

# Add any algorithm dependencies here
RUN apt-get update && \
apt-get install -y ruby2.0 build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./algorun_info /home/algorithm/web/algorun_info/
ADD ./src /home/algorithm/src/

RUN ruby /home/algorithm/src/run.rb make
# RUN ["/usr/bin/ruby","/home/algorithm/src/run.rb","make"]
RUN rm -f src/*.o

# Add your command to execute an algorithm as environment variable EXEC_COMMAND
ENV EXEC_COMMAND "ruby React.rb"

# Add your command options (if any) as environment variable COMMAND_OPTIONS
# EXAMPLE: ENV COMMAND_OPTIONS "-c"

# If you specified -f as a command line option for the output file, ignore this step
# If your code outputs results to a hard-coded file name, specify it as environment variable OUTPUT_FILE_NAME
ENV OUTPUT_FILE_NAME "output.txt"
