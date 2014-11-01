/* "$Id: PreferencesObject.m,v 1.5 2007/02/02 14:52:59 smvasa Exp $" */

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

#import "PreferencesObject.h"


@implementation PreferencesObject

- init
{
	NSString *executablePath = [[[NSProcessInfo processInfo] arguments] objectAtIndex:0];
	NSString *appToolsPath = [[[executablePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/Resources/Tools"];
	NSArray *mytoolPaths = [NSArray arrayWithObjects:@"/Library/BaseFinder/Tools", appToolsPath, nil];
	NSArray *myResourcePaths = [NSArray arrayWithObjects:@"/Library/BaseFinder/Tools", nil];

  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"4", @"NumberViews",
    @"1.0", @"ViewPercent",
    @"novice", @"ExpertMode",
    @"same as loaded", @"AutosaveFormat",
    @"NO", @"DebugMode",
    @"NO", @"useForgroundThreading",
    @"YES", @"loadPublicTools",
    @"NO", @"loadPrivateTools",
    mytoolPaths, @"ToolsPaths",
	myResourcePaths, @"ResourcePaths",
    @"2",@"SplitView",
    @"0",@"DataMarker",
		@"1",@"BaseLines",
    nil];

  [super init];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  expertMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"] retain];
  debugmode  = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
  resourcePaths = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"ResourcePaths"]] retain];
  toolPaths = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"ToolPaths"]] retain];

  //[[NSUserDefaults standardUserDefaults] boolForKey:@"useForgroundThreading"];

  return self;
}

- (void)showPreferences:sender
{
  if(prefPanel==nil) {
    [NSBundle loadNibNamed:@"Preferences.nib" owner:self];
  }
  [prefPanel makeKeyAndOrderFront:self];
}

- (void)switchExpertMode:sender
{
  int   level;

  level = [expertModeID selectedRow];
  [expertMode release];
  switch(level) {
    case 0: expertMode = [[NSString stringWithCString:"beginner"] retain]; break;
    case 1: expertMode = [[NSString stringWithCString:"novice"] retain]; break;
    case 2: expertMode = [[NSString stringWithCString:"expert"] retain]; break;
  }
}

- (void)changeDebugMode:sender
{
  debugmode = (BOOL)[debugModeID intValue]; 
}

- (void)setParams:sender
{
  [[NSUserDefaults standardUserDefaults] setObject:expertMode forKey:@"ExpertMode"];

  [[NSUserDefaults standardUserDefaults] setBool:debugmode forKey:@"DebugMode"];
  
  [[NSUserDefaults standardUserDefaults] setBool:[threadingID state]
                                          forKey:@"useForgroundThreading"];

  [[NSUserDefaults standardUserDefaults] setBool:[[toolLoadID cellAtRow:0 column:0] state]
                                          forKey:@"loadPublicTools"];
  [[NSUserDefaults standardUserDefaults] setBool:[[toolLoadID cellAtRow:1 column:0] state]
                                          forKey:@"loadPrivateTools"];
  
  [[NSUserDefaults standardUserDefaults] setObject:toolPaths forKey:@"ToolPaths"];
  [[NSUserDefaults standardUserDefaults] setObject:resourcePaths forKey:@"ResourcePaths"];

//  [prefPanel orderOut:self];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSwitchExpertMode" object:self];
}

- (void)resetPanel:sender
{
  NSArray   *expertTypes = [NSArray arrayWithObjects:@"beginner", @"novice", @"expert", nil];
  int       index;
  
  expertMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"] retain];
  debugmode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];

  [debugModeID setIntValue:(int)debugmode];
  [threadingID setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"useForgroundThreading"]];

  [[toolLoadID cellAtRow:0 column:0] setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"loadPublicTools"]];
  [[toolLoadID cellAtRow:1 column:0] setState:[[NSUserDefaults standardUserDefaults] boolForKey:@"loadPrivateTools"]];

  index = [expertTypes indexOfObject:expertMode];
  if (debugmode)	
    NSLog(@"Preferences set expertMode=%d", index);
  switch(index) {
    case 0: case 1: case 2:
      [expertModeID selectCellAtRow:index column:0];
      break;
    case NSNotFound: default:
      [expertModeID selectCellAtRow:1 column:0];
      break;
  }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
  [self resetPanel:self];
}


- (void)dealloc
{
  [toolPaths release];
	[resourcePaths release];
  [expertMode release];
  
  [super dealloc];


}

- (void)addResourcePath:sender
{
  [resourcePaths addObject:@""];
  [bundleDirs reloadData];

}

- (void)deleteResourcePath:sender
{
  [resourcePaths removeObjectAtIndex:[bundleDirs selectedRow]];
  [bundleDirs reloadData];
}


//Responding to messages for table containing additional resource paths.
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
    id theRecord;
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [resourcePaths count]);
    theRecord = [resourcePaths objectAtIndex:rowIndex];
    return theRecord;
}
- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
//    id theRecord;
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [resourcePaths count]);
//    theRecord = [records objectAtIndex:rowIndex];
    [resourcePaths replaceObjectAtIndex:rowIndex withObject:anObject];
//    [theRecord setObject:anObject forKey:[aTableColumn identifier]];
    return;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [resourcePaths count];
}


@end
