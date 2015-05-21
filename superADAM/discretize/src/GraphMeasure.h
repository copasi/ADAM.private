// GraphMeasure.h

#ifndef _POLYMATH_DISCRETIZATION_GRAPH_MEASURE_H_
#define _POLYMATH_DISCRETIZATION_GRAPH_MEASURE_H_

// vector - a dynamic array template
#include <vector>
// list - a doubly linked list template
#include <list>
// set - a ordered set of unique values
#include <set>
// algorithm - provides sort, find, ... methods
#include <algorithm>
// iostream - for console input/output
#include <iostream>

using namespace std;

#include "BoolArray.h"

// Define types for a List of unsigned integers
typedef list<size_t> IndexList;
typedef IndexList::iterator IndexListIter;

// Define types for a List of doubles
typedef list<double> DoublesList;
typedef DoublesList::iterator DoublesListIter;

// Define types for a List of long doubles
typedef list<long double> LongDoubleList;
typedef LongDoubleList::iterator LongDoubleListIter;

// Define types for a Vector of unsigned integers
typedef vector<size_t> IndexVector;
typedef IndexVector::iterator IndexVectorIter;

// Define types for a Set of unsigned integer
typedef set<size_t> IndexSet;
typedef IndexSet::iterator IndexSetIter;

// Define types for a Vector of doubles
typedef vector<double> ValueList;
typedef ValueList::iterator ValueListIter;

// Define a structure to hold a pair of node numbers (indices)
struct NodePair
{
	size_t	A;
	size_t	B;
};

// Define a List of node pairs to represent a path
typedef list<NodePair> NodePairList;
typedef NodePairList::iterator NodePairListIter;

// Define a Vector of node pair lists to represent a list of paths
typedef vector<NodePairList> PathList;
typedef PathList::iterator PathListIter;

// Define a structure to hold weighted edge information
struct WeightedEdge
{
	size_t	A;
	size_t	B;
	double  w;

	bool operator>( const WeightedEdge& other ) const
	{
		return w > other.w;
	}
};

// Define a type for a list of edges
typedef list<WeightedEdge> EdgeList;
typedef EdgeList::iterator EdgeListIter;

// Define another structure to hold weighted edge information
struct WeightedEdge2
{
	size_t	A;
	size_t	B;
	double  w;
};

// Define a type for a list of edges
typedef vector<WeightedEdge> EdgeVector;
typedef EdgeVector::iterator EdgeVectorIter;

// Define a structure to hold the matirix of time series information
struct Matrix
{
	double**	m;
	size_t		rows;
	size_t		cols;
	IndexList	removed;
};


// A class to hold a weighted graph
class WeightedGraph
{
public:
	// Construct a weighted graph object of n nodes
	//   with no initial edges
	WeightedGraph( size_t n );

	// Construct a weighted graph representing the distances between
	//  every pair of values in the given list
	WeightedGraph( const ValueList& vlist );

	// Copy constructor
	WeightedGraph( const WeightedGraph& other);

	// Set the element of the weight matrix at [i,j]
	void Set( size_t i, size_t j, const double& w );

	// Return the element of the weight matrix at [i,j]
	double Get( size_t i, size_t j ) const;

	// Use a breadth-first traversal to find the shortest non-weighted path between a and b.
	// If there is a path between a and b, return -1;
	//  if there is no path between a and b, return the number of visited nodes.
	int Breadth_first( int a, int b ) const;

	// Return true if there exists a path between a and b
	bool IsConnected( size_t a, size_t b );

	// Returns true if the graph is connected
	bool IsGraphConnected();

	// Returns the minimum vertex degree of a graph
	int MinDegree( ) const;

	// Remove the weighted edge directly connecting a to b
	//  return true if this disconnects the graph
	void RemoveEdge( size_t a, size_t b );

	// Determines if a subgraph should be further disconnected.
	bool DisconnectFurther( WeightedGraph graph );

	// Return the average weight of this graph
	double AvgWeight( );

	// Extract the subgraph that contains a
	WeightedGraph ExtractSubGraph( size_t a );

	// Convert the weight matrix to a list of weighted edges
	//	sorted in decreasing order by weight
	void IndexEdgeWeights( );

	// Return a list of the edges (a,b) of maximal weight
	EdgeList FindHeaviestEdges( );

	// Return the maximum edge weight of a graph
	double MaxWeight();

	// Returns true if the distance between adjacent vertices of a connected graph
	//  with more then one vertex is the same for all vertices, e.g. 1,2,3,4,5
	bool IsDistanceSame( );


	friend ostream& operator<<( ostream& out, const WeightedGraph& g );

	inline size_t Size( ) const { return mNumNodes; } 

	inline size_t Vertex( size_t i ) const { return mVertexLabels[i]; }

private:
	// Number of nodes (vertices) in this graph
	size_t		mNumNodes;

	// Numbers labeling each of the vertices
    IndexVector	mVertexLabels;

	// A matrix of edge weights
	// mWeightMatrix[i][j] != 0 => edge (i,j) exists in the graph
	double**	mWeightMatrix;

	// A list of weighted edges sorted in decreasing weight order
	EdgeList	mSortedEdges;
	// The initial average weight of the graph before any edge is removed
	static double	initAvgWeight;
	// The maximum edge weight of the graph before any edge is removed
	//  (in fact the distance between the two most distant points in the time series)
	static double	initMaxWeight;
};

// Define a Vector of weighted graphs
typedef vector<WeightedGraph> GraphVector;
typedef GraphVector::iterator GraphVectorIter;

// Define a Vector of vectors of discretized variables
typedef vector<ValueList> DiscrVars;
typedef DiscrVars::iterator DiscrVarsIter;

// Sort the graphs in a vector by the label of the virst node
GraphVector SortGraphs( GraphVector components );

// Read MULTIPLE time series from files and arranges them into matrices.
//  Each column is a variable.
Matrix MatrixOfTimeSeries ( const char* filename );

// Remove flat variables
Matrix RemoveFlat( Matrix mtx );

// Calculates the separaton measure of a discretized variable.
double SeparationMeasure( WeightedGraph orig_graph, GraphVector components );

// Define types for a vector of lists of double
typedef vector<DoublesList> DoublesListVector;
typedef DoublesListVector::iterator DoublesListVectorIter;

// Define a structure to hold discretized variable and its separation measure information
struct GraphSepMeasure
{
	size_t				index;
	GraphVector			components;
	double				separation_measure;
	ValueList			time_series;
	ValueList			shift_time_series;
	ValueList			discr_time_series;
	DoublesListVector	clusters;
	unsigned int		field;
	char*				error_message;

	bool operator>( const GraphSepMeasure& other ) const
	{
		return index > other.index;
	}
};

//void siftDown( EdgeVector numbers, int root, int bottom );

// Define a type for a list graphs and separation measures
typedef list<GraphSepMeasure> GraphSepMeasureList;
typedef GraphSepMeasureList::iterator GraphSepMeasureListIter;

// Define a type for a list of file names
typedef list<const char*> InputFilesList;
typedef InputFilesList::iterator InputFilesListIter;

// Discretize multiple time series given in files
Matrix DiscretizeAllVariables( InputFilesList& FileList );

// If the max number of states per variable is not prime, 
//  keep disconnecting until a prime is reached
GraphSepMeasureList DisconnectToGetPrime ( GraphSepMeasureList variables );

// Removes repeated values from the time series and discretizes it
GraphSepMeasure RemoveRepeatedAndDiscr ( DoublesList orig_values, const size_t var_index );

//Reapeatedly disconnect a connected graph and store the two subgraphs into 
//  a vector of graphs; return a vector of graphs and its separation measure
GraphSepMeasure DisconnectAndSplit( const ValueList& vlist, const size_t var_index);

// Determine which variables are strongly correlated
Matrix Correlation( InputFilesList FileList, GraphSepMeasureList variables, IndexList removed );

// Discretize similarly strongly correlated variables
GraphSepMeasureList CommonDiscretization( GraphSepMeasureList correlated_variables );

// Inserts empty states into the leading variable's discretization to make them a power of a prime number
GraphSepMeasure InsertStates( GraphSepMeasure var );

// Continue to split if a component contains more than half of all the points
GraphSepMeasureList InfoMeasure( GraphSepMeasureList variables );


#endif // _POLYMATH_DISCRETIZATION_GRAPH_MEASURE_H_
