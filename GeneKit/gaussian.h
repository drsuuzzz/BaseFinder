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
#import <Foundation/NSObject.h>
#import "MGMutableFloatArray.h"
#import "LadderPeak.h"
#define WIDTH_CUTOFF 2.5


@interface Gaussian:LadderPeak <LadderPeak>
{

  @public
  float center;
	float width;
	float scale;
	float residual;
	NSString	*annotation;
}

+ (id)GaussianWithWidth:(float)width scale:(float)scale center:(float)center;
+ (id)GaussianFittedFrom:(unsigned)start to:(unsigned)end toData:(MGMutableFloatArray *)array;
- init;
-(void)dealloc;

- (float)center;
- (float)scale;
- (float)fitResidual;
- (void)setCenter:(float)val;
- (void)setScale:(float)val;
- (float)area;
- (NSString *)annotation;
- (void)setAnnotation:(NSString *)aString;

//- (void)subtractFromData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff;
//- (void)addToData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff;
- (id)copyWithZone:(NSZone *)zone;



@end