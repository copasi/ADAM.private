FROM ahosny/algorun:0.9.1

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

# Add your algorithm code foler to /home/algorithm/src/
ADD CMakeLists.txt /home/algorithm/
ADD ./src /home/algorithm/src/

# Add any algorithm dependencies here
RUN apt-get update && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
wget http://www.cmake.org/files/v2.8/cmake-2.8.3.tar.gz && \
tar -xf cmake-2.8.3.tar.gz
RUN cd cmake-2.8.3 && \
./bootstrap && \
make -C /cmake-2.8.3/ && \
make -C /cmake-2.8.3/ install && \
cmake /home/algorithm/CMakeLists.txt && \
make -C /home/algorithm/ clean && \
make -C /home/algorithm/ install

# Add your command to execute an algorithm as environment variable EXEC_COMMAND
ENV EXEC_COMMAND "ruby Cyclone.rb"

# Add your command options (if any) as environment variable COMMAND_OPTIONS
# ENV COMMAND_OPTIONS "-c"

# If you specified -f as a command line option for the output file, ignore this step
# If your code outputs results to a hard-coded file name, specify it as environment variable OUTPUT_FILE_NAME
ENV OUTPUT_FILE_NAME "output.txt"



