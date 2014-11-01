 
/* "$Id: GaussFitTool.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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


#import "GaussFitTool.h"
#import "GaussianView.h"
#import <GeneKit/NumericalObject.h>

#include <GeneKit/ghist.h>
#include <GeneKit/histlib.h>

@implementation GaussFitTool

- init
{
  [super init];
  return self;
}

- (NSString *)toolName
{
  return @"Gaussian Peak Fitting-1.0.1";
}

- (BOOL)isOnlyAnInterface;
{
  return YES;
}

@end

@implementation GaussFitToolCtrl

- init
{
  [super init];
  ngauss = 1;
  gaussData = NULL;
  firstLoc = lastLoc = 0;
  selectedChannel = 0;
  numPoints = 0;
  scale = mean = sigma = 0.0;
  return self;
}

- (void)appWillInit
{
  [channelSelID setAllowsEmptySelection:NO];
  //[toolMaster registerForEventNotification:self];
  [super appWillInit];
}

- (void)resetSelChannels
{
  // superclass method enables all channels present in seqEdit
  // this tool uses the SelChannels differently.  It is a radio
  // hence only one can be selected at a time.  Override method
  // to do nothing
  return;
}

- (void)getParams
{
  [super getParams];
  if (channelSelID == nil) return;
  selectedChannel = [channelSelID selectedColumn]  + 4*[channelSelID selectedRow];
}

- (void)displayParams
{
  int    numChannels, index;
  BOOL   dataValid=NO;

  dataValid = !([toolMaster pointStorageID] == nil);

  if(!dataValid)
    numChannels=0;
  else
    numChannels = [toolMaster numberChannels];
  
  if (channelSelID == nil) return;
  for(index=0;index<8;index++) {
    if(index<numChannels)
      [[channelSelID cellAtRow:index/4 column:index%4] setEnabled:YES];
    else
      [[channelSelID cellAtRow:index/4 column:index%4] setEnabled:NO];
  }

  //[channelSelID selectCellAtRow:0 column:1];
  //[[channelSelID cellAtRow:0 column:1] setState:YES];
  [channelSelID selectCellAtRow:selectedChannel/4 column:selectedChannel%4];
  [channelSelID display];

  if(!dataValid) return;
  
  [[gaussParamsID cellAtRow:0 column:0] setFloatValue:scale];
  [[gaussParamsID cellAtRow:1 column:0] setFloatValue:firstLoc + mean +
    [[toolMaster pointStorageID] deleteOffset]];
  [[gaussParamsID cellAtRow:2 column:0] setFloatValue:sigma];
}

- (void)inspectorDidDisplay
{
  if ([toolMaster pointStorageID] == nil) return;
  [toolMaster registerForEventNotification:self];
}

- (BOOL)inspectorWillUndisplay
{
  if([super inspectorWillUndisplay]) {
    [toolMaster deregisterForEventNotification:self];
    return YES;
  }
  return NO;
}

- (void)mouseEvent:(range)theRange
{
  firstLoc = theRange.start;
  lastLoc = theRange.end;

  [self updateView:self];
  [self displayParams];
}

- (void)keyEvent:(NSEvent*)keyEvent
{
  NSString       *charString;
  unichar        thischar; //really an unsigned short

  charString = [keyEvent charactersIgnoringModifiers];
  if([charString length] > 0) {
    thischar = [charString characterAtIndex:0];
    //fprintf(stderr, "GaussTool keyevent 0x%X\n", thischar);
    if (thischar==103) { // 'g' character
      [self show];
      [self fitGaussian:self];
    }
  }
}

- (void)clearPeakFile:sender
{
  NSString   *path = [NSHomeDirectory() stringByAppendingPathComponent:@"gaussPeaks"];
  FILE       *peakFile;
  
  peakFile = fopen([path fileSystemRepresentation], "w");
  if(peakFile != NULL)  {
    fprintf(peakFile, "\n");
    fclose(peakFile);
  }
}

- prepareGaussData
{
  int      i;
  Trace    *pointsID;
  float    *dataArray, min;
  NumericalObject  *numObj=[NumericalObject new];

  [self getParams];
  numPoints = 0;
  pointsID = [toolMaster pointStorageID];
  if(pointsID == nil) return nil;
  dataArray = [pointsID sampleArrayAtChannel:selectedChannel];	
  numPoints = lastLoc-firstLoc + 1;
  min = [numObj minVal:&(dataArray[firstLoc]) numPoints:numPoints];
  //if(gaussData != NULL) free(gaussData);
  gaussData = vector(1,numPoints*2);
  for(i=1;i<=numPoints;i++)
    gaussData[i] = dataArray[firstLoc + i -1] - min;
  [numObj release];
  return self;
}

- (void)updateView:sender
{
  //int    i;
		
  selectedChannel = [channelSelID selectedColumn]  + 4*[channelSelID selectedRow];
  if(firstLoc == lastLoc) return;

  mean = sigma = scale = 0.0;
  [self prepareGaussData];
  printf("GaussFitViewer channel%d  firstLoc=%d  lastLoc=%d\n", selectedChannel,firstLoc,lastLoc);
  //for(i=1; i<=numPoints; i++)
  //  printf("  %2d  %f\n", i, gaussData[i]);

  [myGaussView setFittedMu:mean sigma:sigma scale:scale];
  [myGaussView setData:gaussData :numPoints];
}

- (void)fitGaussian:sender
{	
  int      i;
  float    *x, hival, loval;

  printf("GaussFit firstLoc=%d  lastLoc=%d\n",firstLoc, lastLoc);
  if(lastLoc - firstLoc < 2) {
    printf(" need minimum of 3 points\n");
    return;
  }
  
  x  = vector(1,numPoints);	/* array of x positions for each point */
  for(i=1;i<= numPoints;i++) x[i] = i;

  [self prepareGaussData];

  NS_DURING
    /*** the gaussian fitting section ***/
    stats(gaussData,numPoints,&mean,&sigma,&hival,&loval);
    printf("  mean=%f  hival=%f  loval=%f\n", mean, hival, loval);

    scale=hival;
    sigma=7.0;
    specialgausfit(x,gaussData,numPoints,&scale,&mean,&sigma);
    printf("  mean=%f  sigma=%f  scale=%f\n", firstLoc + mean +
           [[toolMaster pointStorageID] deleteOffset], sigma, scale);

    //free_vector(x, 1, numPoints);
    //free_vector(data, 1, numPoints);
  NS_HANDLER
    NSLog(@"error during gaussian fitting\n%@",[localException description]);
    NSRunAlertPanel(@"Error loading script", @"%@", @"OK", nil, nil, localException);
  NS_ENDHANDLER

  [self displayParams];
  [myGaussView setFittedMu:mean sigma:sigma scale:scale];
  [myGaussView setData:gaussData :numPoints];

  {
    NSString   *path = [NSHomeDirectory() stringByAppendingPathComponent:@"gaussPeaks"];
    FILE       *peakFile;

    fprintf(stderr,"about to write peaks\n");
    peakFile = fopen([path cString], "a");
    if(peakFile != NULL) {
      fprintf(peakFile, "%f  %f\n",
              mean+firstLoc+[[toolMaster pointStorageID] deleteOffset], sigma);
      fflush(peakFile);
      fclose(peakFile);
    }
  }
}


@end
