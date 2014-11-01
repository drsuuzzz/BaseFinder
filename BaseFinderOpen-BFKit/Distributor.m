
/* "$Id: Distributor.m,v 1.11 2008/04/15 20:50:22 smvasa Exp $" */

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

#import "Distributor.h"
#import "SequenceEditor.h"
#import "ToolMaster.h"
#import "MasterView.h"
#import "BasesView.h"
#import "ScriptEditor.h"
#import "PrintingOptions.h"
#import <BaseFinderKit/LanesFile.h>
#import "MultiFileManager.h"
#import <GeneKit/StatusController.h>
#import <GeneKit/AsciiArchiver.h>
#import <Foundation/NSUserDefaults.h>
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "buildNumber.h"
#import "DirectoryBrowser.h"
#import "PhredFile.h"

/****
* April 15, 1994: Relinked so print options appear in print panel instead of page
* layou panel.
****/

@implementation Distributor

- init
{
  NSArray   *sendTypes = [NSArray arrayWithObjects:NSTabularTextPboardType, nil];

  [super init];
  multiFileManager = nil;
  [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:NULL];	//to send out
  [NSApp setServicesProvider:self];	//to receive service requests
  saveFormat = 6; //.scf
  saveGroupIndex = SELECTED_FILES;
  openPath = [NSHomeDirectory() retain];
  lastSaveDir = [NSHomeDirectory() retain];
//  savePanel = nil;
  return self;
}

- (void)dealloc
{
  [openPath release];
  [lastSaveDir release];
  [super dealloc];
}

/* File types right now:
seq - archived objects (the most native format)
dat, fd, txt - tab delimited text floating point data
ccd - binary data from HUGE/CCD
cap - binary data from capillary system
bfd - binary floating point data, 4 byte floats, each in a block following
      the previous one.
abi, ABI, abd, ABD, ab1, fsa - raw/processed ABI sequencer format
*/

- (void)open:sender
{	
  NSArray  *files;
  //NSArray  *OLDfileType = [NSArray arrayWithObjects:@"bf",@"ccd",@"snd",@"fd",@"cap",@"bfd", nil];
  NSArray  *fileType = [NSArray arrayWithObjects:@"dat", @"abi", @"ABI", @"abd", @"ABD", @"ab1", @"fsa",
    @"lanes", @"scf", @"lane", @"esd", @"txt", @"shape", nil];
  NSOpenPanel   *openPanel;
  int  i;
  StatusController   *statusPanel = [StatusController connect];
  
  openPanel = [NSOpenPanel openPanel];

  [openPanel setAllowsMultipleSelection:YES];

  if ([openPanel runModalForDirectory:openPath
                                 file:@""
                                types:fileType]) {
    [openPath release];
    openPath = [[openPanel directory] retain];

    [statusPanel center];
    [statusPanel messageConnect:self :"Opening files" :""];
    files = [openPanel filenames];
    for (i=0; i<[files count]; i++) {
      [statusPanel updateMessage:self :(char*)[[[files objectAtIndex:i] lastPathComponent] cString]];
      [self openFile:[files objectAtIndex:i]];
    }
    [statusPanel done:self];
    
    if(GSeqEdit == nil) [SequenceEditor new];
    [GSeqEdit setLanesFile:[multiFileManager currentLanesFile]];
    /* following code is to enable mouseEntered, mouseExited, and mouseMoved events */
    [GSeqEdit shouldRedraw];
    [[GSeqEdit masterViewID] resetTrackingRectToVisible];
    [GSeqEdit show:self];
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  }
}

- (void)openDirectory:sender;
{
  NSArray  *files;
  NSArray  *fileTypes = [NSArray arrayWithObjects:@"dat", @"abi", @"ABI", @"abd", @"ABD", @"ab1", @"fsa",
    @"lanes", @"scf", @"lane", @"esd", @"txt", @"shape", nil];
  NSOpenPanel   *openPanel;
  NSString      *thisFile, *extn, *dirToOpen = [NSHomeDirectory() retain];
  int  i;
  StatusController   *statusPanel = [StatusController connect];

  openPanel = [NSOpenPanel openPanel];

  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanChooseFiles:NO];
  [openPanel setTreatsFilePackagesAsDirectories:NO];
  [openPanel setTitle:@"Open all in directory"];

  if ([openPanel runModalForDirectory:dirToOpen
                                 file:@""
                                types:fileTypes]) {
    [dirToOpen release];
    dirToOpen = [[openPanel filename] retain];
    NSLog(@"about to open all in '%@'", dirToOpen);

    [statusPanel center];
    [statusPanel messageConnect:self :"Opening files" :""];
    files = [[NSFileManager defaultManager] directoryContentsAtPath:dirToOpen];
    for (i=0; i<[files count]; i++) {
      thisFile = [files objectAtIndex:i];
      extn = [[thisFile pathExtension] lowercaseString];
      if([fileTypes indexOfObject:extn] != NSNotFound) {
        fprintf(stderr, "%s about to open\n", [thisFile cString]); fflush(stderr);
        [statusPanel updateMessage:self :""];
        [statusPanel updateMessage:self :(char*)[thisFile cString]];
        [self openFile:[dirToOpen stringByAppendingPathComponent:thisFile]];
      }
      else {
        fprintf(stderr, "%s not valid file\n", [thisFile cString]); fflush(stderr);
      }      
    }
    [statusPanel done:self];

    if(GSeqEdit == nil) [SequenceEditor new];
    [GSeqEdit setLanesFile:[multiFileManager currentLanesFile]];
    /* following code is to enable mouseEntered, mouseExited, and mouseMoved events */
    [GSeqEdit shouldRedraw];
    [[GSeqEdit masterViewID] resetTrackingRectToVisible];
    [GSeqEdit show:self];
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  }
}

- (void)openFile:(NSString *)fullPath
{
  LanesFile         *lanesFileObj;
  NSString          *type = [[fullPath pathExtension] lowercaseString];
  NSArray           *fileTypes = [NSArray arrayWithObjects:@"dat", @"abi", @"ABI", @"abd", @"ABD", @"ab1", @"fsa",
                                  @"lanes", @"scf", @"lane", @"esd", @"txt", @"shape",nil];
  //  StatusController  *updateBox;
  //  char              myname[32];	

  if(![fileTypes containsObject:type]) {
    NSLog(@"Trying to open file of unknown type %@", type);
    return;
  }
  NS_DURING

    lanesFileObj = [[LanesFile alloc] initWithContentsOfFile:fullPath];



    if(lanesFileObj == nil) {		/* error, or cancel of load */
      return;
    }
    [lanesFileObj switchToLane:1]; // Forces a load

    [toolMaster checkForNewResourcesInScript:[lanesFileObj activeScript]];
		[toolMaster setControllerForToolsInScript:[lanesFileObj activeScript]];
    [multiFileManager addLanesFile:lanesFileObj];
    [lanesFileObj release];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", @"Error loading file '%@'.\n%@", @"OK", nil, nil,
                    [fullPath lastPathComponent], localException);
    NSLog(@"exception during -openFile %@: %@\n", fullPath, localException);
    if(lanesFileObj != nil) [lanesFileObj release];
    lanesFileObj = nil;
  NS_ENDHANDLER
}


- (void)loadFromPasteboard:(NSPasteboard*)pasteboard userData:(NSString *)userData error:(NSString **)msg;
{
  //Next System Services Provider method
  NSData    *tempData;
  id        seqEditID=nil, initRtn=NULL;
  int       x=0, ok=0;
  NSArray   *types;
  StatusController  *updateBox;
  LanesFile         *lanesFileObj;

  if (debugmode) fprintf(stderr,"LOAD FROM PASTEBOARD\n");
  types = [pasteboard types];
		/* this message must be sent before a read can be sent to a pasteboard */
  for(x=0; x<[types count]; x++) {
    if([[types objectAtIndex:x] isEqualToString:NSTabularTextPboardType]) ok=1;
    if (debugmode) fprintf(stderr," avail %s\n", [[types objectAtIndex:x] cString]);
  }
  if(!ok) return;

  updateBox = [StatusController connect];
  [updateBox processConnect:self :"Loading Data from pasteboard"];

  tempData = [pasteboard dataForType:NSTabularTextPboardType];
  if (debugmode) fprintf(stderr,"pbStream = %d\n", (int) tempData);

  lanesFileObj = [[LanesFile alloc] initFromTabedData:tempData];
  [updateBox done:self];

  if(lanesFileObj == nil) {	/* error, or cancel of load */
    /*****
    NXRunAlertPanel(
                    [stringTable valueForStringKey:"Open Alert Title"],
                    [stringTable valueForStringKey:"Open Alert Message"],
                    [stringTable valueForStringKey:"ok button"],
                    NULL, NULL, fullPath);
    *****/
    [seqEditID release];
    return;
  }
  [multiFileManager addLanesFile:lanesFileObj];

  if(GSeqEdit == nil) {
    seqEditID = [SequenceEditor new];
    initRtn = [seqEditID setLanesFile:lanesFileObj];
  }
  /* following code is to enable mouseEntered, mouseExited, and mouseMoved events */
  [[GSeqEdit masterViewID] resetTrackingRectToVisible];

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  [lanesFileObj release];
}

#ifdef OLDCODE
- (void)addOpenFile:sender
{		
  NSArray  *files;
  NSArray  *fileType = [NSArray arrayWithObjects:@"bf", @"dat", @"snd", @"fd", nil];
  NSOpenPanel   *openPanel = nil;
  char *thefileType;
  int  i;

  if (GSeqEdit) {

    openPanel = [NSOpenPanel openPanel];

    [openPanel setAllowsMultipleSelection:YES];

    if ([openPanel runModalForTypes:fileType]) {
      files = [openPanel filenames];
      for (i=0; i<[files count]; i++) {
        thefileType = strrchr([[files objectAtIndex:i] cString], '.');
        if (!strcmp(thefileType, ".dat") || !strcmp(thefileType, ".fd")) {
          if (![GSeqEdit addAnotherDataFile:[[files objectAtIndex:i] cString]])
            NSRunAlertPanel([NSString stringWithCString:[stringTable valueForStringKey:"Open Alert Title"]],
                            [NSString stringWithCString:[stringTable valueForStringKey:"Open Alert Message"]],
                            [NSString stringWithCString:[stringTable valueForStringKey:"ok button"]],
                            nil, nil, *files);
        }
        /***
          else if (!strcmp(thefileType, ".snd")) {
            if (![GSeqEdit addAnotherSNDFile:fullName])
              NXRunAlertPanel([stringTable valueForStringKey:"Open Alert Title"],
                              [stringTable valueForStringKey:"Open Alert Message"],
                              [stringTable valueForStringKey:"ok button"],
                              NULL, NULL, *files);
          }
        ***/
        else if (!strcmp(thefileType, ".bf")) {
          return;
        }
      }
      return;
    }
    return;
  }
}
#endif

- (int)application:sender openFile:(NSString *)path
{			
		NSLog(@"IN application:sender openFile:\n");
  [self openFile:path];
  if (debugmode) fprintf(stderr, "In app open with :%s    type:%s\n",[path cString], [[path pathExtension] cString]);

  if(GSeqEdit == nil) [SequenceEditor new];
  [GSeqEdit setLanesFile:[multiFileManager currentLanesFile]];
  /* following code is to enable mouseEntered, mouseExited, and mouseMoved events */
  [[GSeqEdit masterViewID] resetTrackingRectToVisible];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
  if ([[multiFileManager allLanesFiles] count] == 1)
    [GSeqEdit show:self];
	NSLog(@"DONE WITH application:sender openFile:\n");
  return YES;
}

- (BOOL)checkScript:(NSString*)filename
{
  NewScript       *newScript;
  AsciiArchiver   *archiver;
  NSString        *scriptName;
  BOOL            rtnVal=YES;

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:filename];
  if(archiver == NULL) return NO;

  NS_DURING
    newScript = [archiver readObjectWithTag:"script"];
    if(newScript!=nil) {
      [toolMaster checkForNewResourcesInScript:newScript];
    }
  NS_HANDLER
    scriptName = [filename lastPathComponent];
    if([scriptName length] == 0) scriptName = filename;
    NSRunAlertPanel(@"Error Panel", @"Error loading script '%@'.\n%@", @"OK", nil, nil,
                    scriptName, localException);
    NSLog(@"exception during -checkScript %@: %@\n", scriptName, localException);
    rtnVal = NO;
  NS_ENDHANDLER
  if(archiver) [archiver release];
  return rtnVal;
}

- (void)importScript:sender
{	
  NSArray         *files;
  NSOpenPanel     *openPanel;
  int             i;
  NSFileManager   *manager = [NSFileManager defaultManager];
  NSString        *thisPath, *newPath;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setAccessoryView:importScriptExtn];

  if ([openPanel runModalForDirectory:NSHomeDirectory()  file:nil  types:nil]) {
    files = [openPanel filenames];
    for (i=0; i<[files count]; i++) {
      thisPath = [files objectAtIndex:i];
      if(![self checkScript:thisPath]) return;

      if([importScriptExtn selectedRow] == 0) //public
        newPath = [NSString pathWithComponents:[NSArray arrayWithObjects:
          NSOpenStepRootDirectory(), @"LocalLibrary", @"BaseFinder", @"Scripts",
          [thisPath lastPathComponent], nil]];
      else
        newPath = [NSString pathWithComponents:[NSArray arrayWithObjects:
          NSHomeDirectory(), @"Library", @"BaseFinder", @"Scripts",
          [thisPath lastPathComponent], nil]];

      if([manager fileExistsAtPath:newPath]) {
        if(NSRunAlertPanel(@"Error Panel", @"Script named %@ already exists.", @"Overwrite", @"Cancel", nil,
                        [newPath lastPathComponent]) == NSAlertAlternateReturn) return;
        [manager removeFileAtPath:newPath  handler:nil];
      }

      [manager copyPath:thisPath toPath:newPath  handler:nil];
    }
    [[toolMaster scriptEditor] getResourceList:self]; //reloads the list of scripts
  }
}

- (void)attachPhredFile:sender;
{
  PhredFile     *aPhredFile;
  NSArray       *fileTypes = [NSArray arrayWithObjects:@"phd", @"1", nil];
  NSOpenPanel   *openPanel;
  NSString      *thisPath;
  Trace         *currentData;
  NSArray       *phredCalls;

  openPanel = [NSOpenPanel openPanel];
  [openPanel setAllowsMultipleSelection:NO];

  if ([openPanel runModalForDirectory:openPath file:nil types:fileTypes]) {
    [openPath release];
    openPath = [[openPanel directory] retain];

    thisPath = [openPanel filename];
    aPhredFile = [[PhredFile alloc] initWithContentsOfFile:thisPath];
    phredCalls = [[aPhredFile phredInfo] objectForKey:@"phredBaseCall"];
    currentData = [[[multiFileManager currentLanesFile] activeScript] currentData];
    [[currentData taggedInfo] setObject:phredCalls forKey:@"phredCalls"];

    [GSeqEdit shouldRedraw];
  }
}

/*****
*
* Saving Section
*
******/

- (NSString*)activeSaveExtension
{ // coordinate with extn2SaveFormat
  NSString     *extn;
  switch(saveFormat) {
    case 0: extn = @"lane"; break;
    case 1: extn = @"lanes"; break;
    case 2: extn = @"seqd"; break;
    case 3: extn = @"dat"; break;
    case 4: extn = @"bfd"; break;
    case 5: extn = @"seq"; break;
    case 6: extn = @"scf"; break;
    case 7: extn = @"scfd"; break;
    case 8: extn = @"fasta"; break;
		case 9: extn = @"txt"; break;
    case 10: extn = @"shape"; break;
    default: extn = [NSString string]; break;
  }
  return [[extn copy] autorelease];
}

- (int)extn2SaveFormat:(NSString *)extn
{ // coordinate with activeSaveExtension
  NSArray *extnList;
  int activeSaveFormat;

  extnList = [NSArray arrayWithObjects: @"lane", @"lanes", @"seqd", @"dat",
    @"bfd", @"seq", @"scf", @"scfd", @"fasta", @"txt", @"shape", nil];
  activeSaveFormat = [extnList indexOfObject:extn];
  return activeSaveFormat;
}
    
- (void)switchSaveFormat:sender
{
  NSString   *extn;

  saveFormat = [sender indexOfSelectedItem];
  extn = [self activeSaveExtension];
  if (debugmode)
    NSLog(@"switch savetype to %@", extn);
}

- (void)switchSaveGroupIndex:sender
{
  saveGroupIndex = [sender selectedRow];
  if (debugmode)
    NSLog(@"switch saveGroupIndex to %d", saveGroupIndex);
}

- (void)setCanChooseFiles:(BOOL)filesOkay
{
  if (filesOkay)
    canChooseFiles = YES;
  else
    canChooseFiles = NO;
}

- (void)setLastSaveDir:(NSString *)newDir
{
  if (lastSaveDir != nil)
    [lastSaveDir release];
  lastSaveDir = [[NSString stringWithString:newDir] retain];
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{ // delegate method for SavePanel
  NSFileManager    *manager = [NSFileManager defaultManager];
  BOOL isDir;

  [manager fileExistsAtPath:filename isDirectory:&isDir];
  return canChooseFiles || isDir; // if you can't choose files, it better be a dir
}

- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename
{ // delegate method for SavePanel
  BOOL isDir=NO;
  NSFileManager    *manager = [NSFileManager defaultManager];

  [manager fileExistsAtPath:filename isDirectory:&isDir];
  if (!canChooseFiles && isDir || canChooseFiles && !isDir)
    return YES;
  else
    return NO;
}

- (void)saveCurrentAs:sender // activated from app menu
{
  NS_DURING
    [self saveCurrentFileWithPanel];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", [localException reason], @"OK", nil, nil);
  NS_ENDHANDLER
}

- (void)saveCurrent:sender // activated from app menu
{
  NS_DURING
    [self save:CURRENT_FILE];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", [localException reason], @"OK", nil, nil);
  NS_ENDHANDLER
}

- (void)saveSelected:sender // activated from app menu
{
  NS_DURING
    [self save:SELECTED_FILES];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", [localException reason], @"OK", nil, nil);
  NS_ENDHANDLER
}

- (void)saveAs:sender // activated from app menu
{
  NS_DURING
    [self saveToDirWithPanel:saveGroupIndex];
  NS_HANDLER
    NSRunAlertPanel(@"Error Panel", [localException reason], @"OK", nil, nil);
  NS_ENDHANDLER
}

- (void)save:(enum fileGroupType)fileGroupIndex
{
  // No panel;  simply replaces files using the same formats
  int              i;
  NSMutableArray   *filesToSave = nil;
  LanesFile        *thisLane;

  if (fileGroupIndex == SELECTED_FILES)
      filesToSave = [multiFileManager selectedLanesFiles];
  else if (fileGroupIndex == CURRENT_FILE) {
		thisLane = [multiFileManager currentLanesFile];
		if (thisLane == nil)
			filesToSave = [multiFileManager selectedLanesFiles];
		else
			filesToSave = [NSArray arrayWithObject:thisLane];
	}
	else		
      filesToSave = [multiFileManager allLanesFiles];
  if (filesToSave == nil || [filesToSave count] == 0) {
    NSBeep();
    return;
  }
  for (i = 0; i < [filesToSave count]; i++) {
    thisLane = [filesToSave objectAtIndex: i];
//    [thisLane setDefaultSaveFormat:@"SAME AS LOADED"];
		if ([thisLane needsSaveAs] == NO)
			[thisLane saveCurrentToDefaultFormat];
		else
			[self saveCurrentFileWithPanel];
  }
  return;
}

- (void)setupSaveFormatForCurrentFile
{
  NSString         *saveName, *extn;
  int              theSaveFormat, i;
  NSArray          *subviewArray;
  NSPopUpButton    *extnPopUp=nil;

  saveName = [[GSeqEdit fileName]lastPathComponent];
  extn = [saveName pathExtension];
  theSaveFormat = [self extn2SaveFormat:extn];
  if (theSaveFormat == NSNotFound) {
    extn = @"scf";
    theSaveFormat=6;
  }

  subviewArray = [[saveCurrentPanelExtn contentView] subviews];
  for(i=0; i<[subviewArray count]; i++) {
    if([[subviewArray objectAtIndex:i] isKindOfClass:[NSPopUpButton class]])
      extnPopUp = [subviewArray objectAtIndex:i];
  }
  if(extnPopUp != nil) [extnPopUp selectItemAtIndex:theSaveFormat];  //sets the popUpButton
  saveFormat = theSaveFormat;            //sets saveFormat to match
}

- (void)saveCurrentFileWithPanel
{
  NSString         *saveName, *alertMsg;
  LanesFile        *thisLane;
  int              panelResponse;
  NSSavePanel		*savePanel;
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL overwriteFile = NO;
	
  thisLane = [GSeqEdit lanesFile];
  if (thisLane == nil) {
    NSBeep();
    return;
  }

  [self setupSaveFormatForCurrentFile];

  savePanel = [NSSavePanel savePanel];
  [savePanel setDelegate:self];
  [self setCanChooseFiles:YES];  // for save panel delegate methods
  [savePanel setTitle:@"Save displayed lanes file"];
//  [savePanel setPrompt:@"Filename"];
  [savePanel setAccessoryView:saveCurrentPanelExtn];
  
  do {
		panelResponse = [savePanel runModalForDirectory:lastSaveDir
																							 file:[[[GSeqEdit fileName] lastPathComponent] stringByDeletingPathExtension]];
		if(panelResponse == NSOKButton) {
			saveName = [savePanel filename];
			saveName = [saveName stringByDeletingPathExtension];  // normal case
			saveName = [self getFilenameFrom:saveName withFormat:saveFormat];
			if ([manager fileExistsAtPath:saveName]){
				alertMsg = [NSString stringWithFormat:@"The file %@ already exists.  Do you want to overwrite it?",saveName];
				if (NSRunAlertPanel(@"BaseFinder", alertMsg, @"No", @"Yes", nil)!=NSAlertDefaultReturn)
					overwriteFile = YES;		
			}
			else
				overwriteFile = YES;
		}
			
		} while ((panelResponse == NSOKButton) && (overwriteFile == NO));
		if (panelResponse == NSOKButton) {
			[self setLastSaveDir:[saveName stringByDeletingLastPathComponent]];
			//[self saveLane:thisLane withFormat:theSaveFormat andPath:saveName];
			[self saveLane:thisLane withFormat:saveFormat andPath:saveName];
			[GSeqEdit setFileName:[thisLane fileName]];
			[multiFileManager updateView];
		}
    

  savePanel = nil;
}

- (void)saveToDirWithPanel:(enum fileGroupType)fileGroupIndex
{
  // bring up SavePanel, and allow user to change file format, as
  // well as which file grouping will be saved
  int              i;
  NSString         *fileName, *dirName, *extn;
  NSMutableArray   *filesToSave = nil;
  LanesFile        *thisLane;
  BOOL             isDir=NO;
  NSFileManager    *manager = [NSFileManager defaultManager];
  int               panelResponse;
//  DirectoryBrowser *dirPanel = [[DirectoryBrowser alloc] init];
  NSSavePanel *savePanel = [NSSavePanel savePanel];

  filesToSave = [multiFileManager allLanesFiles];
  if (filesToSave == nil || [filesToSave count] == 0) {
    NSBeep();
    return;
  }

//  [dirPanel setAccessoryView:savePanelExtn];
  [savePanel setAccessoryView:savePanelExtn];
  extn = [self activeSaveExtension];
  [saveGroupIndexRadio selectCellAtRow:saveGroupIndex column:0];

//  panelResponse = [dirPanel runModalForDirectory:lastSaveDir];
  panelResponse = [savePanel runModal];
  
  if(panelResponse == NSFileHandlingPanelOKButton) {
	  if (saveGroupIndex == SELECTED_FILES)
		  filesToSave = [multiFileManager selectedLanesFiles];
	  
	  if (filesToSave == nil || [filesToSave count] == 0) {
		  NSRunAlertPanel(@"BaseFinderOpen", @"No files selected.", nil, nil, nil);
		  return;
	  }
	  
	  dirName = [savePanel directory];
	  if (![manager fileExistsAtPath:dirName isDirectory:&isDir])
		  [manager createDirectoryAtPath:dirName
							  attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777] forKey:@"NSPosixPermissions"]];
	  if ([manager fileExistsAtPath:dirName isDirectory:&isDir] && !isDir)
		  dirName = [dirName stringByDeletingLastPathComponent];
      //error, toDirectory is a file (BUT NT open panel does not allow selection of a directory)
	  
	  [self setLastSaveDir:dirName];
	  for(i=0; i<[filesToSave count]; i++) {
		  thisLane = [filesToSave objectAtIndex:i];
		  fileName = [[[thisLane fileName] lastPathComponent]
			  stringByDeletingPathExtension];
		  fileName = [dirName stringByAppendingPathComponent:fileName];
		  [self saveLane:thisLane withFormat:saveFormat andPath:fileName];
	  }
  }
}

- (NSString *)getFilenameFrom:(NSString *)fileName withFormat:(int)theSaveFormat
{
	NSString *newFileName;
	
	switch(theSaveFormat) {
		case 0:
			newFileName = [fileName stringByAppendingPathExtension:@"lane"];
			break;
		case 1:
			newFileName = [fileName stringByAppendingPathExtension:@"lanes"];
			break;
		case 3:
			newFileName = [fileName stringByAppendingPathExtension:@"dat"];
			break;
		case 5:
			newFileName = [fileName stringByAppendingPathExtension:@"seq"];
			break;
		case 6:
			newFileName = [fileName stringByAppendingPathExtension:@"scf"];
			break;
		case 8:
			newFileName = [fileName stringByAppendingPathExtension:@"fasta"];
			break;
		case 9:
			newFileName = [fileName stringByAppendingPathExtension:@"txt"];
			break;
    case 10:
      newFileName = [fileName stringByAppendingPathExtension:@"shape"];
      break;
		default:
			newFileName = fileName;
			break;
	}

	return newFileName;
}

- (void)saveLane:(LanesFile *)thisLane withFormat: (int)theSaveFormat
         andPath:(NSString *)fileName
{
  NS_DURING
    switch(theSaveFormat) {
      case 0:
				[thisLane saveCurrentToLANE:fileName];				
        break;
      case 1:
        [thisLane saveLanesTo:fileName];
        [GSeqEdit setFileName:fileName];
        break;
      case 3:
        [thisLane saveCurrentToDAT:fileName];
        break;
      case 5:
        [thisLane saveCurrentSequenceToSEQ:fileName];
        break;
      case 6:
        [thisLane saveCurrentToSCF:fileName];
        break;
      case 8:
        [thisLane saveCurrentSequenceToFASTA:fileName];
        break;
			case 9:
				[thisLane saveCurrentToDAT:fileName];
				break;
      case 10:
        [thisLane saveCurrentToSHAPE:fileName];
        break;
      default:
        [thisLane setDefaultSaveFormat:@"same as loaded"];
        [thisLane saveCurrentToDefaultFormat];
        break;
    }
    NS_HANDLER
      if([[localException name] isEqualToString:BFFileSystemException]) {
        NSRunAlertPanel(@"File System Error", [localException reason], @"OK", nil, nil);
        NSLog(@"File System Error during -saveLane %@\n", [localException reason]);
      } else {
        NSRunAlertPanel(@"Error Panel", @"Error saving to file '%@'.\n%@", @"OK", nil, nil,
                        [fileName lastPathComponent], localException);
        NSLog(@"exception during saveLane %@: %@\n", fileName, localException);
      }
    NS_ENDHANDLER
}

- openDoc:(char *)name
{
  /**** for unarchiving files (.bf files) ****/
  NSArchiver       *ts;
  SequenceEditor   *theObject=NULL;

  ts = [[NSUnarchiver alloc] initForReadingWithData:
    [NSData dataWithContentsOfFile:[NSString stringWithCString:name]]];
  if (ts) {
    theObject = [[ts decodeObject] retain];		/* SequenceEditor object */
    [ts release];
    GSeqEdit = theObject;
    [theObject setFileName:[NSString stringWithCString:name]];
    [theObject show:self];
  }
  return theObject;
}

- (void)closeActiveFile:sender
{
  [multiFileManager closeActiveFile:sender];
}

- (void)printFrontSeq:sender
{
  NSLog([[[NSFontManager sharedFontManager] availableFonts] description]);
  [GSeqEdit printSelf];
}

- (void)doPageLayout:sender
{
  [NSApp runPageLayout:self];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{	
  //NSApplication *theApplication = [notification object];
  NSString      *resourcePath;
  NSFileManager *filemanager;
	NSLog(@"IN applicationWillFinishLaunching\n");
  [self showInfoPanel:self];

  filemanager = [NSFileManager defaultManager];
  resourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects:
    NSOpenStepRootDirectory(), @"Library", nil]];
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];
  resourcePath = [resourcePath stringByAppendingPathComponent:@"BaseFinder"];
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];

  resourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects:
    NSHomeDirectory(), @"Library", nil]];
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];
  resourcePath = [resourcePath stringByAppendingPathComponent:@"BaseFinder"];
  if (![filemanager fileExistsAtPath:resourcePath])
    [filemanager createDirectoryAtPath:resourcePath attributes:nil];
  
  NS_DURING
    //[theApplication setServicesProvider:self];
    NS_HANDLER
      NSLog(@"Unable to set services %@",localException);
    NS_ENDHANDLER

    NS_DURING
      [toolMaster appWillInit];
    NS_HANDLER
      NSLog(@"Unable to appInit toolMaster %@",localException);
    NS_ENDHANDLER

    multiFileManager = [MultiFileManager new];
		NSLog(@"DONE WITH applicationWillFinishLaunching\n");
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{	
  NSArray   *sendTypes = [NSArray arrayWithObjects:NSTabularTextPboardType, nil];

  [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:NULL];	//to send out
  [infoPanel orderOut:self];
  [savePanelExtn retain];
  [saveCurrentPanelExtn retain];
  [importScriptExtn retain];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  return [multiFileManager closeAllFiles];
}

- (void)boundToAll:sender
{
  [[GSeqEdit masterViewID] boundToAll];
  [[GSeqEdit masterViewID] shouldRedraw];
}

- (void)boundToSelected:sender
{
  [[GSeqEdit masterViewID] boundToSelected];
  [[GSeqEdit masterViewID] shouldRedraw];
}

- (ToolMaster*)toolMaster { return toolMaster; }

- (void)stepBack:sender
{
  [[toolMaster scriptEditor] stepBy:-1];
}

- (void)stepForward:sender
{
  [[toolMaster scriptEditor] stepBy:1];
}

- (void)showInfoPanel:sender
{
  if(infoPanel==nil) {
#ifdef SHAPEFINDER
    [NSBundle loadNibNamed:@"InfoPanelSF.nib" owner:self];
#else
    [NSBundle loadNibNamed:@"InfoPanel.nib" owner:self];
#endif
    if (debugmode) NSLog(@"screen=%@", [[NSScreen mainScreen] deviceDescription]);
    [infoPanelBuildNumber setStringValue:[NSString stringWithFormat:@"build %d", BUILDNUMBER]];
  }
  [infoPanel center];
  [infoPanel makeKeyAndOrderFront:self];
  [infoPanel display];
}

- (void)flushScriptCache:sender;
{
  //resets the script to the beginning (raw data)
  //and flushes all subsequent data from cache
  NewScript  *currentScript = [GSeqEdit currentScript];

  if(currentScript == nil) return;

  [currentScript setCurrentEditIndex:0];
  [currentScript setDesiredExecuteIndex:0];
  [currentScript execToIndex:0];
  [currentScript clearCacheButCurrentExecuted];
  
  [GSeqEdit shouldRedraw];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"BFSynchronizeScriptAndTools" object:self];
}

@end
