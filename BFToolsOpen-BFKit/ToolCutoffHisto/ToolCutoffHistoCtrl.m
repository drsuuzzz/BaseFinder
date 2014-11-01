/* "$Id: ToolCutoffHistoCtrl.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

/* Generated by Interface Builder */

#import "ToolCutoffHistoCtrl.h"
#import "ToolCutoffHisto.h"
#import <GeneKit/HistogramView.h>

/*****
* July 19, 1994 Mike Koehrsen
* Split ToolCutoffHisto class into ToolCutoffHisto and ToolCutoffHistoCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolCutoffHistoCtrl

- init
{
  ToolCutoffHisto *procStruct = (ToolCutoffHisto *)dataProcessor;
  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"2.0", @"HISTcutoff",
    @"3", @"HistLoUp",
    @"0", @"HistCombined",
    nil];
  NSUserDefaults   *myDefaults;

  [super init];
  myDefaults = [NSUserDefaults standardUserDefaults];
  [myDefaults registerDefaults:defaultsDict];

  procStruct->threshold = (float)atof([[myDefaults objectForKey:@"HISTcutoff"] cString]);
  procStruct->lowUP = (int)atoi([[myDefaults objectForKey:@"HistLoUp"] cString]);
  procStruct->combinedData = (BOOL)atoi([[myDefaults objectForKey:@"HistCombined"] cString]);
  return self;
}

- (void)getParams
{
  ToolCutoffHisto *procStruct = (ToolCutoffHisto *)dataProcessor;
  char 	temp[255];

  procStruct->threshold = [cutoffFormID floatValue];
  if(procStruct->threshold<0) procStruct->threshold=0.0;
  if(procStruct->threshold>100.0) procStruct->threshold=100.0;

  procStruct->lowUP=0;
  procStruct->lowUP += [[upperLowerID cellAtRow:0 column:0] intValue]*2;
  procStruct->lowUP += [[upperLowerID cellAtRow:1 column:0] intValue];

  sprintf(temp, "%f", procStruct->threshold);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:temp] forKey:@"HISTcutoff"];

  sprintf(temp, "%d", procStruct->lowUP);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:temp] forKey:@"HistLoUp"];

  procStruct->combinedData = [combinedID state];
  sprintf(temp, "%d", procStruct->combinedData);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:temp] forKey:@"HistCombined"];

  [super getParams];
}

- (void)displayParams
{
  ToolCutoffHisto *procStruct = (ToolCutoffHisto *)dataProcessor;

  [cutoffFormID setFloatValue:procStruct->threshold];

  [[upperLowerID cellAtRow:0 column:0] setIntValue:procStruct->lowUP&2];
  [[upperLowerID cellAtRow:1 column:0] setIntValue:procStruct->lowUP&1];

  [combinedID setState:procStruct->combinedData];
  [super displayParams];
}

- (void)inspectorDidDisplay
{
  Trace    *thisData;
  int      channel;
  NSColor  *tempColor;

  if([toolMaster pointStorageID] == nil) return;

  thisData=[toolMaster pointStorageID];
  for(channel=0; channel<[thisData numChannels]; channel++) {
    tempColor = [[toolMaster colorForChannel:channel] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [histViewID setColor:tempColor forChannel:channel];
    [bigHistViewID setColor:tempColor forChannel:channel];
  }
  [histViewID setData:thisData];
  [bigHistViewID setData:thisData];
  //[bigHistViewID addHorizScale];
}

@end

