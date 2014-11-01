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
NIH Cystic Fibrosis


******************************************************************/

#import "ToolTRFLPCtrl.h"
#import "ToolTRFLP.h"

@implementation ToolTRFLPCtrl

- init
{	
	NSUserDefaults	*myDefaults;
	NSDictionary		*defaultsDict=[NSDictionary dictionaryWithObjectsAndKeys:
																@"20.0",@"trflp-cut1",
																@"20.0",@"trflp-cut2",nil];
  [super init];
  
  openPath = [NSHomeDirectory() retain];
	
	myDefaults = [NSUserDefaults standardUserDefaults];
	[myDefaults registerDefaults:defaultsDict];
	[myDefaults synchronize];
	
  return self;
}

- (void)awakeFromNib
{
	NSString	*tempS, *tempS2;
	float			tempThresh[2];
	int				tstate;
	
	tempS2 = [dataProcessor getTheData:tempThresh :&tstate];
	tempThresh[0] = [[[NSUserDefaults standardUserDefaults] objectForKey:@"trflp-cut1"] floatValue];
	tempThresh[1] = [[[NSUserDefaults standardUserDefaults] objectForKey:@"trflp-cut2"] floatValue];
	tempS = [NSString stringWithFormat:@"%7.3f",tempThresh[0]];
  [[thresholdID cellAtIndex:0] setStringValue:tempS];
	tempS = [NSString stringWithFormat:@"%7.3f",tempThresh[1]];
	[[thresholdID cellAtIndex:1] setStringValue:tempS];	
	[dataProcessor setTheData:tempS2 :tempThresh :tstate];
}

- (void)getParams
{
  NSString *markerType;
  float    threshold[2];
	NSUserDefaults	*myDefaults=[NSUserDefaults standardUserDefaults];
  
  markerType = [standardID objectValueOfSelectedItem];
  
  threshold[0] = [[thresholdID cellAtIndex:0] floatValue];
	threshold[1] = [[thresholdID cellAtIndex:1] floatValue];
	if ((threshold[0] <=0) || (threshold[1] <= 0)) {
		threshold[0] = 20.0;
		threshold[1] = 20.0;
	}
	
	[myDefaults setFloat:threshold[0] forKey:@"trflp-cut1"];
	[myDefaults setFloat:threshold[1] forKey:@"trflp-cut2"];
	
	[dataProcessor setTheData:markerType :threshold :[primerID state]];
  
	[dataProcessor saveOutFile:[outputFileID stringValue]];
  	
  [super getParams];
}

- (void)displayParams
{
  NSString  *outString, *standard, *tempString;
	float			tempThresh[2];
	int				pstate;
  
	standard = [dataProcessor getTheData:tempThresh :&pstate];
 	outString = [dataProcessor getOutFile];
  if (outString == nil) {
    [outputFileID setStringValue:[openPath stringByAppendingPathComponent:@"output.txt"]];
  }
  else
    [outputFileID setStringValue:outString];
	
  if (standard != nil) {
    [standardID selectItemWithObjectValue:standard];
    [standardID setStringValue:standard];
  }
  else {
    [standardID selectItemWithObjectValue:@"Custom"];
    [standardID setStringValue:@"Custom"];
  }
  
	tempString = [NSString stringWithFormat:@"%7.3f",tempThresh[0]];
  [[thresholdID cellAtIndex:0] setStringValue:tempString];
	tempString = [NSString stringWithFormat:@"%7.3f",tempThresh[1]];
	[[thresholdID cellAtIndex:1] setStringValue:tempString];


	[primerID setState:pstate];
	
  [super displayParams];
}

-(void)saveOutFile:sender
{
  NSSavePanel		*savePanel;
	int						result;
  NSString      *tempPath;
  
  savePanel = [NSSavePanel savePanel];
  //[savePanel setAllowsSelection:YES];
	[savePanel setDelegate:self];
	[savePanel setTitle:@"Save Peaks and Areas file"];
  if ([dataProcessor getOutFile] != nil) {
    tempPath = [[dataProcessor getOutFile] stringByDeletingLastPathComponent];
    if (![openPath isEqualTo:tempPath]) {
      [openPath release];
      openPath = [tempPath copy];
    }    
  }  
	result = [savePanel runModalForDirectory:openPath file:[[outputFileID stringValue] lastPathComponent]];
  if (result == NSOKButton) {
    [openPath release];
    openPath = [[savePanel directory] retain];
		[outputFileID setStringValue:[savePanel filename]];
    [dataProcessor saveOutFile:[savePanel filename]];
  }
  
}

-(void)dealloc
{
  if (openPath != nil)
    [openPath release];
  [super dealloc];
}

@end
