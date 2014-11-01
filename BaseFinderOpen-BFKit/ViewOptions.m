/* "$Id: ViewOptions.m,v 1.6 2007/02/02 14:52:58 smvasa Exp $" */

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

/*********
* 
* note that if the name associated with a channel is empty i.e. len=0
* then this inspector will display a default of "Channel x" but does
* not send that name back to the channel
*
**********/
#import "ViewOptions.h"
#import "SequenceEditor.h"
#import "MasterView.h"
#import <GeneKit/NumericalRoutines.h>
#import "BasesView.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


@implementation ViewOptions

- init
{
	int		x;
	
	[super init];
	//printf("ViewOptions init\n");
	localBases=255;
	for(x=0;x<8;x++) {
		channelColor[x] = [NSColor whiteColor];
		newColor[x] = [NSColor whiteColor];
		channelEnabled[x] = 1;
		rosettaStone[x] = ' ';
	}
	localBackgroundColor = [NSColor whiteColor];
	[self readSeqEditor];
	return self;
}

- (void) awakeFromNib
{
  int			viewtype;
  int     markType;
	int			lines;
  
  viewtype = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SplitView"] intValue];
  [chanView selectCellAtRow:viewtype column:0];
  markType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DataMarker"] intValue];
  [dataMarker selectCellAtRow:markType column:0];
	lines = [[[NSUserDefaults standardUserDefaults] objectForKey:@"BaseLines"] intValue];
	[baseLines setState:lines];
}

- setBaseStates:(int)type
{
	/* old outdated function */
	int			x, bit;
	
	switch(type) {
		case 0:	/* show all bases always */
			localBases = 255;
			break;
		case 1:	/* show only selected bases */
			localBases=0;
			bit=1;
			for(x=0;x<[seqEditor numberChannels];x++) {
				if(channelEnabled[x]) localBases = localBases | bit;
				bit=bit*2;
			}
			break;
		case 2: /* don't show bases */
			localBases = 0;
			break;
	}
	[masterViewID setActiveBases:localBases];
	return self;
}


- (void)changeColor:sender
{
        newColor[0] = [colorWell1 color];
        newColor[1] = [colorWell2 color];
        newColor[2] = [colorWell3 color];
        newColor[3] = [colorWell4 color];
        newColor[4] = [colorWell5 color];
        newColor[5] = [colorWell6 color];
        newColor[6] = [colorWell7 color];
        newColor[7] = [colorWell8 color]; 
}


- setColorWell:(NSColor *)thisColor :(int)pos
{
	switch (pos) {
		case 0:	[colorWell1 setColor:thisColor]; break;
		case 1:	[colorWell2 setColor:thisColor]; break;
		case 2:	[colorWell3 setColor:thisColor]; break;
		case 3:	[colorWell4 setColor:thisColor]; break;
		case 4:	[colorWell5 setColor:thisColor]; break;
		case 5:	[colorWell6 setColor:thisColor]; break;
		case 6:	[colorWell7 setColor:thisColor]; break;
		case 7:	[colorWell8 setColor:thisColor]; break;
	};
	return self;
}


- setColorWellEnabled:(int)state :(int)pos
{
	id			thisColorWell=NULL;
	
	switch (pos) {
		case 0:	thisColorWell=colorWell1; break;
		case 1:	thisColorWell=colorWell2; break;
		case 2:	thisColorWell=colorWell3; break;
		case 3:	thisColorWell=colorWell4; break;
		case 4:	thisColorWell=colorWell5; break;
		case 5:	thisColorWell=colorWell6; break;
		case 6:	thisColorWell=colorWell7; break;
		case 7:	thisColorWell=colorWell8; break;
	};
	[thisColorWell setEnabled:state];
	return self;
}

#ifdef OLDCODE
- (void)parseLabels
{	
  int        x,y, numTokens, count;
  char       tempStr[64], tokens[32][64];
  char       *strPtr;
  Base       *tempBase;
  Sequence   *baseStorage;

  for(x=0;x<[seqEditor numberChannels];x++) {
    y=0;
    strcpy(tempStr, [[[seqEditor pointStorageID] labelForChannel:x] cString]);
    strPtr = strtok(tempStr," ");		/* space delimited tokens */

    while(strPtr != NULL) {
      strcpy(tokens[y],strPtr);
      y++;
      strPtr = strtok(NULL," ");
    }
    numTokens=y;
    rosettaStone[x]=' ';
    for(y=0;y<numTokens;y++) {
      /* takes last single character token as the label */
      if(strlen(tokens[y])==1) rosettaStone[x]=tokens[y][0];
    }
    sprintf(tempStr,"%c:",rosettaStone[x]);
    [[activeBasesID cellAtRow:0 column:x+1] setTitle:[NSString stringWithCString:tempStr]];
  }

  if((baseStorage=[seqEditor baseStorageID]) == NULL) return;

  count = [baseStorage seqLength];
  for(x=0; x< count; x++) {
    tempBase = [baseStorage baseAt:x];
    if(tempBase->channel >= 0) {
      tempBase->base = rosettaStone[tempBase->channel];
    }
    else {
      tempBase->base = 'N';
    }
  } 
}
#endif

/*****
*
* Scale Panel routines
*
*****/
- (void)updateScale:sender
{
	int			type;
	
	type = [normTypeID selectedRow];
	[[seqEditor masterViewID] setChannelNorm:type];
	if(type==2) {		//manual, also set the min max manually
		[self getMinMax];
		[[seqEditor masterViewID] setDataMin:minY max:maxY];
	}
	[scalePanel orderOut:self];
	[seqEditor shouldRedraw]; 
}

- (void)resetScale
{
	int			type;
	
	type = [[seqEditor masterViewID] channelNorm];
	[normTypeID selectCellAtRow:type column:0];
	
	[[seqEditor masterViewID] getDataMin:minY max:maxY];
	[self showMinMax];

	if(type==2)
		[self setEditable:YES];
	else
		[self setEditable:NO]; 
}

- (void)setEditable:(BOOL)value
{
	int		i;
	
	for(i=0; i<8; i++) {
		if(i<4) {
			[[minMax1ID cellAtRow:0 column:i] setEnabled:value] ;
			[[minMax1ID cellAtRow:1 column:i] setEnabled:value] ;
		}
		else {
			[[minMax2ID cellAtRow:0 column:i-4] setEnabled:value];
			[[minMax2ID cellAtRow:1 column:i-4] setEnabled:value];
		}
	}
}

- (void)switchNormType:sender
{
	int			row;
	
	row = [normTypeID selectedRow];
	switch(row) {
		case 0:		// common scale
			[self calcMinMaxWithCommonScale:YES];
			[self setEditable:NO];
			break;
		case 1:		// individual scales
			[self calcMinMaxWithCommonScale:NO];
			[self setEditable:NO];
			break;
		case 2:		// manual editing
			[self setEditable:YES];
			break;
	}
	[self showMinMax]; 
}

- (void)calcMinMaxWithCommonScale:(BOOL)useCommon
{
	/** this function will reset minY, maxY to the min/max of the entire data set **/
	int     i,j;
	float   min,max, *thePoints;
	Trace   *traceData = [seqEditor pointStorageID];
	
	max = 0;
	min = FLT_MAX;

	thePoints = (float *)calloc([traceData length], sizeof(float));
	for (j = 0; j < [traceData numChannels]; j++) {
		for(i=0; i<[traceData length]; i++)
			thePoints[i] = [traceData sampleAtIndex:i channel:j];  

		minY[j] = minVal(thePoints, [traceData length]);
		maxY[j] = maxVal(thePoints, [traceData length]);
		if(minY[j]<min) min = minY[j];
		if(maxY[j]>max) max = maxY[j];
	}
	if(useCommon) {
		for (j = 0; j < [traceData numChannels]; j++) {
			minY[j] = min;
			maxY[j] = max;
		}
	}
	free(thePoints); 
}

- (void)showMinMax
{
  int              i;
  NSTextFieldCell  *thisCell;

  for(i=0; i<[seqEditor numberChannels]; i++) {
    if(i<4) {
      thisCell = [minMax1ID cellAtRow:0 column:i];
      [thisCell setFloatingPointFormat:YES left:8 right:4];
      [thisCell setFloatValue:minY[i]];
      thisCell = [minMax1ID cellAtRow:1 column:i];
      [thisCell setFloatingPointFormat:YES left:8 right:4];
      [thisCell setFloatValue:maxY[i]];
    }
    else {
      thisCell = [minMax2ID cellAtRow:0 column:i-4];
      [thisCell setFloatingPointFormat:YES left:8 right:4];
      [thisCell setFloatValue:minY[i]];
      thisCell = [minMax2ID cellAtRow:1 column:i-4];
      [thisCell setFloatingPointFormat:YES left:8 right:4];
      [thisCell setFloatValue:maxY[i]];
    }
  }
  for(i=[seqEditor numberChannels]; i<8; i++) {
    if(i<4) {
      thisCell = [minMax1ID cellAtRow:0 column:i];
      [thisCell setStringValue:@""];
      [thisCell setEnabled:NO];
      thisCell = [minMax1ID cellAtRow:1 column:i];
      [thisCell setStringValue:@""];
      [thisCell setEnabled:NO];
    }
    else {
      thisCell = [minMax2ID cellAtRow:0 column:i-4];
      [thisCell setStringValue:@""];
      [thisCell setEnabled:NO];
      thisCell = [minMax2ID cellAtRow:1 column:i-4];
      [thisCell setStringValue:@""];
      [thisCell setEnabled:NO];
    }
  }
}

- (void)getMinMax
{	
  int			i;

  for(i=0; i<8; i++) {
    if(i<4) {
      minY[i] = [[minMax1ID cellAtRow:0 column:i] floatValue];
      maxY[i] = [[minMax1ID cellAtRow:1 column:i] floatValue];
    }
    else {
      minY[i] = [[minMax2ID cellAtRow:0 column:i-4] floatValue];
      maxY[i] = [[minMax2ID cellAtRow:1 column:i-4] floatValue];
    }
  } 
}

/****
*
*
* Channel View Panel
*
*
****/

- (void)updateChanView:sender
{
	int			viewtype;
	
	viewtype = [chanView selectedRow];
  [[NSUserDefaults standardUserDefaults] setInteger:viewtype forKey:@"SplitView"];
	[chanViewPanel orderOut:self];
	[seqEditor shouldRedraw]; 
}

/****
*
* Data Marker Panel
*
****/
- (void)updateDataMark:sender
{
  int markType, lines;
  
  markType = [dataMarker selectedRow];
	lines = [baseLines state];
  [[NSUserDefaults standardUserDefaults] setInteger:markType forKey:@"DataMarker"];
	[[NSUserDefaults standardUserDefaults] setInteger:lines forKey:@"BaseLines"];
  [dataMarkPanel orderOut:self];
  [seqEditor shouldRedraw];
}

/****
*
* General
*
****/

- (void)readSeqEditor
{
  int              x, bit=1;
  NSButtonCell     *thisButton;
  NSTextFieldCell  *thisLabel;
  id               baseStorage;
  NSString         *tempName;
  BOOL             colored;

  if(seqEditor == NULL) {
    [self reset];
    return;
  }

  baseStorage = [seqEditor baseStorageID];

  localBackgroundColor = [seqEditor backgroundColor];
  [backgroundColorWell setColor:localBackgroundColor];
  localBases = [masterViewID activeBases];

  colored = [[seqEditor returnWindowID] canStoreColor];
  if(!colored) 	[backgroundColorWell setEnabled:NO];
  else [backgroundColorWell setEnabled:YES];

  for(x=0; x<[seqEditor numberChannels]; x++) {
    channelEnabled[x] = [seqEditor channelEnabled:x];
    thisButton=[buttons cellAtRow:x column:0];
    [thisButton setEnabled:YES];
    [thisButton setIntValue:channelEnabled[x]];

    tempName = [[seqEditor pointStorageID] labelForChannel:x];
    thisLabel=[labels cellAtRow:x column:0];
    [thisLabel setEnabled:1];
    if([tempName length]==0) {
      tempName = [NSString stringWithFormat:@"Channel %1d", x+1];
    }
    [thisLabel setStringValue:tempName];

    channelColor[x] = [seqEditor channelColor:x];
    newColor[x] = channelColor[x];
    [self setColorWellEnabled:1 :x];
    [self setColorWell:channelColor[x] :x];
  }

  for(x=[seqEditor numberChannels]; x<8; x++) {
    thisButton=[buttons cellAtRow:x column:0];
    [thisButton setIntValue:0];
    [thisButton setEnabled:NO];

    thisLabel=[labels cellAtRow:x column:0];
    [thisLabel setEnabled:0];
    tempName = [NSString stringWithFormat:@"Channel %1d",x+1];
    [thisLabel setStringValue:tempName];

    [self setColorWell:[NSColor whiteColor] :x];
    [self setColorWellEnabled:0 :x];
  }
  [buttons display];
  
  bit=1;
  for(x=0;x<5;x++) {
    [[activeBasesID cellAtRow:0 column:x] setIntValue:(localBases&bit)];
    bit=bit*2;
    if(baseStorage) [[activeBasesID cellAtRow:0 column:x] setEnabled:YES];
    else [[activeBasesID cellAtRow:0 column:x] setEnabled:NO];
  }
  //[self parseLabels];
  [activeBasesID display];
  
  [self resetScale];
}


- (void)reset
{
  /* clears and inactivates the panel */
  int   x;
  id    thisButton, thisLabel;

  for(x=0; x<8; x++) {
    thisButton=[buttons cellAtRow:x column:0];
    [thisButton setIntValue:0];
    [thisButton setEnabled:NO];

    thisLabel=[labels cellAtRow:x column:0];
    [thisLabel setEnabled:0];
    [thisLabel setStringValue:[NSString stringWithFormat:@"Channel %1d",x+1]];

    [self setColorWell:[NSColor whiteColor] :x];
    [self setColorWellEnabled:0 :x];
    [[activeBasesID cellAtRow:0 column:x] setIntValue:0];
    [[activeBasesID cellAtRow:0 column:x] setEnabled:NO];
  }
  [buttons display];
  [backgroundColorWell setColor:[NSColor whiteColor]];
  [backgroundColorWell setEnabled:NO];
}


- (void)upDate:sender
{
  int         x, bit=1;
  int         dirty=0;
  int         tempState;
  int         oldBases=localBases;
  NSString    *tempName;
  NSColor     *tempColor;
  BOOL        colored;

  colored = [[seqEditor returnWindowID] canStoreColor];
  if(colored) {
    tempColor = [backgroundColorWell color];
    if(![localBackgroundColor isEqual:tempColor]) dirty=1;
    localBackgroundColor = tempColor;
    [seqEditor setBackgroundColor:tempColor];
  }
  localBases = 0;
  for(x=0; x<[seqEditor numberChannels]; x++) {
    tempName = [[labels cellAtRow:x column:0] stringValue];
    if(![[[seqEditor pointStorageID] labelForChannel:x] isEqualToString:tempName]) {
      [[seqEditor pointStorageID] setLabel:tempName forChannel:x];
      //[self parseLabels];
      dirty=1;
    }

    tempState = [[buttons cellAtRow:x column:0] intValue];
    if(tempState != channelEnabled[x]) dirty=1;
    channelEnabled[x] = [[buttons cellAtRow:x column:0] intValue];
    [seqEditor setEnabled:channelEnabled[x] channel:x];

    if(![channelColor[x] isEqual:newColor[x]]) dirty=1;
    channelColor[x] = newColor[x];
    [seqEditor setColor:channelColor[x] channel:x];
  }
  for(x=0;x<5;x++) {
    localBases = localBases | (bit*[[activeBasesID cellAtRow:0 column:x] intValue]);
    bit = bit*2;
  }
  [masterViewID setActiveBases:localBases];
  if(localBases!=oldBases) dirty=1;

  [channelsPanel orderOut:self];
  [labelsPanel orderOut:self];

  if(dirty) {
    [seqEditor shouldRedraw];
  } 
}


- (void)cancel:(id)sender
{
  int    x, bit=1;

  [channelsPanel orderOut:self];
  [labelsPanel orderOut:self];
  [scalePanel orderOut:self];
	[chanViewPanel orderOut:self];
  [dataMarkPanel orderOut:self];

  for(x=0; x<[seqEditor numberChannels]; x++) {
    [[labels cellAtRow:x column:0] setStringValue:[[seqEditor pointStorageID] labelForChannel:x]];
    [[buttons cellAtRow:x column:0] setIntValue:channelEnabled[x]];
    [self setColorWell:channelColor[x] :x];
  }
  for(x=0;x<5;x++) {
    [[activeBasesID cellAtRow:0 column:x] setIntValue:(localBases&bit)];
    bit=bit*2;
  }
  [backgroundColorWell setColor:localBackgroundColor];
  [self resetScale];
}

- (void)setBaseLabels
{
	 
}

- (void)windowDidUpdate:(NSNotification *)notification
{
  //NSWindow *theWindow = [notification object];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
  /* when any atributes panel appears */
  //NSWindow *theWindow = [notification object];
  [self readSeqEditor];
}

@end
