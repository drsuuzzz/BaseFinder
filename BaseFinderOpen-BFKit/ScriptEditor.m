/* "$Id: ScriptEditor.m,v 1.5 2008/04/15 20:53:41 smvasa Exp $" */

/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, Lloyd Smith and portions Morgan Koehrsen

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

#import "ScriptEditor.h"
#import "SequenceEditor.h"
#import "ToolMaster.h"
#import <BaseFinderKit/NewScript.h>
#import <BaseFinderKit/GenericToolCtrl.h>
#import <BaseFinderKit/LanesFile.h>
#import <BaseFinderKit/ScriptScheduler.h>
#import <GeneKit/AsciiArchiver.h>
#import <GeneKit/StatusController.h>
#import <ctype.h>

/*****
* July 19, 1994 Mike Koehrsen
* Made some minor changes associated with the reorganization of the tool hierarchy.
*****/

@implementation ScriptEditor

+ new
{
  ScriptEditor    *newSelf;
  
  newSelf = [super new];
  [NSBundle loadNibNamed:@"ScriptEditor.nib" owner:newSelf];
  return newSelf;
}

- (void)setToolMaster:(ToolMaster*)theToolMaster;
{
  toolMaster = theToolMaster;
}

- init
{
  NSString   *tempPath;
  
  [super init];
  matrixView=nil;
  scriptPositionMatrix=nil;
  toolMaster = nil;
  newlyLoadedScript=nil;

  tempPath = [[NSBundle mainBundle] pathForResource:@"BFGrayScriptArrow" ofType:@"tiff"];
  grayScriptArrow = [[NSImage alloc] initWithContentsOfFile:tempPath];
  tempPath = [[NSBundle mainBundle] pathForResource:@"BFScriptArrow" ofType:@"tiff"];
  scriptArrow = [[NSImage alloc] initWithContentsOfFile:tempPath];
  return self;
}

- (void)appWillInit
{
  [self makeMatrix:[[scrollView contentView] bounds]];
  //[scrollView setBackgroundColor:[[scrollView window] backgroundColor]];
  [scrollView setAutoresizesSubviews:YES];
  [[scrollView window] setDelegate:self];

  [resourceMenu setAction:@selector(selectResource:)];
  [resourceMenu setTarget:self];
  [resourceSourceID setTarget:self];
  [resourceSourceID setAction:@selector(getResourceList:)];

  // test public resource directory, and
  // disable that cell if it doesn't exist
  // and can't be created
  //  Assuming that the private directory can always be created,
  // since it's in the user's home directory
  [resourceSourceID selectCellAtRow:0 column:0];
  if (![self resourcePath]) {
          [[resourceSourceID cellAtRow:0 column:0] setEnabled:NO];
          [resourceSourceID selectCellAtRow:0 column:1];
  }
  [self getResourceList:resourceSourceID];
  [resourceSourceID retain];
  [saveButtonID retain];
  [autoexecuteSwitch retain];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(fillView)
                                               name:@"BFSynchronizeScript"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(fillView)
                                               name:@"BFSynchronizeScriptAndTools"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(switchExpertMode)
                                               name:@"BFSwitchExpertMode"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateExecuteDisplay)
                                               name:@"BFScriptThreadFinished"
                                             object:nil];

  [scriptPanel setFrameUsingName:@"ScriptPanel"];
  [scriptPanel display];
  [scriptPanel setFrameAutosaveName:@"ScriptPanel"];
  [scriptPanel display];
  [scriptPanel orderFront:self];

  [self switchExpertMode]; 
}

- (void)showPanel;
{
  [scriptPanel orderFront:self];
}

- (void)switchExpertMode
{
  NSString    *expertMode;

  expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];
/*
  if([expertMode isEqualToString:@"beginner"]) {
    [resourceSourceID removeFromSuperview];
    [saveButtonID removeFromSuperview];
    [autoexecuteSwitch removeFromSuperview];
    [[GSeqEdit currentScript] setAutoexecute:YES];
  }
  else {
    //add views back in if not already there
    if([[[scriptPanel contentView] subviews] indexOfObjectIdenticalTo:resourceSourceID] == NSNotFound)
      [[scriptPanel contentView] addSubview:resourceSourceID];
    if([[[scriptPanel contentView] subviews] indexOfObjectIdenticalTo:saveButtonID] == NSNotFound)
      [[scriptPanel contentView] addSubview:saveButtonID];
    if([[[scriptPanel contentView] subviews] indexOfObjectIdenticalTo:autoexecuteSwitch] == NSNotFound)
      [[scriptPanel contentView] addSubview:autoexecuteSwitch];
  }
  [scriptPanel display]; 
 */
}

- (void)switchAutoexecute:sender
{
  [[GSeqEdit currentScript] setAutoexecute:[autoexecuteSwitch state]];
  if([[GSeqEdit currentScript] autoexecute])
    [GSeqEdit shouldRedraw];
}

- (void)makeCellTemplate
{
  cellTemplate = [[NSButtonCell alloc] init];
  [cellTemplate setButtonType:NSToggleButton];
  [cellTemplate setBordered:NO];
  [cellTemplate setBezeled:NO];
  [cellTemplate setAlignment:NSLeftTextAlignment];
  [cellTemplate setHighlightsBy:NSChangeGrayCellMask/*NSChangeBackgroundCellMask*/];
}


- (void)makeMatrix:(NSRect)frameRect
{
  NSRect        tempRect;
  NSSize        tempSize;
  int           count=[[GSeqEdit currentScript] count];
  NSView        *docView;
  //NSBox         *divider;
  NSButtonCell  *posCellTemplate;
  NSColor       *backColor = [[scrollView window] backgroundColor];

  frameRect.origin.x = 0.0;
  frameRect.origin.y = 0.0;
  //make the script position matrix
  posCellTemplate = [[NSButtonCell alloc] init];
  [posCellTemplate setButtonType:NSToggleButton];
  [posCellTemplate setBordered:NO];
  [posCellTemplate setImagePosition:NSImageLeft];
  [posCellTemplate setHighlightsBy:NSNoCellMask];
  [posCellTemplate setImage:scriptArrow];
  [posCellTemplate setAlternateImage:nil];
  [posCellTemplate setTitle:nil];
  tempRect = frameRect;
  tempRect.size.width = 14;
  scriptPositionMatrix = [[NSMatrix alloc] initWithFrame:frameRect
                                                    mode:NSRadioModeMatrix
                                               prototype:posCellTemplate
                                            numberOfRows:count
                                         numberOfColumns:1];
  tempSize.width = 0.0;
  tempSize.height = 0.0;
  [scriptPositionMatrix setIntercellSpacing:tempSize];
  [scriptPositionMatrix setBackgroundColor:backColor];
  [scriptPositionMatrix setCellBackgroundColor:backColor];
  tempSize.width = 12.0;
  tempSize.height = 12.0;
  [scriptPositionMatrix setCellSize:tempSize];
  [scriptPositionMatrix setAutoscroll:NO];
  [scriptPositionMatrix setScrollable:NO];
  [scriptPositionMatrix setAllowsEmptySelection:YES];
  [scriptPositionMatrix setTarget:self];
  [scriptPositionMatrix setAction:@selector(changeExecutePosition:)];
  [scriptPositionMatrix setAutosizesCells:NO];
  [scriptPositionMatrix setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
  [scriptPositionMatrix sizeToCells];



  [self makeCellTemplate];
  frameRect.size.width -= 16.0;
  frameRect.origin.x = 18.0;
  matrixView = [[NSMatrix alloc] initWithFrame:frameRect
                                          mode:NSListModeMatrix //change from NSRadioModeMatrix to allow highlighting
                                     prototype:cellTemplate
                                  numberOfRows:count
                               numberOfColumns:1];
  tempSize.width = 0.0;
  tempSize.height = 0.0;
  [matrixView setIntercellSpacing:tempSize];
  [matrixView setBackgroundColor:[[matrixView window] backgroundColor]/*backColor*/];
  [matrixView setCellBackgroundColor:[[matrixView window] backgroundColor]/*backColor*/];
  tempSize.width = 205.0;
  tempSize.height = 12.0;
  [matrixView setCellSize:tempSize];
  [matrixView setFont:[NSFont userFixedPitchFontOfSize:12]];
  [matrixView setAutoscroll:YES/*NO*/];
  [matrixView setScrollable:YES];
  [matrixView setAllowsEmptySelection:YES];
  [matrixView setTarget:self];
  [matrixView setAction:@selector(rollback:)];
  [matrixView setDoubleAction:@selector(doubleClickSelect:)];
  [matrixView setAutoresizingMask:(NSViewWidthSizable|NSViewMinYMargin)];
  [matrixView setAutosizesCells:YES];
  [matrixView sizeToCells];

  /*
  frameRect.size.width = 2.0;
  frameRect.origin.x = 15.0;
  divider = [[NSBox alloc] initWithFrame:frameRect];
  [divider setAutoresizingMask:(NSViewMaxXMargin|NSViewHeightSizable)];
  [divider setBorderType:NSLineBorder];
  [divider setTitlePosition:NSNoTitle];
    */
  
  tempRect = [scriptPositionMatrix frame];
  tempRect = NSUnionRect(tempRect, [matrixView frame]);
  //tempSize = [scrollView contentSize];
  //if(tempRect.size.width > tempSize.width) tempRect.size.width=tempSize.width;
  docView = [[ScriptView alloc] initWithFrame:tempRect];
  [docView setAutoresizesSubviews:YES];
  [docView setAutoresizingMask:(NSViewWidthSizable)];
  [docView addSubview:scriptPositionMatrix];
  [docView addSubview:matrixView];
  //[docView addSubview:divider];
  [scrollView setDocumentView:docView];
}

- (void)open:sender
{
  NewScript       *newScript;
  NSString        *filename;
  NSOpenPanel     *openPanel = [NSOpenPanel openPanel];
  AsciiArchiver   *archiver;
  char            tagBuf[MAXTAGLEN];
  NSArray         *fileType = [NSArray arrayWithObjects:@"scr", nil];

  [openPanel setAllowsMultipleSelection:NO];
  if ([openPanel runModalForTypes:fileType])
    filename = [openPanel filename];
  else return;

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:filename];

  [archiver getNextTag:tagBuf];

  if ((newScript = [archiver readObject])!=nil) {
    [GSeqEdit setCurrentScript:newScript];
    [self fillView];
    [GSeqEdit shouldRedraw];
  }
  if(archiver) [archiver release];
}

- (void)openScript:(NSString*)filename
{
  NewScript       *newScript;
  AsciiArchiver   *archiver;
  char tagBuf[MAXTAGLEN];
  NSString        *scriptName;

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:filename];
  if(archiver == NULL) return;

  [archiver getNextTag:tagBuf];

  NS_DURING
    if ((newScript = [archiver readObject])!=nil) {
      scriptName = [filename lastPathComponent];
      if([scriptName length] == 0)
        [newScript setScriptName:filename];
      else
        [newScript setScriptName:scriptName];

      if(newlyLoadedScript != nil) [newlyLoadedScript release];
      newlyLoadedScript = [newScript copy];
      [newScript connectAllToolsToScript];
      [newlyLoadedScript connectAllToolsToScript];
      
      [toolMaster checkForNewResourcesInScript:newScript];
			
			[toolMaster setControllerForToolsInScript:newScript];  //for scripts the Controller is never set in the tools
			[toolMaster setControllerForToolsInScript:newlyLoadedScript];

      [GSeqEdit setCurrentScript:newScript]; //copied into curent lanes file
      [self fillView];
      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
      [GSeqEdit shouldRedraw];
    }
  NS_HANDLER
    scriptName = [filename lastPathComponent];
    if([scriptName length] == 0) scriptName = filename;
    NSRunAlertPanel(@"Error Panel", @"Error loading script '%@'.\n%@", @"OK", nil, nil,
                    scriptName, localException);
    NSLog(@"exception during -openScript %@: %@\n", scriptName, localException);
  NS_ENDHANDLER
  if(archiver) [archiver release];
}

#ifdef OLDCODE
- (void)switchSaveToPublic:sender
{
  //only root can save to the public scripts directory
  BOOL		saveToRoot=[saveToRootID state];
  id			rootPanel, domainID;
  //void		*domainHandle;		//NI domain handle

  if (debugmode) fprintf(stderr,"switchSaveToPublic %d\n", saveToRoot);
  if(saveToRoot) {
    domainID = [[NIDomain alloc] init];
    //[domainID setConnection:"/"];
    [domainID setConnection:"."];

    if (debugmode) fprintf(stderr,"current NI server = '%s'\n", [domainID getCurrentServer]);
    if (debugmode) fprintf(stderr,"getDomainHandle = %d\n", (int)[domainID getDomainHandle]);

    rootPanel = [NILoginPanel new];
    //if ([rootPanel runModal:self inDomain:[domainID getDomainHandle]])
    //[rootPanel runModal:self inDomain:[domainID getDomainHandle]];
    //if ([rootPanel isValidLogin:self])

    if ([rootPanel runModal:self inDomain:[domainID getDomainHandle] withUser:"root"
            withInstruction:"You must have superuser status to save public scripts.  Please enter root password."
                allowChange:NO]) {
      if (debugmode) fprintf(stderr,"valid login\n");
    }
    else {
      if (debugmode) fprintf(stderr,"non-valid login\n");
    }

    [domainID release];
    [rootPanel release];
  }
}
#endif

- (void)saveAs:sender
{
  NSString       *pathname;
  AsciiArchiver  *archiver;
  int            oldResourcePath=[resourceSourceID selectedColumn];
  BOOL           saveToRoot=[saveToRootID state];
	
  if(saveToRoot)
    [resourceSourceID selectCellAtRow:0 column:0];
  else
    [resourceSourceID selectCellAtRow:0 column:1]; //switch to private

  pathname = [[self resourcePath] stringByAppendingPathComponent:
    [[scriptSaveLabelID cellAtIndex:0] stringValue]];

  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:[GSeqEdit currentScript] tag:"script"];
  if([archiver writeToFile:pathname atomically:YES] == NO) {
    NSRunAlertPanel(@"File system Error", @"Unable to write file. File system error: Permission denied", @"", nil, nil);
  }
  if(archiver) [archiver release];
  [[GSeqEdit currentScript] setScriptName:[[scriptSaveLabelID cellAtIndex:0] stringValue]];

  [[scriptSaveLabelID window] orderOut:self];
  [resourceSourceID selectCellAtRow:0 column:oldResourcePath]; //switch back
  [self getResourceList:resourceSourceID];
}


	/* - formatFilename:(const char *)theFilename;
	 * {
	 * 	char path[MAXPATHLEN+1];
	 * 	const char *h;
	 * 	char *p;
	 * 	struct stat curr_ds, home_ds;
	 * 	NXCoord	maxWidth, accumWidth=0.0, ellipsisWidth, tildeWidth;
	 * 	NXSize	filenameSize;
	 * 	NXFontMetrics *metrics;
	 * 	float fontSize;
	 * 
	 * 	if (!theFilename) {
	 * 		[filenameForm setStringValue:"" at:0];
	 * 		return self;
	 * 	}
	 * 
	 * 	h=NXHomeDirectory();
	 * 	strcpy(path,theFilename);
	 * 	stat(h,&home_ds);
	 * 
	 * 	metrics=[[filenameForm font] metrics];
	 * 	fontSize=[[filenameForm font] pointSize];
	 * 	ellipsisWidth=metrics->widths[(unsigned char)'\274']*fontSize;
	 * 	tildeWidth=metrics->widths[(unsigned char)'~']*fontSize;
	 * 	[filenameForm getCellSize:&filenameSize];
	 * 	maxWidth=filenameSize.width - [[filenameForm cellAt:0 :0] titleWidth] - 15;
	 * 
	 * 	for(p=path+strlen(path)-1;p>path;p--){
	 * 		accumWidth+=(metrics->widths[(unsigned char)*p]*fontSize);
	 * 		if (*p=='/') {
	 * 			*p='\0';
	 * 			stat(path,&curr_ds);
	 * 			if ((curr_ds.st_dev == home_ds.st_dev) && (curr_ds.st_ino == home_ds.st_ino) &&
	 * 														(accumWidth+tildeWidth < maxWidth)){
	 * 				*p='/';
	 * 				*--p='~';
	 * 				break;
	 * 			}
	 * 			*p='/';
	 * 		}
	 * 		if (accumWidth+ellipsisWidth >= maxWidth) {
	 * 			*p='\274';
	 * 			break;
	 * 		}
	 * 	}
	 * 	
	 * 	[filenameForm setStringValue:p at:0];
	 * 	return self;
	 * }
	 */

- (void)windowDidResize:(NSNotification *)aNotification
{

  return;
}

- (void)fillView
{
  int        i, currentExecuteIndex, desiredExecuteIndex;
  NSString   *tempstr;
  NSRect     tempRect1, tempRect2;
  NSSize     tempSize;
  NSView     *docView;
  NewScript  *script = [GSeqEdit currentScript];

  if(script == nil) script=newlyLoadedScript;

  [matrixView renewRows:[script count] columns:1];
  [matrixView sizeToCells];
  [scriptPositionMatrix renewRows:[script count] columns:1];
  [scriptPositionMatrix sizeToCells];
  tempRect1 = [scriptPositionMatrix frame];
  tempRect2 = [matrixView frame];
  tempRect1 = NSUnionRect(tempRect1, tempRect2);
  //fprintf(stderr, "new script rect %f %f %f %f\n", tempRect1.origin.x, tempRect1.origin.y,
  //       tempRect1.size.width, tempRect1.size.height);
  docView = [scrollView documentView];
  tempSize = [scrollView contentSize];
  if(tempRect1.size.width > tempSize.width) tempRect1.size.width=tempSize.width;
  //if(tempRect1.size.height < tempSize.height) tempRect1.size.height=tempSize.height;
  [docView setAutoresizesSubviews:NO];
  [docView setFrameSize:tempRect1.size];
  [docView setAutoresizesSubviews:YES];
/*
  tempRect2 = tempRect1;
  tempRect2.size.width = 2.0;
  tempRect2.origin.x = 15.0;
  [divider setFrame:tempRect2];
*/
  currentExecuteIndex = [script currentExecuteIndex];
  desiredExecuteIndex = [script desiredExecuteIndex];
  for (i=0;i<[script count];i++) {
    tempstr = [script nameAtIndex:i];
    [[matrixView cellAtRow:i column:0] setTitle:tempstr];
    if((i!=desiredExecuteIndex) && (i!=currentExecuteIndex))
      [[scriptPositionMatrix cellAtRow:i column:0] setImage:nil];
    else {
      if (i==currentExecuteIndex)
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:scriptArrow];
      else
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:grayScriptArrow];
      if([script threadIsExecuting] && (desiredExecuteIndex==currentExecuteIndex))
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:grayScriptArrow];
    }
  }

  [matrixView selectCellAtRow:[script currentEditIndex] column:0];
  /*[[scrollView setDocView:matrixView] free];*/
  //[matrixView sizeToCells];
  /*[[scrollView setDocView:matrixView] free];*/
  [matrixView setNeedsDisplay:YES];
  [scriptPositionMatrix setNeedsDisplay:YES];
  [docView setNeedsDisplay:YES];

  if(script == NULL)
    [resourceLabelID setStringValue:[NSString string]];
  else
    [resourceLabelID setStringValue:[script scriptName]];
  [resourceLabelID display];
  [autoexecuteSwitch setState:[script autoexecute]];
  [scriptPanel display];
}

- (void)ORIGrollback:sender
{
  NewScript  *script = [GSeqEdit currentScript];
  NSString   *expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];

  if([expertMode isEqualToString:@"beginner"]) {
    [script setDesiredExecuteIndex:[matrixView selectedRow]];
    //[script execToIndex:[matrixView selectedRow]];
    [GSeqEdit shouldRedraw];
  }
  else {
    if([script autoexecute]) {
      [script setDesiredExecuteIndex:[matrixView selectedRow]];
      //[script execToIndex:[matrixView selectedRow]];
      [GSeqEdit shouldRedraw];
    }
    else
      [script setCurrentEditIndex:[matrixView selectedRow]];
  }

  if(![expertMode isEqualToString:@"expert"]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  } else {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScript" object:self];
  }
}

- (void)rollback:sender
{
  NewScript  *script = [GSeqEdit currentScript];
  NSString   *expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];

  [matrixView highlightCell:YES atRow:[matrixView selectedRow] column:0];
  if([expertMode isEqualToString:@"beginner"]) {
    [script setCurrentEditIndex:[matrixView selectedRow]];
    [script setDesiredExecuteIndex:[matrixView selectedRow]];
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:script];
    //[script executeInThread];
    //[script execToIndex:[matrixView selectedRow]];
    //[GSeqEdit shouldRedraw];
  }
  else {
    [script setCurrentEditIndex:[matrixView selectedRow]];
  }

  if(![expertMode isEqualToString:@"expert"]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  } else {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScript" object:self];
  }
}

- (void)doubleClickSelect:sender
{
  NewScript   *script = [GSeqEdit currentScript];
  NSString    *expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];

  if(![expertMode isEqualToString:@"expert"]) {
    [self rollback:self];
    return;
  }

  if([script autoexecute]) {
    [script setDesiredExecuteIndex:[matrixView selectedRow]];
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:script];
    //[script executeInThread];
    //[script execToIndex:[matrixView selectedRow]];
    //[GSeqEdit shouldRedraw];
  }
  else
    [script setCurrentEditIndex:[matrixView selectedRow]];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
}

- (void)showParams:sender
{
  GenericTool      *currTool;
  int              row=[matrixView selectedRow];
  GenericToolCtrl  *controller;

  if (debugmode) NSLog(@"ScriptEditor try to showParams (doubleClick)");
  currTool = [[GSeqEdit currentScript] toolAt:row];
  if (currTool == nil)
    return;

  controller = [toolMaster controllerForClass:[currTool class]];

  currTool = [currTool copy];
  [currTool clearPointers];
  [controller setDataProcessor:currTool];
  [controller displayParams];
  [controller show]; 
}

//for handling multithreaded display
- (void)changeExecutePosition:sender
{
  NewScript  *script = [GSeqEdit currentScript];
  NSString   *expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];
  int        selectedRow = [scriptPositionMatrix selectedRow];

  if([script threadIsExecuting]) {
    NSBeep();
    return;
  }
  if(![expertMode isEqualToString:@"expert"]) {
    [script setCurrentEditIndex:selectedRow];
    [script setDesiredExecuteIndex:selectedRow];
    [self updateExecuteDisplay];
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:script];
    //[script executeInThread];
    //[script execToIndex:selectedRow];
    //[GSeqEdit shouldRedraw];
  }
  else {    
    [script setDesiredExecuteIndex:selectedRow];
    [[scriptPositionMatrix selectedCell] setImage:grayScriptArrow];
    [self updateExecuteDisplay];
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:script];
    //[script executeInThread];
    //[script execToIndex:selectedRow];  //will be replaced by a threaded object
  }

  if(![expertMode isEqualToString:@"expert"]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  } else {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScript" object:self];
  }
}

- (void)updateExecuteDisplay
{
  int        i, currentExecuteIndex, desiredExecuteIndex;
  NewScript  *script = [GSeqEdit currentScript];
  NSString   *expertMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"];

  [GSeqEdit shouldRedraw];
  currentExecuteIndex = [script currentExecuteIndex];
  desiredExecuteIndex = [script desiredExecuteIndex];
  for (i=0;i<[script count];i++) {
    if((i!=desiredExecuteIndex) && (i!=currentExecuteIndex))
      [[scriptPositionMatrix cellAtRow:i column:0] setImage:nil];
    else {
      if (i==currentExecuteIndex)
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:scriptArrow];
      else
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:grayScriptArrow];
      if([script threadIsExecuting] && (desiredExecuteIndex==currentExecuteIndex))
        [[scriptPositionMatrix cellAtRow:i column:0] setImage:grayScriptArrow];
    }
  }
  [scriptPositionMatrix display];

  if(![expertMode isEqualToString:@"expert"]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  } else {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScript" object:self];
  }
}

// Step in script to position <current position> + inc, where inc is + or -
- (void)stepBy:(int)inc
{
  int newRow = [matrixView selectedRow] + inc;
  int nrows, ncols;

  [matrixView getNumberOfRows:&nrows columns:&ncols];
  if (newRow >= 0 && newRow < nrows) {
    [matrixView selectCellAtRow:-1 column:-1];
    [matrixView selectCellAtRow:newRow column:0];
    [self rollback:self];
  } else
    NSBeep();
}

- (void)truncate
{
  [[GSeqEdit currentScript] truncate];
  [self fillView];
}

- (void)applyToAll:sender
{
  NewScript       *script = [[GSeqEdit dataManager] activeScript];
  NSDictionary    *userInfo;

  if(script == nil) script=newlyLoadedScript;
  if(script == nil) return;
  
  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    script, @"script",
    [NSNumber numberWithBool:[autosaveSwitch state]], @"autosave",
    nil];
  
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFApplyScriptToAll"
                    object:self
                 userInfo:userInfo];
}


/****
*
* new resource-like script storage
*
****/


- (NSString *)resourcePath
{
  NSString *oldDir, *resourcePath;
  NSFileManager *filemanager;

  filemanager = [NSFileManager defaultManager];
  oldDir = [filemanager currentDirectoryPath];
  if ([resourceSourceID selectedColumn]==0)
    resourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects:
      NSOpenStepRootDirectory(),
      @"Library",
      @"BaseFinder",
      [self resourceSubdir],
      nil]];
  else
    resourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects:
      NSHomeDirectory(),
      @"Library",
      @"BaseFinder",
      [self resourceSubdir],
      nil]];
  
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];
  [filemanager changeCurrentDirectoryPath:oldDir];			
  return resourcePath;
}

// must be overridden; e.g., "Matrixes", "Mobilities"
- (NSString *)resourceSubdir
{
  return @"Scripts";
}

- (void)getResourceList:sender
{
  NSFileManager *filemanager;
  NSString *path, *pullDownTitle;
  NSArray *contents, *itemTitles;
  BOOL isDir=NO;

  //NSLog(@"popUptitles=%@", [resourceMenu itemTitles]);
  pullDownTitle = [[resourceMenu itemTitleAtIndex:0] retain];
  [resourceMenu removeAllItems];
  [resourceMenu addItemWithTitle:pullDownTitle];
  [pullDownTitle autorelease];
  //NSLog(@"popUptitles=%@", [resourceMenu itemTitles]);
  filemanager = [NSFileManager defaultManager];
  path = [self resourcePath];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
    return;
  contents = [filemanager directoryContentsAtPath:path];

  itemTitles = [contents sortedArrayUsingSelector:@selector(compare:)];
  [resourceMenu addItemsWithTitles:itemTitles];
}

- (void)selectResource:sender
{
  NSString   *currentLabel, *fullPath;	

  if([resourceMenu indexOfSelectedItem] < 1) {
    //if (debugmode) fprintf(stderr,"no new script label\n");
    return;
  }

  currentLabel = [resourceMenu titleOfSelectedItem];
  [resourceLabelID setStringValue:currentLabel];
  [resourceLabelID display];

  fullPath = [[self resourcePath] stringByAppendingPathComponent:currentLabel];
  if (debugmode) fprintf(stderr," loading script '%s'\n", [fullPath cString]);

  [self openScript:fullPath]; 
}

/*****
*
* autosave panel section
*
*****/

- (void)switchAutosave:sender
{
  NSString  *autosaveFormat;

  if(![autosaveSwitch state]) return;  //don't need to raise autosavePanel

  autosaveFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"AutosaveFormat"];
  [autosavePopUp selectItemWithTitle:autosaveFormat];

  if([NSApp runModalForWindow:autosavePanel] == NSRunStoppedResponse) { //ok
    [[NSUserDefaults standardUserDefaults] setObject:[autosavePopUp titleOfSelectedItem]
                                              forKey:@"AutosaveFormat"];
  }
  else { //cancel
    [autosaveSwitch setState:0];
  }
  [autosavePanel orderOut:self];
}

- (void)autosavePanelOK:sender
{
  [NSApp stopModal];
}

- (void)autosavePanelCancel:sender
{
  [NSApp abortModal];
}

@end



@implementation ScriptView

- (BOOL)isFlipped
{
  return YES;
}

- (void)drawRect:(NSRect)rects
{	
  NSRect    tempRect = [self bounds];
  NSPoint p1, p2;
  [[NSColor blackColor] set];
//  PSsetgray(NSBlack);
  p1.x = 15.0; p1.y = 0.0;
  p2.x = 15.0; p2.y = tempRect.size.height;
  [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
}

@end
