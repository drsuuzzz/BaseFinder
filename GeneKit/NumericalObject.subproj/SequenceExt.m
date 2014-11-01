/* "$Id: SequenceExt.m,v 1.3 2007/05/23 20:31:58 smvasa Exp $" */
/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "SequenceExt.h"
//#import <objc/List.h>
//#import "ArrayStorage.h"
#import <Sequence.h>
#import <Trace.h>

#define INITIALBASEOWNER 0
#define STANDARDCONFIDENCE	0.6


@implementation NumericalObject(SequenceExt)


- (Sequence *)returnInitBases:(Trace *)trace
{
  /* This routine takes a list of points and creates an initial list of "bases" simply
  based on maxima found.  The id is the pointer to the baseList returned, which will
  only be different from the one passed in if the one passed in was NULL.
  numPoints is the number of points in the trace (four channel) structure. */

  int i,j;
//  Storage * resultingMaxima;
  NSArray *resultingMaxima;
  int maximaCount;
  int numChannels;
  Base *newBase;
  Sequence *baseList = [Sequence newSequence];


  //printf("returnInitBases baseList=%d\n",(int)baseList);

  numChannels = [trace numChannels];
  for (i = 0; i < numChannels; i++) {
    resultingMaxima = [self findMaxima1:(float *)[[trace sampleDataAtChannel:i] bytes]
                                       :[trace length]
                                       :NULL];
    maximaCount = [resultingMaxima count];
    for (j = 0; j < maximaCount; j++) {
 /*     oneBase.location = [[resultingMaxima objectAtIndex:j] intValue];
      oneBase.confidence = STANDARDCONFIDENCE;
      oneBase.channel = i;
      oneBase.owner = INITIALBASEOWNER; */
      switch (i) {
        case A_BASE: 
            newBase = [Base baseWithCall:'A' floatConfidence:STANDARDCONFIDENCE location:[[resultingMaxima objectAtIndex:j] intValue]];
          break;
        case T_BASE:             
            newBase = [Base baseWithCall:'T' floatConfidence:STANDARDCONFIDENCE location:[[resultingMaxima objectAtIndex:j] intValue]];
          break;
        case C_BASE:             
            newBase = [Base baseWithCall:'C' floatConfidence:STANDARDCONFIDENCE location:[[resultingMaxima objectAtIndex:j] intValue]];
          break;
        case G_BASE:             
            newBase = [Base baseWithCall:'G' floatConfidence:STANDARDCONFIDENCE location:[[resultingMaxima objectAtIndex:j] intValue]];
          break;
      };
      [newBase setChannel:i];
      [newBase setAnnotation:[NSNumber numberWithInt:INITIALBASEOWNER] forKey:@"owner"];

      [baseList addBase:newBase];
    }
  };
  [baseList sortByLocation];
  //= [self sortBaseList:baseList];
  return baseList;
}

/*
- (Sequence *)sortBaseList:(Sequence *)baseStorageStruct
{
  This does probably the most inneficient job of sorting I could have
  imagined - but it should sort the bases present in order of location. */
/*  
  int i,j;
  int count, loc;
  int min;	
  aBase	 *theBase, *otherBase, swap;
  aBase *baseArray;


  count = [baseStorageStruct count];
  baseArray = (aBase *)[baseStorageStruct returnDataPtr];
  for (i = 0; i < count; i++) {
    min = baseArray[i].location;
    loc = i;
    for (j = i; j < count; j++) {
      if ((baseArray[j].location) < min) {
        min = (baseArray[j].location);
        loc = j;
      }
    };
    if (loc != i) {
      theBase = &baseArray[i];
      otherBase = &baseArray[loc];
      swap = *theBase;
      *theBase = *otherBase;
      *otherBase = swap;
    }
  }
  return baseStorageStruct;

}		
*/

- (NSMutableArray *)findMaxima1:(float*)numbers :(int)numPoints :(NSMutableArray *)theStorage
{
  NSMutableArray  *theMaximaStorage;
  int i, center, left, right;

  if (theStorage == NULL)
    theMaximaStorage = [NSMutableArray array];
  else
    theMaximaStorage = theStorage;

  for (i = 1; i < (numPoints - 1); i++) {
    if ((numbers[i] > numbers[i-1]) && (numbers[i] > numbers[i+1]))
      [theMaximaStorage addObject:[NSNumber numberWithInt:i]];
    else if ((numbers[i] > numbers[i-1]) && (numbers[i] == numbers[i+1])) {
      left = i;
      while ((numbers[i] == numbers[i+1]) && (i < (numPoints+1)))
        i++;
      if (numbers[i] > numbers[i+1]) {
        right = i;
        center = left + (right-left)/2;
        [theMaximaStorage addObject:[NSNumber numberWithInt:center]];
      }
    }
  }

  return theMaximaStorage;
}





- (NSMutableArray *)findMinima:(float*)numbers :(int)numPoints :(NSMutableArray *)theStorage
{
  NSMutableArray * theMinimaStorage;
  int i, center, left, right;

  if (theStorage == NULL)
    theMinimaStorage = [NSMutableArray array];
  else
    theMinimaStorage = theStorage;

  for (i = 1; i < (numPoints - 1); i++) {
    if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
      [theMinimaStorage addObject:[NSNumber numberWithInt:i]];
    else if ((numbers[i] < numbers[i-1]) && (numbers[i] == numbers[i+1])) {
      left = i;
      while ((numbers[i] == numbers[i+1]) && (i < (numPoints+1)))
        i++;
      if (numbers[i] < numbers[i+1]) {
        right = i;
        center = left + (right-left)/2;
        [theMinimaStorage addObject:[NSNumber numberWithInt:center]];
      }
    }
  }

  return theMinimaStorage;
}

- (int)findrightminloc:(int)location :(float*)numbers :(int)numPoints
{
  int i, left;


  for (i = location; i < (numPoints-1); i++) {
    if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
      return i;
    else if ((numbers[i] < numbers[i-1]) && (numbers[i] == numbers[i+1])) {
      left = i;
      while ((numbers[i] == numbers[i+1]) && (i < (numPoints-1)))
        i+=1;
      if (numbers[i] < numbers[i+1])
        return left;
    }
  }
  return (numPoints-1);  /* min not found */
}

- (int)findleftminloc:(int)location :(float*)numbers :(int)numPoints
{
  int i, right;


  for (i = location; i > 0; i--) {
    if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
      return i;
    else if ((numbers[i] < numbers[i+1]) && (numbers[i] == numbers[i-1])) {
      right = i;
      while ((numbers[i] == numbers[i-1]) && (i > 0))
        i-=1;
      if (numbers[i] < numbers[i-1])
        return right;
    }
  }
  return 0;  /* min not found */
}

- (int)countmin:(int)location :(float*)nums :(int)channel
{
//	if (nums[location] < ((LOWCUTOFF/100) * //abs(expectedMinHeight(channel,location))
//	+ expectedMinHeight(channel,location)))
                return YES;
//	else
//		return FALSE;
}

- (float)peakwidth:(int)location :(float*)numbers :(int)numPoints :(int)channel
{	
  int templeftloc, temprightloc;

  // Scan to the left until min value is likely to REALLY be a minimum
  templeftloc = [self findleftminloc:location :numbers :numPoints];
  while((templeftloc > 0) && (![self countmin:templeftloc :numbers :channel]))
    templeftloc = [self findleftminloc:templeftloc-1 :numbers :numPoints];

  //Scan to the right until max value is high enough to really be maximum
  temprightloc = [self findrightminloc:location :numbers :numPoints];
  while((temprightloc < (numPoints-1))&&(![self countmin:temprightloc :numbers :channel]))
    temprightloc = [self findrightminloc:temprightloc+1 :numbers :numPoints];

  return abs(temprightloc - templeftloc);
  //	return abs([self findrightminloc:location :numbers :numPoints] -
  //	           [self findleftminloc:location :numbers :numPoints]);

}

- (int)lefthalfheightpoint:(int)location :(float*)numbers :(int)numPoints
{
  int leftminloc, i;
  float leftmin, halfcutoff;

  leftminloc = [self findleftminloc:location :numbers :numPoints];
  leftmin = numbers[leftminloc];
  halfcutoff = (numbers[location] - leftmin)/2 + leftmin;
  for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;

  return i;
}

 - (int)righthalfheightpoint:(int)location :(float*)numbers :(int)numPoints
{
  int rightminloc, i;
  float rightmin, halfcutoff;

  rightminloc = [self findrightminloc:location :numbers :numPoints];
  rightmin = numbers[rightminloc];
  halfcutoff = (numbers[location] - rightmin)/2 + rightmin;
  for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++) ;

  return i;
}

- (int)halfHeightPeakWidth:(int)location :(float*)numbers :(int)numPoints
{
  // Find the peak width based on half height measure
  float leftmin, rightmin, maxmin, halfcutoff;
  int leftminloc, rightminloc;
  int i;
  int lefthalfheightloc, righthalfheightloc;


  leftminloc = [self findleftminloc:location :numbers :numPoints];
  rightminloc = [self findrightminloc:location :numbers :numPoints];
  leftmin = numbers[leftminloc];
  rightmin = numbers[rightminloc];

  maxmin = (leftmin > rightmin ? leftmin : rightmin);
  halfcutoff = (numbers[location] - maxmin)/2 + maxmin;

  for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;
  lefthalfheightloc = i;

  for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++);
  righthalfheightloc = i;

  return  (righthalfheightloc - lefthalfheightloc);

}

- (int)halfHeightPeakAveWidth:(int)location :(float*)numbers :(int)numPoints
{
  // Find the peak width based on half height measure
  float leftmin, rightmin, halfcutoff;
  int leftminloc, rightminloc;
  int i;
  int lefthalfheightloc, righthalfheightloc;


  leftminloc = [self findleftminloc:location :numbers :numPoints];
  rightminloc = [self findrightminloc:location :numbers :numPoints];
  leftmin = numbers[leftminloc];
  rightmin = numbers[rightminloc];

  //	minmin = (leftmin < rightmin ? leftmin : rightmin);

  halfcutoff = (numbers[location] - leftmin)/2 + leftmin;
  for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;
  lefthalfheightloc = i;

  halfcutoff = (numbers[location] - rightmin)/2 + rightmin;
  for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++);
  righthalfheightloc = i;

  return  (righthalfheightloc - lefthalfheightloc);

}

- (void)secondOrderMaxFit:(id)Data :(int)chan :(float*)A :(int)n
{
  NSMutableArray * maxStorage, *secondOrderMaxStorage;
  int numPoints, i, j;
  float *numbers, *maxnums;
  int maxcount;
  float *fitnums[3];
  int   right, center, left;

  numbers = [Data sampleArrayAtChannel:chan];
  numPoints = [Data length];

  secondOrderMaxStorage = [NSMutableArray array];
  maxStorage = [self findMaxima1:numbers :numPoints :NULL];
  maxnums = (float *)calloc([maxStorage count]+1, sizeof(float));

  maxcount= [maxStorage count];
//  tmp = (int *)[maxStorage returnDataPtr];
  for (i = 0; i < maxcount; i++) {
    maxnums[i] =  numbers[[[maxStorage objectAtIndex:i] intValue]];
  }

  for (i = 1; i < (maxcount - 1); i++) {
    if ((maxnums[i] > maxnums[i-1]) && (maxnums[i] > maxnums[i+1]))
      [secondOrderMaxStorage addObject:[maxStorage objectAtIndex:i]];
//      &tmp[i]];
    else if ((maxnums[i] > maxnums[i-1]) && (maxnums[i] == maxnums[i+1])) {
      left = i;
      while ((maxnums[i] == maxnums[i+1]) && (i < (maxcount+1)))
        i++;
      if (maxnums[i] > maxnums[i+1]) {
        right = i;
        center = left + (right-left)/2;
        [secondOrderMaxStorage addObject:[maxStorage objectAtIndex:center]];
        //&tmp[center]];
      }
    }
}



//  soMaxNums = (int *)[secondOrderMaxStorage returnDataPtr];
  for (i = 0; i < 3; i++)
    fitnums[i] = (float *)calloc([secondOrderMaxStorage count], sizeof(float));
  for (j = 0; j < [secondOrderMaxStorage count]; j++) {
    fitnums[0][j] = [[secondOrderMaxStorage objectAtIndex:j] floatValue];
    //(float) soMaxNums[j];
    fitnums[1][j] = numbers[[[secondOrderMaxStorage objectAtIndex:j] intValue]];
//    (float) numbers[soMaxNums[j]];
//    fitnums[2][j] = 1;
  }
  [self myfit:fitnums[0] :fitnums[1] :fitnums[2] :[secondOrderMaxStorage count] :A :n :self];
  //fprintf(stderr,"a0:%e a1:%e a2:%e\n", A[0], A[1], A[2]);

  for (i = 0; i < 3; i++)
    free(fitnums[i]);
//  [secondOrderMaxStorage release];
  free(maxnums);
}	


- (void)secondOrderMinFit:(id)Data :(int)chan :(float*)A :(int)n
{
  id minStorage;
  id secondOrderminStorage;
  int numPoints, i, j;
  float *numbers, *minnums;
  int mincount;
  float *fitnums[3];
  int right, center, left;

  numbers = [Data sampleArrayAtChannel:chan];
  numPoints = [Data length];

  minStorage = [self findMinima:numbers :numPoints :NULL];
  secondOrderminStorage = [NSMutableArray array];

  minnums = (float *)calloc([minStorage count]+1, sizeof(float));

  mincount= [minStorage count];
//  tmp = (int *)[minStorage returnDataPtr];
  for (i = 0; i < mincount; i++) {
    minnums[i] =  numbers[[[minStorage objectAtIndex:i] intValue]];
  }

  for (i = 1; i < (mincount - 1); i++) {
    if ((minnums[i] < minnums[i-1]) && (minnums[i] < minnums[i+1]))
      [secondOrderminStorage addObject:[minStorage objectAtIndex:i]];
    else if ((minnums[i] < minnums[i-1]) && (minnums[i] == minnums[i+1])) {
      left = i;
      while ((minnums[i] == minnums[i+1]) && (i < (mincount+1)))
        i++;
      if (minnums[i] < minnums[i+1]) {
        right = i;
        center = left + (right-left)/2;
        [secondOrderminStorage addObject:[minStorage objectAtIndex:center]];
      }
    }
  }



//  sominNums = (int *)[secondOrderminStorage returnDataPtr];
  for (i = 0; i < 3; i++)
    fitnums[i] = (float *)calloc([secondOrderminStorage count], sizeof(float));
  for (j = 0; j < [secondOrderminStorage count]; j++) {
    fitnums[0][j] = [[secondOrderminStorage objectAtIndex:j] floatValue];
    fitnums[1][j] =  numbers[[[secondOrderminStorage objectAtIndex:j] intValue]];
    fitnums[2][j] = 1;
  }
  [self myfit:fitnums[0] :fitnums[1] :fitnums[2] :[secondOrderminStorage count] :A :n :self];
  //fprintf(stderr,"a0:%e a1:%e a2:%e\n", A[0], A[1], A[2]);
  for (i = 0; i < 3; i++)
    free(fitnums[i]);
//  [minStorage release];
//  [secondOrderminStorage release];
  free(minnums);
}	

@end
