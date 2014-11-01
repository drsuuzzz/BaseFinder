/* "$Id: ToolBaseCalling.h,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import <BaseFinderKit/GenericTool.h>
//#import "SeqList.h"


@interface ToolBaseCalling:GenericTool
{
//  ArrayStorage         *localBaseList;
//  SeqList              *localDataList;

  Sequence         *localBaseList;
  Trace              *localDataList;


  @public
  float    weights[5];
  float    finalout, callquit, throwout;
  int      maxit, highorder;
  float    bwidthtol, ewidthtol, spacetol;
  BOOL     useBIS;
  int      BISlane;
}

//- (void)convertDataToInternal;
//- (void)convertInternalToData;
- apply;
- (void)returnCallingThresholds:(float *)CallQuit :(float *)FinalOut :(float *)ThrowOut;
- (void)returnObjectWeights:(float **)Weights;
- (void)returnCallingInts:(int *)HighOrder :(int *)MaxIt;
- returnTolerances:(float *) bwtol :(float *) ewtol :(float *)sptol;

- (BOOL)modifiesData;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

- copyWithZone:(NSZone *)zone;
- (void)dealloc;

@end
