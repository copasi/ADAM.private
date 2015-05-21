// GraphMeasure.cpp

/***	TAKES MULTIPLE TIME SERIES AS AN INPUT		***
	Works with negative time points.
	Removes flat variables. Does chop equally spaced points.
	Sets separation measure to 0 for variables whose clusters contain one point each.	
	If a center of mass is b/n two centers, split the cluster. Takes the reciprocal of the separation measure.
	Does not apply graph.IsDistanceSame().																		 */


#include "GraphMeasure.h"
#include <cmath>
#include <fstream>
#include <iostream>
#include <string>
#include <stdlib.h>

//#include "RankCorr.h"

#define DISCR_THRESHOLD 0.5
//#define DISCR_THRESHOLD 0.08

// This compare will force decending order
// struct CompareEdges
// {
//	bool operator()( const WeightedEdge& a, const WeightedEdge& b )
//	{
// 		return a.w > b.w;
//	}
//};

/*bool CompareEdges( const WeightedEdge& a, const WeightedEdge& b )
{
	return a.w > b.w;
}
bool CompareGraphs( const WeightedGraph& g, WeightedGraph& h )
{
	

}
*/

double WeightedGraph::initAvgWeight;
double WeightedGraph::initMaxWeight;

// Construct a weighted graph object of n nodes
WeightedGraph::WeightedGraph( size_t n )
{
	mNumNodes = n;
	size_t i,j;

	// Make an array of n pointers to arrays of doubles,
	//  where each array represents a column of the matrix
	mWeightMatrix = new double*[n];

	for( i = 0; i < n; ++i )
	{
		// Make labels 1 thru n
		mVertexLabels.push_back( i );

		mWeightMatrix[i] = new double[n];
		for( j = 0; j < n; ++j )
		{
			mWeightMatrix[i][j] = 0.0;
		}
	}
}

// Construct a weighted graph representing the distances between
//  every pair of values in the given list
WeightedGraph::WeightedGraph( const ValueList& vlist )
{
	mNumNodes = vlist.size( );
	size_t i,j;
	double sum = 0.0;
	size_t n = mNumNodes;
	size_t zero_edges = 0, nonzero_edges = 0;
	// Make an array of n pointers to arrays of doubles,
	//  where each array represents a column of the matrix
	mWeightMatrix = new double*[n];

	for( i = 0; i < n; ++i )
	{
		// Make labels 1 thru n
		mVertexLabels.push_back( i );

		mWeightMatrix[i] = new double[n];
		for( j = 0; j < i + 1; ++j )
		{
			mWeightMatrix[i][j] = 0.0;
			++zero_edges;
		}
		for( j = i + 1; j < n; ++j )
		{
			mWeightMatrix[i][j] = fabs( vlist[i] - vlist[j] );
			++nonzero_edges;
		}
	}
	IndexEdgeWeights();
	for( i = 0; i < n; ++i )
	{
		for( j = i + 1; j < n; ++j )
		{
			sum += mWeightMatrix[i][j];
		}
	}
	initAvgWeight = sum / (n*(n-1)/2);
	
	double maxWeight = 0.0;
	EdgeListIter e_iter = mSortedEdges.begin();

	while( e_iter != mSortedEdges.end() )
	{
		if( e_iter->w > maxWeight )
		{
			maxWeight = e_iter->w;
		}
		++e_iter;
	}
	initMaxWeight = maxWeight;
}

// Copy constructor
WeightedGraph::WeightedGraph( const WeightedGraph& other)
{
	mNumNodes = other.mNumNodes;

	mWeightMatrix = new double*[mNumNodes];

	size_t i,j, sum = 0;
	for( i = 0; i < mNumNodes; ++i )
	{
		// Make labels 1 thru n
		mVertexLabels.push_back( other.mVertexLabels[ i ] );

		mWeightMatrix[i] = new double[mNumNodes];
		for( j = 0; j < mNumNodes; ++j )
		{
			mWeightMatrix[i][j] = other.mWeightMatrix[i][j];
		}
	}
	IndexEdgeWeights();
}


// Set the element of the weight matrix at [i,j]
void WeightedGraph::Set( size_t i, size_t j, const double& w )
{
	if( ( i >= mNumNodes ) || ( j >= mNumNodes ) )
	{
		throw( "WeightedGraph::Set - index out of bounds" );
	}

	mWeightMatrix[i][j] = w;

	// Update the edge list
	WeightedEdge e = {i, j, w };
	mSortedEdges.push_back( e );

	mSortedEdges.sort( std::greater<WeightedEdge>() );

}

// Get the element of the weight matrix at [i,j]
double WeightedGraph::Get( size_t i, size_t j ) const
{
	if( ( i >= mNumNodes ) || ( j >= mNumNodes ) )
	{
		throw( "WeightedGraph::Get - index out of bounds" );
	}

	return mWeightMatrix[i][j];
}

// If there is a path between a and b, return -1;
//  if there is no path between a and b, return the number of visited nodes.
int WeightedGraph::Breadth_first( int a, int b ) const
{
// Use a breadth-first traversal to find the shortest non-weighted path between a and b
	/*
		Based on ICS 161: Design and Analyis of Algorithms
		Lecture Notes for February 15, 1996
		Department of Information & Computer Science, UC Irvine
		by David Eppstein
	*/

//	cout << "Breadth_first..." << endl;
	// List of nodes that we want to visit next, start with 'a'
	IndexList visit_list;
	visit_list.push_back( a );

	// Set of nodes that have already been on the visit list
	//   this is a <set> to make the lookup fast O(ln(N));
	IndexSet marked_set;

	IndexSetIter iter;
	while( !visit_list.empty() )
	{
		// Remove the first element from the visited list
		int x = visit_list.front();
		visit_list.pop_front( );

		// If it is the destination, we found a path
		if( x == b ) return -1;

		// Add every non-marked node connected to w to the visit_list
		size_t k;
		for( k = 0; k < x; ++k )
		{
			if( mWeightMatrix[k][x] != 0.0 )
			{
				// If k is not in the marked_set, then add it to both
				iter = marked_set.find( k );
				if( iter == marked_set.end() )
				{
					marked_set.insert( k );
					visit_list.push_back( k );
				}
			}
		}
		for( k = x+1; k < mNumNodes; ++k )
		{
			if( mWeightMatrix[x][k] != 0.0 )
			{
				// If k is not in the marked_set, then add it to both
				iter =  marked_set.find( k );
				if( iter == marked_set.end() )
				{
					marked_set.insert( k );
					visit_list.push_back( k );
				}
			}
		}
	}
	// We could not find a path from a to b
	return marked_set.size();
}

bool WeightedGraph::IsConnected( size_t a, size_t b ) 
{
	if( ( a >= mNumNodes ) || ( b >= mNumNodes ) )
	{
		throw( "WeightedGraph::IsConnected - node number out of bounds" );
	}

	size_t n = mNumNodes;
	// Count the number of nonzero edges
	size_t num_edges = 0;
	EdgeListIter e_iter = mSortedEdges.begin();
	while( e_iter != mSortedEdges.end() )
	{
		if( e_iter->w != 0)
			++num_edges;
		++e_iter;
	}
	size_t m = num_edges;
	// a and b can not be connected if nobody is
	if( m == 0 ) return false;

	// Graph must be connected if less than N - 1 edges are missing
	//  from the complete graph which has N * (N - 1) / 2
	if( m > (n - 1)*( n - 2 ) / 2 ) return true;

	if ( Breadth_first( a, b ) == -1)
		return true;
	else
		return false;
}

// Returns true if the graph is connected
bool WeightedGraph::IsGraphConnected()
{
//	cout << "IsGraphConnected..." << endl;
	size_t n = mNumNodes;
	// Count the number of nonzero edges
	size_t num_edges = 0;
	EdgeListIter e_iter = mSortedEdges.begin();
	while( e_iter != mSortedEdges.end() )
	{
		if( e_iter->w != 0)
			++num_edges;
		++e_iter;
	}
	size_t m = num_edges;

	// A single node is considered a connected graph
	if( n == 1 ) return true;
	// cannot be connected if nobody is
	if( m == 0 && n > 1) return false;

	// Graph must be connected if less than N - 1 edges are missing
	//  from the complete graph which has N * (N - 1) / 2 edges
	if( m > (n - 1)*( n - 2 ) / 2 ) 
		return true;

	// Graph must be disconnected if there are less than N - 1 edges
	if( n - 1 > m )	
		return false;
	
	// We could not find a path from a to b
	if ( Breadth_first( 0, -1 ) == n ) 
		return true;
	else
		return false;
}

// Returns the minimum vertex degree of a graph
int WeightedGraph::MinDegree( ) const
{
	size_t n = mNumNodes;
	size_t i, j, k, min = n, deg = 0;

	for( k = 0; k < n; ++k )
	{
		for( i = 0; i < k; ++i )
		{
			if (this->Get(i,k) > 0.0)
				++deg;
		}
		for( j = k+1; j < n; ++j )
		{
			if (this->Get(k,j) > 0.0)
				++deg;
		}
		if(deg < min)		
			min = deg;
		deg = 0;
	}
	return min;
}

// Remove the weighted edge directly connecting a to b
//  return true if the graph remains connected
void WeightedGraph::RemoveEdge( size_t a, size_t b )
{
	if( ( a >= mNumNodes ) || ( b >= mNumNodes ) )
	{
		throw( "WeightedGraph::RemoveEdge - index out of bounds" );
	}

	// Set the weight of edge a,b to zero
	this->mWeightMatrix[a][b] = 0.0;

	// Remove the a,b edge from the edge list
	EdgeListIter iter = mSortedEdges.begin( );
	while( iter != mSortedEdges.end() )
	{
		if( ( iter->A == a ) && ( iter->B == b ))
		{
			mSortedEdges.erase( iter );
			break;
		}
		++iter;
	}
	//return IsConnected( a, b );
}

EdgeVector siftDown( EdgeVector numbers, int root, int bottom )
{
  int done, maxChild;
  WeightedEdge temp;
//  cout << "siftDown..." << endl;
  done = 0;
  while ((root*2 < bottom-1) && (!done))
  {
    if (root*2 == bottom)
      maxChild = root * 2;
    else if (numbers.at(root * 2).w > numbers.at(root * 2 + 1).w)
      maxChild = root * 2;
    else
      maxChild = root * 2 + 1;

    if (numbers.at(root).w < numbers.at(maxChild).w)
    {
      temp = numbers.at(root);
      numbers.at(root) = numbers.at(maxChild);
      numbers.at(maxChild) = temp;
      root = maxChild;
    }
    else
      done = 1;
  }
  return numbers;
}

// Using the weight matrix, create a list of edges sorted by weight
void WeightedGraph::IndexEdgeWeights( )
{
//	cout << "IndexEdgeWeights... " << endl;
	int i, j, mSortedSize = 0, numEdges = 0;
	size_t num = mNumNodes;
	EdgeVector edges;
	EdgeVectorIter edgeIter = edges.begin();

	edges.clear();

	for( i = 0; i < num; ++i )
	{
		for( j = i + 1; j < num; ++j )
		{
			WeightedEdge e = { i, j, mWeightMatrix[i][j] };
			edges.push_back( e );
			mSortedEdges.push_back( e );
		}
	}

	numEdges = mSortedEdges.size();
	mSortedEdges.sort( std::greater<WeightedEdge>() );
	if( mSortedEdges.size() < numEdges )
	{
		WeightedEdge temp;
		int array_size = edges.size();

		for (i = (array_size / 2)-1; i >= 0; i--)
		{
			int root = i, bottom = array_size;
			int done, maxChild;
			WeightedEdge temp;
//			cout << "siftDown..." << endl;
			done = 0;
			while ((root*2 < bottom-1) && (!done))
			{
				if (root*2 == bottom)
				  maxChild = root * 2;
				else if (edges.at(root * 2).w > edges.at(root * 2 + 1).w)
				  maxChild = root * 2;
				else
				  maxChild = root * 2 + 1;

				if (edges.at(root).w < edges.at(maxChild).w)
				{
				  temp = edges.at(root);
				  edges.at(root) = edges.at(maxChild);
				  edges.at(maxChild) = temp;
				  root = maxChild;
				}
				else
				  done = 1;
			}
		}
//			edges = siftDown(edges, i, array_size);

		for (i = array_size-1; i >= 1; i--)
		{
			temp = edges.at(0);
			edges.at(0) = edges.at(i);
			edges.at(i) = temp;
			
			int root = 0, bottom = i-1;
			int done, maxChild;
			WeightedEdge temp;
//			cout << "siftDown..." << endl;
			done = 0;
			while ((root*2 < bottom-1) && (!done))
			{
				if (root*2 == bottom)
				  maxChild = root * 2;
				else if (edges.at(root * 2).w > edges.at(root * 2 + 1).w)
				  maxChild = root * 2;
				else
				  maxChild = root * 2 + 1;

				if (edges.at(root).w < edges.at(maxChild).w)
				{
				  temp = edges.at(root);
				  edges.at(root) = edges.at(maxChild);
				  edges.at(maxChild) = temp;
				  root = maxChild;
				}
				else
				  done = 1;
			}
			//edges = siftDown(edges, 0, i-1);
		}
		mSortedEdges.clear();	
		for( i = 0; i < edges.size(); ++i )
			mSortedEdges.push_front( edges.at(i) );
	}
/*		ofstream ef1 ("after_sort.txt");
		for( i = 0; i < mSortedEdges.size(); ++i )
		{
			if (ef1.is_open())
			{
				ef1 << "(" << mSortedEdges.front().A << ", " << mSortedEdges.front().B << ") " << mSortedEdges.front().w << endl;
				mSortedEdges.push_back( mSortedEdges.front() );
				mSortedEdges.pop_front();
			}
		}
		ef1.close();
*/
}

// Return the average weight of the edges of this graph
double WeightedGraph::AvgWeight()
{
	double total_weight = 0.0;
	size_t num_edges = 0;

	EdgeListIter e_iter = mSortedEdges.begin();
	while( e_iter != mSortedEdges.end() )
	{
		if( e_iter->w != 0 )
			++num_edges;
		total_weight += e_iter->w;
		++e_iter;
	}
	if( num_edges == 0 )
		return 0;
	else
		return total_weight / num_edges;
}

// Return the maximum edge weight of a graph
double WeightedGraph::MaxWeight()
{
	double maxWeight = 0.0;
	EdgeListIter e_iter = mSortedEdges.begin();

	while( e_iter != mSortedEdges.end() )
	{
		if( e_iter->w > maxWeight )
		{
			maxWeight = e_iter->w;
		}
		++e_iter;
	}
	return maxWeight;	
}

// Extract the subgraph that contains vertex 'a'
	WeightedGraph WeightedGraph::ExtractSubGraph( size_t a )
{
	// Use a breadth-first traversal to find the shortest non-weighted path
	/*
		Based on ICS 161: Design and Analyis of Algorithms
		Lecture Notes for February 15, 1996
		Department of Information & Computer Science, UC Irvine
		by David Eppstein
	*/

	// List of nodes that we want to visit next, start with 'a'
	IndexList visit_list;
	visit_list.push_back( a );

	// List of nodes that have already been on the visit list
	IndexVector marked_list;
	marked_list.push_back( a );

	IndexVectorIter iter;
	while( !visit_list.empty() )
	{
		// Remove the first element from the visited list
		size_t x = visit_list.front();
		visit_list.pop_front( );

		// Add every non-marked node connected to w to the visit_list
		size_t k;
		for( k = 0; k < x; ++k )
		{
			if( mWeightMatrix[k][x] != 0.0 )
			{
				// If k is not in the marked_list, then add it to both
				iter = find( marked_list.begin(), marked_list.end(), k );
				if( iter == marked_list.end() )
				{
					marked_list.push_back( k );
					visit_list.push_back( k );
				}
			}
		}
		for( k = x+1; k < mNumNodes; ++k )
		{
			if( mWeightMatrix[x][k] != 0.0 )
			{
				// If k is not in the marked_list, then add it to both
				iter = find( marked_list.begin(), marked_list.end(), k );
				if( iter == marked_list.end() )
				{
					marked_list.push_back( k );
					visit_list.push_back( k );
				}
			}
		}
	}

	// Sort the list of every node connected to a into lexographic order
	sort( marked_list.begin(), marked_list.end() );

	// Make a new subgraph for a and all nodes connected to it
	size_t n = marked_list.size();
	WeightedGraph sub_graph( n );

	size_t i, j, k, m;
	for( i = 0; i < n; ++i )
	{
		k = marked_list[i];
		sub_graph.mVertexLabels[i] = this->mVertexLabels[ k ];

		for( j = i + 1; j < n; ++j )
		{
			m = marked_list[j];
			sub_graph.mWeightMatrix[i][j] = mWeightMatrix[k][m];
		}
	}
//	cout << sub_graph.mSortedEdges.size() << endl;
	return sub_graph;
}

// Returns a list of the edges (a,b) of maximal weight
EdgeList WeightedGraph::FindHeaviestEdges( )
{
	EdgeList edge_list;

	double max_weight = mSortedEdges.front().w;
	double weight = 0.0;

	// Append all the edges with max_weight to the edge list
	EdgeListIter edge_iter = mSortedEdges.begin();
	while( edge_iter != mSortedEdges.end() )
	{
		weight = edge_iter->w;

		if( weight == max_weight && edge_iter->w != -1 )
		{
			edge_list.push_back( *edge_iter );
		}
		else 
		{
			// quit as soon as we find one less than max_weight
			break;
		}
		++edge_iter;
	}
	return edge_list;
}

// Determine if a CONNECTED	subgraph should be further disconnected.
//  If the average_weight_after_disconnecting/initAvgWeigh > 0.5,
//  then keep disconnecting. Otherwise don't.
bool WeightedGraph::DisconnectFurther( WeightedGraph graph )
{
	
/*	ofstream examplefile ("example.txt");
	if (examplefile.is_open())
	{
		examplefile << graph << endl;
	}
	examplefile.close();
*/	
//	cout << "DisconnectFurther..." << endl;
	// Find distance between the first point in the time series corresponding to the
	//  current component and the last one
	size_t i;
	double dist = 0;
	for( i = 0; i < Size() - 1; ++i )
	{	
		dist += graph.Get( i, i+1 );
	}
	
 	size_t n = graph.mNumNodes;
	if( n == 1 ) return false;

	if( !graph.IsGraphConnected() )
		throw( "WeightedGraph::DisconnectFurther - subgraph not connected" );

	// If the component is not a complete graph but the distance between
	//  its first and last node is <= 1/2 the maximum edge weight of the graph before any edge is removed.
	//  then do not disconnect further	
	if( (graph.MinDegree() == n - 1) || ( graph.IsDistanceSame() ) )
		return false;
	else if( (graph.AvgWeight() / initAvgWeight > DISCR_THRESHOLD) || (dist >= DISCR_THRESHOLD * initMaxWeight) )
		return true;
	else
		return false;
}

// Returns true if the distance between adjacent vertices of a connected graph
//  with more then one vertex is the same for all vertices, e.g. 1,2,3,4,5
bool WeightedGraph::IsDistanceSame( )
{
	size_t i;
	double dist = Get( 0, 1 );
	for( i = 1; i < Size() - 1; ++i )
	{	
		if( Get( i, i+1 ) != dist )
			return false;
	}
	return true;
}

// Sort the graphs in a vector by the label of the first node
GraphVector SortGraphs( GraphVector components )
{
//	cout << "SortGraphs..." << endl;
	size_t i, j, n;
	for( i = 0; i < components.size(); ++i )
	{
		for( j = i+1; j < components.size(); ++j )
		{
			if( components.at( j ).Vertex(0) < components.at( i ).Vertex(0) )
				
			{		
				n = components.at( i ).Size();
				WeightedGraph tempGraph( n );
				tempGraph = components.at( i );
				components.at( i ) = components.at( j );
				components.at( j ) = tempGraph;
			}
		
		}
	}
	
		return components;
}

// Removes repeated values from the time series and disctetizes it
GraphSepMeasure RemoveRepeatedAndDiscr( DoublesList orig_values, const size_t var_index )
{
	double entry, first_occurence;
	ValueList noRepeatedValues, noRepDiscr, orig_discrete, ov;
	DoublesList SortedNoRep, orig;
	GraphVector graphs;
	GraphSepMeasure vectorOFgraphs;
	size_t i, j;
	
	SortedNoRep = orig_values;
	SortedNoRep.sort();
	
//	cout << "RemoveRepeatedAndDiscr..." << endl;
	// Remove repeated values
	first_occurence = SortedNoRep.front();

//	ofstream ex ("NoRepeated.txt");
//	ex << first_occurence << endl;

	noRepeatedValues.push_back( first_occurence );
	SortedNoRep.pop_front();

	while( !SortedNoRep.empty() )
	{
		entry = SortedNoRep.front();
		if( entry != first_occurence )
		{
			first_occurence = entry;
			noRepeatedValues.push_back( first_occurence );
//			ex << first_occurence << endl;
			SortedNoRep.pop_front();
		}
		else
		{
			SortedNoRep.pop_front();
		}
	}
//	ex.close();

	// Discretize the data with no repeated values
	vectorOFgraphs = DisconnectAndSplit( noRepeatedValues, var_index );
	orig = orig_values;
	// Put original values into a vector
	while( !orig_values.empty() )
	{
		ov.push_back( orig_values.front() );
		orig_values.pop_front();
	}
	vectorOFgraphs.time_series = ov;
	
	// Print in a file the disconnected discretization components (sorted)
/*	graphs = vectorOFgraphs.components;
	GraphVectorIter graph_iter = graphs.begin();
	ofstream examplefile ("example.txt");
	while( !graphs.empty() )
	{
		if (examplefile.is_open())
		{
			examplefile << graphs.front() << endl;
			graphs.erase( graph_iter );
		}
	}	
	examplefile.close();
*/
	// Replace the points (with no repetitions) with their corresponding
	//  discrete values
	for( i = 0; i < vectorOFgraphs.components.size(); ++i )
	{
		for( j = 0; j < vectorOFgraphs.components.at(i).Size(); ++j )
		{
			noRepDiscr.push_back( i );
		}
	}

	
	while( !orig.empty() )
	{
		for ( j = 0; j < noRepeatedValues.size() && !orig.empty(); ++j )
		{
			if( orig.front() == noRepeatedValues.at(j) )
			{
				orig_discrete.push_back( noRepDiscr.at(j) );
				orig.pop_front();
			}
		}
	
	}
	
	vectorOFgraphs.discr_time_series = orig_discrete;

	return vectorOFgraphs;
}



// Repeatedly disconnect a connected graph and store the two subgraphs into 
//  a vector of graphs; return a vector of graphs and its separation measure
GraphSepMeasure DisconnectAndSplit( const ValueList& vlist, const size_t var_index)//, const DoublesList orig_values )
{
	size_t i, j, n, compSize;
	EdgeList edge_list;
	WeightedEdge edge;
//	double sm;
	// A vector to store components that may need more disconnecting
	GraphVector components, temp_components;
	// A vector to store components that should not be disconnected any more
	GraphVector final_components;
	GraphSepMeasure graphSep;
	// Form a weighted graph representing the distances between all
	//  unique pairs of values
	WeightedGraph graph( vlist );
//	cout << "DisconnectAndSplit..." << endl;
	bool adjacent_removed = false;
	if( vlist.size() == 1 )
	{
		final_components.push_back( graph );
		graphSep.components = final_components;
		graphSep.separation_measure = 0;
		graphSep.index = var_index;
//		cout << graphSep.separation_measure << endl;
		return graphSep;
	}
	else
	{
//		while( graph.IsGraphConnected() )
		while( (adjacent_removed == false) || graph.IsGraphConnected() )
		{
			edge_list = graph.FindHeaviestEdges();
			// Remove all edge(s) of heaviest weight
			while( !edge_list.empty() )
			{
				edge = edge_list.front();
				edge_list.pop_front();
				if( abs( (long)(edge.A - edge.B) ) == 1 )
					adjacent_removed = true;
				graph.RemoveEdge( edge.A, edge.B );
			}
		}
//		graph.IndexEdgeWeights();
//		cout << "Graph disconnected" << endl;
		// Split the graph into two or more subgraph and put them in a vector of graphs
		i = 0;
		compSize = 0;
		while( compSize < graph.Size() )
		{
			j = i+1;
			while( j < graph.Size() && graph.IsConnected( i, j ) )
				++j;
			components.push_back( graph.ExtractSubGraph(i) );
/*			if( !components.back().IsGraphConnected() )
			{
			//	cout << components.back() << endl;
				cout << "Component not connected!! " << endl;
				ofstream examplefile ("example.txt");
				if (examplefile.is_open())
				{
					examplefile << components.back() << endl;
				}
				examplefile.close();
			}
*/
			compSize += components.back().Size();
			i = j;
		}
//		cout << graph.Size() << endl;
//		GraphVector components_temp = components;
//		components_temp = SortGraphs( components );





		// Once the graph is disconnected for the first time,
		// we need to check if each component has to be also disconnected 
		while( !components.empty() )
		{
			n = components.front().Size();
			WeightedGraph subgraph ( n );
			subgraph = components.front();
			GraphVectorIter graph_iter = components.begin();
			components.erase( graph_iter );
//			cout << subgraph << endl
			if( subgraph.DisconnectFurther( subgraph ) )
			{
				while( subgraph.IsGraphConnected() )
				{
					edge_list = subgraph.FindHeaviestEdges();
					// Remove all edge(s) of heaviest weight
					while( !edge_list.empty() )
					{
						edge = edge_list.front();
						edge_list.pop_front();
						subgraph.RemoveEdge( edge.A, edge.B );
					}
				}
				// Once a component cannot be further disconnected, store it in final_components
				i = 0;
				compSize = 0;
				while( compSize < subgraph.Size() )
				{
					j = i+1;
					while( j < subgraph.Size() && subgraph.IsConnected( i, j ) )	
						++j;
					components.push_back( subgraph.ExtractSubGraph(i) );
					compSize += components.back().Size();
					i = j;
				}
			}
/*			else if( n >= 0.5*graph.Size() )
			{
				WeightedGraph testsubgr ( n );
				testsubgr = subgraph;
				while( testsubgr.IsGraphConnected() )
				{
					edge_list = testsubgr.FindHeaviestEdges();
					// Remove all edge(s) of heaviest weight
					while( !edge_list.empty() )
					{
						edge = edge_list.front();
						edge_list.pop_front();
						testsubgr.RemoveEdge( edge.A, edge.B );
					}
				}
				temp_components.clear();
				i = 0;
				compSize = 0;
				while( compSize < testsubgr.Size() )
				{
					j = i+1;
					while( j < testsubgr.Size() && testsubgr.IsConnected( i, j ) )	
						++j;
					temp_components.push_back( testsubgr.ExtractSubGraph(i) );
					compSize += temp_components.back().Size();
					i = j;
				}
				double ceil_half = ceil( (double)(temp_components.back().Size() + temp_components.front().Size()) / 2 );
				if( temp_components.size() > 2 )
					final_components.push_back( subgraph );
				else if( ceil_half >= temp_components.back().Size()-0.1*temp_components.back().Size() 
					&& ceil_half >= temp_components.front().Size()-0.1*temp_components.front().Size() )
				{
					final_components.push_back( temp_components.front() );
					final_components.push_back( temp_components.back() );
				}
				else
				{
					final_components.push_back( subgraph );
				}
			}
*/
			else
			{
				final_components.push_back( subgraph );
			}
		}
		graphSep.components = SortGraphs( final_components );
		graphSep.index = var_index;
//		cout << "Done with " << graphSep.index << " : " << graphSep.components.size() << " states" << endl;
//		cout << graphSep.time_series.back() << endl;

		return graphSep;
	}
}

// Calculates the separaton measure of a discretized variable.
double SeparationMeasure( WeightedGraph orig_graph, GraphVector components )
{
	size_t num_components = components.size();
	ValueList components_avg_weight;
	GraphVectorIter GraphIter = components.begin();
	size_t i, j, m, n;
	double two_components_distance;
	double ratio, r, max_avg_weight;
//	cout << "SeparationMeasure..." << endl;

	if( num_components == 1 )
	{
		return 0;
	}

	// Initialize ratio
/*	if( components.at(0).AvgWeight() != 0 )
		ratio = orig_graph.Get( components.at(0).Vertex(0), components.at(1).Vertex(0) ) / components.at(0).AvgWeight();
	else if( components.at(1).AvgWeight() != 0 )
		ratio = orig_graph.Get( components.at(0).Vertex(0), components.at(1).Vertex(0) ) / components.at(1).AvgWeight();
	else
		ratio = 0;
*/
	// Initialize ratio to a nonzero value if there is one or to 0
	ratio = 0;
	for( i = 0; i < num_components; ++i )
	{
		for( j = i+1; j < num_components; ++j )
		{
			for( m = components.at(i).Vertex(0); m < components.at(i).Size(); ++m )
			{
				// Initialize two_components_distance
				two_components_distance = orig_graph.Get( components.at(0).Vertex(0), components.at(1).Vertex(0) );
				for( n = components.at(j).Vertex(0); n < components.at(i).Size(); ++n )
				{
					if( orig_graph.Get( m, n ) < two_components_distance )
						two_components_distance = orig_graph.Get( m, n );
				}
			}
			if( components.at(i).AvgWeight() > components.at(j).AvgWeight() )
				max_avg_weight = components.at(i).AvgWeight();
			else
				max_avg_weight = components.at(j).AvgWeight();
			if( max_avg_weight < 0 )
				throw( "Negative weight!!" );
			if( max_avg_weight != 0 && two_components_distance != 0 )
			{
				ratio = two_components_distance / max_avg_weight;
				break;
			}
		}
	}
	if( ratio == 0 )
		return 0;
	else
	{
		// For each pair of components G, H find |gi - hj| for all gi in G and hj in H
		for( i = 0; i < num_components; ++i )
		{
			for( j = i+1; j < num_components; ++j )
			{
				for( m = components.at(i).Vertex(0); m < components.at(i).Size(); ++m )
				{
					// Initialize two_components_distance
					two_components_distance = orig_graph.Get( components.at(0).Vertex(0), components.at(1).Vertex(0) );
					for( n = components.at(j).Vertex(0); n < components.at(i).Size(); ++n )
					{
						if( orig_graph.Get( m, n ) < two_components_distance )
							two_components_distance = orig_graph.Get( m, n );
					}
				}
				if( components.at(i).AvgWeight() > components.at(j).AvgWeight() )
					max_avg_weight = components.at(i).AvgWeight();
				else
					max_avg_weight = components.at(j).AvgWeight();
				
				// Avoid dividing by 0 (in case both components have only one vertex).
				// In this case we have no criterion for separation measure and we set it to 0.
				if( max_avg_weight == 0 )
					r = 0;
				else
					r = two_components_distance / max_avg_weight;
				// Find the minimal ratio two_components_distance / max_avg_weight
				if( r < ratio && r != 0)
					ratio = r;
			}
		}
		return ratio;
	}
}

// Read MULTIPLE time series from files and arranges them into matrices.
//  Each column is a variable.
Matrix MatrixOfTimeSeries ( const char* filename )
{
	size_t i = 0, j = 0, k;
	string s, t;
	int x, y;
	double z;
	char buffer[1000];
	int num_columns = 0, num_rows = 0;
	// A two-dimensional array (a matrix) to store the time series; each column will contain a time series
	double**	AllVariables;
	bool once = true;
	Matrix matr;


//	cout << "MatrizOfTimeSeries..." << endl;
	ifstream inputfile ( filename );
	if (! inputfile.is_open())
	{ cout << "Error opening file"; exit (1); }

	// Precount the total number of points in the time series
	while ( !inputfile.eof() )
	{
		inputfile.getline( buffer, 1000 );
		if( once )
		{
			s = std::string( buffer );
			s += "  ";
			x = 0;
			while( x != s.npos )
			{
				x = s.find_first_of ( "-eE0123456789.", x );
				y = s.find_first_not_of( "-eE.0123456789", x );
				if( x != s.npos )
				{
					x = y;
					++num_columns;
				}
			}
			once = false;
		//	++num_rows;
		}		
		s = std::string( buffer );
		if(s.length() > 0)
			++num_rows;
		else
			break;
	}

	inputfile.close();
	
	// Allocates the 2-dim array
	AllVariables = new double*[num_columns];
	for( j = 0; j < num_columns; ++j )
	{
		AllVariables[j] = new double[num_rows];
	}
	
	// Reset to open at the beginning of the file
	inputfile.clear();
	inputfile.open( filename );
	if ( !inputfile.is_open() )
	{ cout << "Error opening file"; exit (1); }
	
	// Fill the time series into the matrix
	i = 0; j = 0;
	unsigned int loc;
	int power;
	while ( !inputfile.eof() )
	{
		inputfile.getline( buffer, 1000 );
		t = std::string( buffer );
		t += "  ";
		x = 0;
		if( t.length() > 2 )
		{
			while( x != t.npos )
			{
				x = t.find_first_of ( "-eE0123456789.", x );
				y = t.find_first_not_of( "-eE.0123456789", x );
				if( x != t.npos )
				{
					loc = t.substr( x, y-x ).find( "E", 0 );
					if( loc == string::npos )
						z = atof( t.substr( x, y-x ).c_str() );
					else
					{
						power = atoi( t.substr( x+loc+1 ).c_str() );
						if( power < 0 )
						{
							z = atof( t.substr( x, loc ).c_str() );
							for( k = 1; k <= abs(power); ++k )
							{
								z /= 10;
							}
						}
						else
						{
							z = atof( t.substr( x, loc ).c_str() );
							for( k = 1; k <= power; ++k )
							{
								z *= 10;
							}
						}
					}
					x = y;
					AllVariables[i][j] = z;
					++i;
				}
			}
			++j;
			i = 0;
		}
	}
	inputfile.close();

	matr.m = AllVariables;
	matr.rows = num_rows;
	matr.cols = num_columns;

	// Scales the variables
/*	for( j = 0; j < num_columns; ++j )
	{
		max = matr.m[j][0];
		for( i = 1; i < num_rows; ++i )
		{
			if( matr.m[j][i] > max )
				max = matr.m[j][i];
		}
		for( i = 0; i < num_rows; ++i )
		{
			matr.m[j][i] /= max;
		}
	}
*/

	return matr;
}

// Remove flat variables
Matrix RemoveFlat( Matrix mtx )
{
	size_t		i, j, col = 0;
	double		entry;
	Matrix		noflatmtx;
	IndexList	removed;

	for( j = 0; j < mtx.cols; ++j )
	{
		entry = mtx.m[j][0];
		for( i = 1; i < mtx.rows; ++i )
		{
			if( mtx.m[j][i] != entry )
			{
				++col;
				break;
			}
			if( i == mtx.rows-1 )
				removed.push_back(j);
		}
	}
	noflatmtx.m = new double*[col];
	for( j = 0; j < col; ++j )
	{
		noflatmtx.m[j] = new double[mtx.rows];
	}
	noflatmtx.cols = col;
	noflatmtx.rows = mtx.rows;
	col = 0;
	for( j = 0; j < mtx.cols; ++j )
	{
		entry = mtx.m[j][0];
		for( i = 1; i < mtx.rows; ++i )
		{
			if( mtx.m[j][i] != entry )
			{
				noflatmtx.m[col] = mtx.m[j];
				++col;
				break;
			}
		}
	}
	size_t rem_size = removed.size();
	for(i = 0; i < rem_size; ++i)
	{
		noflatmtx.removed.push_back( removed.front() );
		removed.pop_front();
	}
	return noflatmtx;
}


// Discretize MULTIPLE time series given in files
Matrix DiscretizeAllVariables( InputFilesList& FileList )
{
	size_t i, j, ts = 1, k;
	DoublesList orig_values;
	Matrix mtx, BIGmtx;
	GraphSepMeasureList variables;
	const char* filename;
	InputFilesList FL = FileList;
	size_t numberOfFiles = FileList.size();

//	cout << "DiscretizaAllVariables..." << endl;
	// Get the data from the first file
	filename = FL.front();
	FL.pop_front();
	mtx = MatrixOfTimeSeries( filename );
	// Allocates a 2-dim array to hold all time series
	BIGmtx.m = new double*[mtx.cols];
	for( j = 0; j < mtx.cols; ++j )
	{
		BIGmtx.m[j] = new double[mtx.rows * numberOfFiles];
	}
	BIGmtx.cols = mtx.cols;
	BIGmtx.rows = mtx.rows * numberOfFiles;
	// Copy the first time series into the big matrix
	for( j = 0; j < mtx.cols; ++j )
	{
		for ( i = 0; i < mtx.rows; ++i )
		{
			BIGmtx.m[j][i] = mtx.m[j][i];
		}
	}
	// Get the rest of the files
	while( !FL.empty() )
	{
		filename = FL.front();
		FL.pop_front();
		mtx = MatrixOfTimeSeries( filename );
		// Copy the next time series into the big matrix
		k = 0;
		for( j = 0; j < mtx.cols; ++j )
		{
			for ( i = mtx.rows * ts; i < mtx.rows * ts + mtx.rows; ++i )
			{
				BIGmtx.m[j][i] = mtx.m[j][k];
				++k;
			}
			k = 0;
		}
		++ts;
	}
	// Remove variables whose time points in all time series are constant
	BIGmtx = RemoveFlat( BIGmtx );

/*	for( i = 0; i < BIGmtx.cols; ++i )
	{
		for( j = 0; j < BIGmtx.rows; ++j )
		{
			cout << BIGmtx.m[i][j] << endl;
		}
	}
	cout << "\n" << endl;
*/
	
	for( j = 0; j < BIGmtx.cols; ++j )
	{
		for( i = 0; i < BIGmtx.rows; ++i )
		{
			orig_values.push_back( BIGmtx.m[j][i] );
		}
		variables.push_back( RemoveRepeatedAndDiscr( orig_values, j ) );
		orig_values.clear();
	}
	
	// Sort the variables' graphs in decreasing order according to their separation measure
	variables.sort( std::greater<GraphSepMeasure>() );
	variables = InfoMeasure( variables );
	variables = DisconnectToGetPrime( variables );
	return Correlation( FileList, variables, BIGmtx.removed );
}

// Continue to split if a component contains more than half of all the points
GraphSepMeasureList InfoMeasure( GraphSepMeasureList variables )
{
	size_t i, j, k, n = 0, vars = variables.size(), same = 0, count = 0;
	ValueList dts;
	double median = 0;
	DoublesList samestate;
	bool another = false;

	for(i = 0; i < vars; ++i)
	{
		n = variables.back().components.size();
		dts = variables.back().discr_time_series;
		for(j = 0; j < n; ++j)
		{
			for(k = 0; k < dts.size(); ++k)
			{
				if(dts.at(k) == j)
				{
					++same;
					samestate.push_back(variables.back().time_series.at(k));
				}
			}
			samestate.sort();
			for(count = 1; count <= samestate.size()/2; ++count)
			{
				samestate.pop_front();
			}
			median = samestate.front();
			if( (same > (double)dts.size()/2) && (variables.back().components.at(j).Size() > 1) )
			{	
				for(k = 0; k < dts.size(); ++k)
				{
					if(variables.back().time_series.at(k) > median)
					{
						++variables.back().discr_time_series.at(k);
						another = true;
					}
				}
			}
			same = 0;
			median = 0;
			samestate.clear();
		}
/*		if(another)
			cout << "Variable " << i+1 << ": discretized into " << n+1 << " states." << endl;
		else
			cout << "Variable " << i+1 << ": discretized into " << n << " states." << endl;
		another = false;
*/
		variables.push_front( variables.back() );
		variables.pop_back();
	}
	return variables;
}

// If the max number of states per variable is not prime, 
//  keep disconnecting until a prime is reached
GraphSepMeasureList DisconnectToGetPrime ( GraphSepMeasureList variables )
{
//	cout << "DisconnectToGetPrime..." << endl;
	// Find the maximum number of states
	size_t num_states = 0;
	size_t i, j, k;
	for( i = 0; i < variables.size(); ++i )
	{
		for ( j = 0; j < variables.front().discr_time_series.size(); ++j )
		{
			if( variables.front().discr_time_series.at(j) > num_states )
				num_states = variables.front().discr_time_series.at(j);
		}
		variables.push_back( variables.front() );
		variables.pop_front();
	}
	// Check if the max number of states is a prime
	unsigned int primes[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};
	size_t st = sizeof( primes ) / sizeof( primes[0] );
	size_t field;
	++num_states;
	for( i = 0; i < st-1; ++i )
	{
		if( num_states >= primes[i] && num_states <= primes[i+1] )
		{
			if( num_states == primes[i] || num_states == primes[i+1] )
			{
				field = num_states;
				break;
			}
			else 
			{
				field = primes[i+1];
				break;
			}
		}
	}
	if( field > variables.front().time_series.size() )
	{
		variables.front().field = 0;
		variables.front().error_message = "One or more of your variables takes on less distinct points than the cardinality of the field required.";
		return variables;
//		throw( "Less points than states" );
	}
//	cout << "initial # of states: " << num_states << endl;
//	cout << "Field:  F_" << field << endl;
	// Identify how many times each variable needs to be disconnected
	//  to make it have # states = cardinality of field
	size_t max = 0, add = 0, clust_size = 0;
	size_t site = 0, comp = 0, p;
	double max_dist, first_pt;
	DoublesListVector points_states;
	DoublesList state, new_state;
	DoublesListVectorIter points_states_iter;
	bool assigned_to_state;
	int instate;
//	ofstream ef2 ("P4.txt");
	for( i = 0; i < variables.size(); ++i )
	{
		points_states.clear();
		for ( j = 0; j < variables.front().discr_time_series.size(); ++j )
		{
//			ef2 << variables.front().discr_time_series.at(j) << endl;
			if( variables.front().discr_time_series.at(j) > max )
				max = variables.front().discr_time_series.at(j);
		}
//		ef2.close();
//		cout << "\n";
/*		for ( j = 0; j < variables.front().discr_time_series.size(); ++j )
		{
			cout << variables.front().time_series.at(j) << " ";
		}
		cout << "\n";
*/
		add = field - max - 1;
		// Split states if necessary
		if( add != 0 )
		{
			for( k = 0; k <= max; ++k )
			{
				for( j = 0; j < variables.front().time_series.size(); ++j)
				{
					if( variables.front().discr_time_series.at(j) == k )
					{
						state.push_back( variables.front().time_series.at(j) );
					}
				}
				state.sort();
				points_states.push_back( state );
				state.clear();
			}
			while( add > 0 )
			{
				max_dist = 0;
				clust_size = points_states.front().size();
				for( j = 0; j < points_states.size(); ++j )
				{
					for( k = 0; k < points_states.at(j).size(); ++k )
					{
						first_pt = points_states.at(j).front();
						points_states.at(j).push_back( first_pt );
						points_states.at(j).pop_front();
						if( points_states.at(j).front() - first_pt > max_dist )
						{
							max_dist = points_states.at(j).front() - first_pt;
							comp = j;
							site = k;
							clust_size = points_states.at(j).size();
						}
						else if( (points_states.at(j).front() - first_pt == max_dist)&&(points_states.at(j).size() > clust_size) )
						{
							max_dist = points_states.at(j).front() - first_pt;
							comp = j;
							site = k;
							clust_size = points_states.at(j).size();
						}
					}
				}
				if(max_dist == 0)
				{
					variables.front().field = 0;
					variables.front().error_message = "One or more of your variables does not take on enough values to obtained the appropriate field cardinality.";
					return variables;
					throw("Cannot obtain prime number of states.");
				}
				for( p = 0; p <= site; ++p )
				{
					points_states.at(comp).push_back( points_states.at(comp).front() );
					points_states.at(comp).pop_front();
				}
				new_state.clear();
				clust_size = points_states.at(comp).size();
				for( p = 1; p < clust_size - site; ++p )
				{
					new_state.push_back( points_states.at(comp).front() );
					points_states.at(comp).pop_front();
				}
//				points_states.at(comp).sort();
				points_states_iter = points_states.begin();
				++comp;
				points_states_iter += comp;
				points_states.insert( points_states_iter, new_state );
				points_states_iter = points_states.begin();
				--add;
			}
		}		
		comp = 0; site = 0;
		add = 0;
		max = 0;
		// Update the discrete time series
		for( j = 0; j < variables.front().time_series.size(); ++j )
		{
			assigned_to_state = false;
			instate = -1;
			for( k = 0; k < points_states.size(); ++k )
			{
				for( p = 0; p < points_states.at(k).size(); ++p )
				{
					if( variables.front().time_series.at(j) == points_states.at(k).front() )
					{
/*						if( assigned_to_state && (st == k) )
						{
							throw( "Same point assigned to two different states!" );
						}
						else
						{														*/
							assigned_to_state = true;
							instate = k;
//						}
						variables.front().discr_time_series.at(j) = k;
					}
					points_states.at(k).push_back( points_states.at(k).front() );
					points_states.at(k).pop_front();
				}
			}
		}
/*		for( j = 0; j < variables.front().time_series.size(); ++j )
		{
			cout << variables.front().discr_time_series.at(j) << " ";
		}
		cout << "\n";
*/
		variables.push_back( variables.front() );
		variables.pop_front();
	}

	variables.front().field = field;
	return variables;
}

Matrix Correlation( InputFilesList FileList, GraphSepMeasureList variables, IndexList removed )
{
	GraphSepMeasure var, var_compare, temp, leading;
	GraphSepMeasureList varList, old_varList, correlated_variables, newly_discretized, all_newly_discretized;
	Matrix mtx;
	size_t n, i, j, k, pos, pos1, states = 0, index;
	double cc, max, center_of_mass, min_dist;
//	SpearmanRankCorrelate SRC;
//	double** AllVariables;
	ValueList centers;
	size_t numberOfFiles = FileList.size();
	// ts_length contains the length of a single time series
	size_t ts_length = variables.front().time_series.size() / numberOfFiles; //!!
	const char* filename;
	unsigned int cardinality = variables.front().field;
	char* message = variables.front().error_message;
	

//	cout << "Correlation..." << endl;	
/*	ofstream examplefile ("correlation.txt");
	while( !variables.empty() )
	{
		var = variables.front();
		if( var.components.size() > states )
		{
			states = var.components.size();
			index = var.index;
		}
		if (examplefile.is_open())
		{
			examplefile << "Variable " << var.index << " is correlated to variables:" << endl;
		}
	
		n = var.time_series.size();
		variables.pop_front();
		correlated_variables.push_back( var );
		varList = variables;
		old_varList = variables;
		variables.clear();

		while( !varList.empty() )
		{
			var_compare = varList.front();
			cc = SRC.RankCorrelate( var.shift_time_series, var_compare.shift_time_series );
			if ( SRC.TestSignificance(cc, n) )
			{
				correlated_variables.push_back( var_compare );
				if (examplefile.is_open())
				{
					examplefile << varList.front().index << endl;
				}
			}
			else
			{
				variables.push_back( var_compare );	
			}
			varList.pop_front();
		}

//		newly_discretized = CommonDiscretization( correlated_variables );
		newly_discretized = correlated_variables;
		correlated_variables.clear();
		while( !newly_discretized.empty() )
		{
			// Copy the index to the separation_measure to be able to sort by to it
			newly_discretized.front().separation_measure = newly_discretized.front().index;
			all_newly_discretized.push_back( newly_discretized.front() );
			newly_discretized.pop_front();
		}
	}
	examplefile.close();
	// At this point for each variable only the index, shift_time_series, and discr_time_series are up-to-date 
	
	// Scale the time series by dividing by the absolute value of the element with maximal absolute value
	for( i = 0; i < all_newly_discretized.size(); ++i )
	{
		temp = all_newly_discretized.front();
		all_newly_discretized.pop_front();
		max = 0.0;
		for( j = 0; j < temp.time_series.size(); ++j )
		{
			if( fabs( temp.time_series.at(j) ) > max )
			{
				max = fabs( temp.time_series.at(j) );
			}
		}
		for( j = 0; j < temp.time_series.size(); ++j )
		{	
			if( max != 0 )
			{
				temp.time_series.at(j) /= max;
			}
		}

		for( j = 0; j < temp.clusters.size(); ++j )
		{
			for( k = 0; k < temp.clusters.at(j).size(); ++k )
			{
				if( max != 0 )
				{
					temp.clusters.at(j).front() /= max;
				}
				temp.clusters.at(j).push_back( temp.clusters.at(j).front() );
				temp.clusters.at(j).pop_front();
			}
		}
		all_newly_discretized.push_back( temp );
	}

	// Choose the variable that discretized to the max. number of states and has a max. separation measure
	for( i = 0; i < all_newly_discretized.size(); ++i )
	{
		if( all_newly_discretized.front().index == index )
		{
			all_newly_discretized.front() = InsertStates( all_newly_discretized.front() );
			leading = all_newly_discretized.front();
		}
		all_newly_discretized.push_back( all_newly_discretized.front() );
		all_newly_discretized.pop_front();
	}
*/
	// Map the discretization states of each variable according to the proximity 
	//  of the center of mass to the leading variable's states' centers of mas

/*	for( i = 0; i < states; ++i )
	{
		center_of_mass = 0.0;
		k = leading.clusters.at(i).size();
		while( !leading.clusters.at(i).empty() )
		{
			center_of_mass += leading.clusters.at(i).front();
			leading.clusters.at(i).pop_front();
		}
		if( k != 0 )
		{
			center_of_mass /= k;
		}
		else
			center_of_mass = 2;
		centers.push_back( center_of_mass );
	}
	for( i = 1; i < centers.size() - 1; ++i )
	{
		if( centers.at(i) == 2 )
		{
			centers.at(i) = ( centers.at(i-1) + centers.at(i+1) ) / 2;
		}
	}
//	all_newly_discretized.push_back( temp );
//	all_newly_discretized.pop_front();
	
	for( n = 0; n < all_newly_discretized.size(); ++n )
	{
		temp = all_newly_discretized.front();
		all_newly_discretized.pop_front();
		if( temp.index != index )
		{
			for( i = 0; i < temp.clusters.size(); ++i )
			{
				center_of_mass = 0.0;
				k = temp.clusters.at(i).size();
				for( j = 0; j < temp.clusters.at(i).size(); ++j )
				{
					center_of_mass += temp.clusters.at(i).front();
					temp.clusters.at(i).push_back( temp.clusters.at(i).front() );
					temp.clusters.at(i).pop_front();
				}
				if( k != 0 )
				{
					center_of_mass /= k;
				}
				else 
					throw( "Correlation -- unexpected empty state" );
				min_dist = fabs( centers.front() - center_of_mass );
				pos = 0;
				for( j = 1; j < centers.size(); ++j )
				{
					if( fabs( centers.at(j) - center_of_mass ) < min_dist )
					{
						min_dist = fabs( centers.at(j) - center_of_mass );
						pos = j;
					}
				}

				pos1 = centers.size();
				// If the center of mass is equally distant from two centers, split the cluster
				if( pos < centers.size() - 1 && fabs( centers.at(pos + 1) - center_of_mass ) == min_dist )
				{
					pos1 = pos + 1;
				}
				if( pos1 < centers.size() )
				{
					for( j = 0; j < temp.time_series.size(); ++j )
					{
						for( k = 0; k < temp.clusters.at(i).size(); ++k )
						{
							if( temp.time_series.at(j) == temp.clusters.at(i).front() )
							{
								if( temp.time_series.at(j) <= center_of_mass )
									temp.discr_time_series.at(j) = pos;
								else
									temp.discr_time_series.at(j) = pos1;
							}
							temp.clusters.at(i).push_back( temp.clusters.at(i).front() );
							temp.clusters.at(i).pop_front();
						}
					}
				}
				else
				{
					for( j = 0; j < temp.time_series.size(); ++j )
					{
						for( k = 0; k < temp.clusters.at(i).size(); ++k )
						{
							if( temp.time_series.at(j) == temp.clusters.at(i).front() )
							{
								temp.discr_time_series.at(j) = pos;
							}
							temp.clusters.at(i).push_back( temp.clusters.at(i).front() );
							temp.clusters.at(i).pop_front();
						}
					}
				}
			}
		}
		all_newly_discretized.push_back( temp );
	}

*/	// Sort the the variables in their original order
//	variables.sort( std::greater<GraphSepMeasure>() );
	
	// Place the discretized variables in a matrix
	ValueListIter itr;
	mtx.cols = variables.size();
	mtx.rows = variables.front().discr_time_series.size();
	double** AllVariables;
	AllVariables = new double*[mtx.rows];
	for( i = 0; i < mtx.rows; ++i )
	{
		AllVariables[i] = new double[mtx.cols];
	}
	j = 0;
	while( !variables.empty() )
	{
		i = 0;
		while( !variables.back().discr_time_series.empty() )
		{
			AllVariables[i][j] = variables.back().discr_time_series.front();
			itr = variables.back().discr_time_series.begin();
			variables.back().discr_time_series.erase( itr );
			++i;
		}
		++j;
		variables.pop_back();
	}
	mtx.m = AllVariables;
	
	// Print in files the discretized variables
/*	const char* filenames[] = 
	{
		"out1.txt",
		"out2.txt"
	};
	InputFilesList FL;
	for( i = 0; i < numberOfFiles; ++i )
	{
		FL.push_back( filenames[i] );
	}
*/
//	size_t num_states = 0;
	size_t nf = 0;
	size_t num_removed = removed.size();
	size_t incr = 0;

	while( !FileList.empty() )
	{
		filename = FileList.front();
		FileList.pop_front();
		ofstream exfile( (std::string(filename) + std::string(".out") ).c_str() );
		if (exfile.is_open())
		{
			exfile << cardinality << endl;
			exfile << endl;
			for( i = ts_length*nf; i < ts_length*nf + ts_length; ++i )
			{
				incr = 0;
				for( j = 0; j < mtx.cols + num_removed; ++j )
				{
					if( j < removed.front() )
					{
						exfile << mtx.m[i][j-incr];
						exfile << "\t"; 
					}
					else if( j == removed.front() )
					{
						exfile << 0;
						exfile << "\t"; 
						removed.push_back(removed.front());
						removed.pop_front();
						++incr;
					}
					else
					{
						exfile << mtx.m[i][j-incr];
						exfile << "\t"; 
					}
				}
				exfile << "\n";
			}
		}
		if(cardinality == 0)
			exfile << message;
		exfile.close();
		++nf;
	}
	
	
/*	// Print in a file the discretized variables
	ofstream exfile ("H:\\Brandy_MC2\\fnc-gen\\output7.txt");
	if (exfile.is_open())
	{
		for( i = 0; i < mtx.rows; ++i )
		{
			for( j = 0; j < mtx.cols; ++j )
			{
				exfile << mtx.m[i][j];
				exfile << "\t";
			}
			exfile << "\n";
			if( (i+1) % ts_length == 0 )
				exfile << "\n";
		}
	}
	exfile.close();
*/

	return mtx;
}

// Discretize similarly strongly correlated variables
GraphSepMeasureList CommonDiscretization( GraphSepMeasureList correlated_variables )
{	
	// First match point by point the variables to the discrete states
	//  of the best clustering variable they are strongly related to.
	GraphSepMeasureList newly_discretized;
	GraphSepMeasure related_var;
	size_t i, j;
	DoublesListVector valuesVector;
	DoublesListVectorIter iter;
	DoublesList state_values;
	size_t forward, backward, first_to_second, second_to_first;
	DoublesList v1, v2;
	ValueList ts;
	bool empty_b = false, empty_f = false, empty_fs = false, empty_sf = false;
		
	GraphSepMeasure best_clustering = correlated_variables.front();
	correlated_variables.pop_front();

	for( i = 0; i < best_clustering.components.size(); ++i )
	{
		for( j = 0; j < best_clustering.time_series.size(); ++j )
		{
			if( best_clustering.discr_time_series.at(j) == i )
			{
				state_values.push_back( best_clustering.time_series.at(j) );
			}
		}
		state_values.sort();
		valuesVector.push_back( state_values );
		state_values.clear();
	}
	best_clustering.clusters = valuesVector;
	newly_discretized.push_back( best_clustering );
	valuesVector.clear();
	if( correlated_variables.empty() )
			return newly_discretized;

	while( !correlated_variables.empty() )
	{
		related_var = correlated_variables.front();
		correlated_variables.pop_front();
		// Build a vector of double lists. Each list contains the points
		// in the time series of related_var that belong to the discrete state 
		// correconding to the consecutive number of the list.
		for( i = 0; i < best_clustering.components.size(); ++i )
		{
			for( j = 0; j < best_clustering.time_series.size(); ++j )
			{
				if( best_clustering.discr_time_series.at(j) == i )
				{
					state_values.push_back( related_var.time_series.at(j) );
				}
			}
			state_values.sort();
			valuesVector.push_back( state_values );
			state_values.clear();
		}

		// If the last element in a state is greater than the first element
		//  in the next state, move it to the next state unless moving the first 
		//  element of the next state to the current state would restore the balance
		//  (meaning no overlapping) with less elements moved.
		for( i = 0; i < valuesVector.size() - 1; ++i )
		{	
			backward = 0;
			v2 = valuesVector.at(i+1);
			j = 0;
			while( valuesVector.at(i-j).empty() )	++j;
			v1 = valuesVector.at(i-j);
			while( v1.back() >= v2.front() && !v2.empty() )
			{
				v1.push_back( v2.front() );
				v1.sort();
				v2.pop_front();
				if( v2.empty() )
					empty_b = true;
				++backward;
			}
			
			forward = 0;
			v2 = valuesVector.at(i+1);
			j = 0;
			while( valuesVector.at(i-j).empty() )	++j;
			v1 = valuesVector.at(i-j);
			while( v1.back() >= v2.front() && !v1.empty() )
			{
				v2.push_back( v1.back() );
				v2.sort();
				v1.pop_back();
				if( v1.empty() )
					empty_f = true;
				++forward;
			}
		
			first_to_second = 0;
			v2 = valuesVector.at(i+1);
			j = 0;
			while( valuesVector.at(i-j).empty() )	++j;
			v1 = valuesVector.at(i-j);
			while( v1.back() >= v2.front() && !v1.empty() && first_to_second < v1.size() + v2.size() )
			{
				v2.push_back( v1.back() );
				v2.sort();
				v1.pop_back();
				if( v1.empty() )
					empty_fs = true;
				++first_to_second;
				if( v1.back() >= v2.front() && !v1.empty() && !v2.empty() && first_to_second < v1.size() + v2.size() )
				{
					v1.push_back( v2.front() );
					v1.sort();
					v2.pop_front();
					if( v2.empty() )
						empty_fs = true;
					++first_to_second;
				}
			}
			second_to_first = 0;
			v2 = valuesVector.at(i+1);
			j = 0;
			while( valuesVector.at(i-j).empty() )	++j;
			v1 = valuesVector.at(i-j);
			while( v1.back() >= v2.front() && !v2.empty() && second_to_first < v1.size() + v2.size() )
			{
				v1.push_back( v2.front() );
				v1.sort();
				v2.pop_front();
				if( v2.empty() )
					empty_sf = true;
				++second_to_first;
				if( v1.back() >= v2.front() && !v1.empty() && !v2.empty() && second_to_first < v1.size() + v2.size() )
				{
					v2.push_back( v1.back() );
					v2.sort();
					v1.pop_back();
					if( v1.empty() )
						empty_sf = true;
					++second_to_first;
				}
			}
			
			
			if( backward == forward && forward == first_to_second && first_to_second == second_to_first )
			{
				if( !empty_b )
				{
					j = 0;
					while( valuesVector.at(i-j).empty() )	++j;
					
					while( ( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() ) && (!valuesVector.at(i+1).empty()) )
					{
						valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
						valuesVector.at(i-j).sort();
						valuesVector.at(i+1).pop_front();
					}					
				}
				else if( !empty_f )
				{
					j = 0;
					while( valuesVector.at(i-j).empty() )	++j;
					while( ( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() ) && (!valuesVector.at(i-j).empty()) )
					{
						valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
						valuesVector.at(i+1).sort();
						valuesVector.at(i-j).pop_back();
					}
				}
				else if( !empty_sf )
				{
					j = 0;
					while( valuesVector.at(i-j).empty() )	++j;
					while( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i+1).empty() )
					{
						valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
						valuesVector.at(i-j).sort();
						valuesVector.at(i+1).pop_front();
						if( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i-j).empty() )
						{
							valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
							valuesVector.at(i+1).sort();
							valuesVector.at(i-j).pop_back();
						}
					}
				}
				else
				{
					j = 0;
					while( valuesVector.at(i-j).empty() )	++j;
					while( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i-j).empty() )
					{
						valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
						valuesVector.at(i+1).sort();
						valuesVector.at(i-j).pop_back();
						if( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i+1).empty() )
						{
							valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
							valuesVector.at(i-j).sort();
							valuesVector.at(i+1).pop_front();
						}
					}
				}
			}

			else if( backward <= forward && backward <= first_to_second && backward <= second_to_first )
			{
				j = 0;
				while( valuesVector.at(i-j).empty() )	++j;
				
				while( ( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() ) && (!valuesVector.at(i+1).empty()) )
				{
					valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
					valuesVector.at(i-j).sort();
					valuesVector.at(i+1).pop_front();
				}
			}
			else if( forward <= backward && forward <= first_to_second && forward <= second_to_first )
			{
				j = 0;
				while( valuesVector.at(i-j).empty() )	++j;
				while( ( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() ) && (!valuesVector.at(i-j).empty()) )
				{
					valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
					valuesVector.at(i+1).sort();
					valuesVector.at(i-j).pop_back();
				}
			}
			else if( first_to_second <= backward && first_to_second <= forward && first_to_second <= second_to_first )
			{
				j = 0;
				while( valuesVector.at(i-j).empty() )	++j;
				while( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i-j).empty() )
				{
					valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
					valuesVector.at(i+1).sort();
					valuesVector.at(i-j).pop_back();
					if( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i+1).empty() )
					{
						valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
						valuesVector.at(i-j).sort();
						valuesVector.at(i+1).pop_front();
					}
				}
			}
			else
			{
				j = 0;
				while( valuesVector.at(i-j).empty() )	++j;
				while( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i+1).empty() )
				{
					valuesVector.at(i-j).push_back( valuesVector.at(i+1).front() );
					valuesVector.at(i-j).sort();
					valuesVector.at(i+1).pop_front();
					if( valuesVector.at(i-j).back() >= valuesVector.at(i+1).front() && !valuesVector.at(i-j).empty() )
					{
						valuesVector.at(i+1).push_back( valuesVector.at(i-j).back() );
						valuesVector.at(i+1).sort();
						valuesVector.at(i-j).pop_back();
					}
				}
			}
		}

		// If there are empty states as a first state or between full states.
		//  shift back to fill them in
		for( i = 0; i < valuesVector.size(); ++i )
		{
			if( valuesVector.at(i).empty() )
			{
				iter = valuesVector.begin() + i;
				valuesVector.erase( iter );
				--i;
			}
		}
		
		// Replace the time series points with their corresponding discrete states
		related_var.discr_time_series.clear();
		ValueListIter itr;
		for( j = 0; j < valuesVector.size(); ++j )
		{
			valuesVector.at(j).sort();
		}
		related_var.clusters = valuesVector;
		
/*		cout << "\n" << endl;
		while( !related_var.clusters.empty() )
		{
			while( !related_var.clusters.back().empty() )
			{
				cout << related_var.clusters.back().front() << endl;
				related_var.clusters.back().pop_front();
			}
			cout << "\n" << endl;
			related_var.clusters.pop_back();
		}
*/
		ts = related_var.time_series;
		while( !related_var.time_series.empty() )
		{
			i = 0;
			while( related_var.time_series.front() > valuesVector.at(i).back() )
				++i;
			related_var.discr_time_series.push_back(i);
			itr = related_var.time_series.begin();
			related_var.time_series.erase( itr );
		}
		valuesVector.clear();
		related_var.time_series = ts;
		newly_discretized.push_back( related_var );
	}
	
	return newly_discretized;
}

// Inserts empty states into the leading variable's discretization to make them a power of a prime number
GraphSepMeasure InsertStates( GraphSepMeasure var )
{
	// Assume the time series is no more than 60 points (or that for some reason the variable will not
	//  discretize to more than 60 states)
	unsigned int primes[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};
	size_t n = sizeof( primes ) / sizeof( primes[0] );
	size_t i, j, k;
	size_t field, insert_states, loc = 0;
	double max_distance = 0;
	DoublesListVector clust = var.clusters;
	DoublesListVectorIter iter = clust.begin();
	DoublesList elist; // an empty list
	
	for( i = 0; i < n-1; ++i )
	{
		if( clust.size() >= primes[i] && clust.size() <= primes[i+1] )
		{
			if( clust.size() == primes[i] || clust.size() == primes[i+1] )
			{
					cout << "Field:  F_" << clust.size() << endl;
				return var;
			}
			else 
			{
				field = primes[i+1];
				cout << "Field:  F_" << field << endl;
				break;
			}
		}
	}

/*	insert_states = field - clust.size();
	while( insert_states > 0 )
	{
		for( i = 0; i < clust.size() - 1; ++i )
		{
			j = 1;
			if( clust.at(i+j).empty() )	
				++j;
			if( clust.at(i+j).back() - clust.at(i).front() > max_distance && j == 1)
			{
				max_distance = clust.at(i+j).back() - clust.at(i).front();
				loc = i+1;
			}
		}
		iter += loc;
		clust.insert( iter, elist );
		iter = clust.begin();
		--insert_states;
		max_distance = 0;
	}
	var.clusters = clust;
	
	// Update the discretization of the variable
	for( j = 0; j < var.time_series.size(); ++j )
	{
		for( i = 0; i < var.clusters.size(); ++i ) 
		{
			for( k = 0; k < var.clusters.at(i).size(); ++k )
			{
				if( var.time_series.at(j) == var.clusters.at(i).front() )
				{
					var.discr_time_series.at(j) = i;
				}
				var.clusters.at(i).push_back( var.clusters.at(i).front() );
				var.clusters.at(i).pop_front();
			}
		}
	}
*/
	return var;
}



/*

Based on CMU online course material
	Course: "Causal and Statistical Reasoning"
	Module: "Causation to Association: D-separation"

FormAllDisjointPaths[X,Y]
	path_list = {X}
	While path_list keeps changing
		For all paths p in path_list
			z = last of p
			if z != Y
				For all nodes u connected to z but not in p
					If ( {z,u} is not an element of any path )
						remove p from path_list first time
						append {p,u} to path_list
				end-for
			end-if
		end-for
	end-while



// Find all paths from a to b that do not share a common edge
PathList WeightedGraph::AllEdgeDisjointPaths( size_t a, size_t b, size_t max_k ) const
{
	// Create a matrix to remember which edges are already on a path
	size_t i,j;
	bool** edge_used_matrix = new bool*[ mNumNodes ];
	for( i = 0; i < mNumNodes; ++i )
	{
		edge_used_matrix[i] = new bool[mNumNodes];
		for( j = 0; j < mNumNodes; ++j )
		{
			edge_used_matrix[i][j] = false;
		}
	}

	// List of boolean arrays of length mNumNodes

	NodeVisitedList node_visited_list;

	// Create a list to hold all disjoint paths from a to b
	PathList path_list;
	NodePair root = {0, a};
	NodePairList path;
	path.push_back( root );
	path_list.push_back( path );

	// Create a node visited array for the first path
	BoolArray nv0( mNumNodes );
	nv0[a] = true;
	node_visited_list.push_back( nv0 );

	// Count the number of disjoint paths from a to b
	size_t disjoint_path_count = 0;

	bool path_list_changed = true;
	while( path_list_changed )
	{
		// For each path in the path list
		PathListIter pl_iter = path_list.begin();
		NodeVistedListIter nv_iter = node_visited_list.begin();

		while( pl_iter != path_list.end( ) )
		{
			// Get the last edge on the current path
			NodePair last_edge = pl_iter->back();
			size_t z = last_edge.B;
			// If we have reached 'b'
			if( z == b )
			{
				if( ++disjoint_path_count >= max_k )
				{
					// We have found max_k disjoint paths from a to b
					return path_list;
				}
			}
			else
			{
				bool first_change = true;
				size_t u;
				for( u = 0; u < z; ++u )
				{
					// If there exist and edge between u and z
					if( mWeightMatrix[u][z] != 0 )
					{
						// If u is not already on the current path
						if( !( (*nv_iter)[u] ) )
						{
							NodePair zu = {z, u};
							if( first_change )
							{
								pl_iter->push_back( zu );
								(*nv_iter)[u] = true;
								first_change = false;
							}
							else
							{
								// Make a copy of the current path
								path_list.push_back( *pl_iter );

								// change last entry to (z, u)
								pl_iter->back() = zu;

								// Create a node visited array for this path
								//  as a copy of the current one
								BoolArray nv( *nv_iter );
								nv[u] = true;
								node_visited_list.push_back( nv );
							}
						}
					}
				}
			}
			
			// Next path
			++pl_iter;
			++nv_iter;
		}

	}
	return path_list;

}


// Computes the connectivity of a graph, that is, 
// the minimum number of edges whose deletion disconnects the graph.
int WeightedGraph::Connectivity( WeightedGraph graph ) const
{	
	size_t i;
	if( !graph.IsGraphConnected() )
		return 0;
	if( graph.MinDegree() == 1 )
		return 1;
	for( i = 2; i < graph.MinDegree(); ++i )
		if( graph.Remove_N_Edges( i, graph ) )
			return i;
	return graph.MinDegree();
}


// Determines if a subgraph should further disconnected.
// If connectivity < minimum degree != 1, then disconnect;
// if connectivity = minimum degree = 1, then remove the heaviest edges
// if doing so decreases the average weight of the graph.
bool WeightedGraph::DisconnectFurther( WeightedGraph graph ) 
{
	EdgeList edge_list;
	WeightedEdge edge;
	// Currently Connectivity() does not work correctly
	if( (graph.Connectivity() < graph.MinDegree()) )
		return true;
	if( (graph.Connectivity() == graph.MinDegree()) && (graph.MinDegree() != 1) )
		return false;
	// if connectivity = minimum degree = 1
	else
	{
		edge_list = graph.FindHeaviestEdges();
		// Remove all edge(s) of heaviest weight
		while( !edge_list.empty() )
		{
			edge = edge_list.front();
			edge_list.pop_front();
			graph.RemoveEdge( edge.A, edge.A );
		}
		
		// If removing heaviest edge(s) would disconnect the graph, return true;
		if( graph.IsGraphConnected() )
			return false;
		else
			return true;	
	}
}
*/

ostream& operator<<( ostream& out, const WeightedGraph& g )
{
	size_t i, j;
	char buf[16];
	for( j = 0; j < g.Size(); ++j )
	{
		sprintf( buf, "%7d ", g.Vertex( j ) );
		out << buf;
	}
	out << endl;
	for( i = 0; i < g.Size(); ++i )
	{
		for( j = 0; j < g.Size(); ++j )
		{
			sprintf( buf, "%7.5f ", g.Get( i, j ) );
			out << buf;
		}
		out << endl;
	}
	out << endl;
	return out;
}
