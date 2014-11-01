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

#import <Foundation/NSArray.h>
#import "LadderPeak.h"
#import "Peak.h"
#import <GeneKit/Trace.h>

#define WidthTol 3
#define Errortol 1
#define STD_WINDOW 10
#define CUTFACTOR 2.0
#define MinWidth 3

@interface EventLadder:NSObject
{
@public
  NSMutableArray *ladder;
  Trace *_traceData;
  float maxCenter;
}

+ newLadder;
- init;
- (void)setTrace:(Trace *)trace;
- (Trace *)trace;
- (NSMutableArray *)array;
- (void)setArray:(NSMutableArray *)newArray;
- (void)addEntry:(id <LadderPeak>)entry;
- (void)addObjectsFromArray:(NSArray *)array;
- (void)removeEntryAt:(unsigned int)position;
- (void)replaceEntryAt:(unsigned int)position with:(id <LadderPeak>)peak;
- (void)insertEntry:(id <LadderPeak>)peak At:(unsigned int)position;
- (id <LadderPeak>)entryAtPosition:(unsigned)pos;
- (unsigned)count;
- (float)maxExtent;
- (void)empty;
- (void)writeToFile:(NSString *)fname;
- (id <LadderPeak>)objectAtIndex:(unsigned)i;
- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)reverseObjectEnumerator;
- (id)copyWithZone:(NSZone *)zone;
- (void)sort;
- (unsigned int)locationOfEntryIdenticalTo:(id <LadderPeak>)peak;
- (NSArray *)eventsOverlappingLocation:(unsigned)loc;
- (NSArray *)peaksOverlappingPeak:(id <LadderPeak>) peak;
- (NSMutableArray *)peaksBetween:(float)loc1 and:(float)loc2;
- (void)dealloc;

@end
