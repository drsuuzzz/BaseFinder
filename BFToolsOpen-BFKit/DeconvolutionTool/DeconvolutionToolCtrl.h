
/* "$Id: DeconvolutionToolCtrl.h,v 1.3 2008/04/15 20:51:04 smvasa Exp $" */
/***********************************************************

Copyright (c) 1994-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import <BaseFinderKit/ResourceToolCtrl.h>

@interface DeconvolutionToolCtrl:ResourceToolCtrl
{
  IBOutlet NSBox  *accessoryView;

  id		displayView;
  id		channelID;
  id		constID;
  id		numIterationsID;
  id		alphaID;
  int		curChannel, newMethod;

  id		newMethodView;
  id		newMethodID;

//  id		slidingModeView;
//  id		slideChannelID;

  id		shiftData;
	id		previousView;
}

- (NSString *)resourceSubdir;
- (void)appWillInit;
- setToDefault;
- (void)displayParams;
- (void)getParams;
- (void)simData:sender;

- (void)startNew;
- (void)finishNew;
- (void)switchFunctionDisplay:sender;
- (void)showConstants;

- (void)newMethodOK:sender;
- (void)setViewToEnter;
- (void)setViewToDisplay;

- (float)polyFitFunction:(float)x :(int)np;
- (BOOL)fitSigmas:(float *)coeffs;

//- (void)mouseEvent:(range)theRange;
//- (void)switchSlideChannel:sender;
//- (void)fitEquation;

@end