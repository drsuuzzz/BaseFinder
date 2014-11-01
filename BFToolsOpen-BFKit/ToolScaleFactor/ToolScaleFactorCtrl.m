/***********************************************************

Copyright (c) 2005 Suzy Vasa 

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

#import "ToolScaleFactorCtrl.h"
#import "ToolScaleFactor.h"
#import "GeneKit/Trace.h"

@implementation ToolScaleFactorCtrl

- init
{	
  ToolScaleFactor				*procStruct;
	NSUserDefaults				*myDefaults;
  NSDictionary    *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
																		@"1", @"Channel 1",
																		@"1", @"Channel 2",
																		@"1", @"Channel 3",
																		@"1", @"Channel 4",
																		@"1", @"Channel 5",
																		@"1", @"Channel 6",
																		@"1", @"Channel 7",
																		@"1", @"Channel 8",
																		nil];

  [super init];
	myDefaults = [NSUserDefaults standardUserDefaults];
	[myDefaults registerDefaults:defaultsDict];
	[myDefaults synchronize];

  procStruct = (ToolScaleFactor *)dataProcessor;

  procStruct->sfactor[0] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 1"] cString]);
	procStruct->sfactor[1] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 2"] cString]);
  procStruct->sfactor[2] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 3"] cString]);
  procStruct->sfactor[3] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 4"] cString]);
  procStruct->sfactor[4] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 5"] cString]);
  procStruct->sfactor[5] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 6"] cString]);
  procStruct->sfactor[6] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 7"] cString]);
  procStruct->sfactor[7] = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"Channel 8"] cString]);
  return self;
}

- (void)getParams
{
  ToolScaleFactor *procStruct = (ToolScaleFactor *)dataProcessor;	
  char 	C1[255], C2[255], C3[255], C4[255], C5[255], C6[255], C7[255], C8[255];
	int i;

	for (i=0; i < 8; i++)
	{
		procStruct->sfactor[i] = [[scaleformID cellAtIndex:i] floatValue];
		if (procStruct->sfactor[i] <= 0) 
		{
			procStruct->sfactor[i] = 1;
			[[scaleformID cellAtIndex:i] setFloatValue:1];
		}
	}

  sprintf(C1, "%f", procStruct->sfactor[0]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C1]
                                            forKey:@"Channel 1"];

  sprintf(C2, "%f", procStruct->sfactor[1]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C2]
                                            forKey:@"Channel 2"];

  sprintf(C3, "%f", procStruct->sfactor[2]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C3]
                                            forKey:@"Channel 3"];
																						
  sprintf(C4, "%f", procStruct->sfactor[3]);
	[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C4]
                                            forKey:@"Channel 4"];

  sprintf(C5, "%f", procStruct->sfactor[4]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C5]
                                            forKey:@"Channel 5"];

  sprintf(C6, "%f", procStruct->sfactor[5]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C6]
                                            forKey:@"Channel 6"];

	sprintf(C7, "%f", procStruct->sfactor[6]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C7]
                                            forKey:@"Channel 7"];

  sprintf(C8, "%f", procStruct->sfactor[7]);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:C8]
                                            forKey:@"Channel 8"];

  [super getParams];
}

- (void)displayParams
{
  ToolScaleFactor *procStruct = (ToolScaleFactor *)dataProcessor;	
	int i, numChannels;
	
	numChannels = [toolMaster numberChannels];
	for (i=0; i < 8; i++)
	{
		if (procStruct->sfactor[i] <= 0) procStruct->sfactor[i] = 1;
		[[scaleformID cellAtIndex:i] setFloatValue:procStruct->sfactor[i]];
		if (i < numChannels) 
		{
			[[scaleformID cellAtIndex:i] setEnabled:YES];
		}
		else
		{
			[[scaleformID cellAtIndex:i] setEnabled:NO];
		}
	}
	
  [super displayParams];
}

@end
