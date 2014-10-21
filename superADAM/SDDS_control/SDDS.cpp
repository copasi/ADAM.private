#include <iostream>
#include <chrono>
#include <fstream>
#include <iomanip>
#include <string>
#include <vector>
#include <ctime>
#include <algorithm>
#include <stdio.h>
#include <stdlib.h>

#include <random>

using namespace std;

// this random generator needs to be improved 
unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
std::default_random_engine generator(seed);
std::uniform_real_distribution<double> distribution(0.0,1.0);

void nextstate_ia( int *x, int *y, int NumNodes, int MaxInputs, int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,  int *action, int NumNodeEdges ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2 );

void sdds_nextstate(int *x, int *y, int NumNodes, int MaxInputs, int *sdds_nv, int ** sdds_varf, int ** sdds_tt, float ** sdds_prop, int *power2 );
void dec2binary( int *BinState, int NumNodes, int State) ;
float cost_ija(int *BinState, int *BadState,  int NumNodes, int *actions, int NumNodeEdges, int NumCNodes, int *ActionNodes, float * Wi ); 
void prob_ia( int *x, int NumNodes, int MaxInputs, float  *pia, float *Cost_ia, int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,  int *action, int NumActions,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState, float * Wi  )  ;
void operatorTVi( int NumNodes, int MaxInputs,  int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,   int NumNodeEdges, int NumActions ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState ,float *W, float *JV, float alpha, float *newJV , int * U  ) ;

float RecursiveQ(int NumNodes, int MaxInputs,  int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop, int NumNodeEdges, int NumActions ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState, float *Wi, float alpha,  int c, int h, int *x, int *action  ) ;

float normax ( float * array1,  float * array2 , int NumElements );


int main(int argc, char * argv[]) {

   // Value Iteration parameter
   float alpha = 0.9 ;  // discounting cost
   int Nmax =100;   //  maximum number of iterations
   float tol = 0.0001; //  convergence criteria
   int iter =1 ; // iteration

	
   //Input Files 
   string nv_file="";  // name of the file containing the number variables per node 
   string varf_file=""; // names of the file containing the IDs of the input  per node
   string tt_file="";   // transition(truth) table 
   string prop_file="";  // Variable containg the propensities for each node

   //Control inputs
   string cnodes_file=""; // list of control nodes (one node per line)
   string cedges_file=""; // list of control arrows (one node per line): first column heads, secon column tails.

   //Bad State
   string cost_file=""; // list of important nodes that define a bad state

   // Parameters of the mode
   int NumNodes = 0; // number of nodes of the sustem
   int NumStates = 1; // number of states ( 2^(NumNodes) )
   int MaxInputs = 0; // Maximum number of inputs in the Boolean network.
   int MaxInputStates = 1; // Maximum number of input states conciderin all nodes.
   int *sdds_nv ;  // array that store the number of inputs per node
   int **sdds_varf ; // matrix pointers to store the IDs of imputs per node 
   int **sdds_tt ; // matrix pointers to store the transition(truth) table  
   float **sdds_prop  ; // matrix pointers to store the propensities
   int *power2 ;  // matrix used to transform from binary to decimal
   int prod2 ; // helper variable to fill power2
   float *pia ; // probaailities
   float  *Cost_ia ; // cost array 

   // Parameters
   int * Badstate ;
   float * Wi ;
   int * Badindex ;

   int NumNodeEdges  = 0; // Number of control  nodes plus Number of control arrows.
   int NumActions  = 1;
   int NumCNodes = 0; // number of control nodes
   int NumCEdges  = 0;
   int cnode_id =  0; // varible to store the index of control nodes
   int bstate_i = 0; // variable to store tthe badstate of node i
   float wi = 0.0 ; // variable to store the distance weigth of     

   int *Actions ;     // 1 and  0 s for the actions
   int *ActionNodes ; // Ids of control nodes
   int *ActionHeads ; // IDs of the heds of arrows
   int *ActionTails ; // IDs og the tails of arrows.

   // Parameters of Sparse
   int sparse_s = 0;
   int sparse_c = 5;
   int sparse_h = 2; 
   bool sparse_flag = false;

   // local variables
   int NumVariables = 0 ; // used to store th number of variables per node
   int VarID = -1 ; // the id for each varaible
   float node_prop ; // local variable to sotore propensities   
	
   for (int i = 1; i < argc; i++) {
      string arg = argv[i];
      //cout << "Param " << i << ": " << arg << endl;
      int n = 1;
      while (i+n < argc && argv[i+n][0] != '-') n++;

      if (arg == "-nv") {
         if (n == 2) nv_file = argv[++i];
	 else cerr << "-nv requires a file parameter" << endl;
      }
      else if (arg == "-varf") {
         if (n == 2) varf_file = argv[++i];
	 else cerr << "-varf needs a file parameter." << endl;
      }

      else if (arg == "-tt") {
         if (n == 2) tt_file = argv[++i]; 
         else cerr << "-tt requires a file parameter" << endl;
      }
      else if (arg == "-prop") {
         if (n == 2) prop_file = argv[++i];
         else cerr << "-prop requires a file parameter" << endl;
      }
      else if (arg == "-cnodes") {
         if (n == 2) cnodes_file = argv[++i];
         else cerr << "-cnodes  requires a file parameter" << endl;
      }
      else if (arg == "-cedges") {
         if (n == 2) cedges_file = argv[++i];
         else cerr << "-cedges  requires a file parameter" << endl;
      }
      else if (arg == "-cost" ) {
         if (n == 2) cost_file = argv[++i];
         else cerr << "-cost  requires a file parameter" << endl;
      }      
      else if (arg == "-sparse" ) {
         if (n == 2) {
            sparse_s = atoi( argv[++i]  ) ;
            sparse_flag = true ;
         }
         else cerr << "-sparse  requires an integer parameter (initial state) " << endl;
      }
      else if (arg == "-c" ) {
         if (n == 2) sparse_c = atoi(argv[++i]) ;
         else cerr << "-c  requires an integer parameter (sparse )" << endl;
      } 
      else if (arg == "-h" ) {
         if (n == 2) sparse_h = atoi(argv[++i]) ;
         else cerr << "-h  requires an integer parameter (sparse )" << endl;
      }
      else { //Invalid parameter
         cerr << "Invalid parameter " << i << ": " << arg << endl;
      }
   }


   ///////////////////////////////////////// 
   // This part can be implemented as a function
   // Open  the input file with the number of variables per ndoe (nv_file)
   ifstream InFile_nv(nv_file.c_str()); // straming to read number of nodes
   if ( !InFile_nv ) { 
       cerr << "Error opening nv file : " << nv_file  << endl;
       cerr << " -nv flag is mandatory " << endl;
       return 0;
   }
 
   // Read the number of nodes of an SDDS system
   while (InFile_nv) {
       InFile_nv >> NumVariables ;
       if ( InFile_nv)  NumNodes++;
   }
   InFile_nv.clear(); 

   // Read the number of inputs  per node
   sdds_nv = new int [NumNodes] ;
   for (int i = 0 ; i < NumNodes ; i++ ) {
       InFile_nv >> NumVariables ; 
       sdds_nv[i] = NumVariables ;
       if ( NumVariables >  MaxInputs )  MaxInputs = NumVariables ;
   }
   ////////////////////////////////////////////////////

      
   ///////////////////////////////////////////
   // Read the IDs of tne inputs per nodes
   // (This will be better implemented as a function)
   sdds_varf = new int* [MaxInputs] ;     
   for (int i = 0; i < MaxInputs; ++i) 
       sdds_varf[i] = new int[NumNodes];
   
   ifstream InFile_varf(varf_file.c_str()); // straming to read number of nodes
   if ( !InFile_varf ) {
       cerr << "Error opening varf file : " << varf_file  << endl;
       cerr << " -varf flag is mandatory " << endl;
       return 0;
   }
   
   for (int i = 0 ; i < MaxInputs ; i++) {
       int num_columns = 0;
       for (int j = 0 ; j < NumNodes  ; j++ ) {
           InFile_varf >> VarID ;
           if ( InFile_varf ) {
               sdds_varf[i][j] = VarID - 1 ;
               num_columns++ ;               
           }    
       }     
       if (num_columns != NumNodes ) {
           cerr << " Number of columes different than Number of Nodes ";
           cerr << " (obtained from varf_files) " << endl;
           return 0;     
       }
   }
   /////////////////////////////////////////////////


   ///////////////////////////////////////////
   // Read the transition table 
   // (This will be better implemented as a function)
   // compute the total number of states
   
   for ( int i = 0 ; i < MaxInputs ; i++) // MaxInputsStates = 2^(MaxInputs)
       MaxInputStates  =  MaxInputStates  <<  1 ;

   sdds_tt = new int* [MaxInputStates] ;
   for (int i = 0; i < MaxInputStates; ++i)
       sdds_tt[i] = new int[NumNodes];

   ifstream InFile_tt(tt_file.c_str()); // straming to read number of nodes
   if ( !InFile_tt ) {
       cerr << "Error opening tt file : " << tt_file  << endl;
       cerr << " -tt flag is mandatory " << endl;
       return 0;
   }

   for (int i = 0 ; i < MaxInputStates ; i++) {
       int num_columns = 0;
       for (int j = 0 ; j < NumNodes  ; j++ ) {
           InFile_tt >> VarID ;
           if ( InFile_tt ) {
               sdds_tt[i][j] = VarID ; // VarID can only be -1, 0, or  1 only
               num_columns++ ;
           }
       }
       if (num_columns != NumNodes ) {
           cerr << " Number of columnss different than Number of Nodes ";
           cerr << " (obtained from tt_files) " << endl;
           return 0;
       }
   }
   ///////////////////////////////////////////////////////////////

  
   ///////////////////////////////////////////
   // Read the propensity files 
   // (This will be better implemented as a function)
   sdds_prop = new float* [2] ;
   for (int i = 0; i < 2; i++)
       sdds_prop[i] = new float[NumNodes];
   
   ifstream InFile_prop(prop_file.c_str()); // straming to read number of nodes
   if ( !InFile_prop ) {
       cerr << "Error opening tt file : " << prop_file  << endl;
       cerr << " -prop flag is mandatory " << endl;
       return 0;
   }
 
   
   for (int i = 0 ; i < 2 ; i++) {
       int num_columns = 0;
       for (int j = 0 ; j < NumNodes  ; j++ ) {
           InFile_prop >>  node_prop ;
           if ( InFile_prop ) {
               sdds_prop[i][j] =  node_prop  ; // VarID can only be -1, 0, or  1 only
               num_columns++ ;
           }
       }
       if (num_columns != NumNodes ) {
           cerr << " Number of columns different than Number of Nodes ";
           cerr << " (obtained from prop_files) " << endl;
           return 0;
       }
   }
   ///////////////////////////////////////////////////////////////////
  
 
   ///////////////////////////////////////////////////////////////////
   // Read the the file with control nodes
   // This part should be included in a especial function.
   // Moreover, the control part should be part of  special class
   ifstream InFile_cnodes(cnodes_file.c_str()); // straming to read number of nodes
   if ( !InFile_cnodes ) {
       cerr << "Error opening cnodes file : " << cnodes_file  << endl;
       cerr << " -cnodes flag is mandatory " << endl;
       return 0;
   }
   // read file to count number of control nodes 
   while (InFile_cnodes) {
       InFile_cnodes >> cnode_id ;
       if ( InFile_cnodes)  NumCNodes++;
   }
   InFile_cnodes.clear();
   InFile_cnodes.seekg(0, ios::beg) ;
   // Read all the control nodes indexes
   ActionNodes = new int [NumCNodes] ;
   for (int i = 0; i < NumCNodes ; i++ ) {
      InFile_cnodes >> ActionNodes[i] ;
      ActionNodes[i] -= 1; 
   }
   InFile_cnodes.close();
   //////////////////////////////////////////////////////////////////////

  
   ///////////////////////////////////////////////////////////////////
   // Read the file with control edges
   // This part should be included in a especial function.
   // Moreover, the control part should be part of  special class
   ifstream InFile_cedges(cedges_file.c_str()); // straming to read number of nodes
   if ( !InFile_cedges ) {
       cerr << "Error opening cedges file : " << cedges_file  << endl;
       cerr << " -cedges flag is mandatory " << endl;
       return 0;
   }
   // read file to count number of control nodes 
   while (InFile_cedges) {
       InFile_cedges  >> cnode_id >> cnode_id  ;
       if ( InFile_cedges)  NumCEdges++;
   }
   InFile_cedges.clear();
   InFile_cedges.seekg(0, ios::beg);
   // Read all the control nodes indexes
   ActionHeads = new int [NumCEdges] ;
   ActionTails = new int [NumCEdges] ;
   for (int i = 0; i < NumCEdges ; i++ ) {
      InFile_cedges >> ActionHeads[i] >> ActionTails[i] ;
      ActionHeads[i] -= 1;
      ActionTails[i] -= 1;
   }
   
   InFile_cedges.close();

   NumNodeEdges  = NumCEdges + NumCNodes ;
   //////////////////////////////////////////////////////////////////////

   ///////////////////////////////////////////////////////////////////
   // Read the file with bad state
   // This part should be included in a especial function.
   // Moreover, the control part should be part of  special class
   
   Badstate = new int [NumNodes];
   Wi = new float [NumNodes];
   Badindex  = new int [NumNodes]; 
   for ( int i = 0 ; i < NumNodes ; i++) {
       Badstate[i]=0 ;
       Wi[i] = 0.0 ;
   }

   ifstream InFile_cost(cost_file.c_str()); // straming to read number of nodes
   if ( !InFile_cedges ) {
       cerr << "Error opening cost file : " << cedges_file  << endl;
       cerr << " -cost  flag is mandatory " << endl;
       return 0;
   }
  
   //int bstate_i = 0; // variable to store tthe badstate of node i
   //float wi = 0.0 ; // variable to store the distance weigth of

   // read file to count number of control nodes 
   InFile_cost >> cnode_id ;

   while (InFile_cost) {
       if ( ( cnode_id < 1 ) || ( cnode_id > NumNodes ) ) 
           cerr << " Error indexout of range " << endl;
       InFile_cost  >> bstate_i ;
        
       
       InFile_cost  >> wi ;
       if (!InFile_cost) {
           cerr << " Error reading File, eery row require three columns " << endl;
       }
       Wi[ cnode_id - 1 ] = wi; 
       Badstate[ cnode_id - 1 ] = bstate_i ;
       if ( (bstate_i < 0) || (bstate_i > 1) ) {
           cerr << " the values of states should be 0 or 1 " << endl;
       }
       
       InFile_cost >> cnode_id ; // Try to red net line
   }
   InFile_cost.close();
   //////////////////////////////////////////////////////////////////////

   ///////////////////////////////////////////////////////////////////
   //// This part create an array like [2^(n-1) 2^(n-2) ... 2^1  2^0 ] 
   //// can be put in an small function
   prod2 = 1 ;
   power2 = new int [MaxInputs] ;
   for ( int i = 0 ; i < MaxInputs ; i++) {  // MaxInputsStates = 2^(MaxInputs)
       power2[ MaxInputs - i - 1  ] = prod2 ;
       prod2   =  prod2   <<  1 ;  
   }
   //for ( int i = 0; i < MaxInputs ; i++ ) 
   //    cout << power2[i] << " ";
   //cout << endl;
   ///////////////////////////////////////////////////////////////
   

   ///////////// Here I am testing the functions sdds_nextstate and 
   ////////////  the funcion dec2binary 

   // Testing the functions
   int * x = new int[NumNodes] ; 
   int * y = new int[NumNodes] ;
   // compute the total number of states 
   for ( int i = 0 ; i < NumNodes ; i++) 
      NumStates =  NumStates <<  1 ;

   // compute total number of Actions ( 2^(NumNodes+NumEdges) )
   for ( int i = 0; i < NumNodeEdges ; i++ ) 
      NumActions = NumActions << 1 ;



   // testing  the control  probabilities and costs

   int * action = new int[NumNodeEdges] ;
   action[0] = 1;
   action[1] = 1;
  
   pia = new float[NumStates] ;
   Cost_ia = new float[NumStates] ;   


   if ( sparse_flag ) {

      dec2binary( x , NumNodes, sparse_s );
      int c = sparse_c;
      int h = sparse_h ;
      int *a = new int[NumNodeEdges] ;
      int final_action = 0;

      float minQ = 10000000;
      for ( int action = 0 ; action < NumActions; action ++ ) {
          dec2binary( a , NumNodeEdges, action );
          float Q_a =  RecursiveQ(NumNodes, MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, NumNodeEdges,  NumActions,  ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, Badstate, Wi, alpha, c, h, x, a  ) ;
       
          //cout << "--- " << Q_a ;
          if ( Q_a < minQ ) {
             minQ = Q_a ;
             final_action = action;
          }
      }
      //cout << endl;

      for ( int i=0 ; i < NumNodes; i++) 
          cout << x[i] << " ";
      cout  << " ---> " ;
      dec2binary( a  ,  NumNodeEdges , final_action ) ;
      for ( int u = 0 ; u <  NumNodeEdges ; u++ )
          cout << " " << a[u] ;

      cout  << endl;
      return 0 ;
   }
 
    
   //cout<< endl; 
   //for (int State = 0; State < NumStates  ; State++ ) {
   //     dec2binary( x ,  NumNodes, State);
   
   //    prob_ia( x, NumNodes,  MaxInputs, pia, Cost_ia,  NumStates,  sdds_tt, sdds_nv, sdds_varf, sdds_prop, action, NumNodeEdges,  ActionNodes,  NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, Badstate, Wi  ) ; 
   //    for (int j =0 ; j < NumStates ; j++ ) {
   //	  //cout << pia[j] << " " ;
   //       cout << Cost_ia[j] << " " ;
   //    } cout << endl;
         //cout << cost_ija( x , Badstate, NumNodes, action, NumNodeEdges, NumCNodes,  ActionNodes,  Wi ) << " " ;

   //     nextstate_ia( x, y, NumNodes, MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, action, NumNodeEdges, ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2 );    
        
   //     for (int j =0 ; j < NumNodes ; j++ ) {
   //     //cout << pia[j] << " " ;
   //        cout << y[j] << " " ;
   //     } cout << endl;
 
   //} 
   //return 0;

   // Operator 
   
   float maxdiff = 0.0;
   float * JV = new float[NumStates];
   float * newJV = new float[NumStates];
   int * U = new int[NumStates];

   for ( int i = 0; i < NumStates; i++ ) {
      JV[i] = 4.0;
      newJV[i] = JV[i] ; 
   }


   operatorTVi( NumNodes,  MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, NumNodeEdges, NumActions,  ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, Badstate, Wi,  JV, alpha, newJV ,  U  ) ; 
   
   while( ( normax(JV, newJV, NumStates) > tol ) && ( iter < Nmax ) ) {

      for ( int i=0 ; i < NumStates; i++ ) 
          JV[i] = newJV[i] ;

      operatorTVi( NumNodes,  MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, NumNodeEdges, NumActions,  ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, Badstate, Wi, JV, alpha, newJV ,  U  ) ;
      iter++; 
   }
 
   //for ( int State = 0; State < NumStates  ; State++ ) {
   //   cout << newJV[State] << "  " << U[State] << endl;
   //}

   for ( int i=0 ; i < NumStates; i++ )
          JV[i] = newJV[i] ;

   operatorTVi( NumNodes,  MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, NumNodeEdges, NumActions,  ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, Badstate, Wi,  JV, alpha, newJV ,  U  ) ;
   //cout << "-------------------" << endl;
   for ( int State = 0; State < NumStates  ; State++ ) {
      //cout << newJV[State] << "  " << U[State] << endl;
      cout << State  << "  --->  " ;
      
      dec2binary( action  ,  NumNodeEdges , U[State] ) ;
      for ( int a = 0 ; a <  NumNodeEdges ; a++ )  
          cout << " " << action[a] ;

      cout  << endl;
   }

   //delete [] BinState;
   delete [] JV ;
   delete [] newJV ;
   delete [] U ;
   delete [] sdds_nv ;
   delete [] x;
   delete [] y;
   return 0;
}

//////////////////////////////////////////////////////////////
// RecursiveQ  Function of Sparse Sample Algorithm
// Inputs
//  SDDS     : The Stochastic Discrete Dynamicl system
//  Actions  : Action class
//  c        : parameter of SSA algorithm
//  h        : parameter of SSA algorithm
//  state    : initial state of the systems

float RecursiveQ(int NumNodes, int MaxInputs,  int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop, int NumNodeEdges, int NumActions ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState, float *Wi, float alpha,  int c, int h, int *x, int *action  ) {

   if (h == 0) {
      return 0.0 ;
   }
   //cout << " x " << x[0] << x[1] << x[2] << endl;
   float Q = 0.0 ;
   float R = 0.0 ;

   int *y = new int[NumNodes] ;
   int *a = new int[NumNodeEdges] ;

   for (int i = 0 ; i < c ; i++ ) {
      
      nextstate_ia( x, y, NumNodes, MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, action, NumNodeEdges, ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2 ); 
 
      //    cout << " c = " << c << " h= "<< h << endl;
      float minQ = 10000000;
      for ( int action = 0 ; action < NumActions; action ++ ) {
          dec2binary( a , NumNodeEdges, action );
          float Q_a =  RecursiveQ(NumNodes, MaxInputs, NumStates, sdds_tt, sdds_nv, sdds_varf, sdds_prop, NumNodeEdges,  NumActions,  ActionNodes, NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, BadState, Wi, alpha, c, h-1, y, a  ) ;
          if ( Q_a < minQ ) {
              minQ = Q_a ;
          }  
          //cout << " === " << Q_a << " c = " << c << " h= "<< h << endl; 
      }  
      
      Q = Q + minQ ;
      R = R + cost_ija(y, BadState,  NumNodes, action, NumNodeEdges, NumCNodes, ActionNodes,  Wi );
         
   }

   delete [] y;
   delete [] a;

   return ( R + alpha*Q ) / c ; 
}




//////////////////////////////////////////////////////////////
///  Define Operator T
///   x current state ( array of 1 or 0, with a size of NumNodes)
///   pia       : array of 2^n douable elements, this will hold the probabilitites
///   NumNodes  : number of nodes of SDDS
///   MaxInputs : Maximun indegree
void operatorTVi( int NumNodes, int MaxInputs,  int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,   int NumNodeEdges, int NumActions ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState, float *Wi, float *JV, float alpha, float *newJV , int * U  )  {
  
   int * action  = new int [ NumNodeEdges ] ;
   int * x = new int [NumNodes ] ;
   float * pia = new float [ NumStates ]; 
   float * Cost_ia = new float [ NumStates ] ; 
   float * temp_J = new float [NumActions  ] ;


   for (int i = 0 ; i < NumStates; i++  ) {
      for (int u = 0 ; u < NumActions; u++ ) {

         dec2binary( action , NumNodeEdges, u );
         dec2binary( x, NumNodes, i ) ;
 

         float avg_J = 0; 
         float avg_g = 0; 
 
         prob_ia( x, NumNodes,  MaxInputs, pia, Cost_ia,  NumStates,  sdds_tt, sdds_nv, sdds_varf, sdds_prop, action, NumNodeEdges, ActionNodes,  NumCNodes, ActionHeads, ActionTails, NumCEdges, power2, BadState, Wi  ) ;


         for (int j =0 ; j < NumStates; j++ ){
            avg_J = avg_J +  pia[j] * JV[j] ; 
            avg_g = avg_g +  pia[j] * Cost_ia[j]  ;
         }

         temp_J[u] = avg_g +  alpha*avg_J ;

      }

      newJV[i] = 1000000.0 ;
      U[i]  = 0 ;
      for (int u = 0 ; u < NumActions; u++ ) {
          if ( temp_J[u] < newJV[i]  ) {
              newJV[i] = temp_J[u] ;
              U[i] =  u ;
          }
      }


   }
   
   delete [] action ; 
   delete [] pia ;
   delete [] Cost_ia ;
   delete [] x ; 
   delete [] temp_J ;
}





//////////////////////////////////////////////////////////////
///  This function compute the probabilities of going from state x to the other states  
///   x current state ( array of 1 or 0, with a size of NumNodes)
///   pia       : array of 2^n douable elements, this will hold the probabilitites
///   NumNodes  : number of nodes of SDDS
///   MaxInputs : Maximun indegree
///   sdds_nv   : array of number of variables per node
///   sdds_varf : array with the nodes ids for each nodes ( size MaxInputs x NumNodes)  
///   sdds_tt   : array with transition table of the SDDS ( size MaxInputStates x NumNodes )
/// Output
///   y   new state

void prob_ia( int *x, int NumNodes, int MaxInputs, float  *pia, float *Cost_ia, int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,  int *action, int NumNodeEdges ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2, int * BadState, float *Wi )  { 
   
   // internal variables
   //int * Cost_ia  = new int [NumStates] ;
   int * z  = new int [NumNodes] ;
   int * y  = new int [NumNodes] ;
   int * FreeNodes  = new int [NumNodes] ;
   int * newx = new int [NumNodes] ; 
   int * newx2 = new int [NumNodes] ; 
   float * prob_up = new float [NumNodes]; 
   float * prob_dn = new float [NumNodes];

 
   // initialize the probabilies and cost
   for (int i = 0 ; i < NumStates ; i ++ ) { 
       pia[i] = 0.0 ;
       Cost_ia[i] = 1000;
   }

   // initializa the z 
   for (int i = 0 ; i < NumNodes ; i ++ ) {
       z[i] = 0 ;
       FreeNodes[i] = 1; 
       newx[i] = x[i] ; 
       newx2[i] = x[i] ;
       prob_up[i] = sdds_prop[0][i];
       prob_dn[i] = sdds_prop[1][i];
   }
   // Set control nodes to be zero if control is 1
   for (int i = 0; i  <  NumCNodes ; i ++ ) {
       if ( action[i] == 1) {
           newx[ ActionNodes[i] ] = 0;  // Node is desable, put to zero
           newx2[ ActionNodes[i] ] = 0;  // Node is desable, put to zero
           FreeNodes[   ActionNodes[i]  ]  = 0 ; // Node is marked as a cntrol node        
           prob_up[i] = 0.0;
           prob_dn[i] = 0.0;
       }
   }
   
   // Set control nodes to be zero if control is 1
   for (int i = 0 ; i < NumCEdges; i++ ) {
       if ( action[i + NumCNodes ] == 1) {
           FreeNodes[ ActionHeads[i]  ]  = -1; // Node is marked as a cntrol node
       }
   }

    

   // compute z, the deterministi next state 
   for (int i = 0; i < NumNodes; i++ ) {

       if ( FreeNodes[i] == 1) {
           int nv = sdds_nv[i];
           int k = 0;
           for (int j = 0 ; j < MaxInputs ; j ++ ) {
               int Indx =  MaxInputs - nv  + j;
               k = k + power2[Indx]*newx[ sdds_varf[j][i] ] ;
           }
           z[i] = sdds_tt[k][i];
       }
       else if ( FreeNodes[i] == -1 ) {
           for (int j = 0 ; j  < NumNodes ; j++ ) 
               newx[j] = newx2[j] ;
           
           for ( int j = 0 ; j < NumCEdges; j ++ ) 
               newx2[ ActionTails[j] ] = 0 ;
         
           int nv = sdds_nv[i];
           int k = 0;
           for (int j = 0 ; j < MaxInputs ; j ++ ) {
               int Indx =  MaxInputs - nv  + j;
               k = k + power2[Indx]*newx2[ sdds_varf[j][i] ] ;
           }
           z[i] = sdds_tt[k][i];
       }
       //cout << z[i] << " " ;
   }
   //cout << " Zeta ------- " << endl;
   

   for ( int state  = 0 ; state < NumStates; state++ ) {
       dec2binary( y ,  NumNodes, state);
       pia[state] = 1.0;
       Cost_ia[state]= cost_ija( y , BadState,  NumNodes, action, NumNodeEdges , NumCNodes, ActionNodes, Wi );


       for ( int k=0; k<NumNodes; k++ ){
           float c = 0.0;
           
           if (z[k] > newx[k]) {
              if ( y[k] == z[k] ) 
                 c = c + prob_up[k] ;
 
              if ( y[k] == newx[k] ) 
                 c = c + ( 1.0 - prob_up[k] ) ;             
           }
           else if ( z[k] < newx[k] ) {
              if ( y[k] == z[k] ) 
                 c = c + prob_dn[k] ;

              if ( y[k] == newx[k] )
                 c = c + ( 1.0 - prob_dn[k] ) ;              
           }
           else {
              if ( y[k] == newx[k]  ) 
                 c = 1.0;
           } 
           pia[state] = pia[state] * c ;
       }
   }

   //delete [] Cost_ia ;   
   delete [] FreeNodes ;
   delete [] z ;   
   delete [] y ;   
   delete [] newx ;
   delete [] newx2 ;
   delete [] prob_up ;
   delete [] prob_dn ;

}

void nextstate_ia( int *x, int *y, int NumNodes, int MaxInputs, int NumStates,  int **sdds_tt, int *sdds_nv, int **sdds_varf,  float ** sdds_prop,  int *action, int NumNodeEdges ,  int *ActionNodes, int NumCNodes, int *ActionHeads, int *ActionTails, int NumCEdges, int *power2 ) { 
   
   //cout << " see " << x[0] << x[1] << x[2] <<  endl; 
   // local variables
   int * z  = new int [NumNodes] ;
   int * FreeNodes  = new int [NumNodes] ;
   int * newx = new int [NumNodes] ;
   int * newx2 = new int [NumNodes] ;
   float * prob_up = new float [NumNodes];
   float * prob_dn = new float [NumNodes];


   // initializa the z 
   for (int i = 0 ; i < NumNodes ; i ++ ) {
       z[i] = 0 ;
       FreeNodes[i] = 1;
       newx[i] = x[i] ;
       newx2[i] = x[i] ;
       prob_up[i] = sdds_prop[0][i];
       prob_dn[i] = sdds_prop[1][i];
   }

   // Set control nodes to be zero if control is 1
   for (int i = 0; i  <  NumCNodes ; i ++ ) {
       if ( action[i] == 1) {
           newx[ ActionNodes[i] ] = 0;  // Node is desable, put to zero
           newx2[ ActionNodes[i] ] = 0;  // Node is desable, put to zero
           FreeNodes[   ActionNodes[i]  ]  = 0 ; // Node is marked as a cntrol node        
           prob_up[i] = 0.0;
           prob_dn[i] = 0.0;
       }
   }


   // Set control nodes to be zero if control is 1
   for (int i = 0 ; i < NumCEdges; i++ ) {
       if ( action[i + NumCNodes ] == 1) {
           FreeNodes[ ActionHeads[i]  ]  = -1; // Node is marked as a cntrol node
       }
   }

   // compute z, the deterministi next state 
   for (int i = 0; i < NumNodes; i++ ) {

       if ( FreeNodes[i] == 1) {
           int nv = sdds_nv[i];
           int k = 0;
           for (int j = 0 ; j < MaxInputs ; j ++ ) {
               int Indx =  MaxInputs - nv  + j;
               //cout << " " << power2[Indx] << " " << newx[ sdds_varf[j][i] ] << " " <<  sdds_varf[j][i] <<  endl;
               k = k + power2[Indx]*newx[ sdds_varf[j][i] ] ;
           }
	   //cout << " So far so good " << k << " " << i << endl;
           z[i] = sdds_tt[k][i];
       }
       else if ( FreeNodes[i] == -1 ) {
           for (int j = 0 ; j  < NumNodes ; j++ )
               newx[j] = newx2[j] ;

           for ( int j = 0 ; j < NumCEdges; j ++ )
               newx2[ ActionTails[j] ] = 0 ;

           int nv = sdds_nv[i];
           int k = 0;
           for (int j = 0 ; j < MaxInputs ; j ++ ) {
               int Indx =  MaxInputs - nv  + j;
               k = k + power2[Indx]*newx2[ sdds_varf[j][i] ] ;
           }
           z[i] = sdds_tt[k][i];
       }
   }

   for ( int k=0; k<NumNodes; k++ ) {
       double r  = distribution(generator); // random generator

       if ( newx2[k] > z[k] ) {
           if ( r < prob_dn[k] )
              y[k] = z[k];
           else
              y[k] = newx2[k];
       }
       else if ( newx2[k] < z[k]  ) {
           if ( r < prob_up[k] )
              y[k] = z[k];
           else
              y[k] = newx2[k];          
       }
       else {
           y[k] = newx2[k] ; 
       }
   }

   delete [] FreeNodes ;
   delete [] z ;
   delete [] newx ;
   delete [] newx2 ;
   delete [] prob_up ;
   delete [] prob_dn ;

}




//////////////////////////////////////////////////////////////
/// This function compute the new state after  one step of a SDDS
///  The current state is x  (binary array of n elements, 
///  where  n is # of genes).
/// Inputs 
///   x   current state ( array of 1 or 0, with a size of NumNodes)
///   NumNodes  : number of nodes of SDDS
///   MaxInputs : Maximun indegree
///   sdds_nv   : array of number of variables per node
///   sdds_varf : array with the nodes ids for each nodes ( size MaxInputs x NumNodes)  
///   sdds_tt   : array with transition table of the SDDS ( size MaxInputStates x NumNodes )
/// Output
///   y   new state 
void sdds_nextstate(int *x, int *y, int NumNodes, int MaxInputs, int *sdds_nv, int ** sdds_varf, int ** sdds_tt, float ** sdds_prop, int *power2 ) {

   int *z = new int [NumNodes] ; 
   for (int i=0 ; i < NumNodes ; i++ ) {

       int nv = sdds_nv[i];
       int k = 0;
       for (int j = 0 ; j < MaxInputs ; j ++ ) {
           int Indx =  MaxInputs - nv  + j;
           k = k + power2[Indx]*x[  sdds_varf[j][i] ] ;
       }
       z[i] = sdds_tt[k][i];
   }
   

   for (int i=0 ; i < NumNodes ; i++ ) {
       double r  = distribution(generator); // random generator
       if ( x[i] > z[i] ) {
           if ( r < sdds_prop[1][i] )
              y[i] = z[i];
           else
              y[i] = x[i];
       }
       else if (  x[i] < z[i] ) {
           if ( r < sdds_prop[0][i] )
              y[i] = z[i];
           else
              y[i] = x[i];
       }
       else
           y[i] = x[i] ;
   }
}

//////////////////////////////////////////////////////
/// Comppute the cost( or reward) when the systems
/// transition from a current state "i" to an state "j"
/// ehwn the action "a" was taken.
/// Inputs 
/// BinState   : Represent the sate of "j", it is an array that store the binary number
///              most significant digit is first (index=0)
/// NumNodes   : Number of nodes (size of BinState)
/// actions    : Vector that stores the states of nodes and edges of
///              of an specific action
/// NumActions : Number of control nodes + N of control edlges
/// NumCNodes  : Number of control nodes
float cost_ija(int *BinState, int *BadState,  int NumNodes, int *actions, int NumNodeEdges, int NumCNodes, int *ActionNodes, float * Wi ) { 
   ///// Parameters to compute Cost
   float  Cost = 0.0 ;
   float  Wn = 1.0 ;   // Weigth for control nodes
   float  We = 0.5 ; // Wiegth fro control arrows

   //int *Wi = new int [NumNodes];
   int *Freenodes = new int [NumNodes] ;

   for ( int i = 0; i < NumNodes ; i++ ) 
      Freenodes[i] = 1; 

   for ( int i = 0; i < NumCNodes ; i++ ) 
      Freenodes[ ActionNodes[i] ] = 0;
   
   //////////////////////////////////////////////// 

   // cost of control nodes
   for ( int i = 0 ; i < NumCNodes; i++ ) 
      Cost = Cost +  Wn * actions[i] ;

   // cost of control edges
   for ( int i = NumCNodes ; i < NumNodeEdges  ; i++ ) 
      Cost = Cost +  We  * actions[i] ;

   // cost of bad state
   for ( int  i = 0; i < NumNodes; i++){ 
      if  (( Freenodes[i] == 1 ) && ( BinState[i] != BadState[i]) ) {
         Cost = Cost + Wi[i] ;
      }
   }

   //delete [] Wi ; 
   delete [] Freenodes ;
   return Cost ;
   
}



//////////////////////////////////////////////////////
///Convert decimal number to binary   
///Inputs  
///BinState : Vector that store the binary number
///           most significant digit is first (index=0)
///NumNodes : Number of bits(Nodes) of the final binary number
///State    : Decimal number to be converted to binary

///output 
///Binstate
/////////////////////////////////////////////////////
void dec2binary( int *BinState, int NumNodes, int State) {

   int bit = NumNodes -1;
   int number = State;
   do{
      if ( (number & 1) == 0 )
         BinState[bit] = 0 ;
      else
         BinState[bit] = 1 ;

      number >>= 1;
      bit--;
   } while ( number );

   for (int i = bit ; i >= 0 ; i--)
       BinState[i] = 0 ;
} 

/////////////////////////////////////////////////////
/// Function tht compute the maximum diference between
/// two arrays
float normax ( float * array1,  float * array2 , int NumElements ) {

   float maximum = -1.0;
   for (int i = 0 ; i <  NumElements; i++) {
       float diff = array1[i] - array2[i] ;

       if ( diff < 0.0 ) 
           diff = -1.0 * diff ;
              
       if ( diff > maximum )
           maximum = diff ;
   }
   return maximum ;
}

