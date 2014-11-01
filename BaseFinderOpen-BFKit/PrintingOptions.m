/* "$Id: PrintingOptions.m,v 1.3 2006/08/04 20:31:26 svasa Exp $" */

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

#import "PrintingOptions.h"

/****
* April 18, 1994: Redid printing options so they appear in the print panel instead of the
* page layout panel. Added an option to print the data range values.  Relinked so Distributor
* can method this object.
****/

@implementation PrintingOptions

+ new
{
  BOOL  rtnVal;
  id tmpself = [[PrintingOptions alloc] init];
  //[tmpself autorelease];      //must come back and fix later, but this fixes crash when canceling print.
  
  rtnVal = [NSBundle loadNibNamed:@"PrintingOptions.nib" owner:tmpself];
  if (debugmode) NSLog(@"PrintingOptions nib=%i", rtnVal);
  //[self prepareToPrint];
  return tmpself;
}

- init
{
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
	   [NSNumber numberWithInt:1], @"LaneCount",
	   [NSNumber numberWithInt:1], @"LaneToUse",
	   @"0", @"PrintFileAsTitle",
	   @"1", @"PrintPointMarks",
	   @"1", @"PrintHeader",
	   @"1", @"PrintDataRange",
	   @"4", @"PrintViewsPerPage",
	   @"0.5", @"PrintViewScale",
		 nil];
	[super init];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
	return self;
}

- (NSView *)accessoryView;
{
  return optionsView;
}

- (void)doPageLayout:sender
{
	id		layout;
	NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];
	
	layout = [NSPageLayout pageLayout];
	[fileAsTitleID setState:(int)atoi([[myDefs objectForKey:@"PrintFileAsTitle"] cString])];
	[pointMarkersID setState:(int)atoi([[myDefs objectForKey:@"PrintPointMarks"] cString])];
	[includeHeaderID setState:(int)atoi([[myDefs objectForKey:@"PrintHeader"] cString])];
	[dataRangeID setState:(int)atoi([[myDefs objectForKey:@"PrintDataRange"] cString])];
	[layout setAccessoryView:optionsView];
	[NSApp runPageLayout:self]; 
}

- (void)prepareToPrint
{
  int              viewsPerPage, scale;
  char             tmpStr[64];
  NSUserDefaults   *myDefs = [NSUserDefaults standardUserDefaults];

  [fileAsTitleID setState:(int)atoi([[myDefs objectForKey:@"PrintFileAsTitle"] cString])];
  [pointMarkersID setState:(int)atoi([[myDefs objectForKey:@"PrintPointMarks"] cString])];
  [includeHeaderID setState:(int)atoi([[myDefs objectForKey:@"PrintHeader"] cString])];
  [dataRangeID setState:(int)atoi([[myDefs objectForKey:@"PrintDataRange"] cString])];
  //[[NSPrintPanel printPanel] setAccessoryView:optionsView];
	
  //below now able to set in the .nib
  //[numViewsID setAction:@selector(switchNumViews:)];
  //[numViewsID setTarget:self];
  //[viewScaleID setAction:@selector(switchViewScale:)];
  //[viewScaleID setTarget:self];

  viewsPerPage = atoi([[myDefs objectForKey:@"PrintViewsPerPage"] cString]);
  [numViewsID selectItemAtIndex:(viewsPerPage-1)];

  scale = (int)(atof([[myDefs objectForKey:@"PrintViewScale"] cString])*100);
  sprintf(tmpStr,"%1d%%",scale);
  if(scale > 0)
    [viewScaleID selectItemWithTitle:[NSString stringWithCString:tmpStr]];
  else
    [viewScaleID selectItemWithTitle:@"Fit to single page"]; 
}

- (void)switchFileAsTitle:sender
{
  char             tmpString[255];
  NSUserDefaults   *myDefs = [NSUserDefaults standardUserDefaults];

  sprintf(tmpString, "%d", [sender state]);
  [myDefs setObject:[NSString stringWithCString:tmpString] forKey:@"PrintFileAsTitle"];
  [myDefs synchronize]; 
}

- (void)switchPointMarkers:sender
{
	NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];

	[myDefs setObject:[NSString stringWithFormat:@"%d", [sender state]] forKey:@"PrintPointMarks"];
	[myDefs synchronize]; 
}

- (void)switchIncludeHeader:sender
{
	char 	tmpString[255];
	NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];

	sprintf(tmpString, "%d", [sender state]);
	[myDefs setObject:[NSString stringWithCString:tmpString] forKey:@"PrintHeader"];
	[myDefs synchronize]; 
}

- (void)switchRangeDisplay:sender
{
	char 	tmpString[255];
	NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];

	sprintf(tmpString, "%d", [sender state]);
	[myDefs setObject:[NSString stringWithCString:tmpString] forKey:@"PrintDataRange"];
	[myDefs synchronize]; 
}

- (void)switchNumViews:sender
{
  char 	          tmpString[255];
  int             viewsPerPage;
  NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];

  viewsPerPage = [numViewsID indexOfSelectedItem]+1;
  sprintf(tmpString, "%d",viewsPerPage);		
  if (debugmode) fprintf(stderr, "print viewsPerPage = %d\n",viewsPerPage);
  [myDefs setObject:[NSString stringWithCString:tmpString] forKey:@"PrintViewsPerPage"];
  [myDefs synchronize];
}

- (void)switchViewScale:sender
{
  float           viewScale=1.0;
  char            tmpString[255];
  NSUserDefaults  *myDefs = [NSUserDefaults standardUserDefaults];

  switch((int)[viewScaleID indexOfSelectedItem]) {    // get matrix of the PopupList
    case 0: viewScale = 2.0; break;
    case 1: viewScale = 1.5; break;
    case 2: viewScale = 1.25; break;
    case 3: viewScale = 1.0; break;
    case 4: viewScale = 0.75; break;
    case 5: viewScale = 0.5; break;
    case 6: viewScale = 0.25; break;
    case 7: viewScale = 0.1; break;
    case 8: viewScale = 0.0; break;	//fit to single page
  }
  sprintf(tmpString, "%f", viewScale);
  if (debugmode) fprintf(stderr, "print viewScale = %f\n",viewScale);
  [myDefs setObject:[NSString stringWithCString:tmpString] forKey:@"PrintViewScale"];
  [myDefs synchronize];
}


@end
