/* "$Id: ToolMatrix2Ctrl.m,v 1.2 2006/07/09 20:35:15 svasa Exp $" */
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

#import "ToolMatrix2Ctrl.h"
#import "ToolMatrix2.h"

#define WINDOW	15
typedef struct {
  double   rawData[4*WINDOW];    /* the four wavelength florecence channels */
  int      pos;                  /* index in the array where raw data taken from */
  int      destChannel;          /* channel number where this base signal will go */
  char     baseType;             /* "c a g t or N" */
} peakStruct;

/*****
* April 5, 1994 Jessica Hayden
* Second Generation matrix transformation routines.  This tool is designed to work
* properly on unnormalized data, be able to matrix any number dye data (current data size
* limited to 4x4, but routines can be easily expanded to work with larger dataArrays), and
* to preserve relative dye signal intensity across the transformation.
*
* The new routines are based on inverse matrix routines from "Applied Numerical Linear
* Algebra" by William W. Hager.  They do an LU factorization of the matrix and find the
* inverse by solving Ax=b for x for subsequent columns of the identity matrix.  See
* MatrixRoutines.m for longer description (or Hager).
*
* June 8, 1994 Jessica Hayden
* To create a new matrix, this tool sends data to the 3D/4D scatter plot program instead
* of the old way where the user is asked to pick peaks.
*****/

@implementation ToolMatrix2Ctrl

- (NSString *)resourceSubdir
{
  return @"Matrixes";
}

- (void)appWillInit
{
  /* called from ToolMaster */
  [super appWillInit];
  [sendScatterID setEnabled:NO];
  optionsView = [[altView contentView] retain];
  [newView retain];
}

- setToDefault
{
  ToolMatrix2 *procStruct = (ToolMatrix2 *)dataProcessor;
  int i, j;

  for (i=0;i<4;i++)
    for (j=0;j<4;j++) {
      if (i==j)
        procStruct->currentMatrix[i][j]=1.0;
      else
        procStruct->currentMatrix[i][j]=0.0;
    }
      return [super setToDefault];
}

- (void)displayParams
{
  int i,j;
  ToolMatrix2 *procStruct = (ToolMatrix2 *)dataProcessor;

  for (i=0;i<4;i++)
    for (j=0;j<4;j++)
      [[matrixID cellAtRow:i column:j] setFloatValue:procStruct->currentMatrix[i][j]];

  [removeNegativeID setState:procStruct->removeNegative];
  [normalizeMatrixID setState:procStruct->normalizeMatrix];
  [super displayParams];
}

- (void)getParams
{
  int i,j;
  ToolMatrix2 *procStruct = (ToolMatrix2 *)dataProcessor;

  for (i=0;i<4;i++)
    for (j=0;j<4;j++)
      procStruct->currentMatrix[i][j] = [[matrixID cellAtRow:i column:j] floatValue];

  procStruct->removeNegative = [removeNegativeID state];
  procStruct->normalizeMatrix = [normalizeMatrixID state];
  [super getParams];
}

- (void)switchMatrixNormalize:sender
{
  ToolMatrix2 *procStruct = (ToolMatrix2 *)dataProcessor;

  procStruct->normalizeMatrix = [normalizeMatrixID state];
  [self selectResource:self];  //reloads matrix from resource file
}

- (void)inspectorDidDisplay
{
  if ([toolMaster pointStorageID] == nil) return;
  //[toolMaster registerForEventNotification:self];
  [sendScatterID setEnabled:NO];
}

- (BOOL)inspectorWillUndisplay
{
  if([super inspectorWillUndisplay]) {
    [toolMaster deregisterForEventNotification:self];
    return YES;
  }
  return NO;
}

- (void)sendtoScatterPlotter:sender
{
  id        pboard;
  BOOL      rtn;
  NSArray   *pbTypes = [NSArray arrayWithObjects:NSTabularTextPboardType, nil];

  pboard = [NSPasteboard generalPasteboard];
  [pboard declareTypes:pbTypes
                 owner:NULL];

  rtn = [toolMaster writeSelectionToPasteboard:pboard types:pbTypes];
  if(rtn) printf("successfully wrote PB\n");
  else printf("fail in PB write\n");

  rtn = NSPerformService(@"MatrixFinder/Transfer Data", pboard);
  if(rtn) printf("success send service\n");
  else printf("failed service\n");
}

/****
*
* Single peak picking matrix creation routines
*
*****/

- (void)pickBase:sender
{
  [self changeInstruction];
}

- (int)pickingBase
{
  if (!makingNew)
    return -1;
  else
    return [basePickID selectedColumn];
}

- (void)changeInstruction
{
  switch([self pickingBase]) {
    case -1:	/* clear */
      [instructionDisplay setTextColor:[NSColor lightGrayColor]];
      break;
    case 0:	
      [instructionDisplay setStringValue:@"Please Click on a '1' Peak"];
      [instructionDisplay setTextColor:[NSColor blackColor]];
      break;
    case 1:
      [instructionDisplay setStringValue:@"Please Click on an '2' Peak"];
      [instructionDisplay setTextColor:[NSColor blackColor]];
      break;
    case 2:
      [instructionDisplay setStringValue:@"Please Click on a '3' Peak"];
      [instructionDisplay setTextColor:[NSColor blackColor]];
      break;
    case 3:
      [instructionDisplay setStringValue:@"Please Click on a '4' Peak"];
      [instructionDisplay setTextColor:[NSColor blackColor]];
      break;
  }
}

- (void)startNew
{	
  [toolMaster registerForEventNotification:self];
  [self changeInstruction];
  [altView setContentView:newView];
  [altView display];
  
  //[basePickID setEnabled:YES];
  [self setToDefault];
}

- (void)finishNew
{	
  [toolMaster deregisterForEventNotification:self];
  [self changeInstruction];

  [altView setContentView:optionsView];
  [altView display];
  //[basePickID setEnabled:NO];
}

- (void)cancelNew
{
  [super cancelNew];

  [instructionDisplay setTextColor:[NSColor lightGrayColor]];
  [altView setContentView:optionsView];
  [altView display];
}

#ifdef OLDCODE
- (void)mouseEvent:(range)theRange
{	
  /* called from ToolMaster after a peak is clicked on.	*/
  if((theRange.end - theRange.start) <= 1) {
    [sendScatterID setEnabled:NO];
  }
  else {
    [sendScatterID setEnabled:YES];
  }
}
#endif


- (void)mouseEvent:(range)theRange
{
  Trace          *traceObject;
  int            j, channel;
  int            thePoint = theRange.start;
  int            start,end, count, numChannels;
  float          minVal,  *dataArray;
  double         peakVal;
  peakStruct     tempPeak;
  ToolMatrix2      *procStruct = (ToolMatrix2 *)dataProcessor;

  /* called from ToolMaster after a peak is clicked on.
    Find local baseline for each channel and then adjust returned peak level
    relative to that local baseline.  Find by scanning local region for minimum
    value (right now hard coded at 250 elements on either side, but should
           vary depending on sample rate, and speed of run).
    */
  /* first determine the local baseline value for each channel and subtract it */
  
  traceObject = [toolMaster pointStorageID];
  count = [traceObject length];
  numChannels = [traceObject numChannels];
  for(channel=0; channel<numChannels; channel++) {
    dataArray = [traceObject sampleArrayAtChannel:channel];
    start = thePoint-250;
    end	= thePoint+250;
    if(start<0) start=0;
    if(end>count) end=count;
    minVal = dataArray[start];
    for(j=start;j<end;j++) {
      if(minVal > dataArray[j]) minVal = dataArray[j];
    }
    peakVal = (double)dataArray[thePoint];
    peakVal -= (double)minVal;
    /** peakVal = *(float*)[traceObject elementAt:thePoint] - minVal; **/
    /* for now no averaging, just use last peak selected for the final matrix */
    tempPeak.rawData[channel] = peakVal;
  }
  tempPeak.pos = thePoint;
  tempPeak.destChannel = [self pickingBase];

  /* normalize peak to a unit vector */
  peakVal = 0.0;
  for(channel=0; channel<4; channel++)
    peakVal += tempPeak.rawData[channel] * tempPeak.rawData[channel];
  peakVal = sqrt(peakVal);
  for(channel=0; channel<4; channel++)
    tempPeak.rawData[channel] /= peakVal;

  /* now send peak to display */
  for(channel=0; channel<4; channel++) {
    peakVal = tempPeak.rawData[channel];
    procStruct->currentMatrix[channel][[self pickingBase]] = (float)peakVal;
    [[matrixID cellAtRow:channel column:[self pickingBase]] setFloatValue:(float)peakVal];
  }
}

@end
