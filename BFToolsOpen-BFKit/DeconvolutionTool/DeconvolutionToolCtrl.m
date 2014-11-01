
/* "$Id: DeconvolutionToolCtrl.m,v 1.2 2008/04/15 20:51:04 smvasa Exp $" */
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
#import "DeconvolutionToolCtrl.h"
#import "DeconvolutionTool.h"
#import <GeneKit/NumericalObject.h>
#import <string.h>
#import <stdio.h>
#include <sys/types.h>
#include <time.h>
#import "SpreadFunc1.h"

/*****
* Oct 29, 1998 Jessica Severin
* Split into separate files for PDO.
*****/

@implementation DeconvolutionToolCtrl

- init
{	
  DeconvolutionTool   *procStruct;
  NSUserDefaults      *myDefaults;
  NSDictionary        *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"25", @"Deconvolve-numIter",
    @"0.25", @"Deconvolve-alpha",
    nil];

  [super init];
  myDefaults = [NSUserDefaults standardUserDefaults];
  [myDefaults registerDefaults:defaultsDict];
  [myDefaults synchronize];

  procStruct = dataProcessor;

  procStruct->numIterations = (int)atoi([[myDefaults objectForKey:@"Deconvolve-numIter"] cString]);
  procStruct->alpha = (float)atof([[myDefaults objectForKey:@"Deconvolve-alpha"] cString]);
  return self;
}

- (NSString *)resourceSubdir
{
  return @"DeconvolutionFunctions";
}

- (void)appWillInit
{
  /* called from ToolMaster */
  [super appWillInit];
  curChannel = 0;  // C base channel
  shiftData = NULL;

  [[displayView contentView] retain];
  [[newMethodView contentView] retain];
//  [[slidingModeView contentView] retain];
  
  [accessoryView setContentView:[displayView contentView]];
	previousView=displayView;
}

- setToDefault
{
  DeconvolutionTool *procStruct = dataProcessor;

  if(procStruct->spreadFunctionID) [procStruct->spreadFunctionID release];
  procStruct->spreadFunctionID = [[SpreadFunc1 alloc] init];
  return [super setToDefault];
}

- (void)displayParams
{
  DeconvolutionTool *procStruct = dataProcessor;	

  [self showConstants];

  [numIterationsID setIntValue:procStruct->numIterations];
  [alphaID setFloatValue:procStruct->alpha];
  [super displayParams];
}

- (void)getParams
{
  DeconvolutionTool   *procStruct = dataProcessor;
  NSUserDefaults      *myDefaults=[NSUserDefaults standardUserDefaults];
  char                tempStr[255];

  [super getParams];
  procStruct->numIterations = [numIterationsID intValue];
  procStruct->alpha = [alphaID floatValue];

  sprintf(tempStr, "%d", procStruct->numIterations);
  [myDefaults setObject:[NSString stringWithCString:tempStr] forKey:@"Deconvolve-numIter"];

  sprintf(tempStr, "%f", procStruct->alpha);
  [myDefaults setObject:[NSString stringWithCString:tempStr] forKey:@"Deconvolve-alpha"];

  [myDefaults synchronize];
  [self displayParams];
}

- (void)simData:sender;
{
  [dataProcessor createSimData];
}

- (void)inspectorDidDisplay
{
  if ([toolMaster pointStorageID] == nil) return;
  [toolMaster registerForEventNotification:self];
  [self showConstants];
}

- (BOOL)inspectorWillUndisplay
{
  if([super inspectorWillUndisplay]) {
    [toolMaster deregisterForEventNotification:self];
    return YES;
  }
  return NO;
}


- (void)setViewToEnter
{
  int		i;
  float coeff[3];
  //DeconvolutionTool_t *procStruct = (DeconvolutionTool_t *)dataProcessor;
  //id		funcID;

  //funcID = procStruct->spreadFunctionID;
  //if(funcID != NULL) [funcID free];
  //funcID = [[SpreadFunc1 alloc] init];
  //procStruct->spreadFunctionID = funcID;

  for(i=0; i<3; i++) {
    [[constID cellAtRow:i column:0] setBezeled:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor whiteColor]];
    [[constID cellAtRow:i column:0] setSelectable:YES];
    [[constID cellAtRow:i column:0] setEditable:YES];
  }
  if ((newMethod == 2) && [self fitSigmas:coeff]) {  // fit polynomial to Gaussian peaks data
    for (i = 0; i < 3; i++)
      [[constID cellAtRow:i column:0] setDoubleValue:(double)(coeff[i])];
  }
}

- (void)setViewToDisplay
{
  int		i;

  for(i=0; i<3; i++) {
    [[constID cellAtRow:i column:0] setBordered:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor lightGrayColor]];
    [[constID cellAtRow:i column:0] setEditable:NO];
    [[constID cellAtRow:i column:0] setSelectable:YES];
  }
}

- (void)startNew
{
  newMethod = 0; //none
	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]];
  [accessoryView setContentView:[newMethodView contentView]];
  [accessoryView display];
	previousView=newMethodView;
}

- (void)finishNew
{
  //int                i, j;
  //FILE               *fp;
  //char               filename[256];
  //id                 dataChannel;
  //shiftElement_t     *tempShift;

  [self switchFunctionDisplay:self];
  [self setViewToDisplay];
	if (newMethod != 1) {
		[previousView setContentView:[accessoryView contentView]];
		[accessoryView setContentView:[displayView contentView]];	
		[accessoryView display];
		previousView = displayView;		
	}
	newMethod = 0;
}

- (void)cancelNew
{
  newMethod = 0;
  [toolMaster deregisterForEventNotification:self];
  [self setViewToDisplay];
	[previousView setContentView:[accessoryView contentView]];
  [accessoryView setContentView:[displayView contentView]];
  [accessoryView display];
	previousView = displayView;
  [super cancelNew];
}

- (void)newMethodOK:sender
{
  DeconvolutionTool  *procStruct = dataProcessor;
  id		     funcID;
  //int		i;

  funcID = procStruct->spreadFunctionID;
  if(funcID != NULL) [funcID release];
  funcID = [[SpreadFunc1 alloc] init];
  procStruct->spreadFunctionID = funcID;

  newMethod = [newMethodID selectedRow]+1;  //1=by hand, 2=by polynomial fitting
  [self setViewToEnter];
	[previousView setContentView:[accessoryView contentView]];
  [accessoryView setContentView:[displayView contentView]];
	previousView = displayView;
  [accessoryView display];
}

- (void)switchFunctionDisplay:sender
{
  DeconvolutionTool   *procStruct = dataProcessor;
  id                  funcID;
  int                 tempChannel, i;
  double              tval;

  tempChannel = [channelID selectedColumn];
  if(makingNew) {
    // get values from fields for last channels
    funcID = procStruct->spreadFunctionID;
    for(i=0; i<3; i++) {
      tval = [[constID cellAtRow:i column:0] doubleValue];
      [funcID setConstValue:i value:tval];
    }
  }
  curChannel = tempChannel;
  [self showConstants];
}

- (void)showConstants
{
  DeconvolutionTool  *procStruct = dataProcessor;
  id		     funcID;
  int		     i;
  NSCell             *tempCell;

  if(dataProcessor == nil) return;
  funcID = procStruct->spreadFunctionID;
  if(funcID == nil) return;
  for(i=0; i<3; i++) {
    tempCell = [constID cellAtRow:i column:0];
    [tempCell setEntryType:NSDoubleType];
    [tempCell setFloatingPointFormat:YES left:1 right:20];
    [tempCell setDoubleValue:[funcID constValue:i]];
  }
}

- (float)polyFitFunction:(float)x :(int)np
{
  //for the NumericalObject version of myfit
  return pow(x, (np));

}

- (BOOL)fitSigmas:(float *)coeffs
// assume: "float coeffs[3]" -- coeffs contains params for fitted polynomial
{
  const int        maxPoints = 1000;          // limit on # (x, y) pairs
  float            arrayX[maxPoints];         // x values, for numObj
  float            arrayY[maxPoints];         // y values, for numObj
  float            sig[maxPoints];            // relative weight (significance)
  const int        numCoeff=3;
  float            currentX, currentY;
  int              numPoints = 0;             // number of data pairs (x, y)
  int              result;
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  NSString *gaussPeaksFile;
  NSString *dataString;
  NSScanner *theScanner;
  BOOL scanError = NO;
  NumericalObject  *numObj = [[NumericalObject new] autorelease];

  NSLog(@"Deconvolution: fitting Gaussian spread function to data. . .");

  // Get gaussPeaks data: list of <x, y> values
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:@"Gaussian peaks data"];
  result = [openPanel runModalForDirectory:NSHomeDirectory()
                                      file:@"gaussPeaks"
                                     types:nil];
  if (result == NSOKButton) {
    gaussPeaksFile = [[openPanel filenames] objectAtIndex:0];
    dataString = [NSString stringWithContentsOfFile:gaussPeaksFile];
  }
  else
    return NO;

  if (dataString == nil) {
        NSRunAlertPanel(@"Deconvolution tool",
                        @"Could not read gaussPeaks data file.", @"", nil, nil);
    return NO;
  }

  theScanner = [NSScanner scannerWithString:dataString];

  while ((numPoints < maxPoints)  && (scanError == NO)
         && ([theScanner isAtEnd] == NO)) { // scan x, y
    if ([theScanner scanFloat:&currentX]
        && [theScanner scanFloat:&currentY]) {
      arrayX[numPoints] = currentX;
      arrayY[numPoints] = currentY;
      sig[numPoints] = 1.0;
      numPoints++;
    }
    else
      scanError = YES;
  }

  if (numPoints > 0) {
    [numObj myfit:arrayX :arrayY :sig :numPoints :coeffs :numCoeff :self];
  }
  else {
    coeffs[0] = coeffs[1] = coeffs[2] = 0.0;
  }
  if([dataProcessor debugmode])
    NSLog([NSString stringWithFormat:
        @"sigma(x) = (a + bx + cx^2);  a=%e  b=%e  c=%e\n",
        coeffs[0], coeffs[1], coeffs[2]]);
  return YES;
}

#ifdef OLDCODE
/*** Section for creating mobility through sliding traces ***/

typedef struct {
  int		loc;
  int		shift;
}	shiftElement_t;

- (void)mouseEvent:(range)theRange
{
  shiftElement_t	tempShift;

  tempShift.loc = theRange.start;
  tempShift.shift = -theRange.end;
  [[shiftData objectAt:curChannel] addElement:&tempShift];
  printf(" shift chan:%d  %d at %d (len=%d)\n", curChannel, theRange.end, theRange.start,
         [[shiftData objectAt:curChannel] count]);
}

- (void)switchSlideChannel:sender
{
  curChannel = [slideChannelID selectedColumn];
  printf(" switch slide channel to %d\n", curChannel);
  [toolMaster setShiftChannel:curChannel];
}


float spreadPoly(float dataValue, int np)
{	
  return pow(dataValue, (np-1));
}

- (void)fitEquation
{
  float		       *arrayX;        // x values
  float		       *arrayY;        // y values
  float		       *sig;           // relative weight (significance)
  int		       numCoeff=3;
  float		       coeffs[3];      // returned constants for fitted polynominal
  int		       chan, j;
  id		       channelData;
  shiftElement_t       *tempShift;
  DeconvolutionTool    *procStruct = dataProcessor;
  id                   funcID;

  if(shiftData == NULL) return;

  printf("FitEquation to data\n");
  for(chan=0; chan<[shiftData count]; chan++) {
    channelData = [shiftData objectAt:chan];
    arrayX = (float*) malloc(sizeof(float) * [channelData count]);
    arrayY = (float*) malloc(sizeof(float) * [channelData count]);
    sig = (float*) malloc(sizeof(float) * [channelData count]);

    if([channelData count] > 0) {
      for(j=0; j<[channelData count]; j++) {
        tempShift = (shiftElement_t*)[channelData elementAt:j];
        arrayX[j] = tempShift->loc;
        arrayY[j] = tempShift->shift;
        sig[j] = 1.0;
      }

      myfit(arrayX, arrayY, sig, [channelData count], coeffs, numCoeff, spreadPoly);
      printf("fit for channel %d\n", chan);
      printf(" (a/x+bx+c)  a=%f  b=%f  c=%f\n",coeffs[0], coeffs[2], coeffs[1]);

      funcID = procStruct->spreadFunctionID;
      [funcID setConstValue:0 channel:chan value:coeffs[0]];
      [funcID setConstValue:1 channel:chan value:coeffs[2]];
      [funcID setConstValue:2 channel:chan value:coeffs[1]];

      free(arrayX);
      free(arrayY);
      free(sig);
    }
    else {
      printf("fit for channel %d\n", chan);
      printf(" (a/x+bx+c)  a=%f  b=%f  c=%f\n",0.0, 0.0, 0.0);
      funcID = procStruct->spreadFunctionID;
      [funcID setConstValue:0 channel:chan value:0.0];
      [funcID setConstValue:1 channel:chan value:0.0];
      [funcID setConstValue:2 channel:chan value:0.0];
    }
  }
}
#endif

@end
