
/* "$Id: MobilityNonlinearCtrl.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "MobilityNonlinearCtrl.h"
#import "MobilityNonlinear.h"
//#import <objc/Storage.h>
#import <GeneKit/NumericalObject.h>
/*
typedef struct {
  int   loc;
  int   shift;
} shiftElement_t;
*/

/*****
* August 9, 1994 Jessica Hayden
* Second Generation mobility shift routines.
*****/

@implementation MobilityNonlinearCtrl

- (NSString *)resourceSubdir
{
  return @"MobilityFunctions";
}

- (void)appWillInit
{
  /* called from ToolMaster */
  [super appWillInit];
  curChannel = 0;  // C base channel
  shiftData = NULL;
  [[displayView contentView] retain];
  [[newMethodView contentView] retain];
  [[slidingModeView contentView] retain];
  [accessoryView setContentView:[displayView contentView]];
	previousView = displayView;
}

- setToDefault
{
  MobilityNonlinear *procStruct = (MobilityNonlinear *)dataProcessor;

  if(procStruct->mobilityFunctionID) [procStruct->mobilityFunctionID release];
  procStruct->mobilityFunctionID = [[MobilityFunc1 alloc] init];
  return [super setToDefault];
}

- (void)displayParams
{
  [self showConstants];
  [super displayParams];
}

- (void)getParams
{
  [super getParams];
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
  //MobilityNonlinear *procStruct = (MobilityNonlinear *)dataProcessor;
  //id		funcID;

  //funcID = procStruct->mobilityFunctionID;
  //if(funcID != NULL) [funcID free];
  //funcID = [[MobilityFunc1 alloc] init];
  //procStruct->mobilityFunctionID = funcID;

  for(i=0; i<3; i++) {
    [[constID cellAtRow:i column:0] setBezeled:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor whiteColor]];
    [[constID cellAtRow:i column:0] setSelectable:YES];
    [[constID cellAtRow:i column:0] setEditable:YES];
  }
}

- (void)setViewToDisplay
{
  int		i;

  for(i=0; i<3; i++) {
    [[constID cellAtRow:i column:0] setBordered:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor lightGrayColor]];
    [[constID cellAtRow:i column:0] setEditable:NO];
    [[constID cellAtRow:i column:0] setSelectable:NO];
  }
}

- (void)startNew
{
	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]]; 
	newMethod = 0; //none
  [accessoryView setContentView:[newMethodView contentView]];
	previousView = newMethodView;
	[accessoryView display];
}

- (void)finishNew
{
  int               i, j;
  FILE              *fp;
  NSMutableArray           *shiftChannel;
//  shiftElement_t    *tempShift;
  NSString          *logPath;

  switch(newMethod) {
    case 1: //by hand
            //get last params entered
      [self switchFunctionDisplay:self];
      break;

    case 2:	//sliding
      [toolMaster deregisterForEventNotification:self];
      [toolMaster doShift:NO channel:0];

      // create tmp data files HERE!!!!!!!!!
      for(i=0; i<[shiftData count]; i++) {
        logPath = [NSHomeDirectory() stringByAppendingPathComponent:
          [NSString stringWithFormat:@"shiftData%d", i]];
        fp = fopen([logPath fileSystemRepresentation], "w");
        shiftChannel = [shiftData objectAtIndex:i];
        for(j=0; j<[shiftChannel count]; j++) {
//          tempShift = (shiftElement_t*)[shiftChannel elementAt:j];
          if(fp!=NULL) fprintf(fp, "%d\t%d\n", [[[shiftChannel objectAtIndex:j] objectForKey:@"loc"] intValue], [[[shiftChannel objectAtIndex:j] objectForKey:@"shift"] intValue]);
        }
        if(fp!=NULL) fclose(fp);
      }
      [self fitEquation];

      [shiftData release];
      break;
  }
  newMethod = 0;
  [self setViewToDisplay];
  [previousView setContentView:[accessoryView contentView]];
  [accessoryView setContentView:[displayView contentView]];	
	previousView = displayView;
  [accessoryView display];
}

- (void)cancelNew
{
  newMethod = 0;
  [toolMaster deregisterForEventNotification:self];
  [toolMaster doShift:NO channel:0];
  [shiftData release];
  shiftData = NULL;
  [self setViewToDisplay];
	[previousView setContentView:[accessoryView contentView]];
  [accessoryView setContentView:[displayView contentView]];
	previousView = displayView;
  [accessoryView display];
  [super cancelNew];
}

- (void)newMethodOK:sender
{
  int		i;
  MobilityNonlinear *procStruct = (MobilityNonlinear *)dataProcessor;
  id		funcID;

  funcID = procStruct->mobilityFunctionID;
  if(funcID != NULL) [funcID release];
  funcID = [[MobilityFunc1 alloc] init];
  procStruct->mobilityFunctionID = funcID;

  newMethod = [newMethodID selectedRow]+1;  //1=by hand, 2=by sliding
  [previousView setContentView:[accessoryView contentView]];
	switch(newMethod) {
    case 1:
				[self setViewToEnter];
				[accessoryView setContentView:[displayView contentView]];
				previousView = displayView;
			break;
    case 2:
			previousView = slidingModeView;
			[accessoryView setContentView:[slidingModeView contentView]];
      curChannel = [slideChannelID selectedColumn];
      [toolMaster doShift:YES channel:curChannel];
      [toolMaster registerForEventNotification:self];
      shiftData = [[NSMutableArray alloc] init];
      for(i=0; i<[toolMaster numberChannels]; i++) {
        [shiftData addObject:[NSMutableArray array]];
      }
      break;
  }
  [accessoryView display];
}

- (void)switchFunctionDisplay:sender
{
	MobilityNonlinear *procStruct = (MobilityNonlinear *)dataProcessor;
	id		funcID;
	int    tempChannel, i;
	double    tval;
	
	tempChannel = [channelID selectedColumn];
	if(makingNew) {
		// get values from fields for last channels
		funcID = procStruct->mobilityFunctionID;
		for(i=0; i<3; i++) {
			tval = [[constID cellAtRow:i column:0] doubleValue];
			[funcID setConstValue:i channel:curChannel value:tval];
		}
	}
	curChannel = tempChannel;
	[self showConstants]; 
}

- (void)showConstants
{
  MobilityNonlinear *procStruct = (MobilityNonlinear *)dataProcessor;
  id		funcID;
  int		i;
  NSCell        *thisCell;

  funcID = procStruct->mobilityFunctionID;
  for(i=0; i<3; i++) {
    thisCell = [constID cellAtRow:i column:0];
    [thisCell setFloatingPointFormat:YES left:1 right:10];
    [thisCell setDoubleValue:[funcID constValue:i channel:curChannel]];
  }
}


/*** Section for creating mobility through sliding traces ***/

- (void)mouseEvent:(range)theRange
{
//  shiftElement_t	tempShift;
  int                   deleteOffset=0;
  NSDictionary	*dict;

  if([toolMaster pointStorageID] != nil) {
    deleteOffset = [[toolMaster pointStorageID] deleteOffset];
    //printf("deleteOffset = %d\n", deleteOffset);
  }
  
  dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:theRange.start + deleteOffset], @"loc", [NSNumber numberWithFloat: (float)(theRange.start-theRange.end)], @"shift", nil];
//  tempShift.loc = theRange.location + deleteOffset;
//  tempShift.shift = -theRange.length;
  [[shiftData objectAtIndex:curChannel] addObject:dict];

  printf(" shift chan:%d  %d at %d (len=%d)\n",curChannel, [[dict objectForKey:@"shift"] intValue], [[dict objectForKey:@"loc"] intValue],
         [[shiftData objectAtIndex:curChannel] count]);
}

- (void)switchSlideChannel:sender
{
  curChannel = [slideChannelID selectedColumn];
  //[toolMaster log:
  //  [NSString stringWithFormat:@" switch slide channel to %d", curChannel]];
  [toolMaster setShiftChannel:curChannel];
}


float mobilityPoly(float dataValue, int np)
{	
  return pow(dataValue, (np-1));
}


- (float)polyFitFunction:(float)x :(int)np
{
  //for the NumericalObject version of myfit
  return pow(x, (np-1));

}

- (void)fitEquation
{
  float            *arrayX;		// x values
  float            *arrayY;		// y values
  float            *sig;		// relative weight (significance)
  int              numCoeff=3;
  float            coeffs[3];		// returned constants for fitted polynominal
  int              chan, j;
  NSMutableArray          *shiftChannelData;
//  shiftElement_t   *tempShift;
  id               funcID;
  MobilityNonlinear      *procStruct = (MobilityNonlinear *)dataProcessor;
  NumericalObject  *numObj = [[NumericalObject new] autorelease];

  if(shiftData == NULL) return;

  NSLog(@"FitEquation to data");
  for(chan=0; chan<[shiftData count]; chan++) {
    shiftChannelData = [shiftData objectAtIndex:chan];
    arrayX = (float*) malloc(sizeof(float) * [shiftChannelData count]);
    arrayY = (float*) malloc(sizeof(float) * [shiftChannelData count]);
    sig = (float*) malloc(sizeof(float) * [shiftChannelData count]);

    if([shiftChannelData count] > 0) {
      for(j=0; j<[shiftChannelData count]; j++) {
//        tempShift = (shiftElement_t*)[shiftChannelData elementAt:j];
        arrayX[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"loc"] floatValue];
//        tempShift->loc;
        arrayY[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"shift"] floatValue];
        //tempShift->shift;
        sig[j] = 1.0;
      }

      //myfit(arrayX, arrayY, sig, [shiftChannelData count], coeffs, numCoeff, mobilityPoly);
      [numObj myfit:arrayX :arrayY :sig :[shiftChannelData count] :coeffs :numCoeff :self];
      NSLog([NSString stringWithFormat:@"fit for channel %d", chan]);
      NSLog([NSString stringWithFormat:@" (a/x+bx+c)  a=%f  b=%f  c=%f\n",
              coeffs[0], coeffs[2], coeffs[1]]);

      funcID = procStruct->mobilityFunctionID;
      [funcID setConstValue:0 channel:chan value:coeffs[0]];
      [funcID setConstValue:1 channel:chan value:coeffs[2]];
      [funcID setConstValue:2 channel:chan value:coeffs[1]];

      free(arrayX);
      free(arrayY);
      free(sig);
    }
    else {
      NSLog([NSString stringWithFormat:@"fit for channel %d\n", chan]);
      NSLog([NSString stringWithFormat:@" (a/x+bx+c)  a=%f  b=%f  c=%f\n",0.0, 0.0, 0.0]);
      funcID = procStruct->mobilityFunctionID;
      [funcID setConstValue:0 channel:chan value:0.0];
      [funcID setConstValue:1 channel:chan value:0.0];
      [funcID setConstValue:2 channel:chan value:0.0];
    }
  }
}
@end
