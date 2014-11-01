/* "$Id: ResourceToolCtrl.m,v 1.3 2008/04/15 20:53:12 smvasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, Lloyd Smith and Mike Koehrsen

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

#import "ResourceToolCtrl.h"
#import "ResourceTool.h"
#import <GeneKit/AsciiArchiver.h>
#import <ctype.h>

/*****
* Oct 22, 1996 Jessica Severin
*  Finished initial conversion to OpenStep
*
* Jan. 10, 1995
* Changed so resource source  matrix disables "public" option if the
* public directory doesn't exist and can't be created
*
* July 19, 1994 Mike Koehrsen
* Split ResourceTool class into ResourceTool and ResourceToolCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
* Also fixed some minor bugs relating to showing of params loaded from script:
* in some cases the resource pop-up was getting messed up, and the location
* of the resource file (public or private) was not being stored.
*****/


@implementation ResourceToolCtrl

- (void)appWillInit
{
  [self setToDefault];

  [super appWillInit]; // includes displayParams

  [resourceMenuButton setAction:@selector(selectResource:)];
  [resourceMenuButton setTarget:self];

  [newButton setTarget:self];

  [newButton setAction:@selector(newDoneSwitch:)];
  [removeButton setTarget:self];
  [removeButton setAction:@selector(removeResource:)];
  [resourceLabelID setTarget:self];
  [resourceLabelID setAction:@selector(changeLabel:)];
  [resourceSourceID setTarget:self];
  [resourceSourceID setAction:@selector(getResourceList:)];

  [resourceSourceID selectCellAtRow:0 column:0];

  // test public resource directory, and
  // disable that cell if it doesn't exist
  // and can't be created
  //  Assuming that the private directory can always be created,
  // since it's in the user's home directory
  [resourceSourceID selectCellAtRow:0 column:0];
  if (![self resourcePath]) {
    [[resourceSourceID cellAtRow:0 column:0] setEnabled:NO];
    [resourceSourceID selectCellAtRow:1 column:0];
  }
  [self loadResourceList];

  lastUntitledNum = 1;
}

- setToDefault
{
  if (!makingNew)
    [[dataProcessor currentLabel] setString:[dataProcessor defaultLabel]];
  return self;
}

- (NSString *)resourcePath
{
  NSString *oldDir, *resourcePath;
  NSFileManager *filemanager;

  filemanager = [NSFileManager defaultManager];
  oldDir = [filemanager currentDirectoryPath];
  if ([resourceSourceID selectedRow]==0) {
    resourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects:
      NSOpenStepRootDirectory(), @"Library", @"BaseFinder", [self resourceSubdir], nil]];
  } else {
    resourcePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/BaseFinder"] stringByAppendingPathComponent:[self resourceSubdir]];
  }
  /* Added by MCG in case directory doesn't exist */
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];

  [filemanager changeCurrentDirectoryPath:oldDir];	
  return resourcePath;
}


// must be overridden; e.g., "Matrixes", "Mobilities"
- (NSString *)resourceSubdir
{
  return @"";
}

- (void)loadResourceList
{
  NSFileManager *filemanager;
  NSString *path, *file;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;
  NSArray           *itemTitles;
  int               x, numRows;

  [dataProcessor setResourceSource:(short)[resourceSourceID selectedRow]];

  [resourceMenuButton removeAllItems];
  [resourceMenuButton addItemWithTitle:[dataProcessor defaultLabel]];

  filemanager = [NSFileManager defaultManager];

  path = [self resourcePath];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
    return;
  contents = [filemanager directoryContentsAtPath:path];
  enumerator = [contents objectEnumerator];
  while ((file = [enumerator nextObject])) {
    numRows = [resourceMenuButton numberOfItems];
    itemTitles = [resourceMenuButton itemTitles];
    for(x=1; ((x<numRows) && ([file caseInsensitiveCompare:[itemTitles objectAtIndex:x]] == NSOrderedDescending)); x++);
    [resourceMenuButton insertItemWithTitle:file atIndex:x];
  }
  //[resourceMenuButton sizeToFit];
}

- (void)getResourceList:sender
{
  [self setToDefault];
  [self loadResourceList];
  [self displayParams];
}

- (void)newUntitledLabel:(BOOL)display
{
  int              rtnIndex;
  BOOL             found = NO;

  while (!found) {
    [[dataProcessor currentLabel] setString:
      [NSString stringWithFormat:@"Untitled-%d", ++lastUntitledNum]];
    rtnIndex = [resourceMenuButton indexOfItemWithTitle:[dataProcessor currentLabel]];
    if(rtnIndex == -1) found=YES;
  }

  if (display) {
    [resourceMenuButton setTitle:[dataProcessor currentLabel]];
    [resourceLabelID setStringValue:[dataProcessor currentLabel]];
  }
}	

- (void)displayParams
{
  NSString   *label = [dataProcessor currentLabel];

  [resourceLabelID setStringValue:label];
  [resourceSourceID selectCellAtRow:[dataProcessor resourceSource] column:0];
  if ([resourceMenuButton indexOfItemWithTitle:label]<0)
    label = [dataProcessor defaultLabel];
  [resourceMenuButton setTitle:label];

  [super displayParams];
}		

- (BOOL)checkIfResourceIsAvailable
{
  //too check the situation when a script has loaded this tool, but the resource
  //is not available.  Correct resource list is already loaded because the
  //-setDataProcessor method was previously called.
  if ([resourceMenuButton indexOfItemWithTitle:[dataProcessor currentLabel]]<0)
    return NO;
  return YES;
}

- (void)createResourceFromDataProcessor
{
  //situation where tool was loaded from script and resource not available.
  if([self checkIfResourceIsAvailable]) return;
  [self saveResource:[dataProcessor currentLabel]];
  [self loadResourceList];
  [self displayParams];
}

- (void)setDataProcessor:newProcessor
{
  if ([newProcessor resourceSource]!=[dataProcessor resourceSource]) {
    [resourceSourceID selectCellAtRow:[newProcessor resourceSource] column:0];
    [self loadResourceList];
  }
	[super setDataProcessor:newProcessor];
}

- (void)changeLabel:sender
{	
  NSMutableString  *oldLabel;
  NSFileManager    *filemanager;

  // if current resource is default, can't change label
  if ([[dataProcessor currentLabel] isEqualToString:[dataProcessor defaultLabel]]) {
    [resourceLabelID setStringValue:[dataProcessor defaultLabel]];
    NSBeep();
    return;
  }

  // Don't let user change name to something already present in pop-up
  if ([resourceMenuButton indexOfItemWithTitle:[resourceLabelID stringValue]] >= 0) {
    [resourceLabelID setStringValue:[dataProcessor currentLabel]];
    NSBeep();
    return;
  }

  oldLabel = [[dataProcessor currentLabel] mutableCopy];
  [[dataProcessor currentLabel] setString:[resourceLabelID stringValue]];

  filemanager = [NSFileManager defaultManager];
  [filemanager movePath:[[self resourcePath] stringByAppendingPathComponent:oldLabel]
                 toPath:[[self resourcePath] stringByAppendingPathComponent:[dataProcessor currentLabel]]
                handler:nil];

  [self loadResourceList];
  [self displayParams];
}

- (void)startNew
{

}

- (void)finishNew
{

}

- (void)saveResource:(NSString *)name
{
  NSString   *resourcePath;

  if([name isEqualToString:[dataProcessor defaultLabel]]) {
    return;
  }
  resourcePath = [[self resourcePath] stringByAppendingPathComponent:name];
  [dataProcessor writeResource:resourcePath];
}

- loadResource:(NSString *)name
{
  NSString      *resourcePath;
  NSFileManager *filemanager;

  if([name isEqualToString:[dataProcessor defaultLabel]]) {
    [self setToDefault];
    return self;
  }
  filemanager = [NSFileManager defaultManager];
  resourcePath = [[self resourcePath] stringByAppendingPathComponent:name];

  NS_DURING
    [dataProcessor readResource:resourcePath];
  NS_HANDLER
    int  result;
    NSLog(@"error during readResource %@", localException);
    result = NSRunAlertPanel(@"Error loading resource", @"%@", @"Delete", @"Leave alone", nil, [localException  reason]);
    switch(result) {
      case NSAlertDefaultReturn:
        NSLog(@"delete resource '%@'", name);
        [resourceMenuButton removeItemWithTitle:name];
        [filemanager removeFileAtPath:resourcePath handler:nil];
        [self setToDefault];
        [self displayParams];
        break;
      case NSAlertAlternateReturn:
        NSLog(@"leave resource alone");
        break;
      case NSAlertOtherReturn:
        break;
    }
    NS_ENDHANDLER

    return self;
}

- (void)replaceResource:sender
{
  if ([[dataProcessor currentLabel] isEqualToString:[dataProcessor defaultLabel]]) {
    [[self loadResource:[dataProcessor currentLabel]] displayParams];
    return;
  }

  [self getParams];

  [self saveResource:[dataProcessor currentLabel]];
}


- (void)selectResource:sender
{
  NSMutableString    *currentLabel;

  currentLabel=[dataProcessor currentLabel];
  [currentLabel setString:[resourceMenuButton titleOfSelectedItem]];

  [resourceLabelID setStringValue:currentLabel];
  [[self loadResource:currentLabel] displayParams];
}

- (void)removeResource:sender
{
  NSString           *alertMsg, *oldLabel;
  NSFileManager *filemanager;

  if ([[dataProcessor currentLabel] isEqualToString:[dataProcessor defaultLabel]])
    return;

  alertMsg = [NSString stringWithFormat:@"Really remove %@?",[dataProcessor currentLabel]];
#ifdef SHAPEFINDER
  if (NSRunAlertPanel(@"ShapeFinder", alertMsg, @"Yes", @"No", nil)!=NSAlertDefaultReturn)
    return;
#else
  if (NSRunAlertPanel(@"BaseFinder", alertMsg, @"Yes", @"No", nil)!=NSAlertDefaultReturn)
    return;
#endif
  oldLabel = [[dataProcessor currentLabel] copy];
  [self selectResource:resourceMenuButton];
  [[self setToDefault] displayParams];

  [resourceMenuButton removeItemWithTitle:oldLabel];

  filemanager = [NSFileManager defaultManager];
  [filemanager removeFileAtPath:[[self resourcePath] stringByAppendingString:oldLabel] handler:nil];
}

- (void)newDoneSwitch:sender
{
  /* I need to figure this one out
  if(!GSeqEdit) {
    [sender setState:0];
    return;
  }
   */

  if ([sender state]) {
    makingNew = YES;
		
    [self newUntitledLabel:YES];
    [removeButton setEnabled:NO];
    [resourceLabelID setEnabled:NO];
    [resourceMenuButton setEnabled:NO];
    [resourceSourceID setEnabled:NO];
    [[self loadResource:[dataProcessor defaultLabel]] displayParams];

    [self startNew];
  } else {
    [self finishNew];
    makingNew = NO;
    [removeButton setEnabled:YES];
    [resourceLabelID setEnabled:YES];
    [resourceMenuButton setEnabled:YES];
    [resourceSourceID setEnabled:YES];
    [self getParams];
    [self saveResource:[dataProcessor currentLabel]];
  }
}

- (void)cancelNew
{
  makingNew = NO;

  [resourceMenuButton removeItemWithTitle:[dataProcessor currentLabel]];
  [newButton setState:0];
  [removeButton setEnabled:YES];
  [resourceLabelID setEnabled:YES];
  [resourceMenuButton setEnabled:YES];

  [[dataProcessor currentLabel] setString:[dataProcessor defaultLabel]];
  [resourceMenuButton setTitle:[dataProcessor currentLabel]];
  [[self setToDefault] displayParams];
}

- (BOOL)inspectorWillUndisplay
{
  if (makingNew) {
    return NO;
  }

  return [super inspectorWillUndisplay];
}

@end
