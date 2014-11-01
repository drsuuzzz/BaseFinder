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
/****
*  2006-06-05 S. Vasa
*  Peak - redone to support Peak finding and alignment algorithm in the tool Align and Integrate
*
*****/

#import "Peak.h"

@implementation Peak
/*+ (Peak *)peakFrom:(unsigned)_start to:(unsigned)_end center:(unsigned)_center withData:(MGMutableFloatArray *)theData
{
  Peak *temp;
  temp = [[Peak alloc] init];
  temp->start = _start;
  temp->end = _end;
  temp->center = _center;
  temp->signalData = [theData retain];
  return [temp autorelease];
}*/

- init
{
  peaks = [[NSMutableArray arrayWithCapacity:0] retain];
//  CM = -1;
//  VAR = -1;
//  signalData = NULL;
  [super init];
  return self;
}

-(id)copyWithZone:(NSZone *) zone
{
  Peak  *dupSelf;
  int   i;
  NSMutableArray  *tempArray;
  
  dupSelf = [[Peak allocWithZone:zone] init];
  for (i=0; i < [peaks count]; i++) {
    tempArray = [[peaks objectAtIndex:i] mutableCopyWithZone:zone];
    [dupSelf->peaks addObject:[tempArray autorelease]];
  }
  return dupSelf;
}

-(void)dealloc
{
  //[peaks release];
  [super dealloc];
}

-(void) addPosition:(int)pos
{
  NSNumber        *tempPos;
  NSMutableArray  *tempArray;
  
  tempPos = [[NSNumber alloc] initWithInt:pos];
  tempArray = [[NSMutableArray alloc] init];
  [tempArray addObject:tempPos];
  [peaks addObject:tempArray];
  [tempPos release];
  [tempArray release];
}

-(int)position:(int)atPeak
{
  return [[[peaks objectAtIndex:atPeak] objectAtIndex:0] intValue];
}

-(void)replacePosition:(int)atPeak withPos:(int)pos
{
	NSNumber	*tempPos;
	
	tempPos = [[NSNumber alloc] initWithInt:pos];
	[[peaks objectAtIndex:atPeak] replaceObjectAtIndex:0 withObject:tempPos];
	[tempPos release];
}

-(void)addOrigin:(int)atPeak :(NSPoint)point
{
  NSNumber  *tempX, *tempY;
  
  tempX = [[NSNumber alloc] initWithFloat:point.x];
  tempY = [[NSNumber alloc] initWithFloat:point.y];
  [[peaks objectAtIndex:atPeak] addObject:tempX];
  [[peaks objectAtIndex:atPeak] addObject:tempY];
  [tempX release];
  [tempY release];
}

-(void)replaceOrigin:(int)atPeak :(NSPoint)point
{
  NSNumber *tempX, *tempY;
  
  tempX = [[NSNumber alloc] initWithFloat:point.x];
  tempY = [[NSNumber alloc] initWithFloat:point.y];
  [[peaks objectAtIndex:atPeak] replaceObjectAtIndex:1 withObject:tempX];
  [[peaks objectAtIndex:atPeak] replaceObjectAtIndex:2 withObject:tempY];
  [tempX release];
  [tempY release];
}

-(NSPoint)origin:(int)atPeak
{
  NSPoint point;
  
  point.x = [[[peaks objectAtIndex:atPeak] objectAtIndex:1] floatValue];
  point.y = [[[peaks objectAtIndex:atPeak] objectAtIndex:2] floatValue];
  return point;
}

-(int)length:(int)atPeak
{
  return [[peaks objectAtIndex:atPeak] count];
}

@end

@implementation AlignedPeaks

-init
{
  alnPeakList = [[NSMutableArray arrayWithCapacity:0] retain];
  [super init];
  return self;
}

-(void)addAlnPeak:(Peak *)peakItem
{
  [alnPeakList addObject:peakItem];
}

-(int)valueAt:(int)atIndex :(int)atPeak
{
  return [[alnPeakList objectAtIndex:atIndex] position:atPeak];
}

-(void)replacePosition:(int)atIndex atPeak:(int)atPeak with:(int)newPos
{
	[[alnPeakList objectAtIndex:atIndex] replacePosition:atPeak withPos:newPos];
}

-(void)removeLinkedPeaksAt:(int)index
{
	if (index < [alnPeakList count])
		[alnPeakList removeObjectAtIndex:index];
}
-(NSPoint)originAt:(int)atIndex :(int)atPeak
{
  return [[alnPeakList objectAtIndex:atIndex] origin:atPeak];
}

-(void)addOrigin:(int)atIndex :(int)atPeak :(NSPoint)origin
{
  if ([[alnPeakList objectAtIndex:atIndex] length:atPeak] > 1)
    [[alnPeakList objectAtIndex:atIndex] replaceOrigin:atPeak :origin];
  else
    [[alnPeakList objectAtIndex:atIndex] addOrigin:atPeak :origin];
}

-(BOOL)hasOrigin:(int)atIndex :(int)atPeak
{
  BOOL origin=NO;
  
  if ([[alnPeakList objectAtIndex:atIndex] length:atPeak] > 1)
    origin = YES;
  return origin;
}

-(int)length
{
  return [alnPeakList count];
}

-(id)copyWithZone:(NSZone *)zone
{
  AlignedPeaks  *dupSelf;
  Peak          *tempPeak;
  int           i;
  
  dupSelf = [[AlignedPeaks allocWithZone:zone] init];
  
  for (i=0; i<[alnPeakList count]; i++) {
    tempPeak = [[alnPeakList objectAtIndex:i] copyWithZone:zone];
    [dupSelf->alnPeakList addObject:[tempPeak autorelease]];
  }
  
  return dupSelf;
}

-(void)dealloc
{
  [alnPeakList release];
  [super dealloc];
}

@end

/*- (unsigned)start
{
  return start;
}
- (unsigned)end
{
  return end;
}
- (unsigned)center
{
  return center;
}

- (unsigned)width
{
  if (end > start)
    return (end - start);
  else
    return 0;
}

- (float)h
{
    return [signalData elementAt:center];
}

- (float)ldiff
{
  if (signalData)
    return ([signalData elementAt:center] - [signalData elementAt:start]);
  else
    return 0;
}

- (float)rdiff
{
  if (signalData)
    return ([signalData elementAt:center] - [signalData elementAt:end]);
  else
    return 0;
}

- (float)centerValue
{
  if (signalData)
    return ([signalData elementAt:center]);
  else
    return 0;
}


- (NSComparisonResult)compareTo:(Peak *)otherPeak
{
  float selfdiff, otherdiff;

  selfdiff =  ( ([self ldiff] > [self rdiff]) ?
                [self ldiff]  : [self rdiff] );
  otherdiff = ( ([otherPeak ldiff] > [otherPeak rdiff]) ?
                [otherPeak ldiff] : [otherPeak rdiff] );
  if (([self centerValue] * selfdiff / [self peakVariance]) >
      ([otherPeak centerValue] * otherdiff / [otherPeak peakVariance]))
    return NSOrderedAscending;
  else
    return NSOrderedDescending;
}

- (float)centralMoment
{
  if (CM < 0) {
    float numerator=0, denominator=0;
    unsigned i;

    for (i = start; i <= end; i++) {
      numerator += (float)i * [signalData elementAt:i];
      denominator += [signalData elementAt:i];
    }
    CM = numerator/denominator;
  }
  return CM;
}

- (float)peakVariance
{
  if (VAR < 0) {
    float numerator=0, denominator=0, cm=[self centralMoment];
    unsigned i;

    for (i = start; i <= end; i++) {
        numerator += (((float)i - cm)*((float)i - cm)) * [signalData elementAt:i];
      denominator += [signalData elementAt:i];
    }
    VAR = numerator / denominator;
  }
  return VAR;
}*/


