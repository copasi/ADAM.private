Template for JSON-formatted input file
Date: October 21, 2014
-------------------------------------- 

{"task":
	{
		"type": <problemType>,
		"input": ,
		"method":,
			{
				"id": <moduleName>,
				"description": <string>,
				"parameters": [parameters],
			}			
	}
}

--------------------------------------

type: this is the type of problem we are addressing. For example, "reverseEngineering" or "simulation". This should be a keyword.

input: general input data for all problems of the same type

method: here is where we describe each one of our methods
	* id: unique identifier for method.
	* description: brief description can be added
	* parameters: method-specific inputs
