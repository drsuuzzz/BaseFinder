/* "$Id: ToolMaster.m,v 1.8 2007/01/26 02:31:47 smvasa Exp $" */

/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin,  Lloyd Smith and portions Morgan Koehrsen 

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

#import "ToolMaster.h"
#import "SequenceEditor.h"
#import "MasterView.h"
#import "ScriptEditor.h"
#import <GeneKit/StatusController.h>
#import "NDDSLinker.h"
#import <Foundation/NSUserDefaults.h>
#ifndef GNU_RUNTIME
#import <objc/objc-runtime.h>
#endif
#import <BaseFinderKit/GenericTool.h>
#import <BaseFinderKit/ABIProcessToolCtrl.h>
#import <BaseFinderKit/ResourceToolCtrl.h>
#import <BaseFinderKit/GenericToolCtrl.h>
#import "BasesView.h"
#import <BaseFinderKit/NewScript.h>

#define NewGenericTool GenericTool
/******
* Feb 1996 Jessica Severin
* Added Expert/Basic modes.  Expert mode shows everything, while basic
* mode does not show individual tools (only the scripts) and does not
* allow user to save a new script
******/

/******
* July 19, 1994 Mike Koehrsen
* Made some minor changes for compatibility with the new tool hierarchy.
* Also cleaned up the handling of tool and script inspectors.
****/

@interface ToolMaster (PrivateToolMaster)
- (void)synchronizeToScript;
- (void)setupToolButtons:(int)index;
- (void)showToolNotification:(NSNotification*)aNotification;
- (BOOL)toolInScript:(NSString *)toolname;
@end


@implementation ToolMaster

- init
{
  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:1], @"LaneCount",
    [NSNumber numberWithInt:1], @"LaneToUse",
    @"10", @"M",
    @"2", @"sigma",
    @"2", @"COthreshold",
    @"20", @"COwindow",
    @"2", @"COquit",
    @"1", @"HIcutoff",
    @"2", @"HighOrder",
    @"0.30", @"FinalOut",
    @"0.90", @"CallQuit",
    @"0.15", @"Throwout",
    @"10", @"MaxIT",
    @"1", @"W1",
    @"1", @"W2",
    @"1", @"W3",
    @"1", @"W4",
    nil];
  
  [super init];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  defaultsDict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  //NSLog(@"%@", defaultsDict);

  expertMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"] copy];

  [NSBundle loadNibNamed:@"ToolMaster.nib" owner:self];

  baseViewingID = [BasesView new];
  scriptEditor = [ScriptEditor new];
  [scriptEditor setToolMaster:self];

  eventNotifyList = [[NSMutableArray alloc] init];

  tools = [[NSMutableArray alloc] init];
  currToolIx = -1;

  currentToolState = TM_noTool;

  return self;
}

- (void)switchExpertMode
{
  [expertMode release];
  expertMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"ExpertMode"] copy];

  if (debugmode) NSLog(@"ToolMaster expertLevel=%@", expertMode);
  if([expertMode isEqualToString:@"beginner"]) {
    [[processorPopUp retain] removeFromSuperview];
  }
  else {
    if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:processorPopUp] == NSNotFound)
      [[toolPanel contentView] addSubview:processorPopUp];
  }
}


- (void)loadTool:(NSString *)fileName
{
  id        theBundle;
  id        processorClass;
  id        controllerClass;
  NSString  *ctrlName, *baseName;

  // check tool class name  against loadedToolsNames
  if ([toolnames containsObject:fileName]) {
    if (debugmode) fprintf(stderr,"    didn't load %s because it's already been loaded\n", [fileName cString]);
    return;
  }
  if ([libraryNames containsObject:fileName]) {
    NSRunAlertPanel(@"Error loading bundle",
                    @"%@ exists in both NSLibraries and NSTools.\n\nThis bundle will probably not function properly. Please remove one of these bundles from\n/LocalLibrary/Basefinder or\n<your home>/Library/BaseFinder",
                    @"OK", nil, nil, fileName);
    [toolnames addObject:fileName];
    return;
  }

  NS_DURING
    //theBundle=[[NSBundle alloc] initWithPath:fileName];
    theBundle=[NSBundle bundleWithPath:fileName];
    baseName = [fileName lastPathComponent];
    processorClass = [theBundle classNamed:[baseName stringByDeletingPathExtension]];
    //NSLog(@"processorClass=%@", processorClass);
    ctrlName = [[baseName stringByDeletingPathExtension] stringByAppendingString:CTRLSUF];
    controllerClass = [theBundle classNamed:ctrlName];
    //NSLog(@"controllerClass=%@", controllerClass);
    if ((controllerClass == NULL) && ([processorClass superclass] != [NewGenericTool class])) {
      // failed to load class because it already exists
      if (debugmode) fprintf(stderr, "failed to load\n");
      [theBundle release];
    }
//    if ([processorClass superclass] == [NewGenericTool class])
//      [tools addObject:[processorClass newTool:self]];
//    else	
      [tools addObject:[controllerClass newTool:self]];
    [toolnames addObject:baseName];

    // Load help from the bundle:
    //[[NXHelpPanel new] addSupplement:@"SuppHelp" inPath:[theBundle directory]];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", @"Error loading tool '%@'.\n%@", @"OK", nil, nil,
                    fileName, localException);
    NSLog(@"exception during -loadTool %s: %@\n", fileName, localException);
  NS_ENDHANDLER
}

- (void)prepareProcessorPopUp
{
  int           x, row;
  int           numRows;
  NSArray       *itemTitles;
  NSString      *toolName, *tName, *pullDownTitle;

  pullDownTitle = [[processorPopUp itemTitleAtIndex:0] retain];
  [processorPopUp removeAllItems];
  [processorPopUp addItemWithTitle:pullDownTitle];
  [pullDownTitle autorelease];

  for(x=0; x<[tools count]; x++) {
    toolName = [[[tools objectAtIndex:x] dataProcessor] toolName];
    numRows = [processorPopUp numberOfItems];
    itemTitles = [processorPopUp itemTitles];
    for(row=1; row<numRows; row++) {
      tName = [itemTitles objectAtIndex:row];
      if([toolName caseInsensitiveCompare:tName] == NSOrderedAscending) break;
    }
    [processorPopUp insertItemWithTitle:toolName atIndex:row];
  }
  //[processorPopUp sizeToFit];
}


- (void)loadLibDir:(NSString *)path :(id)updateBox
{
  NSFileManager *filemanager;
  NSString *file;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;
      
  if (debugmode) fprintf(stderr,"loading libs from '%s'\n",[path cString]);
  filemanager = [NSFileManager defaultManager];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
      return;
  contents = [filemanager directoryContentsAtPath:path];
  enumerator = [contents objectEnumerator];
  while ((file = [enumerator nextObject])) {
    if ([libraryNames containsObject:file]) {
      if (debugmode) fprintf(stderr,"    didn't load %s because it's already been loaded\n", [file cString]);
    } else
      if ([[file pathExtension] isEqualToString:TOOLSTREXT]) {
        [updateBox updateMessage:self :(char*)[file cString]];
        if (debugmode) fprintf(stderr, " '%s'\n",[file cString]);
        if (debugmode) NSLog(@" '%s'",[file cString]);
        [[[NSBundle alloc] initWithPath:[path stringByAppendingPathComponent:file]] principalClass];
        [libraryNames addObject:file];
      }
  }
}

- (void)loadToolDir:(NSString *)_path :(id)updateBox
{
  NSFileManager *filemanager;
  NSString *file, *oldDir;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;
  NSString *path = [_path stringByStandardizingPath];

  if (debugmode) fprintf(stderr,"loading tools from '%s'\n",[path cString]);
  filemanager = [NSFileManager defaultManager];
  oldDir = [[filemanager currentDirectoryPath] copy];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
    NSLog(@"No such path %@", path);
    return;
  }
  if(![filemanager changeCurrentDirectoryPath:path]) {
    NSLog(@"Cannot chdir to %@", path);
    return;
  }
  contents = [filemanager directoryContentsAtPath:[filemanager currentDirectoryPath]];
  enumerator = [contents objectEnumerator];
  while (file = [enumerator nextObject]) {
    if ([[file pathExtension] isEqualToString:TOOLSTREXT]) {
      [updateBox updateMessage:self :(char*)[file cString]];
      if (debugmode) fprintf(stderr, " '%s'\n",[file cString]);
      [self loadTool:[path stringByAppendingPathComponent:file]];
    }
  }
  [filemanager changeCurrentDirectoryPath:oldDir];
  [oldDir release];
}

- loadTools
{
  StatusController   *updateBox;
//  BOOL   loadPublic = [[NSUserDefaults standardUserDefaults] boolForKey:@"loadPublicTools"];
//  BOOL   loadPrivate = [[NSUserDefaults standardUserDefaults] boolForKey:@"loadPrivateTools"];
  NSDictionary *resourcePaths = [[NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"ToolsPaths"]] retain];
  NSEnumerator *directoryEnumerator = [resourcePaths objectEnumerator];
  NSString *path;

  updateBox = [StatusController connect];
  toolnames = [[NSMutableArray arrayWithCapacity:5] retain];
  libraryNames = [[NSMutableArray arrayWithCapacity:5] retain];

  //first add the ABIProcessed place holder tool
  [tools addObject:[ABIProcessToolCtrl newTool:self]];
  [toolnames addObject:@"ABIProcessTool.bundle"];

  while ((path = [directoryEnumerator nextObject])) {
    [updateBox messageConnect:self :(char *)[[NSString stringWithFormat:@"Loading from %@", path] cString] :""];
    [self loadToolDir:path
                     :updateBox];
    [updateBox done:self];
    [updateBox messageConnect:self :(char *)[[NSString stringWithFormat:@"Loading from %@", [path stringByAppendingPathComponent:@"NSLibraries"]] cString] :""];
    [self loadLibDir:[path stringByAppendingPathComponent:@"NSLibraries"]
                     :updateBox];
    [updateBox done:self];
  }
  
  [self prepareProcessorPopUp];
  return self;	
}

- (void)createNewNDDSToolLink:sender;
{
  NDDSLinker  *linker;

  linker = [NDDSLinker new];
  [linker runModal];
  
}

- (void)showTools:sender
{
  [toolPanel orderFront:self];
}

- (void)showBases:sender
{
  [baseViewingID showPanel:self];
}

- (void)showScriptEditor:sender
{
  [scriptEditor showPanel];
}

-(BOOL) toolInScript:(NSString *)toolname
{
	BOOL			found = NO;
	NewScript	*currentScript;
	int				i, noOfTools;
	NSString	*scriptName;
	
	currentScript = [GSeqEdit currentScript];
	noOfTools = [currentScript count];
	for (i=0; i < noOfTools; i++) {
		scriptName = [[currentScript toolAt:i] toolName];
		if ([scriptName isEqualToString:toolname])
			found = YES;
	}
	return found;
}

- (void)setInspector:(NSView*)aView
{
	int				i;
  
  //[inspectorBox setContentViewMargins:NSMakeSize(0, 0)];
  if(aView == NULL) {
    [inspectorBox setContentView:emptyInspectorID];
    [[toolButton1 retain] removeFromSuperview];
    [[toolButton2 retain] removeFromSuperview];
    [[toolButton3 retain] removeFromSuperview];
    currentToolState = TM_noTool;
    if (debugmode) fprintf(stderr, "empty retainCount=%d\n", [emptyInspectorID retainCount]);
  }
  else {
    [inspectorBox setContentView:aView];
    //[inspectorBox setContentView:NULL];
    if (debugmode) fprintf(stderr, "%s retain count=%d\n", [[aView description] cString], [aView retainCount]);
  }
	for (i=0; i<[tools count]; i++) {
		if (![self toolInScript:[[[tools objectAtIndex:i] dataProcessor] toolName]])
			[[tools objectAtIndex:i] resetParams];
	}
  [inspectorBox display];
  [toolPanel orderFront:self]; 
}


- (void)synchronizeToScript
{
  int  i;
	NewScript        *currentScript = [GSeqEdit currentScript];

  
  if (GSeqEdit==nil) {
    currToolIx = -1;
    [self updateToolInspector];
  }
  else [self showParamsForCurrentScriptTool];

  //now switch all tools to select all Channels in chanSelectID
  for(i=0; i<[tools count]; i++) {
    [[tools objectAtIndex:i] resetSelChannels];
    [[tools objectAtIndex:i] displayParams];
  }
	[self setControllerForToolsInScript:currentScript];
  //[tools makeObjectsPerform:@selector(resetSelChannels)];  
  //[tools makeObjectsPerform:@selector(displayParams)]; 
}

- (void)checkForNewResourcesInScript:(NewScript*)aScript
{
  int              i;
  ResourceToolCtrl *someToolCtrl;
  BOOL             foundNew = NO;
  NSMutableString  *toolsToUpdate = [NSMutableString string];

  for(i=0; i<[aScript count]; i++) {
    someToolCtrl = (ResourceToolCtrl*)[self controllerForClass:[[aScript toolAt:i] class]];
    [someToolCtrl setDataProcessor:[aScript toolAt:i]];
    if((someToolCtrl != nil) && [someToolCtrl isKindOfClass:[ResourceToolCtrl class]]) {
      if(![someToolCtrl checkIfResourceIsAvailable]) {
        if(foundNew) [toolsToUpdate appendFormat:@", %@", [[aScript toolAt:i] toolName]];
        else [toolsToUpdate appendString:[[aScript toolAt:i] toolName]];
        foundNew = YES;
      }
    }
  }
  
  if(foundNew) {
    if(NSRunAlertPanel(@"New resources found in script",
                       @"Script contains new resources for tools:%@",
                       @"Create resources", @"Ignore", nil,
                       toolsToUpdate) == NSAlertDefaultReturn) {
      for(i=0; i<[aScript count]; i++) {
        someToolCtrl = (ResourceToolCtrl*)[self controllerForClass:[[aScript toolAt:i] class]];
        [someToolCtrl setDataProcessor:[aScript toolAt:i]];
        if((someToolCtrl != nil) && [someToolCtrl isKindOfClass:[ResourceToolCtrl class]]) {
          if(![someToolCtrl checkIfResourceIsAvailable])
            [someToolCtrl createResourceFromDataProcessor];
        }
      }
    }
  }
}

- (BasesView*)baseViewingID { return baseViewingID; };
- (ScriptEditor*)scriptEditor { return scriptEditor; }
- tools { return tools; }

- (void)updateToolInspector
{
  if((currToolIx >= 0) && (currToolIx < [tools count])) {
    [[tools objectAtIndex:currToolIx] displayParams];
    [self setInspector:[[tools objectAtIndex:currToolIx] inspectorView]];
    [[tools objectAtIndex:currToolIx] inspectorDidDisplay]; 
  }
  else
    [self setInspector:nil];
}

- activateToolWithIndex:(int)index
{
  if(currToolIx >= 0)
    if(![[tools objectAtIndex:currToolIx] inspectorWillUndisplay]) return NULL;

  if((index >= 0) && (index<[tools count])) {
    currToolIx = index;
    [[tools objectAtIndex:currToolIx] displayParams];
    [self updateToolInspector];
    [[tools objectAtIndex:currToolIx] inspectorDidDisplay];

  } else {
    currToolIx = -1;
    [self updateToolInspector];
  }
		
  return self;
}
	

- (GenericToolCtrl*)controllerForClass:theClass
{
  int i,count=[tools count];
  id currTool;

  for (i=0;i<count;i++) {
    currTool = [tools objectAtIndex:i];
    if([[currTool dataProcessor] class]==theClass)
      return currTool;
  }
  return nil;
}

- (void)setControllerForToolsInScript:(NewScript *)aScript
{
	GenericToolCtrl	*myController;
	GenericTool			*myTool;
	int							count, i;
	
	count = [tools count];
	for (i = 0; i < count; i++) {
		myTool = [aScript toolAt:i];
		if (myTool != nil) {
			myController = [self controllerForClass:[myTool class]];
			[[myController dataProcessor] setController:myController];
		}
	}
}

- (void)showTool:tool
{
  [self activateToolWithIndex:[tools indexOfObject:tool]]; 
}

- (void)showToolNotification:(NSNotification*)aNotification;
{
  [self activateToolWithIndex:[tools indexOfObject:[aNotification object]]]; 
}


- (void)activateTool:sender
{
  //sent from the ProcessorPoUplist of avaliable tools
  int        index, count=[tools count];
  NSString   *toolName, *tName;

  index = [processorPopUp indexOfSelectedItem];
  if(index == 0) {
    currentToolState = TM_noTool;
    [self activateToolWithIndex:-1];
    return;
  }
  
  toolName = [processorPopUp titleOfSelectedItem];
  //printf("activating '%s'\n",[toolName cString]);
  for(index=0; index<count; index++) {
    tName = [[[tools objectAtIndex:index] dataProcessor] toolName];
    if([toolName isEqualToString:tName]) break;
  }

  currentToolState = TM_newTool;
  [self setupToolButtons:index];
  [self activateToolWithIndex:index];
}
	
- (void)showParamsForCurrentScriptTool
{
  GenericTool      *currTool;
  GenericToolCtrl  *controller;
  NewScript        *currentScript = [GSeqEdit currentScript];

  //NSLog(@"ToolMaster try to showParams from script");
  currTool = [currentScript toolAt:[currentScript currentEditIndex]];
  if (currTool == nil) {
    currentToolState = TM_noTool;
    [self activateToolWithIndex:-1];
    return;
  }

  //if currentTool is making new resource, it can't undisplay
  if((currToolIx>=0) && (![[tools objectAtIndex:currToolIx] inspectorWillUndisplay])) return;

  currTool = [currTool copy];
  [currTool clearPointers];

  controller = [self controllerForClass:[currTool class]];
  [controller setDataProcessor:[currTool autorelease]];
		
  currentToolState = TM_toolInScript;
  [self setupToolButtons:0];
  
  [self showTool:controller];
  //[toolPanel display];  //to make display switch look faster
}

- (void)setupToolButtons:(int)index
{
  NewScript  *currentScript = [GSeqEdit currentScript];

  if([expertMode isEqualToString:@"beginner"]) {
    [[toolButton1 retain] removeFromSuperview];
    [[toolButton2 retain] removeFromSuperview];
    [[toolButton3 retain] removeFromSuperview];
    return;
  }

  switch(currentToolState) {
    case TM_newTool:
      if((currentScript == nil) || [[[tools objectAtIndex:index] dataProcessor] isOnlyAnInterface]) {
        [[toolButton1 retain] removeFromSuperview];
        [[toolButton2 retain] removeFromSuperview];
        [[toolButton3 retain] removeFromSuperview];
      } else if([currentScript currentTool] == nil) {
        //current tool in script is not a tool (probably raw data)
        // can only do an append after
        [toolButton1 setTitle:@"Append"];
        if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton1] == NSNotFound)
          [[toolPanel contentView] addSubview:toolButton1];
        [[toolButton2 retain] removeFromSuperview];
        [[toolButton3 retain] removeFromSuperview];
      } else {
        [toolButton1 setTitle:@"Append"];
        if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton1] == NSNotFound)
          [[toolPanel contentView] addSubview:toolButton1];

        [toolButton2 setTitle:@"Insert"];
        if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton2] == NSNotFound)
          [[toolPanel contentView] addSubview:toolButton2];

        [toolButton3 setTitle:@"Replace"];
        if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton3] == NSNotFound)
          [[toolPanel contentView] addSubview:toolButton3];
      }
      break;

    case TM_toolInScript:
      [toolButton1 setTitle:@"Replace"];
      if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton1] == NSNotFound)
        [[toolPanel contentView] addSubview:toolButton1];

      [toolButton2 setTitle:@"Delete"];
      if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton2] == NSNotFound)
        [[toolPanel contentView] addSubview:toolButton2];

      [[toolButton3 retain] removeFromSuperview];
			[toolButton3 setTitle:@"Append"];
			if([[[toolPanel contentView] subviews] indexOfObjectIdenticalTo:toolButton3] == NSNotFound)
          [[toolPanel contentView] addSubview:toolButton3];
      break;

    case TM_noTool:
      [[toolButton1 retain] removeFromSuperview];
      [[toolButton2 retain] removeFromSuperview];
      [[toolButton3 retain] removeFromSuperview];
      break;
  }
}

- (void)deleteBase
{
	if([GSeqEdit baseStorageID] != NULL)
		[baseViewingID deleteSelectedBase]; 
}

- (void)loadBundles
{
  StatusController   *updateBox;
  NSFileManager *filemanager;
  NSString *file, *path;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;
  Class currBundleClass;
  NSBundle *newBundle;

  /** Local Bundles higher priority over Public Tools.
  ** i.e. local version of a tools will be the one loaded
  **/
  updateBox = [StatusController connect];
  [updateBox messageConnect:self :"Loading Bundles" :""];

#ifdef WIN32
  path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSBundles"];
#else
  path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSBundles"];
#endif

  if (debugmode) fprintf(stderr,"loading bundles from '%s'\n",[path cString]);
  filemanager = [NSFileManager defaultManager];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
    [updateBox done:self];
    return;
  }

  contents = [filemanager directoryContentsAtPath:path];
  enumerator = [contents objectEnumerator];
  while (file = [enumerator nextObject]) {
    if ([[file pathExtension] isEqualToString:BUNDLESEXT]) {
      [updateBox updateMessage:self :(char*)[file cString]];
      if (debugmode) fprintf(stderr, " '%s'\n",[file cString]);
      newBundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:file]];
      if (currBundleClass = [newBundle principalClass]) {
        //Need to do anything to initialize bundles?
      }
    }
  }
  [updateBox done:self];

  return;	
}


- (void)appWillInit
{
  int i;
  
  /* from distributor which is the delegate for the App which recieves the
     first message of this cascade.
     */
  //[buttonsBox setOffsets:0 :0];
  [[toolButton1 retain] removeFromSuperview];
  [[toolButton2 retain] removeFromSuperview];
  [[toolButton3 retain] removeFromSuperview];
  [toolPanel display];
  
  [toolPanel setFrameUsingName:@"ToolPanel"];
  [processorPopUp setAction:@selector(activateTool:)];
  [processorPopUp setTarget:self];
  [processorPopUp retain];
  [self loadTools];
//  [self loadBundles];

  emptyInspectorID = [[inspectorBox contentView] retain];
  [inspectorBox retain];
  currToolIx = -1;

  for(i=0; i<[tools count]; i++) {
    [[tools objectAtIndex:i] appWillInit];
  }
  //[tools makeObjectsPerform:@selector(appWillInit)];
  
  [scriptEditor appWillInit];
  [baseViewingID appWillInit];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(synchronizeToScript)
                                               name:@"BFSynchronizeScriptAndTools"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(switchExpertMode)
                                               name:@"BFSwitchExpertMode"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(showToolNotification:)
                                               name:@"ToolMasterShowTool"
                                             object:nil];

  [self switchExpertMode];
  [toolPanel orderFront:self];
}

- (void)windowDidMove:(NSNotification *)aNotification
{
  //to record the toolPanel's new location in the defaults database
  //NSLog(@"toolPanel moved");
  [toolPanel saveFrameUsingName:@"ToolPanel"];
}

- (void)registerForEventNotification:tool
{
	if (![eventNotifyList containsObject:tool]) [eventNotifyList addObject:tool]; 
}

- (void)deregisterForEventNotification:tool
{
	[eventNotifyList removeObject:tool]; 
}

-(void)mouseEvent:(range)theRange
{
}



- (void)notifyMouseEvent:(range)theRange
{
  int i, c = [eventNotifyList count];
	//The NSRange that was used here started failing when Apple changed the length to an unsigned.  We can have negatives...
	//  NSRange  tempRange;

  if(![expertMode isEqualToString:@"beginner"]) {
  //  tempRange = NSMakeRange(theRange.start, theRange.end-theRange.start);
    //NSLog(@"ToolMaster notifyMouseEvent %d, %d", tempRange.location, tempRange.length);
    for (i=0;i<c;i++)
      if ([[eventNotifyList objectAtIndex:i] conformsToProtocol:@protocol(BFToolMouseEvent)]) 
	  {
		  [self mouseEvent:theRange];
		  [[eventNotifyList objectAtIndex:i] mouseEvent:theRange];
      }
  } 
}

- (void)notifyKeyEvent:(NSEvent*)keyEvent
{
  int i, c = [eventNotifyList count];

  if(![expertMode isEqualToString:@"beginner"]) {
    for (i=0;i<c;i++)
      if ([[eventNotifyList objectAtIndex:i] conformsToProtocol:@protocol(BFToolKeyEvent)])
        [[eventNotifyList objectAtIndex:i] keyEvent:keyEvent];
  } 
}	

- (void)log:(NSString*)message;
{
  NSLog(message);
}


/******
*
* Tool Action Section
* (append, insert, replace, delete)
*
*******/

- (void)appendTool
{
  GenericToolCtrl     *newTool;
  GenericTool         *newProcessor;
  NewScript           *currentScript;
  BOOL                statusOK;

  if((currToolIx < 0) || (currToolIx >= [tools count])) return;
  if (GSeqEdit == nil) return;

  //NSLog(@"toolAction APPEND");

  newTool = [tools objectAtIndex:currToolIx];
  if(![newTool inspectorWillUndisplay]) return;
  [newTool getParams];
  newProcessor = [[newTool dataProcessor] copy];

  currentScript = [GSeqEdit currentScript];
  if (debugmode) fprintf(stderr, " currentScriptEditPosition=%d\n", [currentScript currentEditIndex]);
  statusOK = [currentScript appendTool:newProcessor];
  [newProcessor release];

  if(statusOK) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
    //if([currentScript autoexecute]) [GSeqEdit shouldRedraw];
  }
}

- (void)replaceTool
{
  GenericToolCtrl     *newTool;
  GenericTool         *newProcessor;
  NewScript           *currentScript;
  BOOL                statusOK;

  if((currToolIx < 0) || (currToolIx >= [tools count])) return;
  if (GSeqEdit == nil) return;

  //NSLog(@"should replace toolInScript with new one");

  newTool = [tools objectAtIndex:currToolIx];
  if(![newTool inspectorWillUndisplay]) return;
  [newTool getParams];
  newProcessor = [[newTool dataProcessor] copy];

  currentScript = [GSeqEdit currentScript];
  if (debugmode) fprintf(stderr, " currentScriptEditPosition=%d\n", [currentScript currentEditIndex]);
  statusOK = [currentScript replaceToolAtIndex:[currentScript currentEditIndex]
                                      withTool:newProcessor];
  [newProcessor release];

  if(statusOK) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
    //if([currentScript autoexecute]) [GSeqEdit shouldRedraw];
  }
}

- (void)insertTool
{
  GenericToolCtrl     *newTool;
  GenericTool         *newProcessor;
  NewScript           *currentScript;
  BOOL                statusOK;

  if((currToolIx < 0) || (currToolIx >= [tools count])) return;
  if (GSeqEdit == nil) return;
  //NSLog(@"toolAction INSERT");

  newTool = [tools objectAtIndex:currToolIx];
  if(![newTool inspectorWillUndisplay]) return;
  [newTool getParams];
  newProcessor = [[newTool dataProcessor] copy];

  currentScript = [GSeqEdit currentScript];
  if (debugmode) fprintf(stderr, " currentScriptEditPosition=%d\n", [currentScript currentEditIndex]);
  statusOK = [currentScript insertTool:newProcessor];
  [newProcessor release];

  if(statusOK) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
    //if([currentScript autoexecute]) [GSeqEdit shouldRedraw];
  }
}

- (void)deleteTool
{
  NewScript           *currentScript;

  //NSLog(@"should delete this tool");
  if((currToolIx < 0) || (currToolIx >= [tools count])) return;
  if (GSeqEdit == nil) return;
  currentScript = [GSeqEdit currentScript];

  if(![[[tools objectAtIndex:currToolIx] dataProcessor]
            isMemberOfClass:[[currentScript toolAt:[currentScript currentEditIndex]] class]]) {
    if (debugmode) NSLog(@"error in replace, current tool in toolMaster not same as current tool in script");
    return;
  }
  if (debugmode) fprintf(stderr, " currentScriptEditPosition=%d\n", [currentScript currentEditIndex]);

  if([currentScript removeToolAtIndex:[currentScript currentEditIndex]]) {
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
    //if([currentScript autoexecute]) [GSeqEdit shouldRedraw];
  }
}

- (void)toolAction1:sender
{
  switch(currentToolState) {
    case TM_newTool:      //append
      [self appendTool];
      break;
    case TM_toolInScript: //replace
      [self replaceTool];
      break;
    case TM_noTool:       //do nothing
      break;
  }
}

- (void)toolAction2:sender
{
  switch(currentToolState) {
    case TM_newTool:     //insert
      [self insertTool];
      break;
    case TM_toolInScript:
      [self deleteTool];
      break;
    case TM_noTool:      //do nothing
      break;
  }
}

- (void)toolAction3:sender
{
  switch(currentToolState) {
    case TM_newTool:      //replace
      [self replaceTool];
      break;
    case TM_toolInScript: //do nothing
			[self appendTool];
      break;
    case TM_noTool:       //do nothing
      break;
  }
}

/******
*
* BFToolMasterMethods protocol methods.  First set are forwarded to SequenceEditor
*
******/

- (int)numberChannels
{
  if(GSeqEdit == nil) return 0;
  return [GSeqEdit numberChannels];
}

- (Trace*)pointStorageID
{
  if(GSeqEdit == nil) return nil;
  return [GSeqEdit pointStorageID];
}

- (Sequence*)baseStorageID
{
  if(GSeqEdit == nil) return nil;
  return [GSeqEdit baseStorageID];
}

- (EventLadder*)currentLadder
{
  if(GSeqEdit == nil) return nil;
  return [GSeqEdit currentLadder];
}

- (NSColor*)colorForChannel:(int)channel
{
  if(GSeqEdit == nil) return nil;
  return [GSeqEdit channelColor:(int)channel];
}

- (void) setColorForChannel:(int)channel :(NSColor*)color
{
  [GSeqEdit setColor:color channel:channel];
  [[GSeqEdit masterViewID] setColorWells];
}

// these methods are forwarded to masterView
- (void)toggleShiftMode
{
  [[GSeqEdit masterViewID] toggleShiftMode];
}

- (void)setShiftChannel:(int)channel
{
  [[GSeqEdit masterViewID] setShiftChannel:channel];
}

- (void)doShift:(int)state channel:(int)channel
{
  [[GSeqEdit masterViewID] doShift:state channel:channel];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
  return [[GSeqEdit masterViewID] writeSelectionToPasteboard:pboard types:types];
}

- (void)askToRedraw
{
  [GSeqEdit shouldRedraw];
}
@end
