// GraphCluster.cpp
//
// Module to Discretize a set of Time Series
//
//	Partitions a weighted graph of the distances between every pair
//	of numbers in the time series into closley coupled clusters.
//
//	Correlation is used to guide discretization of time series
//		with relatively small ranges.
//
//  Created		3-June-2004		by Elena Dimitrova & John McGee 
//	Last update 9-June-2004
//
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <fstream>
#include <stdlib.h>
#include <string>

using namespace std;

//#include "RankCorr.h"
#include "GraphMeasure.h"

/* static double tar_data[] = 
	{ 
		0.0000492,
		0.0000846,
		0.000116,
		0.00014,
		0.000158,
		0.000171,	
		0.00018,
		0.000187,
		0.000192,	
		0.000195,
		0.000197,
		0.000198,
		0.000198,
		0.000198,
		0.000197,
		0.000196,
		0.000195,
		0.000193,
		0.000191,
		0.000189 ,
		0.000187,
		0.000185,
		0.000183,
		0.00018,
		0.000178,	
		0.000175,
		0.000173,	
		0.00017,
		0.000167,
		0.000165,
		0.000162,
		0.000159,
		0.000156,
		0.000153,
		0.000151,
		0.000148,
		0.000145,
		0.000142,
		0.00014,
		0.000137,
		0.000134,
		0.000131,
		0.000129,
		0.000126,
		0.000123,
		0.000121,
		0.000118,
		0.000116,
		0.000113,
		0.000111
	};

static double nicotine_data[] = 
	{ 
		0.0000758,
		0.0000967,
		0.000139,
		0.000139,
		0.000139,
		0.000283,
		0.000324,
		0.000362,
		0.000395,
		0.000424,
		0.00045,
		0.000473,
		0.000493,
		0.000511,
		0.000526,
		0.000539,
		0.00055,
		0.000559,
		0.000566,
		0.000572 ,

		0.000576,	
		0.000579,
		0.000581,
		0.000581,
		0.000581,
		0.000579,
		0.000577,
		0.000573,
		0.000569,
		0.000564,
		0.000559,
		0.000553,
		0.000547,
		0.00054,
		0.000532,
		0.000525,
		0.000517,
		0.000508,
		0.0005,
		0.000491,
		0.000482,
		0.000473,
		0.000463,
		0.000454,
		0.000444,
		0.000434,
		0.000425,
		0.000415,
		0.000405,
		0.000395
	};
*/
//static double var1[] = {0,1,2,2,1,0,0,0,0};

//static double var2[] = {0,0,2,2,1,0,0,0,0};
		

/*int test_rank_corr()
{
	string s, t;
	int x, y;
	double z;
	double cc = 0;
	char buffer[1000];
	int i, j;
	// A two-dimensional array (a matrix) to store the genes; each row will contain a gene
	GenesVector genes;
	ValueList one_gene;

	ifstream infile ( "Genes_Somogyi.txt" );
	if (! infile.is_open())
	{ cout << "Error opening file"; exit (1); }
	while ( !infile.eof() )
	{
		infile.getline( buffer, 1000 );
		s = std::string( buffer );
		s += "  ";
		x = 0;
		while( x != s.npos )
		{
			x = s.find_first_of ( "-0123456789.", x );
			y = s.find_first_not_of( "-.0123456789", x );
			if( x != s.npos )
			{
				z = atof( s.substr( x, y-x ).c_str() );
				one_gene.push_back(z);
				x = y;
			}
		}
		genes.push_back(one_gene);
		one_gene.clear();
	}
	
	infile.close();

//	size_t n = sizeof( var1 ) / sizeof( double );
	SpearmanRankCorrelate SRC;

	int n = genes.front().size();
	ofstream corr_file ("Correlations_Somogyi.txt");
//	cout <<  genes.size();
	for(i = 0; i < genes.size(); ++i)
	{
		for(j = i+1; j < genes.size(); ++j)
		{
			cc = SRC.RankCorrelate( genes.at(i), genes.at(j), n );
//			corr_file << "Genes (" << i << ", " << j << "), Correlation = " << cc;
			corr_file << "(" << i << ", " << j << ")	" << cc;
			if ( SRC.TestSignificance(cc, n) )
			{		
				corr_file << "	1"<<endl;
			}
			else
			{
				corr_file << "	0"<<endl;
			}
		}
	}
/*
	for(i = 0; i < genes.size()/2; ++i)
	{
		for(j = genes.size()/2; j < genes.size(); ++j)
		{
			cc = SRC.RankCorrelate( genes.at(i), genes.at(j), n );
//			corr_file << "Genes (" << i << ", " << j << "), Correlation = " << cc;
			corr_file << "(" << i << ", " << j << ")	" << cc;
			if ( SRC.TestSignificance(cc, n) )
			{		
				corr_file << "	1"<<endl;
			}
			else
			{
				corr_file << "	0"<<endl;
			}
		}
		corr_file << endl;
	}

	for(i = 0; i < genes.size()/2; ++i)
	{
		size_t dgene = i + genes.size()/2;
		cc = SRC.RankCorrelate( genes.at(i), genes.at(dgene), n );
		corr_file << "(" << i << ", " << dgene << ")	" << cc;
		if ( SRC.TestSignificance(cc, n) )
		{		
			corr_file << "	1"<<endl;
		}
		else
		{
			corr_file << "	0"<<endl;
		}
	}

	corr_file.close();
	return 0;

}
*/
/*
int test_graph_discretize()
{

	// Create a list of random values
	double values[] = { 1, 7, 3, 4, 5 };
	size_t k = sizeof( tar_data ) / sizeof( tar_data[0] );

	ValueList vlist;
	size_t i;
	for( i = 0; i < k; ++i )
	{
//		double v = ( rand() * 5.0 ) / RAND_MAX;
		vlist.push_back( tar_data[i] );
	}

	// Form a weighted graph representing the distances between all
	//  unique pairs of values
	WeightedGraph graph( vlist );

	cout << graph << endl;

	// Form a sorted list of all the edges
	graph.IndexEdgeWeights( );

	EdgeList el;
	WeightedEdge e;
	bool still_connected = true; 

	// As long as the graph is still connected
	while( still_connected )
	{
		EdgeList el = graph.FindHeaviestEdges( );             
		EdgeListIter we_iter = el.begin( );
		while( we_iter != el.end( ) && still_connected )
		{
			e = *we_iter;
			graph.RemoveEdge( e.A, e.B );
			still_connected = graph.IsGraphConnected();
			// next heavy edge
			++we_iter;
		}
	}

	cout << graph << endl;

	WeightedGraph sub_graphA = graph.ExtractSubGraph( e.A );

	cout << "Subgraph A" << endl;
	cout << sub_graphA << endl;

	WeightedGraph sub_graphB = graph.ExtractSubGraph( e.B );

	cout << "Subgraph B" << endl;
	cout << sub_graphB << endl;

	return 0;
}

int test_edge_connectivity()
{
	double values[] = { 1, 7, 3, 4, 5 };
	ValueList vlist;
	size_t i, j;
	for( i = 0; i < 5; ++i )
	{
		vlist.push_back( values[i] );
	}

	// Form a weighted graph representing the distances between all
	//  unique pairs of values
	WeightedGraph graph( vlist );
	cout << graph << endl;
	for( i = 0; i < 5; ++i )
	{
		for( j = i + 1; j < 5; ++j )
		{
			graph.RemoveEdge (i, j);
			cout << "Remove edge ( " << i + 1 <<", " << j + 1<< " ) --" << endl;
			if ( graph.IsGraphConnected() )
					cout << "\tGraph still connected." << endl;
			else
				cout << "\tGraph disconnected." << endl;
		}
	}
	cout << graph.MinDegree() << endl;
	return 0;
}

int test_disconnect_further()
{
	double values[] = { 5, 9, 10, 20 };
	ValueList vlist;
	size_t i;
	for( i = 0; i < 4; ++i )
	{
		vlist.push_back( values[i] );
	}

	// Form a weighted graph representing the distances between all
	//  unique pairs of values
	WeightedGraph graph( vlist );
	cout << graph << endl;
	for( i = 0; i < 1; ++i )
	{
		for( j = i + 1; j < 4; ++j )
		{
			graph.RemoveEdge (i, j);
			cout << "Remove edge ( " << i + 1 <<", " << j + 1<< " ) --" << endl;
			if ( graph.IsGraphConnected() )
					cout << "\tGraph still connected." << endl;
			else
				cout << "\tGraph disconnected." << endl;
		}
	}
	cout << graph << endl;

	if( graph.DisconnectFurther( graph ) ) 
		cout << "Disconnect further." << endl;
	else
		cout << "Do NOT disconnect further." << endl;
	cout << graph << endl;
	return 0;
}


int extract_graph()
{
	double values[] = { 1, 9, 10, 20 };
	ValueList vlist;
	size_t i;
	EdgeList edge_list;
	WeightedEdge edge;

	for( i = 0; i < 4; ++i )
	{
		vlist.push_back( values[i] );
	}

	// Form a weighted graph representing the distances between all
	//  unique pairs of values
	WeightedGraph graph( vlist );
	cout << graph << endl;
	
	while( graph.IsGraphConnected() )
	{
		edge_list = graph.FindHeaviestEdges();
		// Remove all edge(s) of heaviest weight
		while( !edge_list.empty() )
		{
			edge = edge_list.front();
			edge_list.pop_front();
			graph.RemoveEdge( edge.A, edge.B );
		}
	}
	cout << graph.ExtractSubGraph( values[0] ) << endl;
	
	return 0;
}


int test_split_graph()
{
	size_t i;
	ValueList vlist;
	GraphVector vectorOFgraphs;
	double values[] = {1,2, 4,5,6};
/*0.00,
2.45,
4.90,
7.35,
9.80,
12.20,
14.70,
17.10,
19.60,
22.00,
24.50,
26.90,
29.40,
31.80,
34.30,
36.70,
39.20,
41.60,
44.10,
46.50,
49.00,
51.40,
53.90,
56.30,
58.80,
61.20,
63.70,
66.10,
68.60,
71.00,
73.50,
75.90,
78.40,
80.80,
83.30,
85.70,
88.20,
90.60,
93.10,
95.50,
98.00,
100.00,

103.00,
105.00,

108.00,
110.00,

113.00,
115.00,

118.00,
120.00,
	
10000.00};


	for( i = 0; i < 5; ++i )
	{
		vlist.push_back( values[i] );
	}

	vectorOFgraphs = DisconnectAndSplit( vlist );
	GraphVectorIter graph_iter = vectorOFgraphs.begin();
	ofstream examplefile ("example.txt");
	while( !vectorOFgraphs.empty() )
	{
		if (examplefile.is_open())
			examplefile << vectorOFgraphs.front() << endl;
		
		vectorOFgraphs.erase( graph_iter );
	}	
	examplefile.close();

	return 0;

}

int TimeSeries()
{
	size_t i;
	DoublesList orig_values;
	ValueList noRepeatedValues;
	ValueListIter list_iter;
	GraphVector vectorOFgraphs;
	double values[] = {1,1,1,2,2, 3,4};
	for( i = 0; i < 7; ++i )
	{
		orig_values.push_back( values[i] );
	}
	noRepeatedValues = RemoveRepeatedAndDiscr( orig_values );
	vectorOFgraphs = DisconnectAndSplit( noRepeatedValues );
	GraphVectorIter graph_iter = vectorOFgraphs.begin();
	ofstream examplefile ("example.txt");
	while( !vectorOFgraphs.empty() )
	{
		if (examplefile.is_open())
			examplefile << vectorOFgraphs.front() << endl;
		
		vectorOFgraphs.erase( graph_iter );
		//GraphVectorIter graph_iter = vectorOFgraphs.begin();
	}	
	examplefile.close();
	
	return 0;
}

int subsitute_test()
{
	ValueList Discr;
	ValueListIter iter;
	DoublesList orig_values;
	size_t i;
	double values[] = //{ 1,2, 4,5,6,7,8,9,10,11,12,13,   30};//{1,2,3,4,5, 10};
/*	{
		0.000049,

		0.000086,

		0.000120,

		0.000146,
		0.000166,
		0.000182,
		0.000194,
		0.000204,
		0.000211,
		0.000217,
		0.000221,
		0.000224,
		0.000227,
		0.000229,
		0.000230,
		0.000231,
		0.000232,
		0.000232,
		0.000232,
		0.000232,
		0.000232,
		0.000232,
		0.000232,
		0.000232,
		0.000231,
		0.000231,
		0.000231,
		0.000230,
		0.000229,
		0.000229,
		0.000228,
		0.000227,
		0.000226,
		0.000225,
		0.000224,
		0.000223,
		0.000222,
		0.000220,
		0.000219,
		0.000217,
		0.000215,
		0.000213,
		0.000211,
		0.000208,
		0.000206,
		0.000203,
		0.000200,
		0.000197,
		0.000194,
		0.000191
	};
	



{
0.002030,
0.002210,

0.002440,

0.002640,

0.002830,

0.003000,

0.003160,

0.003310,

0.003450,
0.003570,
0.003680,
0.003790,
0.003890,
0.003970,
0.004050,
0.004130,
0.004190,
0.004250,
0.004310,
0.004360,
0.004410,
0.004450,
0.004480,
0.004510,
0.004540,
0.004570,
0.004590,
0.004610,
0.004620,
0.004630,
0.004640,
0.004650,
0.004650,
0.004650,
0.004640,
0.004630,
0.004620,
0.004610,
0.004590,
0.004570,
0.004540,
0.004520,
0.004480,
0.004450,
0.004410,
0.004370,
0.004330,
0.004290,
0.004240,
0.004190
};

	size_t n = sizeof( values ) / sizeof( values[0] );
	for( i = 0; i < n; ++i )
	{
		orig_values.push_back( values[i] );
	}
	Discr = RemoveRepeatedAndDiscr( orig_values );
	iter = Discr.begin();
	while( !Discr.empty() )
	{
		cout << Discr.front() << endl;
		//iter = Discr.begin();
		Discr.erase( iter );
	}
	return 0;

}


/*int test_isGraphConnected()
{
	size_t i;
	ValueList vlist;
	GraphVector vectorOFgraphs;
	double values[] = { 1 };
	for( i = 0; i < 1; ++i )
	{
		vlist.push_back( values[i] );
	}
	WeightedGraph graph( vlist );
	cout << graph << endl;
	cout << graph.IsGraphConnected() << endl;
	return 0;

*/


int main( int argc, char* argv[] )
{
	InputFilesList FileList;

	if( argc >= 2 )
	{
		size_t numberOfFiles = argc - 1;
		size_t i;
		for( i = 0; i < numberOfFiles; ++i )
		{
			FileList.push_back( argv[i+1] );
		}
	}
	else
	{
		std::cout << "USAGE: " << argv[0] << " (space separated list of files)" << std::endl;
		return -1;
	}
	DiscretizeAllVariables( FileList );

	return 0;
}

