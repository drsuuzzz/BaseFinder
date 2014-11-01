/* "$Id: LaneCountController.m,v 1.2 2006/08/04 20:31:26 svasa Exp $" */

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

#import "LaneCountController.h"
#import <Foundation/NSUserDefaults.h>
#import <AppKit/AppKit.h>
#import <stdlib.h>
#define LC_form	0
#define LTU_form 1

@implementation LaneCountController

- init
{
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
	   [NSNumber numberWithInt:1], @"LaneCount",
	   [NSNumber numberWithInt:1], @"LaneToUse",
		 nil];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
	lanecount = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LaneCount"] intValue];
	lanetouse = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LaneToUse"] intValue];
	[super init];

	paramsSet = NO;
	return self;
}

- (void)setParams:sender
{
	NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];
	
	lanecount = [[lanecountID cellAtIndex:LC_form] intValue];
	lanetouse = [[lanecountID cellAtIndex:LTU_form] intValue];
	
	if(lanecount<1) lanecount=1;
	if(lanetouse > lanecount) lanetouse=lanecount;
	if(lanetouse<1) lanetouse=1;
	
	[myDefs setObject:[NSNumber numberWithInt:lanecount] forKey:@"LaneCount"];
	[myDefs setObject:[NSNumber numberWithInt:lanetouse] forKey:@"LaneToUse"];
	[myDefs synchronize];
	
	[[lanecountID cellAtIndex:LC_form] setIntValue:lanecount];
	[[lanecountID cellAtIndex:LTU_form] setIntValue:lanetouse]; 
}

- (void)cancelSet:sender
{
	[self setWindowParams:self];
	[thePanel orderOut:self];
	[NSApp stopModalWithCode:(int)NO]; 
}

- (void)loadData:sender
{
	[self setParams:self];
	[thePanel orderOut:self];
	[NSApp stopModalWithCode:(int)YES]; 
}

- (void)setWindowParams:sender
{
	[[lanecountID cellAtIndex:LC_form] setIntValue:lanecount];
	[[lanecountID cellAtIndex:LTU_form] setIntValue:lanetouse]; 
}


- (BOOL)showAndWaitCount:(int *)count :(int *)touse
{	BOOL status;
	[thePanel makeKeyAndOrderFront:self];
	status = [NSApp runModalForWindow:thePanel];
	printf("status %d\n",status);
	*count = lanecount;
	*touse = lanetouse;
	return status;
}

- (void)windowDidUpdate:(NSNotification *)notification 
{
  //NSWindow *theWindow = [notification object];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
  //NSWindow *theWindow = [notification object];
  [self setWindowParams:self];
}


@end
