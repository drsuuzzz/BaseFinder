/***********************************************************

Copyright (c) 2006 Suzy Vasa 

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

#import "ToolAlignCtrl.h"
#import "ToolAlign.h"
#import "GeneKit/Trace.h"

@interface ToolAlignCtrl (Private)
- (void)channelChange;
- (void)channelChange2;
- (void)channelChange3;
- (void)channelChange4;
-(void)showddNTP:(char *)ddNTP :(NSComboBox *)comboBoxID;
-(void) showChannel:(int *)loc;
- (int)stringToNoChan:(NSString *)channel;
-(NSString *)noToStringChan:(int)channel;
-(void)setAllData;
@end

@implementation ToolAlignCtrl

- (void)appWillInit
{
	[super appWillInit];
	[[viewButtons cellAtRow:0 column:0] setEnabled:YES];
	[[viewButtons cellAtRow:0 column:1] setEnabled:NO];
	[[viewButtons cellAtRow:0 column:2] setEnabled:NO];
		
	[addDelID setMode:NSRadioModeMatrix];
	[[addDelID cellAtRow:0 column:0] setEnabled:NO];
	[[addDelID cellAtRow:0 column:1] setEnabled:NO];
	
	[[initView contentView] retain];
	[[addDelView contentView] retain];
  [[integViewID contentView] retain];
	[[blankView contentView] retain];
	
	[accessoryView setContentView:[blankView contentView]];
  
	previousView = blankView;
  
	viewInd = 0;
	
}
	
- init
{	

  [super init];
	
	openPath = [NSHomeDirectory() retain];

	[[NSNotificationCenter defaultCenter] addObserver:self 
																				selector:@selector(peakPtAddDel:) 
																				name:@"PeakPtHit" object:nil ];
    return self;
}

/***
*
* setup data
*
***/

-(void)showddNTP:(char *)ddNTP :(NSComboBox *)comboBoxID
{
	switch (ddNTP[0]) {
		case 'A':
			[comboBoxID setStringValue:@"ddATP"];
			[comboBoxID selectItemWithObjectValue:@"ddATP"];
			break;
		case 'G':
			[comboBoxID setStringValue:@"ddGTP"];
			[comboBoxID selectItemWithObjectValue:@"ddGTP"];
			break;
		case 'C':
			[comboBoxID setStringValue:@"ddCTP"];
			[comboBoxID selectItemWithObjectValue:@"ddCTP"];
			break;
		case 'T':
			[comboBoxID setStringValue:@"ddTTP"];
			[comboBoxID selectItemWithObjectValue:@"ddTTP"];
			break;
		case 'U':
			[comboBoxID setStringValue:@"ddUTP"];
			[comboBoxID selectItemWithObjectValue:@"ddUTP"];
			break;
    case ' ':
      [comboBoxID setStringValue:@" "];
      [comboBoxID selectItemWithObjectValue:@" "];
      break;
		default:
			[comboBoxID setStringValue:@"ddATP"];
			[comboBoxID selectItemWithObjectValue:@"ddATP"];
			break;
	}
}

-(void) showChannel:(int *)loc
{
  int i;
  NSMutableString  *tempString;
  
  tempString = [NSMutableString stringWithCapacity:9];
  for (i=0; i < 4; i++) {
    switch (loc[i]) {
      case 0:
        [tempString setString:@"Channel 1"];
        break;
      case 1:
        [tempString setString:@"Channel 2"];
        break;
      case 2:
        [tempString setString:@"Channel 3"];
        break;
      case 3:
        [tempString setString:@"Channel 4"];
        break;
    }
    switch (i) {
      case 0:
        [reagentChanID setStringValue:tempString];
        [reagentChanID selectItemWithObjectValue:tempString];
        break;
      case 1:
        [nreagentChanID setStringValue:tempString];
        [nreagentChanID selectItemWithObjectValue:tempString];
        break;
      case 2:
        [ddNTPChan1ID setStringValue:tempString];
        [ddNTPChan1ID selectItemWithObjectValue:tempString];
        break;
      case 3:
        [ddNTPChan2ID setStringValue:tempString];
        [ddNTPChan2ID selectItemWithObjectValue:tempString];
        break;
    }
  }
}

- (int)stringToNoChan:(NSString *)channel
{
  int value=0;
  
  if ([channel isEqualTo:@"Channel 1"])
    value = 0;
  else if ([channel isEqualTo:@"Channel 2"])
    value = 1;
  else if ([channel isEqualTo:@"Channel 3"])
    value = 2;
  else if ([channel isEqualTo:@"Channel 4"])
    value = 3;
  
  return value;
}

-(NSString *)noToStringChan:(int)channel
{
  NSString  *tempString;
  
  switch (channel) {
    case 0: 
      tempString = @"Channel 1";
      break;
    case 1:
      tempString = @"Channel 2";
      break;
    case 2:
      tempString = @"Channel 3";
      break;
    case 3:
      tempString = @"Channel 4";
      break;
    default:
      tempString = @"Channel 1";
      break;
  }
  return tempString;
}

- (IBAction)channelChange:(id)sender
{
  int       temp, temp2, temp3, temp4;
  int       loc[4];
  NSString  *chanString;
    
  temp = [self stringToNoChan:[reagentChanID objectValueOfSelectedItem]];
  temp2 = [self stringToNoChan:[nreagentChanID objectValueOfSelectedItem]];
  temp3 = [self stringToNoChan:[ddNTPChan1ID objectValueOfSelectedItem]];
  temp4 = [self stringToNoChan:[ddNTPChan2ID objectValueOfSelectedItem]];
  
  [dataProcessor getChanLoc:loc];
  
  chanString = [self noToStringChan:loc[0]];
  if (temp == temp2) {
    loc[1] = loc[0];
    loc[0] = temp;
    [dataProcessor setChanLoc:loc];
    [nreagentChanID selectItemWithObjectValue:chanString];
    [nreagentChanID setStringValue:chanString];
  }
  else if (temp == temp3) {
    loc[2] = loc[0];
    loc[0] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan1ID selectItemWithObjectValue:chanString];
    [ddNTPChan1ID setStringValue:chanString];
  }
  else if (temp == temp4) {
    loc[3] = loc[0];
    loc[0] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan2ID selectItemWithObjectValue:chanString];
    [ddNTPChan2ID setStringValue:chanString];
  }
}

- (IBAction)channelChange2:(id)sender
{
  int       temp,temp2, temp3, temp4;
  int       loc[4];
  NSString  *chanString;
  
  temp2 = [self stringToNoChan:[reagentChanID objectValueOfSelectedItem]];
  temp = [self stringToNoChan:[nreagentChanID objectValueOfSelectedItem]];
  temp3 = [self stringToNoChan:[ddNTPChan1ID objectValueOfSelectedItem]];
  temp4 = [self stringToNoChan:[ddNTPChan2ID objectValueOfSelectedItem]];
  
  [dataProcessor getChanLoc:loc];
  
  chanString = [self noToStringChan:loc[1]];
  if (temp == temp2) {
    loc[0] = loc[1];
    loc[1] = temp;
    [dataProcessor setChanLoc:loc];
    [reagentChanID selectItemWithObjectValue:chanString];
    [reagentChanID setStringValue:chanString];
  }
  else if (temp == temp3) {
    loc[2] = loc[1];
    loc[1] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan1ID selectItemWithObjectValue:chanString];
    [ddNTPChan1ID setStringValue:chanString];
  }
  else if (temp == temp4) {
    loc[3] = loc[1];
    loc[1] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan2ID selectItemWithObjectValue:chanString];
    [ddNTPChan2ID setStringValue:chanString];
  }
}

- (IBAction)channelChange3:(id)sender
{
  int       temp,temp2, temp3, temp4;
  int       loc[4];
  NSString  *chanString;
  
  temp2 = [self stringToNoChan:[reagentChanID objectValueOfSelectedItem]];
  temp3 = [self stringToNoChan:[nreagentChanID objectValueOfSelectedItem]];
  temp = [self stringToNoChan:[ddNTPChan1ID objectValueOfSelectedItem]];
  temp4 = [self stringToNoChan:[ddNTPChan2ID objectValueOfSelectedItem]];
  
  [dataProcessor getChanLoc:loc];
  
  chanString = [self noToStringChan:loc[2]];
  if (temp == temp2) {
    loc[0] = loc[2];
    loc[2] = temp;
    [dataProcessor setChanLoc:loc];
    [reagentChanID selectItemWithObjectValue:chanString];
    [reagentChanID setStringValue:chanString];
  }
  else if (temp == temp3) {
    loc[1] = loc[2];
    loc[2] = temp;
    [dataProcessor setChanLoc:loc];
    [nreagentChanID selectItemWithObjectValue:chanString];
    [nreagentChanID setStringValue:chanString];
  }
  else if (temp == temp4) {
    loc[3] = loc[2];
    loc[2] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan2ID selectItemWithObjectValue:chanString];
    [ddNTPChan2ID setStringValue:chanString];
  }  
}

- (IBAction)channelChange4:(id)sender
{
  int temp,temp2, temp3, temp4;
  int       loc[4];
  NSString  *chanString;
  
  temp2 = [self stringToNoChan:[reagentChanID objectValueOfSelectedItem]];
  temp3 = [self stringToNoChan:[nreagentChanID objectValueOfSelectedItem]];
  temp4 = [self stringToNoChan:[ddNTPChan1ID objectValueOfSelectedItem]];
  temp = [self stringToNoChan:[ddNTPChan2ID objectValueOfSelectedItem]];
  
  [dataProcessor getChanLoc:loc];
  
  chanString = [self noToStringChan:loc[3]];
  if (temp == temp2) {
    loc[0] = loc[3];
    loc[3] = temp;
    [dataProcessor setChanLoc:loc];
    [reagentChanID selectItemWithObjectValue:chanString];
    [reagentChanID setStringValue:chanString];
  }
  else if (temp == temp3) {
    loc[1] = loc[3];
    loc[3] = temp;
    [dataProcessor setChanLoc:loc];
    [nreagentChanID selectItemWithObjectValue:chanString];
    [nreagentChanID setStringValue:chanString];
  }
  else if (temp == temp4) {
    loc[2] = loc[3];
    loc[3] = temp;
    [dataProcessor setChanLoc:loc];
    [ddNTPChan1ID selectItemWithObjectValue:chanString];
    [ddNTPChan1ID setStringValue:chanString];
  }
}

-(void)setAllData
{
	int numChannels = [toolMaster numberChannels];
	int	tempLoc[4];
	NSString *tempPath;
	char	ddNTP1[2], ddNTP2[2];
	int		iBegin, iEnd, iSeqFrom, iSeqTo, iStartNo;
	float	nt1sens, nt2sens;
	
	[reagentChanID setEnabled:YES];
  [nreagentChanID setEnabled:YES];
  [ddNTPChan1ID setEnabled:YES];
  if (numChannels > 3) {
    [ddNTPChan2ID setEnabled:YES];
    [ddNTP2ID setEnabled:YES];
  }
  else {
    [ddNTPChan2ID setEnabled:NO];  
    [ddNTP2ID setEnabled:NO];
  }
  [dataProcessor getChanLoc:tempLoc];
  [self showChannel:tempLoc];
	[dataProcessor getddNTP:ddNTP1 :ddNTP2];
	[self showddNTP:ddNTP1 :ddNTP1ID];
  if (numChannels < 4) 
    ddNTP2[0] = ' ';
	[self showddNTP:ddNTP2 :ddNTP2ID];
	
	tempPath = [dataProcessor getFilePath];
	if (tempPath != nil) 
		[sequenceText setStringValue:[tempPath lastPathComponent]];
	else
		[sequenceText setStringValue:@""];
	
	[dataProcessor getRange:&iBegin :&iEnd :&iSeqFrom :&iSeqTo :&iStartNo];
  [seqStartID setIntValue:iStartNo];
  
  if (iSeqFrom != 0) {
    [seqFromID setIntValue:iSeqFrom];
    [seqToID setIntValue:iSeqTo];
  }
  else {
    [seqFromID setStringValue:@""];
    [seqToID setStringValue:@""];
  }
	if (iBegin != -1) {
		[rangeFromID setIntValue:iBegin];
		[rangeToID setIntValue:iEnd];
	}
	else {
		[rangeFromID setStringValue:@""];
		[rangeToID setStringValue:@""];
	}
	
	[dataProcessor getNTSens:&nt1sens :&nt2sens];
	[NTLevel1ID setFloatValue:nt1sens];
	[NTLevel2ID setFloatValue:nt2sens];
  
  [refineID setState:[dataProcessor getRefine]];
	
}

- (IBAction)initData:(id)sender
{
	int numChannels = [toolMaster numberChannels];
		
	if (numChannels == 0) return;
  if ([[accessoryView window] makeFirstResponder:[accessoryView window]]) {
    //give the window first responder status if it doesn't work....
  }
  else //force field editor to resign first responder status
    [[accessoryView window] endEditingFor:nil];
	[[addDelID cellAtRow:0 column:0] setEnabled:NO];
	[[addDelID cellAtRow:0 column:1] setEnabled:NO];
	[[viewButtons cellAtRow:0 column:0] setEnabled:YES];

	[self setAllData];

	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]];
	[accessoryView setContentView:[initView contentView]];
	previousView = initView;
	[accessoryView display];
	[dataProcessor setViewInd:0];
	viewInd = 0;
}

- (IBAction)errorOkay:(id)sender
{
  [errorWinID orderWindow:NSWindowOut relativeTo:0];
}

//set the sequence file
- (void)open:sender
{
  NSArray  *files;
  NSOpenPanel   *openPanel;
  NSString  *tempPath;
  
  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];
  if ([dataProcessor getFilePath] != nil) {
    tempPath = [[dataProcessor getFilePath] stringByDeletingLastPathComponent];
    if (![openPath isEqualTo:tempPath]) {
      [openPath release];
      openPath = [tempPath copy];
    }    
  }
  if ([openPanel runModalForDirectory:openPath
                                 file:@""
                                types:nil]) {
    [openPath release];
    openPath = [[openPanel directory] retain];
    files = [openPanel filenames];
		if ([files count] > 0) {
			[sequenceText setStringValue:[[files objectAtIndex:0] lastPathComponent]];
      [dataProcessor setFilePath:[files objectAtIndex:0]];
		}
  }
}

- (void)updateInit
{
	int				tempLoc[4],i, error=0, temperr = 0;
	NSString	*ddNTPa, *ddNTPb;
  char      ntpA, ntpB;
	BOOL			swapChannels=NO;
  NSColor   *color1, *color2, *color3, *color4;
			
  [errorWinID orderWindow:NSWindowOut relativeTo:0];
  [errorTextID setStringValue:@""];
		ddNTPa = [ddNTP1ID objectValueOfSelectedItem];
		ddNTPb = [ddNTP2ID objectValueOfSelectedItem];
    if (![ddNTPa isEqualTo:@" "])
      ntpA = [ddNTPa characterAtIndex:2];
    else
      ntpA = ' ';
    if (![ddNTPb isEqualTo:@" "])
      ntpB = [ddNTPb characterAtIndex:2];
    else
      ntpB = ' ';
		if (ntpA == ntpB) {
      error = 1;
    }
		[dataProcessor setddNTP:ntpA :ntpB];
	
    [dataProcessor setNTSens:[NTLevel1ID floatValue] :[NTLevel2ID floatValue]];
		
		if (([rangeFromID intValue] == 0) && ([rangeToID intValue] == 0))
      [dataProcessor setRange:-1 :-1];
    else if ([rangeFromID intValue] < [rangeToID intValue])
			[dataProcessor setRange:[rangeFromID intValue] :[rangeToID intValue]];
		else {
      [dataProcessor setRange:-1 :-1];
      error = 3;
    }
    
    if ([seqStartID intValue] > 0)
			[dataProcessor setSeqNo:[seqStartID intValue]];
    
    if (([seqFromID intValue] == 0) && ([seqToID intValue] == 0))
      [dataProcessor setSeqRange:0 :0];
    else if ([seqFromID intValue] < [seqToID intValue])
			[dataProcessor setSeqRange:[seqFromID intValue] :[seqToID intValue]];
    else {
      [dataProcessor setSeqRange:0 :0];
      error = 4;
    }
    
    if ([dataProcessor getFilePath] == nil)
      error = 2;
    else { 
      temperr = [dataProcessor setSequence];
      if (temperr != 0)
        error = temperr;
    }

    [dataProcessor setRefine:[refineID state]];
    
		if (error == 0) {
			[[viewButtons cellAtRow:0 column:1] setEnabled:YES];
			[[viewButtons cellAtRow:0 column:2] setEnabled:YES];
      [dataProcessor doApply:YES];
      [dataProcessor getChanLoc:tempLoc];
      for (i=0;i < 4; i++) {
        if (tempLoc[i] != i)
          swapChannels = YES;
      }
      if (swapChannels) {
        color1 = [toolMaster colorForChannel:tempLoc[0]];
        color2 = [toolMaster colorForChannel:tempLoc[1]];
        color3 = [toolMaster colorForChannel:tempLoc[2]];
        color4 = [toolMaster colorForChannel:tempLoc[3]];
        [toolMaster setColorForChannel:0 :color1];
        [toolMaster setColorForChannel:1 :color2];
        [toolMaster setColorForChannel:2 :color3];
        [toolMaster setColorForChannel:3 :color4];
			}
		}
    else {
      [dataProcessor doApply:NO];
      switch (error) {
        case 1:
          [errorTextID setStringValue:errorNTP];
          break;
        case 2:
          [errorTextID setStringValue:errorSequence];
          break;
        case 3:
          [errorTextID setStringValue:errorRange];
          break;
        case 4:
          [errorTextID setStringValue:errorAGCU];
          break;
        case 5:
          [errorTextID setStringValue:errorPath];
          break;
        default:
          break;
      }
      [errorWinID orderWindow:NSWindowAbove relativeTo:0];
      [errorWinID makeKeyAndOrderFront:self];
    }
}

/***
*
* Add Delete Peaks
*
***/
//notification from sequenceview to add or delete peak
- (void)peakPtAddDel:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSNumber	*value, *tempChan, *value2;
	int	channel;
	int tempLoc[4];

	if (viewInd !=1) return;
	
	value = [userInfo objectForKey:@"value"];
	tempChan =[userInfo objectForKey:@"channel"];
	if (tempChan != nil)
		channel = [tempChan intValue];
	else
		channel = 5;
	
	if ([value intValue] < 0) {
		value2 = [NSNumber numberWithInt:(-[value intValue])];
	}
	else
		value2 = value;
	[dataProcessor getChanLoc:tempLoc];
	if (addDel == 0) {
		if (channel == tempLoc[0]) {
			[dataProcessor addDelPeak:value2 :0];
			[tableView reloadData];
		}
		if (channel == tempLoc[1]) {
			[dataProcessor addDelPeak:value2 :1];
			[tableView reloadData];
		}
    if (channel == tempLoc[2]) {
      [dataProcessor addDelPeak:value2 :2];
      [tableView reloadData];
    }
    if (channel == tempLoc[3]) {
			[dataProcessor addDelPeak:value2 :3];
      [tableView reloadData];
    }
	}
	else {
		switch (channel) {
		case 0:
			[dataProcessor addAddPeak:value2 :0];
			[tableView reloadData];
			break;
		case 1:
			[dataProcessor addAddPeak:value2 :1];
			[tableView reloadData];
			break;
    case 2:
      [dataProcessor addAddPeak:value2 :2];
      [tableView reloadData];
      break;
    case 3:
      [dataProcessor addAddPeak:value2 :3];
      [tableView reloadData];
      break;
		}
	}
}

- (IBAction)modifyAddDel:(id)sender
{
	if ([toolMaster numberChannels] == 0) return;
    //give up first responder status to solve problem with switching from initView to addDelView
  if ([[accessoryView window] makeFirstResponder:[accessoryView window]]) {
    //give the window first responder status if it doesn't work....
  }
  else //force field editor to resign first responder status
    [[accessoryView window] endEditingFor:nil];
	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]];
	[accessoryView setContentView:[addDelView contentView]];
	previousView = addDelView;
	[self setAllData];
	[[addDelID cellAtRow:0 column:0] setEnabled:YES];
	[[addDelID cellAtRow:0 column:1] setEnabled:YES];
	[addDelID selectCellAtRow:0 column:addDel];
	[self changeAddDelMessage:self];
	[accessoryView display];
	viewInd = 1;
	[dataProcessor setViewInd:viewInd];
}

- (IBAction)changeAddDelMessage:(id)sender
{
	NSString *addText = [NSString stringWithString:@"Add Peaks"];
	NSString *delText = [NSString stringWithString:@"Delete Peaks"];

	addDel = [addDelID selectedColumn];
	switch (addDel) {
	case 0:   //delete peaks
		[addDelTextID setStringValue:delText];
    [tableView reloadData];
		break;
	case 1:  //add peaks
		[addDelTextID setStringValue:addText];
		[tableView reloadData];
		break;
	}
}

/***
*
* Table View routines
*
***/
//return value to be displayed in table
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{
	NSMutableArray *tempArray1;
	NSNumber	*tempNumber;
	
	tempNumber = nil;
	switch (addDel) {
	case 0:
		if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
      tempArray1 = [dataProcessor getDelPeak:0];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
		else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"-Reagent"]) {
      tempArray1 = [dataProcessor getDelPeak:1];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
    else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP1"]) {
      tempArray1 = [dataProcessor getDelPeak:2];
      if (row < [tempArray1 count])
        tempNumber = [tempArray1 objectAtIndex:row];
    }
    else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP2"]) {
      tempArray1 = [dataProcessor getDelPeak:3];
      if (row < [tempArray1 count])
        tempNumber = [tempArray1 objectAtIndex:row];
    }
		break;
	case 1:
		if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
      tempArray1 = [dataProcessor getAddPeak:0];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
		else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"-Reagent"]) {
      tempArray1 = [dataProcessor getAddPeak:1];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
    else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP1"]) {
      tempArray1 = [dataProcessor getAddPeak:2];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
    else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP2"]) {
      tempArray1 = [dataProcessor getAddPeak:3];
			if (row < [tempArray1 count])
				tempNumber = [tempArray1 objectAtIndex:row];
		}
		break;
	}
	return tempNumber;
}

// Select value from table and delete it
- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	
	switch (addDel) {
		case 0:
			if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
        if ([[dataProcessor getDelPeak:0] count] > 0)
          [dataProcessor remDelPeak:rowIndex anObject:anObject :0];
			}
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"-Reagent"]) {
        if ([[dataProcessor getDelPeak:1] count] > 0)
          [dataProcessor remDelPeak:rowIndex anObject:anObject :1];
      }
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP1"]) {
        if ([[dataProcessor getDelPeak:2] count] > 0)
          [dataProcessor remDelPeak:rowIndex anObject:anObject :2];
      }
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP2"]) {
        if ([[dataProcessor getDelPeak:3] count] > 0)
          [dataProcessor remDelPeak:rowIndex anObject:anObject :3];
      }      
			break;
		case 1:
			if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
        if ([[dataProcessor getAddPeak:0] count] > 0)
          [dataProcessor remAddPeak:rowIndex anObject:anObject :0];
			}
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"-Reagent"]) {
        if ([[dataProcessor getAddPeak:1] count] > 0)
          [dataProcessor remAddPeak:rowIndex anObject:anObject :1];
      }
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP1"]) {
        if ([[dataProcessor getAddPeak:2] count] > 0)
          [dataProcessor remAddPeak:rowIndex anObject:anObject :2];
      }
			else if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"ddNTP2"]) {
        if ([[dataProcessor getAddPeak:3] count] > 0)
          [dataProcessor remAddPeak:rowIndex anObject:anObject :3];
      }
			break;
	}
  [tableView reloadData];
}
//return number of rows
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{	
	int count=0;
	
	if (addDel == 0)
		if ([[dataProcessor getDelPeak:0] count] > count)
			count = [[dataProcessor getDelPeak:0] count];
		if ([[dataProcessor getDelPeak:1] count] > count)
			count = [[dataProcessor getDelPeak:1] count];
    if ([[dataProcessor getDelPeak:2] count] > count)
      count = [[dataProcessor getDelPeak:2] count];
    if ([[dataProcessor getDelPeak:3] count] > count)
      count = [[dataProcessor getDelPeak:3] count];
	else
		if ([[dataProcessor getAddPeak:0] count] > count)
			count = [[dataProcessor getAddPeak:0] count];
		if ([[dataProcessor getAddPeak:1] count] > count)
			count = [[dataProcessor getAddPeak:1] count];
    if ([[dataProcessor getAddPeak:2] count] > count)
      count = [[dataProcessor getAddPeak:2] count];
    if ([[dataProcessor getAddPeak:3] count] > count)
      count = [[dataProcessor getAddPeak:3] count];
	
	return count;
}
//save column that has been clicked
/*- (void)tableView:(NSTableView *)aTableView didClickTableColumn:(NSTableColumn *)tableColumn
{
			if ([[[tableColumn headerCell] stringValue] isEqualToString:@"+Reagent"])
				selectedColumn = 0;
			else if ([[[tableColumn headerCell] stringValue] isEqualToString:@"-Reagent"])
				selectedColumn = 1;
      else if ([[[tableColumn headerCell] stringValue] isEqualToString:@"ddNTP1"])
        selectedColumn = 2;
      else if ([[[tableColumn headerCell] stringValue] isEqualToString:@"ddNTP2"])
        selectedColumn = 3;
}*/
//allow editing of table entries
/*- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  BOOL result=YES;
  
  if (addDel == 0) {
    if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
      if ([[dataProcessor getDelReagent] count] > 0) 
        result = YES;
    }
    else {
      if ([[dataProcessor getDelnReagent] count] > 0)
        result = YES;
    }
  }
  else {
    if ([[[aTableColumn headerCell] stringValue] isEqualToString:@"+Reagent"]) {
      if ([[dataProcessor getAddReagent] count] > 0)
        result = YES;
    } 
    else {
      if ([[dataProcessor getAddnReagent] count] > 0)
        result = YES;
    }
  }
  return result;
}*/
  
/***
*
* Integrate Data
*
***/

- (IBAction)integrateData:(id)sender
{
  NSString *savePeaks;
  NSString *saveFit;
  
  if ([toolMaster numberChannels] == 0) return;
  if ([[accessoryView window] makeFirstResponder:[accessoryView window]]) {
    //give the window first responder status if it doesn't work....
  }
  else //force field editor to resign first responder status
    [[accessoryView window] endEditingFor:nil];
	[[addDelID cellAtRow:0 column:0] setEnabled:NO];
	[[addDelID cellAtRow:0 column:1] setEnabled:NO];
	[self setAllData];
  if ([dataProcessor fitOngoing]) {
    [[viewButtons cellAtRow:0 column:0] setEnabled:NO];
    [[viewButtons cellAtRow:0 column:1] setEnabled:NO];
    [[viewButtons cellAtRow:0 column:2] setEnabled:NO];
    [progressIndID setHidden:NO];
    [progressIndID startAnimation:self];
    [statusTextID setHidden:NO];
    [statusTextID setStringValue:@"Fitting..."];
  }
  else {
    [[viewButtons cellAtRow:0 column:0] setEnabled:YES];
    [[viewButtons cellAtRow:0 column:1] setEnabled:YES];
    [[viewButtons cellAtRow:0 column:2] setEnabled:YES];
    [progressIndID stopAnimation:self];
    [progressIndID setHidden:YES];
    [statusTextID setStringValue:@""];
    [statusTextID setHidden:YES];
	}
	savePeaks = [dataProcessor getPeakFile];
	saveFit = [dataProcessor getFitFile];
	if (savePeaks == nil) {
		savePeaks = [NSString stringWithString:[openPath stringByAppendingPathComponent:@"mypeaks.txt"]];
		[dataProcessor savePeakFile:savePeaks];
	}
	if (saveFit == nil) {
		saveFit = [NSString stringWithString:[openPath stringByAppendingPathComponent:@"myfit.txt"]];
		[dataProcessor saveFitFile:saveFit];
	}
	[integFile setStringValue:[savePeaks lastPathComponent]];
	[integFitFile setStringValue:[saveFit lastPathComponent]];
	[optimizeID setState:[dataProcessor getOptimizeFlag]];    
		
 	if (previousView != nil)
		[previousView setContentView:[accessoryView contentView]];
	[accessoryView setContentView:[integViewID contentView]];
	previousView = integViewID;
	viewInd = 2;
	[dataProcessor setViewInd:viewInd];
	[accessoryView display];
}

- (void)fitDone
{
	[dataProcessor fitDone];
	[toolMaster askToRedraw];
}

- (void)savePeaks:sender
{
  NSSavePanel		*savePanel;
	int						result;
  NSString      *tempPath;
  
  if ([dataProcessor fitOngoing])
    return; //do not accept changes in the middle of a fit
  savePanel = [NSSavePanel savePanel];
	[savePanel setDelegate:self];
	[savePanel setTitle:@"Save Integrated Peaks file"];
  if ([dataProcessor getPeakFile] != nil) {
    tempPath = [[dataProcessor getPeakFile] stringByDeletingLastPathComponent];
    if (![openPath isEqualTo:tempPath]) {
      [openPath release];
      openPath = [tempPath copy];
    }    
  }  
	result = [savePanel runModalForDirectory:openPath file:[integFile stringValue]];
  if (result == NSOKButton) {
    [openPath release];
    openPath = [[savePanel directory] retain];
		[integFile setStringValue:[[savePanel filename] lastPathComponent]];
    [dataProcessor savePeakFile:[savePanel filename]];
  }
}

- (void)saveFit:sender
{
  NSSavePanel		*savePanel;
	int						result;
  NSString      *tempPath;
  
  if ([dataProcessor fitOngoing])
    return; //do not accept changes in the middle of a fit
  savePanel = [NSSavePanel savePanel];
	[savePanel setDelegate:self];
	[savePanel setTitle:@"Save Input vs Fit file"];
  if ([dataProcessor getFitFile] != nil) {
    tempPath = [[dataProcessor getFitFile] stringByDeletingLastPathComponent];
    if (![openPath isEqualTo:tempPath]) {
      [openPath release];
      openPath = [tempPath copy];
    }    
  }  
	result = [savePanel runModalForDirectory:openPath file:[integFitFile stringValue]];
  if (result == NSOKButton) {
    [openPath release];
    openPath = [[savePanel directory] retain];
		[integFitFile setStringValue:[[savePanel filename] lastPathComponent]];
    [dataProcessor saveFitFile:[savePanel filename]];
  }
}

/***
*
* Generic Tool 
*
***/
- (void)getParams
{
  viewInd = [dataProcessor getViewInd];
  if ([toolMaster numberChannels] == 0) {
    
  }
  else {
    switch (viewInd) {
      case 1: //add-del peaks
        //handled by tableview code
      case 2: //integrate
        [dataProcessor setOptimizeFlag:[optimizeID state]];
      case 0:
      default:
        [self updateInit];
        break;
    }
  }
	
	[dataProcessor setController:self];

  [super getParams];
}

- (void)displayParams
{
	viewInd = [dataProcessor getViewInd];
	if ([toolMaster numberChannels] == 0) {
		[[addDelID cellAtRow:0 column:0] setEnabled:NO];
		[[addDelID cellAtRow:0 column:1] setEnabled:NO];
		if (previousView != nil)
			[previousView setContentView:[accessoryView contentView]];
		[accessoryView setContentView:[blankView contentView]];
		previousView = blankView;
		[accessoryView display];		
	}
	else {
    if ([dataProcessor getFilePath] != nil) {
      [[viewButtons cellAtRow:0 column:1] setEnabled:YES];
      [[viewButtons cellAtRow:0 column:2] setEnabled:YES];
    }    
		[[viewButtons cellAtRow:0 column:0] setEnabled:YES];
		switch (viewInd) {
			case 1:
				[self modifyAddDel:self];
				break;
			case 2:
				[self integrateData:self];
				break;
			case 0:
			default:
				[self initData:self];
				break;
		}
	}
  [super displayParams];
}

- (void)resetParams
{
	[[viewButtons cellAtRow:0 column:1] setEnabled:NO];
	[[viewButtons cellAtRow:0 column:2] setEnabled:NO];
  [[addDelID cellAtRow:0 column:0] setEnabled:NO];
	[[addDelID cellAtRow:0 column:1] setEnabled:NO];
  [dataProcessor releaseMem];
  [dataProcessor initAgain];
  [super resetParams];
}

- (void)inspectorDidDisplay
{
  if ([toolMaster pointStorageID] == nil) return;
  [toolMaster registerForEventNotification:self];
	[super inspectorDidDisplay];
}

- (BOOL)inspectorWillUndisplay
{
	if ([super inspectorWillUndisplay]) {
		[toolMaster deregisterForEventNotification:self];
		return YES;
	}
	return NO;
}

- (void)mouseEvent:(range)theRange
{	
	int offset;
	
	offset = [[toolMaster pointStorageID] deleteOffset];
	if (viewInd == 0) {
		if (theRange.start != theRange.end && (theRange.end - theRange.start != 1)) {
			[dataProcessor setRange:(theRange.start+offset) :(theRange.end+offset)];
			[rangeFromID setIntValue:(theRange.start+offset)];
			[rangeToID setIntValue:(theRange.end+offset)];
		}
	}
}

-(void)dealloc
{
	if (openPath != nil) 
    [openPath release];
	[super dealloc];
}

@end
