MFVSfixedpoints  : MFVSfixedpoints.o graph.o utils.o 
	g++ -o MFVSfixedpoints MFVSfixedpoints.o graph.o utils.o

MFVSfixedpoints.o : MFVSfixedpoints.cpp 
	g++ -c -o MFVSfixedpoints.o MFVSfixedpoints.cpp

graph.o : graph.cpp 
	g++ -c -o graph.o graph.cpp

utils.o : utils.cpp 
	g++ -c -o utils.o utils.cpp

clean:
	rm *.o MFVSfixedpoints 
