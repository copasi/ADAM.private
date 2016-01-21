// RankCorr.h
//
// A class to compute Spearman's Rank Correlation coefficient
//

#ifndef _POLYMATH_DISCRETIZATION_RANK_CORR_H_
#define _POLYMATH_DISCRETIZATION_RANK_CORR_H_

#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>

#include "GraphMeasure.h"

using namespace std;

// Limit for too close to zero
const double epsilon = 1e-12;


// Define types for a Vector of doubles
typedef vector<double> ValueList;
typedef ValueList::iterator ValueListIter;
	
// Define a Vector of vectors
typedef vector<ValueList> GenesVector;
typedef GenesVector::iterator GenesVectorIter;

struct Pair
{
	// Index
	int k;

	// Value
	double x;
};


// Define the type for a list of integers (an ordering)
typedef vector<int> IntList;
typedef IntList::iterator IntListIter;

// Define a type for a list of double (the raw data)
//typedef vector<double> DoubleList;
//typedef DoubleList::iterator DoubleListIter;

// Define a type helpful for ranking
typedef vector<Pair> PairList;
typedef PairList::iterator PairListIter;

/*class SpearmanRankCorrelate
{
public:
	// Default constructor
	SpearmanRankCorrelate( );

	// Compute the rank of a list of data, result put in ordering.
	bool Rank( ValueList& data, IntList& ordering );

	// Compute Spearman's Rank Correlation Coefficient between
	//	two series a, b
	double RankCorrelate( ValueList& a, ValueList& b );

	// Define types for a Vector of DistinctEntry
	typedef vector<double> ValueList;
	typedef ValueList::iterator ValueListIter;
	
	// Define a Vector of vectors
	typedef vector<ValueList> GenesVector;
	typedef GenesVector::iterator GenesVectorIter;

	// Convert the given array of doubles 'a' to a ValueList
	static ValueList ArrayToDoubleList( double a[], size_t n );

	// Compute Spearman's Rank Correlation Coefficient between
	//	two double arrays a, b
	double RankCorrelate( ValueList a, ValueList b, size_t n );

	// Test the significance of the correlation coefficient cc
	//	for series of length n
	bool TestSignificance( double cc, size_t n );

private:
	// Critical threshold for correlation significance
	// at the 0.05 level, indexed by length n
	ValueList	mCriticalValues;
};
*/
#endif // _POLYMATH_DISCRETIZATION_RANK_CORR_H_
