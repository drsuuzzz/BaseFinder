/*	MiscRandom.h

	Copyright 1996 Gregor Purdy.

	This notice may not be removed from this source code.
	The use and distribution of this software is governed by the
	terms of the MiscKit license agreement.  Refer to the license
	document included with the MiscKit distribution for the terms.

   	Converted to OpenStep, August 1996, Uwe Hoffmann.

*/


#import <Foundation/NSObject.h>

@interface MiscRandom : NSObject
{
@private
	int h1, h2, h3;					/*" The seeds for the random number generator"*/
  float gset;  // Storage of second gaussian Deviate
  BOOL haveGset;
}

/*" Initializing "*/
- init;								// Init with seeds from newSeeds;
- initSeeds:(int)s1					// Init with seeds given.
  :(int)s2
  :(int)s3;
  
/*" Determining the seeds "*/
- newSeeds;							// Get seeds from system time.
- setSeeds:(int)s1					// Set seeds to those given.
  :(int)s2
  :(int)s3;
- getSeeds:(int *)s1				// Put the seeds into some vars.
  :(int *)s2
  :(int *)s3;

/*" Asking random numbers "*/
- (int)rand;						// Return a random integer.
- (int)randMax:(int)max;			// Return a random integer 0 <= x <= max.
- (int)randMin:(int)min				// Return a random integer min <= x <= max.
  max:(int)max;
- (float) percent;					// Return a random float 0.0 <= x <= 1.0.
- (int)rollDie:(int)numSides;		// Return a random integer 1 <= x <= numSides.
- (int)roll:(int)numRolls			// Return the best numWanted of numRolls rolls.
  die:(int)numSides;
- (int)rollBest:(int)numWanted		// Return integer sum of best numWanted rolls.
  of:(int)numRolls
  die:(int)numSides;

- (float)gaussRand;


@end


