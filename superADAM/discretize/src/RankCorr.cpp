// RankCorr.cpp
//
//  Class to perform Spearman's Rank Correlation
//
/*
#include "RankCorr.h"
#include "GraphMeasure.h"

// Predicate to compare two Pair objects by x
static bool comp( const Pair& a, const Pair& b )
{
	if( a.x < b.x ) return true;
	return false;
}

// Default constructor
SpearmanRankCorrelate::SpearmanRankCorrelate( )
{
	// Table of critical values for 0.05 confidence level
	// These are such that the probability that the correlation coefficient
	//  for a pair of uncorrelated series of length k will be greater than
	//  crit[k] is 0.05
	static double crit[] = {1.100, 1.100, 1.100, 1.100, 1.100, 0.900, 0.829, 0.714, 0.643,
							0.600, 0.564, 0.523, 0.497, 0.475, 0.457, 0.441, 0.425, 0.412,
							0.399, 0.388, 0.377, 0.368, 0.359, 0.351, 0.343, 0.336, 0.329,
							0.323, 0.317, 0.311, 0.305};

/*
	//	crit[k] is 0.005
	static double crit[] = {1.100, 1.100, 1.100, 1.100, 1.100, 1.100, 1.100, 1.100,
							0.881,	0.833, 0.794, 0.818, 0.780,	0.745, 0.716, 0.689,
							0.666, 0.645, 0.625, 0.608, 0.591, 0.576, 0.562, 0.549,
							0.537, 0.526, 0.515, 0.505, 0.496, 0.487, 0.478};


	//	crit[k] is 0.01
	static double crit[] = {1.100, 1.100, 1.100, 1.100, 1.100, 1.100,
							0.943, 0.893, 0.833, 0.783, 0.745};


	//	crit[k] is 0.025
	static double crit[] = {1.100, 1.100, 1.100, 1.100, 1.100, 1.100,
							0.886, 0.786, 0.738, 0.683, 0.648};


	size_t k = sizeof( crit ) / sizeof( double );

	mCriticalValues = ArrayToDoubleList( crit, k );
}

//Returns true if the correlation coefficient is significant
//Returns false if n is invalid
bool SpearmanRankCorrelate::TestSignificance( double cc, size_t n )
{
	size_t m = mCriticalValues.size();
	if( n >= m )
	{ 
		if( cc > mCriticalValues[m-1] ) return true;
		return false;
	}
	cout << endl;
	cout << mCriticalValues[n] << endl;
	
	return cc > mCriticalValues[n];
}


// Return a list of ranks of the given list of data
//  create a list of indices where each x is replaced
//	by the position it would have in a sorted verion of the list
bool SpearmanRankCorrelate::Rank( ValueList& data, IntList& ordering )
{
	if( data.empty() ) return false;

	PairList plist;
	ValueListIter diter = data.begin();
	int i = 0;
	double x;
	while( diter != data.end() )
	{
		// grab the next value
		x = *diter;

		// form a pair of the value with its original position
		Pair p = {i, x};

		// add pair to end of pair list
		plist.push_back( p );

		ordering.push_back( i );

		// Next value
		++diter;
		++i;
	}

	// Sort the pair list by value
	sort( plist.begin(), plist.end(), comp );

	i = 0;
	int j = 0;
	PairListIter piter = plist.begin( );
	while( piter != plist.end() )
	{
		// the index into ordering is the orginal position of x
		// the number we put there is the new position of x
		j = piter->k;
		ordering[j] = i++;

		// point to the next pair
		++piter;
	}

	return true;
}

// Compute the Spearman's Rank Correlation of the two series a, b
double SpearmanRankCorrelate::RankCorrelate( ValueList& a, ValueList& b )
{

	IntList a_ordering;
	IntList b_ordering;

	Rank( a, a_ordering );
	Rank( b, b_ordering );

	// Compute the means
	double ma = 0.0;
	double mb = 0.0;

	// The slow painful way
	if( false )
	{
		IntListIter ia = a_ordering.begin( );
		IntListIter ib = b_ordering.begin( );

		// Compute sum of a's and sum of b's
		double asum = 0.0;
		double bsum = 0.0;
		int count = 0;
		while( ia != a_ordering.end() && ib != b_ordering.end() )
		{
			asum += *ia++;
			bsum += *ib++;
			++count;
		}

		// Protect divide by zero
		if( count == 0 ) count = 1;

		// compute means
		double amean = asum / count;
		double bmean = bsum / count;
	}


	// Sum of 0 .. n = n*(n-1)/2, so avg is (n-1)/2
	double amean = (a_ordering.size() - 1.0) * 0.5;
	double bmean = (b_ordering.size() - 1.0) * 0.5;

	double rs_sum = 0.0;
	double rr_sum = 0.0;
	double ss_sum = 0.0;

	double r,s;
	IntListIter ia = a_ordering.begin( );
	IntListIter ib = b_ordering.begin( );
	while( ia != a_ordering.end() && ib != b_ordering.end() )
	{
		r = *ia++;
		s = *ib++;

		// Compute the Rank Correlation sums
		rs_sum += ( r - amean ) * ( s - bmean );
		rr_sum += ( r - amean ) * ( r - amean );
		ss_sum += ( s - bmean ) * ( s - bmean );
	}

	// Compute correlation coefficient
	// cc = rs_sum / sqrt( rr_sum * ss_sum );
	double cc = rr_sum * ss_sum;
	if( fabs( cc ) < epsilon )
	{
		cc = 0.0;
	}
	else
	{
		cc = rs_sum / sqrt( rr_sum * ss_sum );
	}

	return cc;
}	

ValueList SpearmanRankCorrelate::ArrayToDoubleList( double a[], size_t n )
{

	ValueList a_list;

	size_t i;
	for( i = 0; i < n; ++i )
	{
		a_list.push_back( a[i] );
	}
	return a_list;
}

// Correlate two arrays of doubles of length n
double SpearmanRankCorrelate::RankCorrelate( ValueList a, ValueList b, size_t n )
{

	// Convert the arrays to lists
//	ValueList a_list = ArrayToDoubleList( a, n ); 
//	ValueList b_list = ArrayToDoubleList( b, n );

	// Correlate the lists
	return RankCorrelate( a, b );

}
*/