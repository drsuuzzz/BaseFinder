
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


#import "EventLadder.h"
#import "StatisticalDistribution.h"
#import "MGMutableFloatArray.h"
#import "FltArrayTraverseExt.h"
#import "LadderPeak.h"

@interface EventLadder(Private)
-(void)setArray:(NSMutableArray *)new;
@end


@implementation EventLadder

+ newLadder
{	id temp;

	temp = [self alloc];
	return [[temp init] autorelease];
}

	
- init
{
  ladder = [[NSMutableArray arrayWithCapacity:0] retain];
  _traceData = NULL;
  maxCenter = 0;
  [super init];
  return self;
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@", count=%d", [ladder count]];
  [tempString appendFormat:@", maxExtent=%f", maxCenter];
  return tempString;
}

-(void)setArray:(NSMutableArray *)newArray
{
    [ladder release];
    ladder = [newArray retain];
}

-(NSMutableArray *)array
{
  return ladder;
}

- (void)addObjectsFromArray:(NSArray *)array
{	
  [ladder addObjectsFromArray:array];
}

- (void)writeToFile:(NSString *)fname
{
  NSMutableString *textOut=[NSMutableString stringWithCapacity:255];
  unsigned i, count;
  id <LadderPeak> temp;

  [textOut appendFormat:@"tuples={\n"];

  count = [ladder count];
  for (i=0; i < (count-1); i++) {
    temp = [self objectAtIndex:i];
    [textOut appendFormat:@"{%f, %f, %f, %d, %e}, ", [temp width], [temp position], [temp height], [temp channel], [temp error]];
  }
  temp = [self objectAtIndex:i];
  [textOut appendFormat:@"{%f, %f, %f, %d, %e}}", [temp width], [temp position], [temp height], [temp channel], [temp error]];

  [textOut writeToFile:fname atomically:NO];
  
}

	
- (void)addEntry:(id <LadderPeak>)entry
{
  [ladder addObject:entry];
  if ([entry endExtent]  > maxCenter)
    maxCenter = [entry endExtent];
}

- (void)removeEntryAt:(unsigned int)position
{
    [ladder removeObjectAtIndex:position];
}

- (void)replaceEntryAt:(unsigned int)position with:(id <LadderPeak>)peak
{
  [ladder replaceObjectAtIndex:position withObject:peak];  
}

- (void)insertEntry:(id <LadderPeak>)peak At:(unsigned int)position
{
  [ladder insertObject:peak atIndex:position];
}

- (unsigned int)locationOfEntryIdenticalTo:(id <LadderPeak>)peak
{
  return [ladder indexOfObjectIdenticalTo:peak];
}


- (NSArray *)eventsOverlappingLocation:(unsigned)loc
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned i, count;

    count = [ladder count];

    for (i = 0; i < count; i++)
        if (([[ladder objectAtIndex:i] startExtent] < loc) && ([[ladder objectAtIndex:i] endExtent] > loc))
            [array addObject:[ladder objectAtIndex:i]];
    return (NSArray *)array;
}

- (NSArray *)peaksOverlappingPeak:(id <LadderPeak>) peak
{

    NSMutableArray *array = [NSMutableArray array];
    unsigned i, count;

    count = [ladder count];

    for (i = 0; i < count; i++)
      if (([[ladder objectAtIndex:i] height] <= [peak valueAt:[(id <LadderPeak>)[ladder objectAtIndex:i] position]]) ||
          ([peak height] <= [[ladder objectAtIndex:i] valueAt:[peak position]]))
        [array addObject:[ladder objectAtIndex:i]];
    return (NSArray *)array;    
}


- (NSMutableArray *)peaksBetween:(float)loc1 and:(float)loc2
{
  NSMutableArray *array = [NSMutableArray array];
  unsigned i, count;
  float location;
  
  count = [ladder count];
/*  if (loc1 > loc2)
    {
    float swap;
    swap = loc1;
    loc1 = loc2;
    loc2 = swap;
    } */
  if (loc1 > loc2)
    return NULL;
  
  for (i = 0; i < count; i++)
    {
    location = [(id <LadderPeak>)[ladder objectAtIndex:i] position];
    if ((location > loc1) && (location < loc2))

      [array addObject:[ladder objectAtIndex:i]];
    }
    return (NSMutableArray *)array;    
}


- (id <LadderPeak>)entryAtPosition:(unsigned)pos
{
  if (pos < [ladder count])
    return [ladder objectAtIndex:pos];
  else
    return NULL;
}

- (void)sort
{
  int   i;
  
  [ladder sortUsingSelector:@selector(comparePosition:)];
  
  //recalc maxCenter
  maxCenter = 0.0;
  for(i=0; i<[ladder count]; i++) {
    if ([[ladder objectAtIndex:i] endExtent]  > maxCenter)
      maxCenter = [[ladder objectAtIndex:i] endExtent];
  }
}


- (unsigned)count
{
  return [ladder count];
}

- (float)maxExtent
{
  return maxCenter;
}

- (void)empty
{
  [ladder release];
  ladder = [[NSMutableArray arrayWithCapacity:0] retain];
  maxCenter = 0;
}

- (id <LadderPeak>)objectAtIndex:(unsigned)i
{
  return [ladder objectAtIndex:i];
}

- (NSEnumerator *)objectEnumerator
{
  return [ladder objectEnumerator];
}

- (NSEnumerator *)reverseObjectEnumerator
{
  return [ladder reverseObjectEnumerator];
}

- (void)setTrace:(Trace *)trace
{
  if (_traceData)
    [_traceData release];
  _traceData = [trace retain];
}

- (Trace *)trace
{
  return _traceData;
}


- (id)copyWithZone:(NSZone *)zone
{
    EventLadder     *dupSelf;

  dupSelf = [[EventLadder allocWithZone:zone] init];
  dupSelf->ladder = [ladder mutableCopyWithZone:zone];
  [dupSelf setTrace:_traceData];
  dupSelf->maxCenter = maxCenter;

  return dupSelf;
}

- (void)dealloc
{
  [ladder release];
  if (_traceData)
    [_traceData release];
  [super dealloc];
}

@end

