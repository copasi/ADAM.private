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
#include "graph.h"


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

  int Ninputs;   // n of inputs
  int *InNodes ; // array with node Ids
  int *NStates;  // array with N states of in nodes
  int *CumMult ; // Array used to get sate
  int *Function ; //node value  given an input
  int Fsize ;  // size of function table;

};

int main() {

    // trying to open the output file for writing
    ofstream OUT( "MFVSfixedpoints.log" ) ;
    if (!OUT) {
        cerr << "Error creating(opening) output file ...exiting" << endl;
        return 0 ;
    }

    // Read the number of nodes and edges
    int NumberNodes, NumberEdges;
    int MaxNStates = 0;

    // Table containing nodes names 
    map<string, int> NodeNames;

    // Name of the file
    string CSVFile;
    cin >> CSVFile ;

    // Reading the File
    ifstream IN( CSVFile.c_str() );
    if (!IN) {
        cerr << "Error openeing input file ...exiting" << endl;
        return 0 ;
    }

    // reading number of nodes
    string line, Name;
    IN >> line;
    IN >> NumberNodes;

    // Reading the maximum number of states 
    IN >> line;
    IN >> MaxNStates ;

    mynode * Nodes  = new mynode [NumberNodes]; // Array of nodes
   
    // reading information of each node
    IN >> line;
    int counter = 0;
    while (IN) {  

       if (line == "AbrevName:" || line == "Name:" ) {
          IN >> Name; // reading the name
          
          Nodes[counter].name = Name ; 
          
          NodeNames[Name] = counter;

          IN >> line;
          while (IN) {
             if ( line == "States:" )
                IN >> Nodes[counter].nstates;
             
             else if ( line == "Table:" ) {
                IN >> Nodes[counter].table_file;
                break ;
             }
             else if ( line=="AbrevNAme:" || line == "Name:"  ) {
                cerr << "missing information for node ";
                cerr << Name << ".... exiting "<< endl ;
                return 0; // if no States and Table, finished
             }
             IN >> line;              
          }
          counter++;
       }        
       
       if (counter == NumberNodes){
          break;
       }
       IN >> line;
    }
   
    // Making a map (Names -> Numbers)
    OUT << "Making the following map :"<< endl;
    for (int i=0 ; i < NumberNodes; i++) {
       string name = Nodes[i].name;
       OUT << Nodes[i].name << " --> " <<  NodeNames[name] << endl;
    }

    // Reading inputs for each node
    for (int  i=0 ; i < NumberNodes; i++ ) {
       string tfile = CSVFile ;
       unsigned found = tfile.rfind('/');
       if (found!=std::string::npos)
           tfile.replace ( found+1 , -1 , Nodes[i].table_file  );

       else
          tfile =  Nodes[i].table_file ;

       ifstream TIN( tfile.c_str() );
       if (!TIN) {
           cerr << "Error openeing Table file ";
           cerr << tfile << " ... exiting" << endl;
           return 0 ;
       }
       string line, self ;
       TIN >> line ;

       while (TIN) {
         if (line == "SPEED:" ) {
            TIN.ignore(235,'\n') ;
            break;
         }
         TIN >> line;
       }
       if (TIN)  {
          string in_name="";
          string old_name="";
          int count = 0;
          TIN >> in_name ; 
          while (TIN) {
               count++;
               if ( in_name == old_name  ) 
                  break;

               old_name = in_name;
               TIN >> in_name ;             
          }
          if ( count == 0 ){
             cerr << "Problems reading inputs in " << tfile << endl;
             return 0;   
          }
          else 
             Nodes[i].Ninputs = count - 1;  
          //cout << old_name <<  " " << count << endl;

       }
       else {
          cerr << "Problems reading " << tfile << endl;
          return 0;
       }
       TIN.close();
    }

    //REading Table
    for (int i  = 0 ; i < NumberNodes ; i++ ) {
        Nodes[i].InNodes = new int [ Nodes[i].Ninputs ];
        Nodes[i].CumMult = new int [ Nodes[i].Ninputs ];
        Nodes[i].NStates = new int [ Nodes[i].Ninputs ];

        string tfile = CSVFile ;
        unsigned found = tfile.rfind('/');
        if (found!=std::string::npos)
            tfile.replace ( found+1 , -1 , Nodes[i].table_file  );

        else
            tfile =  Nodes[i].table_file ;

        ifstream TIN( tfile.c_str() );
        if (!TIN) {
            cerr << "Error openeing Table file ";
            cerr << tfile << " ... exiting" << endl;
            return 0 ;
        }

        string line, self ;
        TIN >> line ;
        while (TIN) {
           if (line == "SPEED:" ) {
              TIN.ignore(235,'\n') ;
              break;
           }
           TIN >> line;
        }

        string nod_names;
        for (int j=0 ; j < Nodes[i].Ninputs ; j++) {
             TIN >> nod_names ;
             int nodeID = NodeNames[ nod_names ] ;
             Nodes[i].InNodes[j] = nodeID;
             Nodes[i].NStates[j] = Nodes[nodeID].nstates ;
        }
        TIN >> nod_names;
        //cout << nod_names << " ";

        if ( Nodes[i].Ninputs > 0 ) {
            Nodes[i].CumMult[  Nodes[i].Ninputs - 1  ] = 1;
            for (int j = Nodes[i].Ninputs - 2 ; j >= 0  ; j--)
               Nodes[i].CumMult[j] = Nodes[i].CumMult[j+1] * Nodes[i].NStates[j+1] ;
        }

        int Fsize = Nodes[i].CumMult[0] * Nodes[i].NStates[0];
        Nodes[i].Fsize = Fsize;

        Nodes[i].Function = new int [ Fsize];
        int val ;
        for (int k = 0 ; k < Fsize ; k++) {
           for (int j = 0 ; j < Nodes[i].Ninputs ; j++)
               TIN >> val ;

           TIN >> val;
           Nodes[i].Function[k] = val;
        }
        TIN.close();
    }

    // change tables for nodes without selfloops
    for (int i  = 0 ; i < NumberNodes ; i++ ) {
        int z = Nodes[i].nstates ;
        
        Nodes[i].selfloop = false;

        for (int j =0 ; j < Nodes[i].Fsize; j=j+z ){

            bool self = true ;            
            int val=0;

            // check x = f(x)
            for (int k=0; k < z ; k++) {
                if (Nodes[i].Function[j+k] == k ) {
                   val = k;
                   self = false;
                   break;
                }
            }
            if (self == true ) {
                Nodes[i].selfloop = true; 
                break; // if no x=f(X) found node is selfloop
            } 

            self = false;
            // check values smaller tan 'val;
            for (int k=0; k < val ; k++) {
                if (Nodes[i].Function[j+k] <= k  ) {
                   self = true;
                   break;
                }
            }
            if (self == true ) {
                Nodes[i].selfloop = true;               
                break; // if exist x <= f(X), 'i' is selfloop
            } 
           

            self = false;
            // check values greater than 'val;
            for (int k=val+1; k < z ; k++) {
                if (Nodes[i].Function[j+k] >= k  ) {
                   self = true;
                   break;
                }
            }
            if (self == true ) {
                Nodes[i].selfloop = true;
                break; // if exist x <= f(X), 'i' is selfloop
            }
             
        }
        //cout <<  Nodes[i].name <<  " | " << Nodes[i].selfloop << endl; 
    }

    // count sSelfEdges
    int SelfEdges =0 ;
    for (int i  = 0 ; i < NumberNodes ; i++ ) {
        if (Nodes[i].selfloop) 
            SelfEdges++;
    }

    // change tables for nodes without selfloops
    for (int i  = 0 ; i < NumberNodes ; i++ ) {
        if ( Nodes[i].selfloop == false ) {
            int z = Nodes[i].nstates ;
            for (int j =0 ; j < Nodes[i].Fsize; j=j+z ){
                int val=0;
                for (int k=0; k < z ; k++) {
                   if (Nodes[i].Function[j+k] == k ) {
                       val = k;
                       break;
                   }
                }
                val = Nodes[i].Function[j+val] ;
                for (int k=0; k < z ; k++)
                    Nodes[i].Function[j+k] = val;
            }
        }
    }
    // Displa tables
    //for (int i  = 0 ; i < NumberNodes ; i++ ) {
    //    cout <<  Nodes[i].name <<  " | " ;
    //    for (int k = 0 ; k < Nodes[i].Fsize ; k++ ){
    //        cout << Nodes[i].Function[k] << " ";
    //    }
    //    cout << endl;
    //}



    // Reading Edges
    IN >> NumberEdges;
    myedge * Edges  = new myedge [NumberEdges + SelfEdges];

    IN >> line;
    counter = 0;
    while (IN) {
       int jj , ii ;

       if (line == "Start:") {
          string name  ;
          IN >> name;
          jj = NodeNames[name];

          IN >> line;  // reading END
          IN >> name;
          ii = NodeNames[name];

          if (ii != jj ) {
             Edges[counter].vj = jj ;
             Edges[counter].vi = ii ;
             counter++;
          }
 
       }
       IN >> line;
        
    }
    IN.close(); 

    for (int i =0 ; i < NumberNodes ; i++) {
        if ( Nodes[i].selfloop ) {
           Edges[NumberEdges].vj = i;
           Edges[NumberEdges++].vi = i;
        }
    }
    ///////////////////////////////////////////
 
    // Counting the Number of inputs per node,
    int * Ninputs   = new int [NumberNodes];
    for (int k  = 0 ; k < NumberNodes ; k++ ) 
        Ninputs[k] = 0; 

    for (int k  = 0 ; k < NumberEdges ; k++ ) {
        int i = Edges[k].vi;
        Ninputs[i]=Ninputs[i] + 1;
           
    }

    // Array with the adjan Matrix
    int * AdjList  = new int [NumberEdges+NumberNodes];
    // The number of inputs per node
    int * IndexNet  = new int [NumberNodes]; // stor the indexes per node
    counter =0;
    for (int k  = 0 ; k < NumberNodes ; k++ ) {
        IndexNet[k] = counter;
        AdjList[counter] = k;
        counter = counter + Ninputs[k] + 1 ;
        Ninputs[k] = 0;
    }

    //Fillin the Adjancensy List
    // Counting the Number of inputs per node,
    for (int k  = 0 ; k < NumberEdges ; k++ ) {
        int j = Edges[k].vj;

        int i = Edges[k].vi;

        Ninputs[i]=Ninputs[i] + 1;
        AdjList[ IndexNet[i] + Ninputs[i] ] = j ;
    }

    /////////////////////////////////////////////
    /// create graph for MFVS computation    
    Graph g(NumberNodes);
    for (int i = 0 ; i < NumberNodes ; i++ )
        g.addVertex(i);

    // in the reduced network    
    for (int i = 0 ; i < NumberEdges ; i++ ) {
        int ii = Edges[i].vi;
        int jj = Edges[i].vj;
        g.addEdge(jj, ii);
    }

    OUT <<endl<< "Original Graph  : " << endl;
    OUT << g.numVertices() << " Vertices"<< endl;
    OUT << g.numEdges() << " Edges" << endl << endl;
    //g.print(true);

    // finding constant nodes
    OUT <<  "Constant Nodes :" << endl;
    vector<int> sources = g.sources();
    for (int i = 0; i < int(sources.size()); ++i)  {
        Nodes[sources[i]].constant = true ;
        OUT << i << "  ";
    }
    OUT << endl << endl;


 
 
    Graph h(NumberNodes);
    h = Graph(g);
    OUT << "MVFS Reduced graph : " << endl;
    h.reduce();
    OUT << h.numVertices() << " Vertices"<< endl;
    OUT << h.numEdges() << " Edges" << endl << endl;

    OUT << "A minimum feedback vertex set : ";

    vector<int> mfvs = g.minimumFeedbackVertexSet(false);

    for (vector<int>::iterator it = mfvs.begin(); it != mfvs.end(); ++it)
        OUT <<  Nodes[*it].name  << " ";
    OUT << endl<<endl;


    OUT << "Is it really a feedback vertex set ? ";
    if (g.isFeedbackVertexSet(mfvs)) OUT  << "yes"<<endl;
    else OUT << "no"<<endl;


   ///// Find the order to evaluate the 
   int MFVSsize = mfvs.size();

   //cout << MFVSsize << endl;
   int * MFVSet = new int [MFVSsize];

   int *  OrderEval  = new int [NumberNodes] ;
   bool * BinState = new bool [NumberNodes];
   bool * BinNext = new bool [NumberNodes];

   for (int i = 0 ; i < NumberNodes ; i++ ) {
       BinState[i] = false;
       BinNext[i] = false;
   }

   for (int i = 0 ; i < MFVSsize ; i ++ ) {
      BinState[ mfvs[i] ]  = true;
   }

      
   bool done =  false;
   int count = 0;

   // Evaluate constant nodes First
   for (int i=0 ; i < NumberNodes ; i++ ) {
      if (Nodes[i].constant) {
         BinState[i] = true;
         BinNext[i] = true;
         OrderEval[count] = i;
         count++;
      }
   }
   
   //Find the order of evaluation 
   while (!done ) {

         for (int k = 0 ; k < NumberNodes ; k++ ) {

             if (BinNext[k]) continue;

             bool allavail= true;
             for (int p = 1 ; p <= Ninputs[k] ; p++) {

                  int j =  AdjList[ IndexNet[k] + p];
                  allavail = allavail && BinState[j] ;

                  if ( !allavail) break;
             }
             if (allavail) {
                 //cout << count << " Orderrr "<< k << endl;
                 OrderEval[count] = k;
                 count++ ;
                 BinState[k] = true;
                 BinNext[k] = true;
             }
         }
         done =  (count == NumberNodes);
   }

   OUT << endl << "Order of Evaluation : " << endl; 
   for ( int k = 0 ; k < NumberNodes ; k++ ){
       OUT << OrderEval[k] << " " ;
   }
   OUT << endl;
   ////////////////////////////////////////////////////////

   int * CurStates = new int[NumberNodes];
   int * NexStates = new int[NumberNodes];
   bool * isMFVS =  new bool[NumberNodes ];
   for (int  i=0 ; i < NumberNodes ; i++ ) {
      CurStates[i] = -1; 
      NexStates[i] = -1; 
      isMFVS[i] = false;
   }

   unsigned int Nstates = 1;
   for (int i=0 ; i < MFVSsize ; i++) {
        Nstates = Nstates * Nodes[mfvs[i]].nstates ;
        isMFVS[  mfvs[i]  ] = true;
   }
   

   if (Nstates == 0) {
      cerr << " MAximum number of states 2^32 ... exiting" << endl;
      return 0;
   }

   // For constant network
   if ( MFVSsize == 0 ) {
     
       // Evaluate the graph in the order stablished
       for (int i = 0  ; i < NumberNodes ; i++ ) {

           int ii = OrderEval[i];
           //cout << "state : " << ii  << " , Value :" << CurStates[ mfvs[] ]  << endl;
           int state = 0;
           int jj =0;
           int valj = 0;

           for (int j=0 ; j < Nodes[ii].Ninputs -1 ; j++  ) {
               jj = Nodes[ii].InNodes[j];
               valj = CurStates[jj];
               state = state + valj*Nodes[ii].CumMult[j];
           }
           CurStates[ii] = Nodes[ii].Function[state] ;
       }

       for (int j = 0 ; j <  NumberNodes ; j++   )
           cout << CurStates[j] << " " ;
       cout << endl;
       return 0;
   }

   int rest =0;
   int bit ;
   int number;

   for (int State = 0 ; State < Nstates ; State++ ) {


         ////// from decimal to base Nmax..
         bit = MFVSsize -1;
         number = State;
         do
         {
           rest =  number %  Nodes[mfvs[bit]].nstates    ;
           CurStates[ mfvs[bit] ] = rest ;

           number = number / MaxNStates ;
           bit--;
         } while ( number );
         for (int i = bit ; i >= 0 ; i--)
              CurStates[ mfvs[i] ] = 0 ;
         
         // Evaluate the rest of the graph
         for (int i = 0  ; i < NumberNodes ; i++ ) {

               int ii = OrderEval[i];
               //cout << "state : " << ii  << " , Value :" << CurStates[ mfvs[] ]  << endl;
               if ( isMFVS[ii] == false ) {
                  int state = 0;
                  int jj =0;
                  int valj = 0;

                  for (int j=0 ; j < Nodes[ii].Ninputs -1 ; j++  ) {
                      jj = Nodes[ii].InNodes[j];
                      valj = CurStates[jj];
                      state = state + valj*Nodes[ii].CumMult[j];
                  }
                  CurStates[ii] = Nodes[ii].Function[state] ;
               }
         }


         // Evalute the next step of the MFVs set 
         bool fixedp = true;
         for ( int i=0 ; i < MFVSsize ; i++  ) {
               int ii = mfvs[i];
               //cout << "state : " << ii  << " , Value :" << CurStates[ mfvs[] ]  << endl;
               int state =0;
               int jj = 0;
               int valj = 0;

               for (int j=0 ; j < Nodes[ii].Ninputs  ; j++  ) {
                   jj = Nodes[ii].InNodes[j];
                   valj = CurStates[jj];
                   state = state + valj*Nodes[ii].CumMult[j];
               }
               NexStates[ii] = Nodes[ii].Function[state] ;

               if (NexStates[ii] != CurStates[ii]) {
                  fixedp = false;
                  break; 
               }
         }
        
         if (fixedp ) {
            for (int j = 0 ; j <  NumberNodes ; j++   ) 
               cout << CurStates[j] << " " ;
            cout << endl; 
         }

   }

}

