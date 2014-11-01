 
/* "$Id: FittedBaselineAdjustCtrl.m,v 1.2 2006/07/18 18:23:05 svasa Exp $" */
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

#import "FittedBaselineAdjustCtrl.h"
#import "FittedBaselineAdjust.h"


/******
* April 26, 1994 Jessica: Fixed bug: this tool would work fine on intel machines
* but would hang indefinately on motorla machines.  The algorithm would hang durring
* the iteration stage and keep adding the same new point forever.  The problem came from
* the fact that in findBaselineMinima, I was checking the interpolation inclusive of the
* end point, and there was a precision difference between the interpolated y at the end
* and the actual y at the end, but only on the motorola machine.  So the algorithm would
* keep adding a new point at the end position and keep finding that it was still negative.
* I suspect the motorola complier differentiates between floats and double, but the intel 
* compiler only uses doubles (so there wasn't this precision error on the intel code).  
* The bug was fixed by recoding the algorithms so that each segment was checked up to
* but not inclusive of the next inflection point.
******/
/*****
* July 19, 1994 Mike Koehrsen
* Split FittedBaselineAdjust class into FittedBaselineAdjust and FittedBaselineAdjustCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/


@implementation FittedBaselineAdjustCtrl

- init
{
  FittedBaselineAdjust *procStruct = dataProcessor;
  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"100", @"BaselineWindow",
    nil];
  NSUserDefaults   *myDefaults;

  [super init];
  myDefaults = [NSUserDefaults standardUserDefaults];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  procStruct->windowWidth = atoi([[myDefaults objectForKey:@"BaselineWindow"] cString]);
  return self;
}

- (void)getParams
{
  FittedBaselineAdjust *procStruct = dataProcessor;

  [super getParams];

  procStruct->windowWidth = [windowWidthID intValue];
  if(procStruct->windowWidth < 2) procStruct->windowWidth=2;
  [windowWidthID setIntValue:procStruct->windowWidth];

  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",procStruct->windowWidth]
                                            forKey:@"BaselineWindow"];
}

- (void)displayParams
{
  FittedBaselineAdjust *procStruct = dataProcessor;

  [super displayParams];

  [windowWidthID setIntValue:procStruct->windowWidth];
}


@end
