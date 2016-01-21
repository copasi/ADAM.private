// BoolArray.h

#ifndef _POLYMATH_DISCRETIZATION_BOOL_ARRAY_H_
#define _POLYMATH_DISCRETIZATION_BOOL_ARRAY_H_

// A class to hold an array of boolean values
//	used for various graph algorithms
class BoolArray
{
public:
	// Constructor
	BoolArray( size_t n )
	{
		// Dynamically allocate the array
		mN = n;
		mBools = new bool[n];
		size_t i = n;
		// set each element to false
		while( i > 0 )
		{
			--i;
			mBools[i] = false;
		}
	}

	// Copy constructor
	BoolArray( const BoolArray& other )
	{
		// Make a new copy of the array of booleans
		mN = other.mN;
		mBools = new bool[mN];
		size_t i = mN;
		while( i > 0 )
		{
			--i;
			mBools[i] = other[i];
		}
	}

	// Destructor
    ~BoolArray()
	{
		// free the dynamically allocated array
		delete [] mBools;
	}


	// Index operator for non-constant BoolArray
	bool& operator[]( size_t i )
	{
		if( i >= mN ) throw( "BoolArray - invalid index" );
		return mBools[i];
	}

	// Index operator for a constant BoolArray
	//	needed to support copy constructor
	const bool& operator[]( size_t i ) const
	{
		if( i >= mN ) throw( "BoolArray - invalid index" );
		return mBools[i];
	}

private:
	// Size of the array
	size_t	mN;
	// Pointer to dynamically allocated array of bool's
	bool*	mBools;
};

// Define types for a Vector of BoolArray objects
typedef vector<BoolArray> NodeVisitedList;
typedef vector<BoolArray>::iterator NodeVistedListIter;

#endif //_POLYMATH_DISCRETIZATION_BOOL_ARRAY_H_
