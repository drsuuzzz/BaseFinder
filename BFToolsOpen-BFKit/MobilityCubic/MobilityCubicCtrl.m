/***********************************************************

Copyright (c) 2007 Suzy Vasa

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
NIH Center for AIDS Research

******************************************************************/
#import "MobilityCubicCtrl.h"
#import "MobilityCubic.h"
#import <GeneKit/NumericalObject.h>


@implementation MobilityCubicCtrl

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
  MobilityCubic *procStruct = (MobilityCubic *)dataProcessor;

  if(procStruct->mobilityFunctionID) [procStruct->mobilityFunctionID release];
  procStruct->mobilityFunctionID = [[Mobility3Func alloc] init];
  return [super setToDefault];
}

- (void)displayParams
{
	int		numChannels, index;
	
	numChannels = [toolMaster numberChannels];
	for(index=0;index<8;index++) {
    if(index<numChannels) {
      [[slideChannelID cellAtRow:index/4 column:index%4] setEnabled:YES];
      [[channelID cellAtRow:index/4 column:index%4] setEnabled:YES];
    }
    else {
      [[slideChannelID cellAtRow:index/4 column:index%4] setIntValue:0];
			[[channelID cellAtRow:index/4 column:index%4] setIntValue:0];
      [[slideChannelID cellAtRow:index/4 column:index%4] setEnabled:NO];
			[[channelID cellAtRow:index/4 column:index%4] setEnabled:NO];
    }
  }	
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
//  [toolMaster registerForEventNotification:self];
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

  for(i=0; i<4; i++) {
    [[constID cellAtRow:i column:0] setBezeled:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor whiteColor]];
    [[constID cellAtRow:i column:0] setSelectable:YES];
    [[constID cellAtRow:i column:0] setEditable:YES];
  }
}

- (void)setViewToDisplay
{
  int		i;

  for(i=0; i<4; i++) {
    [[constID cellAtRow:i column:0] setBordered:YES];
    [[constID cellAtRow:i column:0] setBackgroundColor:[NSColor lightGrayColor]];
    [[constID cellAtRow:i column:0] setEditable:YES];
    [[constID cellAtRow:i column:0] setSelectable:YES];
  }
}

- (void)startNew
{
  newMethod = 0; //none
	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]]; 
	[accessoryView setContentView:[newMethodView contentView]];
	previousView = newMethodView;
  [accessoryView display];
}

- (void)finishNew
{
  int               i, j;
  FILE              *fp;
  NSMutableArray    *shiftChannel;
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
          if(fp!=NULL) fprintf(fp, "%d\t%d\n", [[[shiftChannel objectAtIndex:j] objectForKey:@"loc"] intValue], [[[shiftChannel objectAtIndex:j] objectForKey:@"shift"] intValue]);
        }
        if(fp!=NULL) fclose(fp);
      }
      [self fitEquation];

      [shiftData release];
			curChannel = 4*[channelID selectedRow] + [channelID selectedColumn];
			[self showConstants];
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
  int		i, col, row;
  MobilityCubic *procStruct = (MobilityCubic *)dataProcessor;
  id		funcID;

  funcID = procStruct->mobilityFunctionID;
  if(funcID != NULL) [funcID release];
  funcID = [[Mobility3Func alloc] init];
  procStruct->mobilityFunctionID = funcID;

  newMethod = [newMethodID selectedRow]+1;  //1=by hand, 2=by sliding
  //MCG added this due to change in Cocoa where accessory view is removed
  //10/23/04
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
			col = [slideChannelID selectedColumn];
			row = [slideChannelID selectedRow];
			curChannel = 4*row + col;
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
	MobilityCubic *procStruct = (MobilityCubic *)dataProcessor;
	id		funcID;
	int    tempChannel, i, row, col;
	double    tval;
	
	row = [channelID selectedRow];
	col = [channelID selectedColumn];
	tempChannel = 4*row + col;
	if(makingNew) {
		// get values from fields for last channels
		funcID = procStruct->mobilityFunctionID;
		for(i=0; i<4; i++) {
			tval = [[constID cellAtRow:i column:0] doubleValue];
			[funcID setConstValue:i channel:curChannel value:tval];
		} 
	}
	curChannel = tempChannel;
	[self showConstants]; 
}

- (void)showConstants
{
  MobilityCubic *procStruct = (MobilityCubic *)dataProcessor;
  id		funcID;
  int		i;
  NSCell        *thisCell;

  funcID = procStruct->mobilityFunctionID;
  for(i=0; i<4; i++) {
    thisCell = [constID cellAtRow:i column:0];
    [thisCell setFloatingPointFormat:YES left:1 right:10];
    [thisCell setDoubleValue:[funcID constValue:i channel:curChannel]];
  }
}

- (void)constantsChanged:sender
{
  MobilityCubic *procStruct = (MobilityCubic *)dataProcessor;
  id		funcID;
  int		i;
  NSCell        *thisCell;

  funcID = procStruct->mobilityFunctionID;
  for(i=0; i<4; i++) {
    thisCell = [constID cellAtRow:i column:0];
    [thisCell setFloatingPointFormat:YES left:1 right:10];
    [funcID setConstValue:i channel:curChannel value:[thisCell doubleValue]];
  }
  [self saveResource:[dataProcessor currentLabel]];
}

- (void)selectResource:sender{
  [self saveResource:[dataProcessor currentLabel]];
  [super selectResource:sender];
}


/*** Section for creating mobility through sliding traces ***/

- (void)mouseEvent:(range)theRange
{
  NSDictionary	*dict;

  dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:theRange.start], @"loc", [NSNumber numberWithFloat: -(float)(theRange.end - theRange.start)], @"shift", nil];

  [[shiftData objectAtIndex:curChannel] addObject:dict];

}

- (void)switchSlideChannel:sender
{
	int		row, col;
   
	col = [slideChannelID selectedColumn];
	row = [slideChannelID selectedRow];
	curChannel = 4*row + col;
  [toolMaster setShiftChannel:curChannel];
}



- (float)polyFitFunction:(float)x :(int)np
{
  //for the NumericalObject version of myfit
  return pow(x, (np));

}

- (void)fitEquation
{
  float            *arrayX;		// x values
  float            *arrayY;		// y values
  float            *sig;		// relative weight (significance)
  int              numCoeff=4;
  float            coeffs[4];		// returned constants for fitted polynominal
  int              chan, j;
  NSMutableArray   *shiftChannelData;
  id               funcID;
  MobilityCubic      *procStruct = (MobilityCubic *)dataProcessor;
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
        arrayX[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"loc"] floatValue]; //tempShift->loc;
        arrayY[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"shift"] floatValue]; //tempShift->shift;
        sig[j] = 1.0;
      }

      [numObj myfit:arrayX :arrayY :sig :[shiftChannelData count] :coeffs :numCoeff :self];
      NSLog(@"fit for channel %d", chan);
      NSLog(@" (a+bx+cx^2+dx^3)  a=%f  b=%f  c=%f d=%f\n",
              coeffs[0], coeffs[1], coeffs[2], coeffs[3]);

      funcID = procStruct->mobilityFunctionID;
      [funcID setConstValue:0 channel:chan value:coeffs[0]];
      [funcID setConstValue:1 channel:chan value:coeffs[1]];
      [funcID setConstValue:2 channel:chan value:coeffs[2]];
			[funcID setConstValue:3 channel:chan value:coeffs[3]];

      free(arrayX);
      free(arrayY);
      free(sig);
    }
    else {
      NSLog(@"fit for channel %d\n", chan);
      NSLog(@" (a+bx+cx^2+dx^3)  a=%f  b=%f  c=%f d=%f\n",0.0, 0.0, 0.0, 0.0);
      funcID = procStruct->mobilityFunctionID;
      [funcID setConstValue:0 channel:chan value:0.0];
      [funcID setConstValue:1 channel:chan value:0.0];
      [funcID setConstValue:2 channel:chan value:0.0];
			[funcID setConstValue:3 channel:chan value:0.0];
    }
  }
}
@end
