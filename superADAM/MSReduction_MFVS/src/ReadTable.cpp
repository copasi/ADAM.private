/**
 */

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <utility>
#include <algorithm>
#include <vector>
#include <map>

#include <set>
#include <time.h>


using namespace std;

// Structure for Acyclic edges;
struct myedge {
  int vj;
  int vi;
  int sign;
};

// structure for nodes
struct mynode {
  string name;   //name of the node
  int nstates;   // number of states
  string table_file; // table file name
  bool selfloop ;  // selfloop check
  bool constant;  // constant check

  int Ninputs;
  int *InNodes ;
  int *NStates;
  int *CumMult ;
  int *Function ;
  
};

int EvalFunction(mynode Na, int InState );

int main() {

    // trying to open the output file for writing

    mynode Node1;
    Node1.name = "M";
    Node1.nstates = 2;
    Node1.table_file = "M.dat";
    Node1.selfloop  = false;
    Node1.constant = false;
    Node1.Ninputs = 4;
    Node1.InNodes = new int [Node1.Ninputs];
    Node1.NStates = new int [Node1.Ninputs];
    Node1.CumMult = new int [Node1.Ninputs];

    for (int i=0 ; i < Node1.Ninputs ; i++) 
        Node1.NStates[i] = 2;
    
    if ( Node1.Ninputs > 0 ) {
      Node1.CumMult[  Node1.Ninputs - 1  ] = 1;
      for (int i= Node1.Ninputs - 2 ; i >= 0  ; i--) 
          Node1.CumMult[i] = Node1.CumMult[i+1] * Node1.NStates[i+1] ;
    }
    
    string line , self, NodeName;
    cin >> line ;
    while (cin) {
       if (line == "SELF_LOOP:" ) {
          cin >> self;
          if (self == "YES") { 
             Node1.selfloop = true;
          }
          else 
             Node1.selfloop = false;

          //break;
       } 
       cin >> line;     
       cin.ignore(256,'\n'); 
       // Reading the Names un number of variables
       for (int i = 0 ; i < Node1.Ninputs ; i++) {
           cin >> NodeName ;
           cout << NodeName << endl; 
       }
       cin >> NodeName;

       int Fsize = Node1.CumMult[0] *  Node1.NStates[0];

       Node1.Function = new int [ Fsize];

       int val ;
       for (int i = 0 ; i < Fsize ; i++) {
           for (int j = 0 ; j < Node1.Ninputs ; j++)  
               cin >> val ;
           
           cin >> val;
           Node1.Function[i] = val; 
       }
       break; 
    }

    //int Fval = EvalFunction( Node1 , 14   );
    return 0;  
}

int EvalFunction( mynode Node , int state   ) {

 

}








