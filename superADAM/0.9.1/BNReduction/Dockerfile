FROM ahosny/algorun

MAINTAINER Abdelrahman H. Ibrahim <abdelrahman.hosny@hotmail.com>

# Add your algorithm code folder to /home/algorithm/src/
ADD Macaulay2-key /home/algorithm/
ADD ./src /home/algorithm/src/

# Add any algorithm dependencies here
RUN apt-get update && \
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

# Add your command to execute an algorithm as environment variable EXEC_COMMAND
ENV EXEC_COMMAND "ruby BNReduction.rb"

# Add your command options (if any) as environment variable COMMAND_OPTIONS
# ENV COMMAND_OPTIONS "-c"

# If you specified -f as a command line option for the output file, ignore this step
# If your code outputs results to a hard-coded file name, specify it as environment variable OUTPUT_FILE_NAME
ENV OUTPUT_FILE_NAME "output.txt"



