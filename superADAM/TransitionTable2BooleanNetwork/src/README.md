Transforms truth tables to Boolean formulas.
BEFORE USING:
1. cd quinemcccluskey-master
2. make clean; make all

USAGE: ./tt2boolnet.sh inputfile
OUTPUT (on command line): a string where each line is the i-th function 

INPUT: a file of the form: (note that there are no spaces after the "keywords"
num_functions
n

function
1
inputs
xi xj kl
truth_table
00...000 f(00...000)
00...001 f(00...001)
.
.
.
.

function
2
.
.
.

NOTE: The code can handle inputs such as x1,x2,.(e.g. variables), and k1, k2, (e.g. parameters).
See examples for details.


