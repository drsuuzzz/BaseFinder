/* "$Id: ToolBaseCallingCtrl.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import "ToolBaseCallingCtrl.h"
#import "ToolBaseCalling.h"
#import "CallingController.h"
//#import "SeqList.h"

#define HIHORDER_form 0
#define W1_form 1
#define W2_form 2
#define W3_form 3
#define CALLQUIT_form 4
#define MAXIT_form 5
#define THROWOUT_form 6
#define FINALOUT_form 7
#define BWIDTH_form 8
#define EWIDTH_form 9
#define SPTOL_form 10

/*****
* July 19, 1994 Mike Koehrsen
* Split ToolBaseCalling class into ToolBaseCalling and ToolBaseCallingCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
******/

@implementation ToolBaseCallingCtrl

- init
{
  ToolBaseCalling *procStruct = (ToolBaseCalling *)dataProcessor;

  NSDictionary     *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"2", @"HighOrder",
    @"0.3",@"FinalOut",
    @"0.9", @"CallQuit",
    @"0.15", @"Throwout",
    @"10", @"MaxIT",
    @"1",@"W1",
    @"1",@"W2",
    @"1",@"W3",
    @"1",@"W4",
    @"2.2",@"BWT",
    @"3.3",@"EWT",
    @"2.0",@"SPT",
    @"0", @"UseBIS",
    @"0", @"BISlane", 
    nil];

  [super init];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  procStruct->finalout = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"FinalOut"] cString]);
  procStruct->callquit = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"CallQuit"] cString]);
  procStruct->throwout = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Throwout"] cString]);
  procStruct->weights[0] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"W1"] cString]);
  procStruct->weights[1] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"W2"] cString]);
  procStruct->weights[2] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"W3"] cString]);
  procStruct->weights[3] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"W4"] cString]);
  procStruct->bwidthtol = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"BWT"] cString]);
  procStruct->ewidthtol = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"EWT"] cString]);
  procStruct->spacetol = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"SPT"] cString]);
  procStruct->maxit = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"MaxIT"] cString]);
  procStruct->highorder = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"HighOrder"] cString]);
  procStruct->useBIS = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"UseBIS"] cString]);
  procStruct->BISlane = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"BISlane"] cString]);
  return self;
}

- (void)getParams
{
	ToolBaseCalling *procStruct = (ToolBaseCalling *)dataProcessor;
	char tmp[255];

	procStruct->finalout = [[paramMatrix cellAtIndex:FINALOUT_form] floatValue];
	procStruct->callquit = [[paramMatrix cellAtIndex:CALLQUIT_form] floatValue];
	procStruct->throwout = [[paramMatrix cellAtIndex:THROWOUT_form] floatValue];
	procStruct->weights[0] = [[paramMatrix cellAtIndex:W1_form] floatValue];
	procStruct->weights[1] = [[paramMatrix cellAtIndex:W2_form] floatValue];
	procStruct->weights[2] = [[paramMatrix cellAtIndex:W3_form] floatValue];
	procStruct->maxit = [[paramMatrix cellAtIndex:MAXIT_form] intValue];
	procStruct->highorder = [[paramMatrix cellAtIndex:HIHORDER_form] intValue];
	procStruct->bwidthtol = [[paramMatrix cellAtIndex:BWIDTH_form] floatValue];
	procStruct->ewidthtol = [[paramMatrix cellAtIndex:EWIDTH_form] floatValue];
	procStruct->spacetol  = [[paramMatrix cellAtIndex:SPTOL_form] floatValue];
	procStruct->useBIS = [useBISID state];
	procStruct->BISlane = [BISlaneID intValue];

	sprintf(tmp, "%f", procStruct->finalout);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"FinalOut"];
	sprintf(tmp, "%f", procStruct->callquit);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"CallQuit"];
	sprintf(tmp, "%f", procStruct->throwout);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"Throwout"];
	sprintf(tmp, "%f", procStruct->weights[0]);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"W1"];
	sprintf(tmp, "%f", procStruct->weights[1]);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"W2"];
	sprintf(tmp, "%f", procStruct->weights[2]);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"W3"];
	sprintf(tmp, "%d", procStruct->maxit);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"MaxIT"];	
	sprintf(tmp, "%d", procStruct->highorder);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"HighOrder"];
	sprintf(tmp, "%f", procStruct->bwidthtol);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"BWT"];
	sprintf(tmp, "%f", procStruct->ewidthtol);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"EWT"];
	sprintf(tmp, "%f", procStruct->spacetol);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"SPT"];	
	sprintf(tmp, "%d", procStruct->useBIS);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"UseBIS"];	
	sprintf(tmp, "%d", procStruct->BISlane);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tmp] forKey:@"BISlane"]; 
}

- (void)displayParams
{
	ToolBaseCalling *procStruct = (ToolBaseCalling *)dataProcessor;
	[[paramMatrix cellAtIndex:MAXIT_form] setIntValue:procStruct->maxit];
	[[paramMatrix cellAtIndex:HIHORDER_form] setIntValue:procStruct->highorder];
	[[paramMatrix cellAtIndex:FINALOUT_form] setFloatValue:procStruct->finalout];
	[[paramMatrix cellAtIndex:CALLQUIT_form] setFloatValue:procStruct->callquit];
	[[paramMatrix cellAtIndex:THROWOUT_form] setFloatValue:procStruct->throwout];
	[[paramMatrix cellAtIndex:W1_form] setFloatValue:procStruct->weights[0]];
	[[paramMatrix cellAtIndex:W2_form] setFloatValue:procStruct->weights[1]];
	[[paramMatrix cellAtIndex:W3_form] setFloatValue:procStruct->weights[2]];
	[[paramMatrix cellAtIndex:BWIDTH_form] setFloatValue:procStruct->bwidthtol];
	[[paramMatrix cellAtIndex:EWIDTH_form] setFloatValue:procStruct->ewidthtol];
	[[paramMatrix cellAtIndex:SPTOL_form] setFloatValue:procStruct->spacetol];
	[useBISID setState:procStruct->useBIS];
	[BISlaneID setIntValue:procStruct->BISlane]; 
}

@end

