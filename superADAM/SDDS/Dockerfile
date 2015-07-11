FROM ahosny/algorun:0.9.1

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

# Don't forget to fill files in algorun_info folder and put your source code in src folder
ADD ./algorun_info /home/algorithm/web/algorun_info/
ADD ./src /home/algorithm/src/

# Add any algorithm dependencies here
RUN apt-get update
RUN apt-get install -y ruby2.0 perl cpanminus libgetopt-euclid-perl libjson-perl build-essential
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN cpanm JSON::Parse

# Add your command to execute an algorithm as environment variable EXEC_COMMAND
ENV EXEC_COMMAND "ruby Sdds.rb"

# Add your command options (if any) as environment variable COMMAND_OPTIONS
# EXAMPLE: ENV COMMAND_OPTIONS "-c"

# If you specified -f as a command line option for the output file, ignore this step
# If your code outputs results to a hard-coded file name, specify it as environment variable OUTPUT_FILE_NAME
ENV OUTPUT_FILE_NAME "output.txt"

# If your algorithm uses some default configuration, pass them as environment variables
# ENV PARAM_1 value1
# ENV PARAM_2 value2
