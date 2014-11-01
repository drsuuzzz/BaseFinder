/* "$Id: ToolDeletePrimer2Ctrl.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "ToolDeletePrimer2Ctrl.h"

/****
* April 5, 1994: Jessica Hayden author
* Second generation primer peak deletion tool.  It does not require normalized data
* nor does it require the user to enter parameters.  It does allow two different
* types of primer patterns to be identified.  Most situations, there is a primer
* peak in all detector channels, but it can also work if the primer peak only occurs
* in one of the channels.
*
* The primer peak is defined as the largest magnitude peak in the data stream (or each
* channel).  After finding this peak (or the latest one if one is expected in all
* channels), the algorithm find the first minima in each channel following this peak.
* the furthest minima into the run (from all the channels) is used as the point where
* the primer peak ends (and thus is the place to delete up to).
*
*****/
/*****
* July 19, 1994 Mike Koehrsen
* Split ToolDeletePrimer2 class into ToolDeletePrimer2 and ToolDeletePrimer2Ctrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolDeletePrimer2Ctrl

- init
{
  DeletePrimer2_t *procStruct = (DeletePrimer2_t *)dataProcessor;

  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"NO", @"DelPrimerOnePeak",
    @"YES", @"DelPrimer_performSignalCutoff",
    nil];
  NSUserDefaults   *myDefaults;

  [super init];
  myDefaults = [NSUserDefaults standardUserDefaults];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
  procStruct->useOnePeak = [myDefaults boolForKey:@"DelPrimerOnePeak"];
  procStruct->performSignalCutoff = [myDefaults boolForKey:@"DelPrimer_performSignalCutoff"];
  return self;
}

- (void)getParams
{
  DeletePrimer2_t *procStruct = (DeletePrimer2_t *)dataProcessor;

  [super getParams];

  if([wherePeakOccursID selectedRow] == 1)
    procStruct->useOnePeak = TRUE;
  else
    procStruct->useOnePeak = FALSE;
  [[NSUserDefaults standardUserDefaults] setBool:procStruct->useOnePeak
                                          forKey:@"DelPrimerOnePeak"];

  procStruct->performSignalCutoff = [performSignalCutoffID state];
  [[NSUserDefaults standardUserDefaults] setBool:procStruct->performSignalCutoff
                                          forKey:@"DelPrimer_performSignalCutoff"];
  //[dataProcessor findPrimerPeak:[[toolMaster sequenceEditor] pointStorageID]];
  [self displayParams];
}

- (void)displayParams
{
  DeletePrimer2_t *procStruct = (DeletePrimer2_t *)dataProcessor;

  [super displayParams];

  if(procStruct->useOnePeak) [wherePeakOccursID selectCellAtRow:1 column:0];
  else [wherePeakOccursID selectCellAtRow:0 column:0];
  [peakID setIntValue:procStruct->peakPos];
  [valleyID setIntValue:procStruct->valleyPos];
  [signalCutoffID setStringValue:
    [NSString stringWithFormat:@"%d / %d",procStruct->signalCutoff, procStruct->dataLength]];
  [performSignalCutoffID setState:procStruct->performSignalCutoff];
}

- (void)precalcPrimerPeak:sender
{
  if ([toolMaster pointStorageID]!=nil) {
    [self getParams];
    [dataProcessor findPrimerPeak:[toolMaster pointStorageID]];
    [self displayParams];
    [self calcSignalStrength];
  }
}

- (void)calcSignalStrength
{
  DeletePrimer2_t   *procStruct = (DeletePrimer2_t *)dataProcessor;
  int               valley;
  Trace             *dataID = [toolMaster pointStorageID];
  int               i, numChannels=[dataID numChannels];
  float             *pointArray, total;
  int               chan, pointCount;

  valley = procStruct->valleyPos;
  if(valley < 0) valley=0;

  for (chan=0; chan<numChannels; chan++) {
    pointArray = [dataID sampleArrayAtChannel:chan];
    pointCount = [dataID length];
    total = 0.0;
    for(i=valley; i<pointCount; i++) {
      total += pointArray[i];
    }
    total *= 4.0;
    [[signalID cellAtRow:0 column:chan] setFloatValue:(total / (pointCount - valley))];
  }
}

@end
