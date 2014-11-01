/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "FltArrayTraverseExt.h"

#define sign(x) (((x >= 0) ? 1 : -1))

@implementation MGMutableFloatArray(FltArrayTraverseExt)

- (void)setPosition:(unsigned)position
{
  if (position >= [self count])
    curPos = [self count] - 1;
  else
    curPos = position;
}

- (unsigned)position
{
  return curPos;
}

- (float)curDataValue
{
  return (fltarray[curPos]);
}

- (float)nextDataValue
{
  unsigned temp = curPos + 1;

  if (temp >= [self count])
    temp = [self count] - 1;
  return (fltarray[temp]);
}

- (float)prevDataValue;
{
  unsigned temp=curPos;

  if (temp >=1)
    temp -= 1;
  return (fltarray[temp]);
}

- (BOOL)next
{
  curPos += 1;
  if (curPos >= [self count]) {
    curPos = [self count] - 1;
    reachedEnd = YES;
    return NO;
  }
  return YES;
}


- (BOOL)previous
{
  if (curPos <= 1) {
    curPos = 0;
    return NO;
  }
  curPos -= 1;
  return YES;
}

- (BOOL)atEnd
{
  return reachedEnd;
}

- (void)resetAtEnd
{
  reachedEnd = NO;
}

/* Min, Max, and Derivative routines */
- (unsigned)findNextMax
{
  float currentval;
  unsigned start, end;

  do {currentval = [self curDataValue];}
  while ([self next] && (currentval >= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self next] && (currentval < [self curDataValue]));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self previous];
    start = [self position];
    do {currentval = [self curDataValue];}
    while ([self next] && (currentval == [self curDataValue]));
    [self previous];
    end = [self position];
    [self setPosition:(start + (end-start)/2)];
  } else
    [self previous];
  return curPos;
}

- (unsigned)findPrevMin
{
  float currentval;
  unsigned start, end;

  currentval = [self curDataValue];
  do {currentval = [self curDataValue];}
  while ([self previous] && (currentval <= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self previous] && (currentval > [self curDataValue]));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self next];
    end = [self position];
    do {currentval = [self curDataValue];}
    while ([self previous] && (currentval == [self curDataValue]));
    [self next];	
    start = [self position];
    [self setPosition:(start + (end-start)/2)];
    return ([self position]);
  } else
    [self previous];
  return curPos;
}	

- (unsigned)findNextMin
{
  float currentval;
  unsigned start, end;

  do {currentval = [self curDataValue];}
  while ([self next] && (currentval <= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self next] && (currentval > [self curDataValue]));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self previous];
    start = [self position];
    do {currentval = [self curDataValue];}
    while ([self next] && (currentval == [self curDataValue]));
    [self previous];
    end = [self position];
    [self setPosition:(start + (end-start)/2)];
  } else
    [self previous];
  return curPos;
}

- (unsigned)findNextMinBelowZero
{
  float currentval;
  unsigned start, end;

  do {currentval = [self curDataValue];}
  while ([self next] && (currentval <= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self next] &&
        ((currentval > [self curDataValue]) ||
         (currentval > 0)));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self previous];
    start = [self position];
    do {currentval = [self curDataValue];}
    while ([self next] && (currentval == [self curDataValue]));
    [self previous];
    end = [self position];
    [self setPosition:(start + (end-start)/2)];
  } else
    [self previous];
  return curPos;
}


- (unsigned)findNextMaxAboveZero
{
  float currentval;
  unsigned start, end;

  do {currentval = [self curDataValue];}
  while ([self next] && (currentval >= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self next] &&
        ((currentval < [self curDataValue]) ||
         (currentval < 0)));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self previous];
    start = [self position];
    do {currentval = [self curDataValue];}
    while ([self next] && (currentval == [self curDataValue]));
    [self previous];
    end = [self position];
    [self setPosition:(start + (end-start)/2)];
  } else
    [self previous];
  return curPos;
}

- (unsigned)findPrevMaxAboveZero
{
  float currentval;
  unsigned start, end;

  do {currentval = [self curDataValue];}
  while ([self previous] && (currentval >= [self curDataValue]));
  do {currentval = [self curDataValue];}
  while([self previous] &&
        ((currentval < [self curDataValue]) ||
         (currentval < 0)));
  //The following just checks if the top of the peak is flat, then it
  //finds the middle.
  if (currentval == [self curDataValue]) {
    [self next];
    start = [self position];
    do {currentval = [self curDataValue];}
    while ([self previous] && (currentval == [self curDataValue]));
    [self next];
    end = [self position];
    [self setPosition:(start + (end-start)/2)];
  } else
    [self next];
  return curPos;
}



- (unsigned)findNextInflectionPoint
{
  float curvature1, curvature2;
  curvature2 = [self nextDataValue] - 2 * [self curDataValue] +
    [self prevDataValue];
  [self next];
  do {
    curvature1 = curvature2;
    curvature2 = [self nextDataValue] - 2 * [self curDataValue] +
      [self prevDataValue];}
  while ([self next] && (sign(curvature1) == sign(curvature2)));
  [self previous];
  return curPos;
}

- (unsigned)findNextZeroCrossing
{
  float prevsign;

  do {prevsign = sign([self curDataValue]);}
  while([self next] && (prevsign == sign([self curDataValue])));
  return curPos;
}

- (unsigned)findPrevZeroCrossing
{
  float prevsign;

  do {prevsign = sign([self curDataValue]);}
  while([self previous] && (prevsign == sign([self curDataValue])));
  return curPos;
}

- (MGMutableFloatArray *)secondDerivativeData
{
  unsigned i;
  float *array;
  float val;
  MGMutableFloatArray *secondDerivID;

  if (theArray == NULL)
    return NULL;
  if (count < 2)
    return NULL;
  secondDerivID = [MGMutableFloatArray floatArrayWithCount:0];
  array = [self floatArray];
  val = array[1] - 2*array[0] + array[2];
  [secondDerivID appendValue:val];
  for (i = 1; i < (count-1); i++) {
    val = array[i+1] - 2*array[i] + array[i-1];
    [secondDerivID appendValue:val];
  }
  [secondDerivID appendValue:val];
  return secondDerivID;
}



@end