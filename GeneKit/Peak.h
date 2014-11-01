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

//#import "MGMutableFloatArray.h"
#import <Foundation/Foundation.h>

@interface Peak:NSObject
{
  NSMutableArray  *peaks;
//  unsigned start, end, center;
//  MGMutableFloatArray *signalData;

//  @private
//  float CM;
//  float VAR;
}

//+ (Peak *)peakFrom:(unsigned)_start to:(unsigned)_end center:(unsigned)_center withData:(MGMutableFloatArray *)theData;
- init;
-(id)copyWithZone:(NSZone *)zone;
-(void)dealloc;
-(void) addPosition:(int)pos;
-(int)position:(int)atPeak;
-(void)replacePosition:(int)atPeak withPos:(int)pos;
-(void)addOrigin:(int)atPeak :(NSPoint)point;
-(void) replaceOrigin:(int)atPeak :(NSPoint)point;
-(NSPoint)origin:(int)atPeak;
-(int)length:(int)atPeak;

@end

//- (unsigned)start;
//- (unsigned)end;
//- (unsigned)center;
//- (unsigned)width;
//- (float)h;
//- (float)ldiff;
//- (float)rdiff;
//- (float)centerValue;

//- (NSComparisonResult)compareTo:(Peak *)otherPeak;
//- (float)centralMoment;
//- (float)peakVariance;



@interface AlignedPeaks:NSObject
{
  NSMutableArray *alnPeakList;
}

-init;
-(void)addAlnPeak:(Peak *)peakItem;
-(int)valueAt:(int)atIndex :(int)atPeak;
-(void)replacePosition:(int)atIndex atPeak:(int)atPeak with:(int)newPos;
-(void)removeLinkedPeaksAt:(int)index;
-(NSPoint)originAt:(int)atIndex :(int)atPeak;
-(void)addOrigin:(int)atPeak :(int)atPeak :(NSPoint)origin;
-(BOOL)hasOrigin:(int)atIndex :(int)atPeak;
-(int)length;
-(id)copyWithZone:(NSZone *)zone;
-(void)dealloc;
@end
