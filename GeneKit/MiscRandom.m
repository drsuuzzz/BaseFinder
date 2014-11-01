/*	MiscRandom.h

	Copyright 1996 Gregor Purdy.

	This notice may not be removed from this source code.
	The use and distribution of this software is governed by the
	terms of the MiscKit license agreement.  Refer to the license
	document included with the MiscKit distribution for the terms.

   	Converted to OpenStep, August 1996, Uwe Hoffmann.

*/


#import "MiscRandom.h"
#include <math.h>
#include <stdio.h>
#import <time.h>

@implementation MiscRandom
	/*"
	The MiscRandom class provides services for random number generation and die rolling. 
	It implements its own random number generator with a cycle length of 8.8 trillion.
	
	 
	The algorithm used by the MiscRandom class is that given in the article:
	%{ªA Higly Random Random±Number Generatorº} by T.A. Elkins
	Computer Language, Volume 6, Number 12 (December 1989), Pages 59-65
	Published by:
		Miller Freeman Publications
		500 Howard Street
		San Francisco, CA  94105
		(415) 397-1881
	"*/

- init
  /*"Initializes the Random with seeds from the milliseconds count of the system clock (uses #newSeeds)."*/
{
  [super init];			// Make a new instance using superclass' method
  [self newSeeds];		// Get a new seed for ourselves
  haveGset = NO;                // Don't have extra gaussian random lying around yet
  return self;
}

- initSeeds:(int)s1 :(int)s2 :(int)s3
/*"Initializes the Random with the seeds given (uses #setSeeds:::)."*/
{
    [super init];
    [self setSeeds:s1 :s2 :s3];
    haveGset = NO;                // Don't have extra gaussian random lying around yet
    return self;
}

- newSeeds
/*"Sets the seeds from the milliseconds count of the system clock."*/
{
  h1 = abs(time(NULL) + clock());
  h2 = abs(time(NULL) - clock());
  h3 = abs(time(NULL) + clock());
  return self;	
}

/**
- ORIGnewSeeds
//"Sets the seeds from the milliseconds count of the system clock."
{
    struct timeval theTime;			// gettimeofday return structure
	
    gettimeofday(&theTime,0);		// Get the time of day in seconds and microseconds
    h1 = theTime.tv_usec;			// Set seed 1 by microseconds past second
    gettimeofday(&theTime,0);		// Get the time of day in seconds and microseconds
    h2 = theTime.tv_usec;			// Set seed 2 by microseconds past second
    gettimeofday(&theTime,0);		// Get the time of day in seconds and microseconds
    h3 = theTime.tv_usec;			// Set seed 3 by microseconds past second
    return self;	
}
*/

- getSeeds:(int *)s1 :(int *)s2 :(int *)s3
/*"Puts the values of the seeds into the integer variables pointed to."*/
{
    if((s1 == NULL) || (s2 == NULL) || (s3 == NULL))
		return nil;
    *s1 = h1;
    *s2 = h2;
    *s3 = h3;
    return self;
}

- setSeeds:(int)s1 :(int)s2 :(int)s3
/*"Sets the seeds to the values given."*/
{
    h1 = s1;						// Set the seeds to the values given
    h2 = s2;
    h3 = s3;
    return self;
}

//
// See the Source article for the explanations of these constants
//
#define M1	32771
#define M2	32779
#define M3	32783
#define F1	179
#define F2	183
#define F3	182

#define MAXNUM	32767
#define RANGE	32768

- (int)rand
/*"Returns an int in the range [0, 32767]."*/
{
    h1 = (F1 * h1) % M1;			// Update the sections
    h2 = (F2 * h2) % M2;
    h3 = (F2 * h3) % M3;
    
    if ((h1 > MAXNUM) || (h2 > MAXNUM) || (h3 > MAXNUM))	// If a section is out of range,
        return [self rand];									//   return next result
    else													// Otherwise,
        return (h1 + h2 + h3) % RANGE;						//   Return this result
}

- (int)randMax:(int)max
/*"Returns an int in the range [0, max]."*/
{
    return (int)((float)[self rand] / (float)RANGE * (float)(max + 1));
}

- (int)randMin:(int)min max:(int)max
/*"Returns an int in the range [min, max]."*/
{
    return min + [self randMax:(max - min)];
}

- (float)percent
/*"Returns a float in the range [0.0, 1.0]."*/
{
    return ((float)[self rand] / (float)RANGE);
}

- (int)rollDie:(int)numSides
/*"Returns an int in the range [1, numSides]."*/
{
    return [self randMax:(numSides - 1)] + 1;
}

- (int)roll:(int)numRolls die:(int)numSides
/*"Returns an int in the range [numRolls, numRolls * numSides]"*/
{
    int temp = 0;
    int loop;
	
    for (loop = 1 ; loop <= numRolls ; loop++ )
		temp += [self rollDie:numSides];
    return temp;
}

- (int)rollBest:(int)numWanted of:(int)numRolls die:(int)numSides
/*"Returns the sum of the best numWanted rolls."*/
{
    int temp[numRolls];				// Array of rolls
    int loop1;						// First loop control variable
    int loop2;						// Second loop control variable
    int highest;					// Index of highest found roll
    int accumulator = 0;			// Accumulates total best roll
	
    for(loop1 = 1 ; loop1 <= numRolls ; loop1++)		// Fill an array with rolls
		temp[loop1] = [self rollDie:numSides];
    for (loop1 = 1 ; loop1 <= numWanted; loop1++) {
		highest = 1;									// Start off as if first is highest
		for(loop2 = 2 ; loop2 <= numRolls ; loop2++)	// Scan array for higher rolls
	    	if(temp[loop2] > temp[highest])				// If temp[loop2] is higher, then
				highest = loop2;						// remember that fact
		accumulator += temp[highest];					// Add highest roll to accumulator
		temp[highest] = 0;								// Clear highest roll so we don't find it again
    }
    return accumulator;									// Return what we found
}


// Adapted from Numerical Recipes
// Press, William H., Flannery, Brian P., Teukolsky, Saul A., and Vetterling, William T.
// Cambridge University Press, 1986, pp 202-203

- (float)gaussRand
{
  if (haveGset) {
    haveGset = NO;
    return gset;
  } else {
      double v1, v2, r, fac, gasdev;

      do {
        v1 = 2.0 * (double)[self percent] - 1;
        v2 = 2.0 * (double)[self percent] - 1;
        r = v1 * v1 + v2 * v2;
      } while (r >= 1);
      fac = sqrt(-2.0 * log(r) / r);
      gset = v1 * fac;
      gasdev = v2 * fac;
//      fprintf(stderr, "fac: %g gset: %g gasdev: %g\n", fac, gset, gasdev);
      haveGset = YES;
      return gasdev;
  }
}


@end


