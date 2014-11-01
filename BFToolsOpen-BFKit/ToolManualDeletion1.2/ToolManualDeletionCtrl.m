/* "$Id: ToolManualDeletionCtrl.m,v 1.2 2007/01/31 19:36:11 smvasa Exp $" */
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

#import "ToolManualDeletionCtrl.h"
#import "ToolManualDeletion.h"

#define TMDFIRSTPOINT 0
#define TMDLASTPOINT 1


/*****
* July 19, 1994 Mike Koehrsen
* Split ToolManualDeletion class into ToolManualDeletion and ToolManualDeletionCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*
* August 16, 1994 Jessica Hayden
* Added ability to specify deletion relative to end of data, independent of data
* length.  Uses '$' symbol to specify end of data, and '$-#' to subtract #points
* from end (eg from:$-10 to:$).
*
* February 1996 Jessica Severin
* Added back in the ability to delete data and the associated basecall 
* simultaneously.  Also required a small change to GenericTool.
*/

@implementation ToolManualDeletionCtrl

- init
{
  ToolManualDeletion  *procStruct = dataProcessor;
  NSDictionary *defaultsDict =
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"0", @"DeleteWithSpacers",
      nil];

  [super init];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
  procStruct->leaveSpace = (BOOL)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"DeleteWithSpacers"] cString]);
  useRange=YES;
  return self;
}

- (void)appWillInit
{
  [toolMaster registerForEventNotification:self];
  [rangeView retain];
  [endView retain];
  [altView setContentView:rangeView];

  [super appWillInit];
}

- (void)getParams
{
  ToolManualDeletion *procStruct = dataProcessor;
  char	tmpstr[2];
  int   tempInt, row, col, index, value;

  [super getParams];
  if(useRange) {
    strncpy(procStruct->firstLoc, [[[rangeForm cellAtRow:TMDFIRSTPOINT column:0] stringValue] cString], 32);
    strncpy(procStruct->lastLoc, [[[rangeForm cellAtRow:TMDLASTPOINT column:0] stringValue] cString], 32);
    procStruct->leaveSpace = (BOOL)[leaveSpaceSwitch state];
    [dataProcessor convertDescript:procStruct->firstLoc];
    [dataProcessor convertDescript:procStruct->lastLoc];

    sprintf(tmpstr,"%d",procStruct->leaveSpace);
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmpstr]
                                              forKey:@"DeleteWithSpacers"];
  }
  else {
    strcpy(procStruct->lastLoc, "$");
    tempInt = [endPointsFormCell intValue];
    if(tempInt<0) tempInt=0;
    sprintf(procStruct->firstLoc, "$-%d", tempInt);
    procStruct->leaveSpace = NO;
    [dataProcessor convertDescript:procStruct->firstLoc];
    [dataProcessor convertDescript:procStruct->lastLoc];
  }
	
	for(row=0;row<2;row++) {
    for(col=0;col<4;col++) {
      index = row*4 + col;
      value = [[delChannelID cellAtRow:row column:col] intValue];
      [dataProcessor setDelChans:value at:index];
    }
  }

  [self displayParams];
}

- (void)displayParams
{
  ToolManualDeletion *procStruct = dataProcessor;
  int firstPoint, lastPoint, index, numChannels;

  [super displayParams];
  if(useRange) {
    [leaveSpaceSwitch setState:(int)procStruct->leaveSpace];
  }
  [[rangeForm cellAtRow:TMDFIRSTPOINT column:0] setStringValue:[NSString stringWithCString:procStruct->firstLoc]];
  [[rangeForm cellAtRow:TMDLASTPOINT column:0] setStringValue:[NSString stringWithCString:procStruct->lastLoc]];
  if(strcmp(procStruct->lastLoc, "$") == 0) {
    firstPoint = [dataProcessor convertDescript:procStruct->firstLoc];
    lastPoint = [dataProcessor convertDescript:procStruct->lastLoc];
    [endPointsFormCell setIntValue:(lastPoint-firstPoint)];
  }
  else
    [endPointsFormCell setStringValue:@""];
	numChannels = [toolMaster numberChannels];
	for(index=0;index<8;index++) {
    if(index<numChannels) {
      [[delChannelID cellAtRow:index/4 column:index%4] setEnabled:YES];
      [[delChannelID cellAtRow:index/4 column:index%4] setIntValue:[dataProcessor getDelChans:index]];
    }
    else {
      [[delChannelID cellAtRow:index/4 column:index%4] setIntValue:0];
      [[delChannelID cellAtRow:index/4 column:index%4] setEnabled:NO];
    }
  }	
}

- (void)resetParams
{
	int	row, col, index, numChannels;
	
	numChannels = [toolMaster numberChannels];
	for(row=0;row<2;row++) {
    for(col=0;col<4;col++) {
      index = row*4 + col;
			if (index < numChannels)
				[dataProcessor setDelChans:1 at:index];
			else
				[dataProcessor setDelChans:0 at:index];
    }
  }
}

- (void)switchRangeEnd:sender
{
  if([sender selectedRow] == 0) {
    useRange=YES;
    [altView setContentView:rangeView];
  }
  else {
    useRange=NO;
    [altView setContentView:endView];
  }
  [altView display];
}

- (void)mouseEvent:(range)theRange
{
  ToolManualDeletion *procStruct = dataProcessor;

  sprintf(procStruct->firstLoc, "%d", (theRange.start));
  sprintf(procStruct->lastLoc, "%d", theRange.end);
	[[rangeForm cellAtRow:TMDFIRSTPOINT column:0] setStringValue:[NSString stringWithCString:procStruct->firstLoc]];
  [[rangeForm cellAtRow:TMDLASTPOINT column:0] setStringValue:[NSString stringWithCString:procStruct->lastLoc]];

  //[self displayParams];
}

- (void)keyEvent:(NSEvent*)keyEvent
{
  ToolManualDeletion *procStruct = dataProcessor;
  int            firstPoint, lastPoint;
  NSString       *charString;
  unichar        thischar; //really an unsigned short
  BOOL           oldState=useRange;

  charString = [keyEvent charactersIgnoringModifiers];
  NSLog(@"manualdel keyEvent unicode len=%d", [charString length]);
  if([charString length] > 0) {
    thischar = [charString characterAtIndex:0];
    NSLog(@" keyevent %X", thischar);
    if ((thischar==0x7F) || (thischar=='\010')) { // delete character
      useRange=YES;  //by default a mouseSelect and <del> is a 'RANGE'
      firstPoint = [dataProcessor convertDescript:procStruct->firstLoc];
      lastPoint = [dataProcessor convertDescript:procStruct->lastLoc];
      if(firstPoint==lastPoint) return;

      [self show];  //makes self activate tool in ToolMaster 
      [toolMaster appendTool]; 
      useRange=oldState;
    }
  }
}

@end
