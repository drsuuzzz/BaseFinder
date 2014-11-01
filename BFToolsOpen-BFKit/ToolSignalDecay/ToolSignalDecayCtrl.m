 
/* "$Id: ToolSignalDecayCtrl.m,v 1.8 2008/04/15 20:54:05 smvasa Exp $" */
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
NIH Center for AIDs Research

******************************************************************/

#import "ToolSignalDecayCtrl.h"
#import "ToolSignalDecay.h"

@interface ToolSignalDecayCtrl (Private)
- (void)setupParms;
@end

@implementation ToolSignalDecayCtrl

- init
{
	NSUserDefaults      *myDefaults;
	NSDictionary        *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
																			@"1000", @"Decay-rescale",
																			nil];
	
  [super init];
  myDefaults = [NSUserDefaults standardUserDefaults];
  [myDefaults registerDefaults:defaultsDict];
  [myDefaults synchronize];

  return self;
}

- (void)setupParms
{
	double					temp[3];
	int							scale, i;
	
	scale = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Decay-rescale"] intValue];
	temp[0] = 1000000;
	temp[1] = 0.999;
	temp[2] = 10000;
	[dataProcessor setValues:temp :scale];
	
	[scaleID setIntValue:scale];
	[[coeffsID cellAtIndex:0] setDoubleValue:temp[0]];
	[[coeffsID cellAtIndex:1] setDoubleValue:temp[1]];
	[[coeffsID cellAtIndex:2] setDoubleValue:temp[2]];
	[channelSelID setAllowsEmptySelection:NO];
	[dataProcessor setSelChannels:1 at:0];
	for (i=1; i < [[toolMaster pointStorageID] numChannels]; i++)  {
		[dataProcessor setSelChannels:0 at:i];
	}
	[dataProcessor setNumSelChannels:1];
	[fromID setStringValue:@""];
	[toID setStringValue:@""];
	[dataProcessor setRange:-1 :-1];
}

- (void)awakeFromNib
//Initialize form to always come up as initial values
{
	[self setupParms];
}

- (void)getParams
{
	double	temp[3], old[3];
	int			scale;
	int			from, to;
	NSUserDefaults	*myDefaults=[NSUserDefaults standardUserDefaults];
	
  [super getParams];
	[dataProcessor getValues:old :&scale :&from :&to];
	temp[0] = [[coeffsID cellAtIndex:0] doubleValue];
	temp[1] = [[coeffsID cellAtIndex:1] doubleValue];
	temp[2] = [[coeffsID cellAtIndex:2] doubleValue];		
	scale = [scaleID intValue];
  if(scale < 1) scale=1000;
  [scaleID setIntValue:scale];
	[myDefaults setInteger:scale forKey:@"Decay-rescale"];
	if (temp[0] != old[0] || temp[1] != old[1] || temp[2] != old[2])
		[dataProcessor setValues:temp :scale];
	else {
		temp[0] = 1000000;
		temp[1] = 0.999;
		temp[2] = 10000;
		[dataProcessor setValues:temp :scale];
	}
	from = [fromID intValue];
	to = [toID intValue];
	if (from == 0 || to == 0)
		[dataProcessor setRange:-1 :-1];
	else if ((from < to) && (to < [[toolMaster pointStorageID] length]))
		[dataProcessor setRange:from :to];
	else
		[dataProcessor setRange:-1 :-1];
}

- (void)displayParams
{
	int			scale;
	double	temp[3];
	int			from, to;
	
  [super displayParams];
	[dataProcessor getValues:temp :&scale :&from :&to];
  [scaleID setIntValue:scale];
	[[coeffsID cellAtIndex:0] setDoubleValue:temp[0]];
	[[coeffsID cellAtIndex:1] setDoubleValue:temp[1]];
	[[coeffsID cellAtIndex:2] setDoubleValue:temp[2]];
	if (from != -1 || to != -1) {
		[fromID setIntValue:from];
		[toID setIntValue:to];		
	}
}

- (void)resetParams
{
	[self setupParms];
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
		if (theRange.start != theRange.end && (theRange.end - theRange.start != 1)) {
			[dataProcessor setRange:theRange.start :theRange.end];
			[fromID setIntValue:theRange.start];
			[toID setIntValue:theRange.end];
		}
}

- (void)resetSelChannels
{
  // superclass method enables all channels present in seqEdit
  // this tool uses the SelChannels differently.  It is a radio
  // hence only one can be selected at a time.  Override method
  // to do nothing
  return;
}

@end
