/* "$Id: MultiFileManager.m,v 1.6 2008/04/15 20:50:22 smvasa Exp $" */

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

#import "MultiFileManager.h"
#import <GeneKit/StatusController.h>
#import <BaseFinderKit/ScriptScheduler.h>

@interface MultiFileManager (PrivateMultiFileManager)
- (void)makeCellTemplate;
- (void)makeMatrix:(NSRect)frameRect;
- (void)updateView;
- (void)windowIsKey;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)unMiniaturize:(NSNotification *)aNotification;
- (int)lastSelectedRow;
- (void)setDisplayedCells:(NSArray *) selectedFiles;
@end


@implementation MultiFileManager

+ new
{
  MultiFileManager    *newSelf;
  
  newSelf = [super alloc];
  [NSBundle loadNibNamed:@"MultiFileManager.nib" owner:newSelf];

  [newSelf init];

  return newSelf;
}

- init
{
  [super init];
  matrixView=nil;
  loadedFileArray = [[NSMutableArray array] retain];

  [self makeMatrix:[[scrollView contentView] bounds]];
  //[scrollView setBackgroundColor:[[scrollView window] backgroundColor]];
  [scrollView setDocumentView:matrixView];
  [scrollView setAutoresizesSubviews:YES];

  [panel setDelegate:self];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applyScript:)
                                               name:@"BFApplyScriptToAll"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(unMiniaturize:)
                                               name:NSApplicationDidUnhideNotification
                                             object:nil];

 
  [panel setFrameUsingName:@"MultiFilePanel"];
  [panel display];
  [panel setFrameAutosaveName:@"MultiFilePanel"];
  [panel display];
  [panel orderFront:self];
	[panel setLevel:NSFloatingWindowLevel];
	[panel setHidesOnDeactivate:YES];
  [self setupStatusView];

  return self;
}

- (void)dealloc
{
  if(loadedFileArray != nil) [loadedFileArray release];
  
  [cellTemplate release];
  
  [super dealloc];
  
}

- (void)addLanesFile:(LanesFile*)newLanesFile
{
  NSArray   *selectedFiles;

  [loadedFileArray addObject:newLanesFile];
  [loadedFileArray sortUsingSelector:@selector(compareName:)];
  [self updateView]; // deselects all cells
	selectedFiles = [NSArray arrayWithObject:newLanesFile]; //make new file the selectedfile
  [self setDisplayedCells:selectedFiles];
}

- (void)setDisplayedCells:(NSArray *) selectedFiles
{
  BOOL      oneIsSelected = NO;
  int       row;

  [matrixView deselectAllCells];
  for(row=0; row<[matrixView numberOfRows]; row++)
    if([selectedFiles indexOfObject:[loadedFileArray objectAtIndex:row]] != NSNotFound) {
      // This doesn't work, because selectCellAtRow:column deselects
      // previously selected cells!  Need to find a work-around.
      if(!oneIsSelected) {
        [matrixView selectCellAtRow:row column:0];
        oneIsSelected = YES;
      }
      else {
        [matrixView highlightCell:YES atRow:row column:0];
        [matrixView setState:YES atRow:row column:0];
      }
    }
  if ([selectedFiles count] == 0)
    [matrixView selectCellAtRow:0 column:0];
  [matrixView setNeedsDisplay:YES];
}

// our own version of "selectedRow," since the real thing sometimes returns
// -1 when selectedCells returns a non-empty array
- (int) lastSelectedRow
{
  NSArray *selectedCells;
  id theCell = nil;
  int row, col;
  
  selectedCells = [matrixView selectedCells];
  theCell = [selectedCells lastObject];
  if (theCell != nil)
    if ([matrixView getRow:&row column:&col ofCell:theCell])
      return row;
  
  return -1;
}

- (LanesFile*)currentLanesFile;
{
  int        index;
  LanesFile  *current=nil;

  if([[matrixView selectedCells] count] > 1) return nil;

  index = [self lastSelectedRow];
  if((index>=0) && (index < [loadedFileArray count]) && (GSeqEdit != nil))
    current = [loadedFileArray objectAtIndex:index];
  return current;
}

- (NSMutableArray*)selectedLanesFiles;
{
  int              i, j;
  NSMutableArray   *selectedFiles = [NSMutableArray array];
  NSArray          *selectedCells;
  NSString         *tempString;
  LanesFile        *thisLanesFile;

  selectedCells = [matrixView selectedCells];

  for(i=0; i<[selectedCells count]; i++) {
    for(j=0; j<[loadedFileArray count]; j++) {
      thisLanesFile = [loadedFileArray objectAtIndex:j];
      tempString = [[thisLanesFile fileName] lastPathComponent];
      if([tempString isEqualToString:[[selectedCells objectAtIndex:i] title]])
        [selectedFiles addObject:thisLanesFile];
    }
  }
  return selectedFiles;
}

- (NSMutableArray *)allLanesFiles
{
  return loadedFileArray;
}

- (void)showPanel;
{
  [panel orderFront:self];
}


- (void)makeCellTemplate
{
  cellTemplate = [[NSButtonCell alloc] init];
/*  [cellTemplate setFont:[[NSFontManager new] fontWithFamily:@"Helvetica"   traits:NSUnboldFontMask
                                                     weight:0                size:10]]; */
  [cellTemplate setFont:[NSFont userFontOfSize:12]];
//  [cellTemplate setBezelStyle:NSRoundedBezelStyle];
  [cellTemplate setButtonType:NSToggleButton];
  [cellTemplate setBezeled:NO];
  [cellTemplate setBordered:NO];
  [cellTemplate setAlignment:NSLeftTextAlignment];
  [cellTemplate setHighlightsBy:NSChangeGrayCellMask/*NSChangeBackgroundCellMask*/];

//  [cellTemplate setHighlightsBy:NSChangeBackgroundCellMask];
//  [cellTemplate setHighlightsBy:NSPushInCellMask];
}


- (void)makeMatrix:(NSRect)frameRect
{
  NSSize    tempSize;
  int       count=[loadedFileArray count];

  [self makeCellTemplate];
  frameRect.origin.x = 0.0;
  frameRect.origin.y = 0.0;
  matrixView = [[NSMatrix alloc] initWithFrame:frameRect
                                          mode:NSListModeMatrix
                                     prototype:cellTemplate
                                  numberOfRows:count
                               numberOfColumns:1];
  tempSize.width = 0.0;
  tempSize.height = 1.0;
  [matrixView setIntercellSpacing:tempSize];
  [matrixView setBackgroundColor:[[matrixView window] backgroundColor]];
  [matrixView setCellBackgroundColor:[[matrixView window] backgroundColor]];
  tempSize = [cellTemplate cellSize];
  tempSize.width = frameRect.size.width; //\\205.0;
//  tempSize.height = 16;
  [matrixView setCellSize:tempSize];
 // [matrixView setFont:[[NSFontManager new] fontWithFamily:@"Courier" traits:NSUnboldFontMask weight:0 size:12]];
  [matrixView setFont:[NSFont userFontOfSize:12]];

  [matrixView setAutoscroll:YES];
  [matrixView setScrollable:YES];
  [matrixView setAllowsEmptySelection:YES];
  [matrixView setTarget:self];
  [matrixView setAction:@selector(selectFile:)];
  [matrixView setDoubleAction:@selector(selectFile:)];
  [matrixView setAutoresizingMask:(NSViewWidthSizable)];
  [matrixView setAutosizesCells:YES];

//  [matrixView sizeToCells];
}

- (void)updateView
{
  int           i, count = [loadedFileArray count], current=0;
  NSString      *tempString;
  LanesFile     *thisLanesFile;

  [matrixView renewRows:count columns:1];

  if(count > 0) {
    for (i=0;i<count;i++) {
      thisLanesFile = [loadedFileArray objectAtIndex:i];
      if([GSeqEdit dataManager] == thisLanesFile) current=i;
      tempString = [[thisLanesFile fileName] lastPathComponent];
      [[matrixView cellAtRow:i column:0] setTitle:tempString];
    }
//    [matrixView selectCellAtRow:current column:0];
  }
  [matrixView sizeToCells];
  [matrixView setNeedsDisplay:YES];

//  [panel display];
}


- (void)selectFile:sender
{
  int   index;

  if([[matrixView selectedCells] count] > 1) {
    //[GSeqEdit hide:self];    //modified by: Chih Ling Han
    [GSeqEdit setLanesFile:nil];
    [GSeqEdit shouldRedraw];
  }
  else {
    index = [self lastSelectedRow];
    if((index>=0) && (index < [loadedFileArray count]) && (GSeqEdit != nil))
      [GSeqEdit setLanesFile:[loadedFileArray objectAtIndex:index]];
    [GSeqEdit shouldRedraw];
    [GSeqEdit show:self];
  }
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  [matrixView highlightCell:YES atRow:[matrixView selectedRow] column:0];
}


/******
*
*  event handling section
*
*******/

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
  if (debugmode) NSLog(@"MultiFilePanel is key now");
  if(![panel makeFirstResponder:self])
    if (debugmode) NSLog(@"MultiFilePanel could not become first responder");
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
  [NSApp hide:self];
}

- (void)unMiniaturize:(NSNotification *)aNotification;
{
  NSLog(@"unhide");
  [panel makeKeyAndOrderFront:self];
}

- (BOOL)needToSaveAlert:(LanesFile*)thisLanesFile
{
  int  result;

  result = NSRunAlertPanel(@"Close", @"Save changes to %@", @"Save", @"Don't Save", @"Cancel",
                           [[thisLanesFile fileName] lastPathComponent]);
  switch(result) {
    case NSAlertDefaultReturn:  //Save
      NSLog(@"Saving");
      //save to format it was loaded from. If save to that format is not supported
      //it will save to SCF
      [thisLanesFile saveCurrentToDefaultFormat];  
      break;
    case NSAlertAlternateReturn:  //Close and Don't Save
      NSLog(@"Don't save");
      break;
    case NSAlertOtherReturn:  //Cancel close operation
      NSLog(@"cancel");
      return NO;  //causes loop to cancel
      break;
    case NSAlertErrorReturn:
      NSLog(@"error during NSRunAlertPanel");
      break;
  }
  return YES;  //loop continues
}

- (void)closeActiveFile:sender
{
  int              i, index, newRowIndex=-1;
  NSMutableArray   *selectedFiles = [self selectedLanesFiles];
  LanesFile        *thisLanesFile;

  NSLog(@"  close selected files");
  for(i=0; i<[selectedFiles count]; i++) {
    thisLanesFile = [selectedFiles objectAtIndex:i];
    if([[thisLanesFile activeScript] needsToSave])
      if(![self needToSaveAlert:thisLanesFile] ) return;
    index = [loadedFileArray indexOfObjectIdenticalTo:thisLanesFile];
    if(index != NSNotFound) {
      if(newRowIndex < 0) newRowIndex = index;
      [loadedFileArray removeObjectAtIndex:index];
    }
  }

  // Update loaded lane files display info
  if(newRowIndex < 0) newRowIndex = 0;
  if(newRowIndex >= [loadedFileArray count]) newRowIndex = [loadedFileArray count] - 1;
  if([loadedFileArray count] > 0) { // there are still lane files
    [GSeqEdit setLanesFile:[loadedFileArray objectAtIndex:newRowIndex]];
    [GSeqEdit shouldRedraw];
  }
  else { // no more lane file
    [GSeqEdit hide:self];
    [GSeqEdit setLanesFile:nil];
  } 

  [self updateView];
  [matrixView deselectAllCells];
  [matrixView selectCellAtRow:newRowIndex column:0]; 

  [[NSNotificationCenter defaultCenter]
  postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
}

- (NSApplicationTerminateReply)closeAllFiles
{
  int              i;
  LanesFile        *thisLanesFile;

  NSLog(@"close all files");
  for(i=0; i<[loadedFileArray count]; i++) {
    thisLanesFile = [loadedFileArray objectAtIndex:i];
    if([[thisLanesFile activeScript] needsToSave])
      if(![self needToSaveAlert:thisLanesFile] ) return NO;
  }
  [loadedFileArray removeAllObjects];

  // no more lane files
  [GSeqEdit hide:self];
  [GSeqEdit setLanesFile:nil];

  [self updateView];
  [matrixView deselectAllCells];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  return NSTerminateNow;
}

/*- (void)keyDown:(NSEvent *)theEvent
{
  int        row;
  NSString   *charString;
  unichar    thischar; //really an unsigned short

  charString = [theEvent charactersIgnoringModifiers];
  if (debugmode) NSLog(@"MultiFileManager keyEvent unicode len=%d", [charString length]);
  if([charString length] > 0) {
    thischar = [charString characterAtIndex:0];
    if (debugmode) NSLog(@" keyevent %X", thischar);
    if ((thischar==0x7F) || (thischar=='\010')) { // delete character
      if (debugmode) NSLog(@"  close selected file");
      row = [matrixView selectedRow];
      [loadedFileArray removeObjectAtIndex:row];

      if([loadedFileArray count] > 0) {
        row--;
        if(row<0) row=0;
        if(row >= [loadedFileArray count]) row = [loadedFileArray count] -1;
        [GSeqEdit setLanesFile:[loadedFileArray objectAtIndex:row]];
        [GSeqEdit shouldRedraw];
      } else {
        [GSeqEdit hide:self];
        [GSeqEdit setLanesFile:nil];
      }
      [self updateView];
      [[NSNotificationCenter defaultCenter]
        postNotificationName:@"BFSynchronizeScript" object:self];
    }
  }
} */

- (void)selectAll:(id)sender
{
  [matrixView selectAll:sender];
  [self selectFile:sender];
}

/*****
*
* Script application section
*
******/

- (void)applyScript:(NSNotification *)aNotification
{
  NSDictionary    *userInfo = [aNotification userInfo];
  NewScript       *thisScript;
  BOOL            autosave;
  
  if (debugmode) NSLog(@"notification post of applyScript\n%@", aNotification);
  thisScript = [userInfo objectForKey:@"script"];
  if(![thisScript isKindOfClass:[NewScript class]]) {
    if (debugmode) NSLog(@"error not a script");
    return;
  }
    
  autosave = [[userInfo objectForKey:@"autosave"] boolValue];

  if([[NSUserDefaults standardUserDefaults] boolForKey:@"useForgroundThreading"])
    [self applyScript:thisScript  toAllWithAutoSave:autosave];
  else
    [self applyNoThreadScript:thisScript  toAllWithAutoSave:autosave];
}

- (void)applyScript:(NewScript*)script toAllWithAutoSave:(BOOL)autosave
{
  LanesFile         *thisLanesFile;
  NewScript         *thisScript;
  int               fromLane;
  int               numLanes;
  int               i, fileNum;
  //NSAutoreleasePool *pool;
  NSArray           *selectedFiles = [self selectedLanesFiles];
  //NSString          *autosaveFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"AutosaveFormat"];

  for(fileNum=0; fileNum<[selectedFiles count]; fileNum++) {
    thisLanesFile = [selectedFiles objectAtIndex:fileNum];
    fromLane = [thisLanesFile activeLane];
    numLanes = [thisLanesFile numLanes];

    for (i=1;i<=numLanes;i++) {
      [thisLanesFile switchToLane:i];
      [thisLanesFile applyScript:script];
      thisScript = [thisLanesFile activeScript];
      [thisScript setStatusPercent:0.0];
      [thisScript setStatusMessage:@"backgrounded"];

      [thisScript setIndexesToEnd];
      [thisScript setAutosave:autosave];
      [[ScriptScheduler sharedScriptScheduler] addBackgroundJob:thisScript];

      /** move somewhere
      if(autosave) {
        [statusBox setSuperMessage:@"Saving lane"];
        [thisLanesFile setDefaultSaveFormat:autosaveFormat];
        [thisLanesFile saveCurrentToDefaultFormat];
      }
      [[thisLanesFile activeScript] clearCacheButCurrentExecuted];
      **/
    }
    [thisLanesFile switchToLane:fromLane];
  }

  /** also moved with autosave
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  [GSeqEdit shouldRedraw];
  **/
}


- (void)applyNoThreadScript:(NewScript*)script toAllWithAutoSave:(BOOL)autosave
{
  LanesFile         *thisLanesFile;
  int               fromLane;
  int               numLanes;
  int               i, fileNum;
  StatusController  *statusBox = [StatusController connect];
  NSString          *msgLaneNum;
  NSAutoreleasePool *pool;
  NSArray           *selectedFiles = [self selectedLanesFiles];
  NSString          *autosaveFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"AutosaveFormat"];
  NewScript         *thisScript;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateScriptStatus:)
                                               name:@"BFScriptStatusChanged"
                                             object:nil];

  [statusBox center];
  [statusBox messageConnect:self :"Apply script to file" :""];
  for(fileNum=0; fileNum<[selectedFiles count]; fileNum++) {
    thisLanesFile = [selectedFiles objectAtIndex:fileNum];
    fromLane = [thisLanesFile activeLane];
    numLanes = [thisLanesFile numLanes];

    for (i=1;i<=numLanes;i++) {
      pool =[[NSAutoreleasePool alloc] init];

      msgLaneNum = [NSString stringWithFormat:@"%@", [[thisLanesFile fileName] lastPathComponent]];
      if(numLanes > 1)
        msgLaneNum = [msgLaneNum stringByAppendingFormat:@" lane %d", i];

      [statusBox updateMessage:self :(char*)[msgLaneNum cString]];

      [thisLanesFile switchToLane:i];
      [thisLanesFile applyScript:script];
      thisScript = [thisLanesFile activeScript];
      [thisScript setIndexesToEnd];
      [thisScript execToIndex:[thisScript desiredExecuteIndex]];
      //[[thisLanesFile activeScript] execToEnd];

      NS_DURING
        if(autosave) {
          [thisScript setStatusMessage:@"Saving lane"];
          [thisLanesFile setDefaultSaveFormat:autosaveFormat];
          [thisLanesFile saveCurrentToDefaultFormat];
          [thisScript setStatusMessage:NULL];
        }
      NS_HANDLER
        int  result;
        if([[localException name] isEqualToString:BFFileSystemException]) {
          result = NSRunAlertPanel(@"File System Error", [localException reason], @"OK", @"Cancel all jobs", nil);
          NSLog(@"File System Error during -saveLane %@\n", [localException reason]);
        } else {
          result = NSRunAlertPanel(@"Error Panel", @"Error saving to file '%@'.\n%@", @"OK", @"Cancel all jobs", nil,
                          [[thisLanesFile fileName] lastPathComponent], localException);
          NSLog(@"exception during saveLane %@: %@\n", [thisLanesFile fileName], localException);
        }
        if(result == NSAlertAlternateReturn) {
          i = numLanes+1;
          fileNum = [selectedFiles count];
        }
      NS_ENDHANDLER

      [[thisLanesFile activeScript] clearCacheButCurrentExecuted];

      [pool release];
    }
    [thisLanesFile switchToLane:fromLane];
  }

  [statusBox done:self];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"BFScriptStatusChanged"
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  [GSeqEdit shouldRedraw];
}

/*****
*
* New status display for non-threaded batch processing 
*
*****/

- (void)setupStatusView
{
  NSRect   tempFrame, statusFrame;
  NSView   *panelView = [panel contentView];

  tempFrame = [panelView bounds];
  statusFrame = NSMakeRect(tempFrame.size.width-3.0,
                           tempFrame.size.height-3.0, 1.0, 1.0);

  statusDisplayer = [[UWStatusView alloc] initWithFrame:statusFrame];
  [statusDisplayer setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];
  [statusDisplayer setAnchor:UWStatusUpperRight];
  [statusDisplayer setStatus:nil];
  [panelView addSubview:statusDisplayer positioned:NSWindowAbove relativeTo:nil];
}

- (void)updateScriptStatus:(NSNotification *)notification
{
  //method should be thread safe since notification will be posted from other thread
  NewScript *aScript = [notification object];

  if(debugmode && ([aScript statusMessage] != nil))
    fprintf(stderr, "status: %s, %f\n", [[aScript statusMessage] cString], [aScript statusPercent]);


  if([aScript statusMessage] == nil) {  //clear status
    [statusDisplayer setStatus:nil];
    return;
  }
  if([aScript statusPercent] <= 0.0) {
    [statusDisplayer setStatus:[aScript statusMessage]];
  }
  else {
    [statusDisplayer setStatus:[aScript statusMessage]
                  withProgress:(int)[aScript statusPercent]
                       ofTotal:100];
  }

  [[statusDisplayer superview] display];
}

@end
