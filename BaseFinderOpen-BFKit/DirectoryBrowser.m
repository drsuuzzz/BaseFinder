/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, Lloyd Smith, and David Finton

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


#import "DirectoryBrowser.h"

@implementation DirectoryBrowser

- init
{  
  [super init];
  lastSavePath = [NSHomeDirectory() retain];
  namesInCurrentColumn = [[NSMutableArray array] retain];
#ifdef WIN32
  rootDirectory = [[NSString stringWithCString:"C:"] retain];
#else
  rootDirectory = [[NSString string] retain];
#endif
  currentPath = [[NSString stringWithCString:"/"] retain];
  return self;
}

- (int)runModal
{
  return [self runModalForDirectory:lastSavePath];
}

- (int)runModalForDirectory:(NSString *)path
{
  int result;

  if (!theBrowser) {
    [NSBundle loadNibNamed:@"DirectoryBrowser.nib" owner:self];
#ifndef WIN32
    [driveBox removeFromSuperview];  //don't need in OpenStep
    drivePopUp = nil;
#endif
    [theBrowser setDelegate:self];
    [theBrowser loadColumnZero];
    [theBrowser setTitle:@"/" ofColumn:0];
    [theBrowser setTarget:self];
    [theBrowser setDoubleAction:@selector(ok:)];
    [drivePopUp selectItemWithTitle:[rootDirectory uppercaseString]];
  }
  if (oldAccessoryView != accessoryView) {
    [self loadAccessoryView:accessoryView];
    oldAccessoryView = accessoryView;
  }
  [theBrowser setPath:path];
  result = [NSApp runModalForWindow:thePanel];
  [thePanel orderOut:self];
  return result;
}

- (void)ok:sender
{
  NSString *mainPath;
  NSString *lastElement;

  mainPath = [rootDirectory stringByAppendingString:[theBrowser path]];
  lastElement = [theTextField stringValue];
  if (lastSavePath)
    [lastSavePath release];
  if (![lastElement isEqualToString:@""])
    lastSavePath = [[mainPath stringByAppendingPathComponent: lastElement]
                    retain];
  else
    lastSavePath = [mainPath copy];

  [NSApp stopModalWithCode:NSOKButton];
}

- (void)cancel:sender
{
  [NSApp abortModal];
}

- (void)goHome:sender
{
  [self setDirectory:NSHomeDirectory()];
}

- (void)changeDir:sender
{
  //resets dir to path typed
  NSString       *tempPath, *selectedPath;
  NSFileManager  *fileManager = [NSFileManager defaultManager];
  char           filePath[33];
  BOOL           isWindows=NO, matched=NO;

#ifdef WIN32
  isWindows = YES;
#endif

  tempPath = [theTextField stringValue];
  //First test if reference to a root directory
  strncpy(filePath, [tempPath fileSystemRepresentation], 32);
  if(isWindows) {
    if(isalpha(filePath[0]) && (filePath[1] == ':')) {
      filePath[2] = '\\';
      filePath[3] = '\0';
      if([fileManager fileExistsAtPath:[NSString stringWithCString:filePath]]) { //check for root drive
        [rootDirectory release];
        filePath[2] = '\0';
        rootDirectory = [[NSString stringWithCString:filePath] retain];
        [drivePopUp selectItemWithTitle:[rootDirectory uppercaseString]];
        if([fileManager fileExistsAtPath:tempPath]) { //next check for full path
          selectedPath = [tempPath retain];
        } else {
          selectedPath = [[NSString stringWithCString:"/"] retain];
        }
        [theBrowser loadColumnZero];
        //[theBrowser setPath:selectedPath];
        [selectedPath release];
        matched = YES;
      }
    }
  } else {
    //Unix or Rhapsody
    if(filePath[0] == '/') {
      [rootDirectory release];
      rootDirectory = [[NSString string] retain];
      if([fileManager fileExistsAtPath:tempPath]) {
        [theBrowser loadColumnZero];
        [theBrowser setPath:tempPath];
        matched = YES;
      }
    }
  }

  if(!matched) {
    //didn't look like a reference to a root directory, so now try appending to existing path
    tempPath = [currentPath stringByAppendingPathComponent:[theTextField stringValue]];
    if([fileManager fileExistsAtPath:[rootDirectory stringByAppendingString:tempPath]]) {
      //[theBrowser loadColumnZero];
      [theBrowser setPath:tempPath];
    }
  }

  [theTextField setStringValue:@""];
  [[theTextField window] makeFirstResponder:theTextField];
}

- (void)changeDrive:sender
{
  NSString       *driveName;
  NSFileManager  *fileManager = [NSFileManager defaultManager];

  driveName = [[drivePopUp titleOfSelectedItem] stringByAppendingString:@"/"];
  if([fileManager fileExistsAtPath:driveName]) { //check for root drive
    [rootDirectory release];
    rootDirectory = [[drivePopUp titleOfSelectedItem] retain];
  } else {
      [drivePopUp selectItemWithTitle:[rootDirectory uppercaseString]];
  }
  [theBrowser loadColumnZero];
}

- (void)setDirectory:(NSString *)directory
{
  [theBrowser setPath: directory];
}

- (NSString *)directory
{
  return lastSavePath;
}

- (void)showSelf
{
  [thePanel makeKeyAndOrderFront:self];
}

- (void)setAccessoryView:(NSView *)aView
{
  accessoryView = aView;
}

- (void)loadAccessoryView:(NSView *)aView
{
  id contentView = [thePanel contentView];
  unsigned int oldBrowserMask;
  NSSize size;
  int offset;
  NSSize minSize;
  NSRect aViewFrame = [aView frame];
  NSPoint newOrigin;
  int oldAVHeight;

  [oldAccessoryView removeFromSuperview];

  oldBrowserMask = [theBrowser autoresizingMask];
  [theBrowser setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];

  oldAVHeight = accessoryViewHeight; // from the oldAccessoryView
  accessoryViewHeight = aViewFrame.size.height;
  offset = accessoryViewHeight - oldAVHeight;
  size = [contentView frame].size;
  size.height += offset;
  [thePanel setContentSize:size]; // lengthen the window

  minSize.width = 310;
  minSize.height = 280 + accessoryViewHeight;
  [thePanel setMinSize:minSize];

  // reposition aView within its frame so that it will be just above the text field
  newOrigin.x = 6;
  newOrigin.y = 85;
  [aView setFrameOrigin:newOrigin];

  [aView setAutoresizingMask:
         (NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin)];
  [contentView addSubview:aView positioned:NSWindowBelow relativeTo:theBrowser];

  [theBrowser setAutoresizingMask:oldBrowserMask]; // restore flexible length on browser
}

int dirSort(id string1, id string2, void *context)
{
  const char *start1, *start2;

  start1 = [string1 cString];
  start2 = [string2 cString];
  if (*start1 == '.' && *start2 != '.')
    return NSOrderedDescending;
  else if (*start1 != '.' && *start2 == '.')
    return NSOrderedAscending;
  else
    return [string1 compare:string2
                    options:NSCaseInsensitiveSearch];
}

/* Delegate methods for the browser object --------------------------------- */

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *thePath, *tempPath;
  NSArray *tempNames;
  int i;
  BOOL isDir;
  
  lastFilledColumn = column;

  if (currentPath) [currentPath release];
  thePath = [rootDirectory stringByAppendingString:[sender pathToColumn:column]];
  if(column==0 || ![fileManager fileExistsAtPath:thePath]) {
    thePath = [rootDirectory stringByAppendingString:@"/"];
    if(![fileManager fileExistsAtPath:thePath])
      thePath = [[NSString stringWithCString:"/"] retain];
    currentPath = [[NSString stringWithCString:"/"] retain];    
    //thePath = [NSString stringWithString:NSOpenStepRootDirectory()];
  } else
    currentPath = [[sender pathToColumn:column] retain];
  
  if (column != 0) // not "/", where lastPathComponent is empty string
    [theBrowser setTitle:[currentPath lastPathComponent] ofColumn:column];
  
  if ([namesInCurrentColumn count] > 0)
    [namesInCurrentColumn removeAllObjects];
  
  tempNames = [[[fileManager directoryContentsAtPath:thePath] sortedArrayUsingFunction:dirSort context:NULL] copy];

  // Filter out names which are not directories
  for (i = 0; i < [tempNames count]; i++) {
    isDir = NO;
    tempPath = [thePath stringByAppendingPathComponent:
                           [tempNames objectAtIndex:i]];
    if ([fileManager fileExistsAtPath:tempPath
                          isDirectory:&isDir] && isDir)
      [namesInCurrentColumn addObject:[tempNames objectAtIndex:i]];
  }

  return [namesInCurrentColumn count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell
          atRow:(int)row column:(int)column
//  Notifies the delegate before the NSBrowser displays the specified cell at row in column. This delegate
//  method is responsible for setting any state necessary for the correct display of the cell.
//  Assume that browser:numberOfRowsInColumn has set col # and names
{
  NSFileManager           *fileManager = [NSFileManager defaultManager];
  NSString *aName;
  NSString *truePath;
  BOOL isDir = NO;

  if (column != lastFilledColumn) // namesInCurrentColumn is stale
    [self browser:sender numberOfRowsInColumn:column];

  aName = [namesInCurrentColumn objectAtIndex:row];
  [cell setStringValue: aName];

  truePath = [rootDirectory stringByAppendingString:[currentPath stringByAppendingPathComponent:aName]];
  [fileManager fileExistsAtPath:truePath isDirectory:&isDir]; 
  if (isDir)
    [cell setLeaf:NO];
  else
    [cell setLeaf:YES];
}

/*---------- Delegate method for thePanel, to set number of columns in theBrowser ----------*/
- (void)windowDidResize:(NSNotification *)aNotification
{
  NSRect frame;
  int width;
  int numCols;

  if ([aNotification object] == thePanel) {
    frame = [[thePanel contentView] frame];
    width = frame.size.width;
    numCols = ((width - 10) / 200) + 1;
    [theBrowser setMaxVisibleColumns:numCols];
  }
}

@end
