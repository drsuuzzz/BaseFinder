/***********************************************************

Copyright (c) 1997-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

All Rights Reserved.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, 
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in 
supporting documentation. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of a copyright holder
shall not be used in advertising or otherwise to promote the sale, use
or other dealings in this Software without prior written authorization
of the copyright holder.  Citations, discussions, and references to or regarding
this work in scholarly journals or other scholarly proceedings 
are exempted from this permission requirement.

Support for this work provided by:
The University of Wisconsin-Madison Chemistry Department
The National Institutes of Health/National Human Genome Research Institute
The Department of Energy


******************************************************************/

#include <Foundation/Foundation.h>


typedef struct {
  float	 	fval;
  int		ival;
  BOOL		needsCalc;
} calcValue;

typedef struct {
  float			value;
  unsigned long		count;
} valueCountPair;

// index values for calcVals array:
// The idea is to keep a (value,flag) pair for each of the 
// non-trivial calculations that this class knows how to do, 
// so they're done only as needed
#define D_MEAN 0
#define D_VARIANCE 1
#define D_SKEW 2
#define D_CHISQUARE 3
#define D_MEDIAN 4

#define D_CALCVALS 8 // a little room to grow

@interface StatisticalDistribution:NSObject
{
  valueCountPair  *pairs;
  int             allocPairs,numPairs;

  calcValue       calcVals[D_CALCVALS];
  int             totalCount;

  BOOL            isClear; // used by clear()
}

- (void)addValue:(float)value;
- (void)empty;

- (float)mean;
- (float)variance;
- (float)standardDeviation;
- (float)skew;
- (float)chiSquare;
- (float)median;


- (float)minimum;
- (float)maximum;
	
- (float)percentileValue:(int)percentile;
	
- (int)count;
- (int)countForRange:(float)low :(float)high;
	
- (void)dump;
	
@end

