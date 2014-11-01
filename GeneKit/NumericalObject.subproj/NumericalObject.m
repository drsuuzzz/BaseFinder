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

#import "NumericalObject.h"

@implementation NumericalObject

- init
{
  [super init];
  //NXNameObject("NumericalObject", self, NSApp);
  return self;
}

- (void)setListID:(NSMutableArray*)curID
{
  curListID = curID;
}

- (id)listID
{
  return curListID;
}

- (void)setTrace:(Trace*)newTrace
{
  currentTrace = newTrace;
}

- (void)setSequence:(Sequence*)newSequence
{
  currentSequence = newSequence;
}

- (Trace*)trace { return currentTrace; }
- (Sequence*)sequence { return currentSequence; }

- (void)setChannel:(int)channel
{
  curchannel = channel;
//  if (curListID != nil)
//    curPointsID = [curListID objectAtIndex:channel];
}

- (int)channel
{
  return curchannel;
}



/* Misc routines */
/*
- (ArrayStorage*)copyNegative
{
  return [self copyNegativeWithPoints:curPointsID];
}
- (ArrayStorage*)copyNegativeForChannel:(int)channel
{
  return [self copyNegativeWithPoints:[curListID objectAtIndex:channel]];
}

- (ArrayStorage*) copyNegativeWithPoints:(ArrayStorage*)pointsID
{
  ArrayStorage   *negCopyID;
  int count, i;
  float *dataArray;

  negCopyID = [pointsID copy];
  count = [negCopyID count];
  dataArray = (float*)[negCopyID returnDataPtr];

  for (i = 0; i < count; i++)
    dataArray[i] = -dataArray[i];

  return negCopyID;
}
*/
@end
