/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/* LadderPeak.h created by giddings on Wed 22-Apr-1998 */

#import <Foundation/Foundation.h>
#import "MGMutableFloatArray.h"

//The following protocol is the one that all peaks as part of an EventLadder
//should follow.
@protocol LadderPeak <NSObject>
- (void)setHeight:(float)hgt;
- (void)setWidth:(float)wdth;
- (void)setPosition:(float)pos;
- (void)setSkew:(float)skew;
- (float)width;
- (float)position;
- (float)height;
- (float)skew;
- (float)error;
- (float)area;
- (float)startExtent;
- (float)endExtent;
- (float)valueAt:(float)x;
- (int)channel;
- (void)setChannel:(int)chan;
- (void)subtractFromData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff;
- (void)addToData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff;
@end


@interface LadderPeak : NSObject
{
  @public
  int channel;  
}

- (NSComparisonResult)comparePosition:(id <LadderPeak>)obj;
- (NSComparisonResult)compareSize:(id <LadderPeak>)obj;
- (id)copyWithZone:(NSZone *)zone;
- (int)channel;
- (void)setChannel:(int)chan;


@end
