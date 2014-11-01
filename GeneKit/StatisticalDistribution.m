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

#import "StatisticalDistribution.h"
//need to include math.h for GNUStep
#import <math.h>

#define	D_INITALLOC 60

@interface StatisticalDistribution(StatisticalDistributionLocal)
- (void)grow;
- (void)insertValue:(float)value :(int)ix;
- (void)appendValue:(float)value;
- (void)clear;
	
- (float)calcMean;
- (float)calcMedian;
- (float)calcVariance;
- (float)calcSkew;
- (float)calcChiSquare;
@end

float calcNormalCDF(float);
float lookupNormalCDF(float);

@implementation StatisticalDistribution

- init
{
  [super init];
  isClear = totalCount = allocPairs = numPairs = 0;
  return self;
}

- (void)dealloc
{
  if (pairs) free(pairs);
  [super dealloc];
}

- (void)empty
{
  totalCount = numPairs = 0;
  [self clear];
}
	

- (float)mean
{
  if (!calcVals[D_MEAN].needsCalc)
    return calcVals[D_MEAN].fval;
  else {
    isClear = calcVals[D_MEAN].needsCalc=NO;
    return (calcVals[D_MEAN].fval=[self calcMean]);
  }
}

- (float)median
{
  if (!calcVals[D_MEDIAN].needsCalc)
    return calcVals[D_MEDIAN].fval;
  else {
    isClear = calcVals[D_MEDIAN].needsCalc=NO;
    return (calcVals[D_MEDIAN].fval=[self calcMedian]);
  }
}

- (float)variance
{
  if (!calcVals[D_VARIANCE].needsCalc)
    return calcVals[D_VARIANCE].fval;
  else {
    isClear = calcVals[D_VARIANCE].needsCalc=NO;
    return (calcVals[D_VARIANCE].fval=[self calcVariance]);
  }
}
	
- (float)standardDeviation
{
  return ((float)sqrt((double)[self variance]));
}
	
- (float)skew
{
  if (!calcVals[D_SKEW].needsCalc)
    return calcVals[D_SKEW].fval;
  else {
    isClear = calcVals[D_SKEW].needsCalc=NO;
    return (calcVals[D_SKEW].fval=[self calcSkew]);
  }
}
	
- (float)chiSquare
{
  if (!calcVals[D_CHISQUARE].needsCalc)
    return calcVals[D_CHISQUARE].fval;
  else {
    isClear = calcVals[D_CHISQUARE].needsCalc=NO;
    return (calcVals[D_CHISQUARE].fval=[self calcChiSquare]);
  }
}
	
- (float)minimum
{
  if (numPairs) return pairs[0].value;
  else return 0;
}

- (float)maximum
{
  if (numPairs) return pairs[numPairs-1].value;
  else return 0;
}
		
- (int)count { return totalCount; }

- (void)dump
{
  int   i;
  for (i=0;i<numPairs;i++)
    printf("%f, %d\n",pairs[i].value,(int)pairs[i].count);
}
	


- (void)clear
{
  int i;
  if (isClear) return;
  for (i=0;i<D_CALCVALS;i++)
    calcVals[i].needsCalc = YES;
  isClear = YES;
}

- (void)grow
{
  if (allocPairs>0) {
    pairs = (valueCountPair *)realloc(pairs,allocPairs*2*sizeof(valueCountPair));
    allocPairs *= 2;
  } else {
    pairs = (valueCountPair *)malloc(D_INITALLOC*sizeof(valueCountPair));
    allocPairs = D_INITALLOC;
  }
}

- (void)insertValue:(float)value :(int)ix
{
  int i;
  if (numPairs==allocPairs)
    [self grow];
  for (i=numPairs;i>ix;i--)
    pairs[i] = pairs[i-1];
  pairs[ix].value = value;
  pairs[ix].count = 1;
  numPairs++;
}

- (void)appendValue:(float)value
{
  [self insertValue:value :numPairs];
}

- (void)addValue:(float)value
{
  int	bottom = 0, top = numPairs-1, middle;
  BOOL	inserted = NO;

  // get the boundary cases out of the way:
  if (numPairs==0 || value>pairs[top].value) {
    [self appendValue:value];
    inserted = YES;
  } else if (value==pairs[top].value) {
    pairs[top].count++;
    inserted = YES;
  } else if (value<pairs[0].value) {
    [self insertValue:value :0];
    inserted = YES;
  }  else if (value==pairs[0].value) {
    pairs[0].count++;
    inserted = YES;
  }

  while (!inserted) {
    if (top-bottom==1) {
      [self insertValue:value :top];
      inserted = YES;
    } else {
      middle = (bottom+top)/2;
      if (value<pairs[middle].value)
        top = middle;
      else if (value>pairs[middle].value)
        bottom = middle;
      else {
        pairs[middle].count++;
        inserted = YES;
      }
    }
  }

  totalCount++;
  [self clear];
}

- (int)countForRange:(float)low :(float)high // low inclusive, high exclusive
{
  static	int	startAt = 0;
  int	i;
  int	rangeCount = 0;

  // check some easy cases:
  if (high<=pairs[0].value || low>pairs[numPairs-1].value || numPairs==0)
    return 0;
		
  // usually, this is called in the midst of a series of calls
  // over adjacent but non-overlapping ranges; if this is
  // the case, startAt will be pointing at the first value
  // >= low; check  to make sure
  startAt = startAt >= totalCount ? 0 : startAt;
  if (pairs[startAt].value < low || (startAt>0 && pairs[startAt-1].value>=low)){
    // assumption doesn't hold; set startAt correctly
    for (startAt=0;pairs[startAt].value<low;startAt++);
  }	

  for (i=startAt;i<numPairs && pairs[i].value<high;i++) rangeCount+=pairs[i].count;

  startAt =  i;

  return rangeCount;
}

- (float)calcMean
{
  float myMean=0;
  int i;

  for (i=0;i<numPairs;i++)
    myMean += (pairs[i].value*pairs[i].count)/(float)totalCount;
		
  //printf("calcMean result = %f\n",myMean);	
  // if (fabs(myMean)<1.0 || fabs(myMean)>100000) {
  // printf("mean %f unreasonable; dump:\n", myMean);
  // dump();
  //}	
  return myMean;
}

- (float)calcMedian
{
  return [self percentileValue:50]; 
}

- (float)calcVariance
{
  float myVariance=0, myMean = [self mean], tmp;
  int i;

  for (i=0;i<numPairs;i++) {
    tmp = pairs[i].value - myMean;
    myVariance += ((1.0/(float)(totalCount-1)) * tmp * tmp)*(float)pairs[i].count;	
  }

  //printf("calcVariance result = %f\n",myVariance);

  return myVariance;
}

- (float)calcSkew
{
  float myMean = [self mean], myStandardDeviation = [self standardDeviation], mySkew = 0;

  int i;
  float	tmp, skew = 0;

  for (i=0;i<numPairs;i++) {
    tmp = (pairs[i].value-myMean)/myStandardDeviation;
    skew += ((1.0/(float)totalCount) * tmp * tmp * tmp)*(float)pairs[i].count;		
  }

  return mySkew;
}

// returns  the smallest value at or above the specified percentile
- (float)percentileValue:(int)percentile
{
  int	numBelow = (percentile * totalCount)/100;
  int	i;

  for (i=0;i<numPairs && numBelow>0;i++)
    numBelow -= pairs[i].count;
		
  if (i<numPairs)
    return pairs[i].value;
  else
    return [self maximum] + 1.0;
}


- (float)calcChiSquare
{

  float	myMean = [self mean], myStandardDeviation = [self standardDeviation];
  float	myChiSquare = 0;
  int	 actualCnt;
  float	predictedCnt, tmp;
  int		binsPerStdDev = 4;
  float	lower, upper, binWidth = myStandardDeviation/(float)binsPerStdDev;
  float	normUpper, normLower; // ends of bin, normalized to standard devs.

  /* This constraint on numPairs keeps the chi-square statistic from being
    * artificially elevated by binning of a small number of distinct values.
    * Empirically determined--5 might even be a bit low.
    */
  if (numPairs > 5) {
    if (binWidth > 1.0)
      lower = myMean - (3.0 * myStandardDeviation);
    else {
      binWidth = 1.0;
      lower = myMean;
      while (lower > (myMean - (3.0*myStandardDeviation))) lower -= binWidth;
    }
    upper = lower + binWidth;

    while (upper < (myMean + (3.0*myStandardDeviation))) {			
      actualCnt = [self countForRange:lower :upper];
      normLower = (lower-myMean)/myStandardDeviation;
      normUpper = (upper-myMean)/myStandardDeviation;

      // This avoids division by zero:
      if (normLower >= -3.0 && normUpper <= 3.0)
        predictedCnt = (lookupNormalCDF(normUpper) - lookupNormalCDF(normLower))*totalCount;
      else
        predictedCnt = (calcNormalCDF(normUpper) - calcNormalCDF(normLower))*totalCount;

      tmp = (actualCnt - predictedCnt);
      myChiSquare += (tmp * tmp)/predictedCnt;

      lower += binWidth;
      upper = lower + binWidth;
    }
  }

  return myChiSquare;
}

@end
