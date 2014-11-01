/* "$Id: WidthObj.h,v 1.2 2006/11/21 19:39:32 smvasa Exp $" */
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

#import <Foundation/Foundation.h>
#define POLYLEVEL	3
#import <GeneKit/Sequence.h>
#import <GeneKit/Trace.h>

@interface WidthObj:NSObject
{
  Sequence *thebaseList;
  Trace    * thedataList;
  float   weight;
  float   lowConfThresh;
  id      distributor;

  float   *(*minPoly), *(*maxPoly);
  float   sizePoly[POLYLEVEL];
  float   *(fitpoints[3]);
  float   polycoeffecients[POLYLEVEL];
}


- initwithWeight:(float)Weight minConfidence:(float)conf;
- (void)setupConfidences:(Sequence *)baseList :(Trace *)Data;
- (void)setWeight:(float)Weight;
- (float)confWeight;
- (float)returnWeightedConfidence:(int)baseNumber;
- (float)returnConfidence:(int)baseNumber;
- (int) numberBasesAt:(int)baseNumber;
- (float) returnDataConfidence:(int)location :(int)channel;
- (float) expectedPeakWidth:(int)location :(int)channel;
- (float) peakWidth:(int)location :(int)channel;
- (int)baseWidth:(Trace *)Data :(int)channel :(int)location;
-(float)averagePeakWidth:(Trace *)Data :(Sequence *)baseList;
- (float)widthAt:(int)baseNumber;

@end
