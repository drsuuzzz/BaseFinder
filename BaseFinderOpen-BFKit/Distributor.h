
/* "$Id: Distributor.h,v 1.2 2006/08/04 20:31:26 svasa Exp $" */

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

#import <AppKit/AppKit.h>

extern BOOL debugmode;

enum fileGroupType {
    SELECTED_FILES,
    ALL_FILES,
  CURRENT_FILE
};

@class ToolMaster, MultiFileManager, LanesFile;

@interface Distributor:NSResponder
{
  MultiFileManager       *multiFileManager;
  id                     stringTable;
  IBOutlet ToolMaster    *toolMaster;
  id                     toolChannel;
  id                     toolBases;
  id                     suggestionForm;
  unsigned int           targetDocIndex;
  id                     analysisWindow;
  id                     analysisText;
  id                     printOptionsID;
  int                    saveFormat;
  enum fileGroupType     saveGroupIndex;
  id                     saveGroupIndexRadio;
  BOOL                   canChooseFiles;
//  id                     savePanel;
  id                     savePanelExtn;
  id                     saveCurrentPanelExtn;
  IBOutlet NSMatrix      *importScriptExtn;
  NSString               *lastSaveDir;
  IBOutlet NSPanel       *infoPanel;
  IBOutlet NSTextField   *infoPanelBuildNumber;
  NSString               *openPath;
  NSTrackingRectTag      masterViewTrackingTag;
	NSLock *loadToolsLock;
}

- init;
- (void)open:sender;
- (void)openDirectory:sender;
- (void)openFile:(NSString *)fullPath;
- (void)loadFromPasteboard:(NSPasteboard*)pasteboard userData:(NSString *)userData error:(NSString **)msg;
- (int)application:sender openFile:(NSString *)path;
- openDoc:(char *)name;
- (void)importScript:sender;
- (void)attachPhredFile:sender;

- (void)switchSaveFormat:sender;
- (void)switchSaveGroupIndex:sender;
- (void)setCanChooseFiles:(BOOL)filesOkay;
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename;
- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename;
- (void)saveCurrent:sender;
- (void)saveCurrentAs:sender;
- (void)saveSelected:sender;
- (void)saveAs:sender;
- (void)save:(enum fileGroupType)fileGroupIndex;
- (void)saveCurrentFileWithPanel;
- (void)saveToDirWithPanel:(enum fileGroupType)fileGroupIndex;
- (void)saveLane:(LanesFile *)thisLane withFormat: (int)theSaveFormat
         andPath:(NSString *)fileName;
- (NSString *)getFilenameFrom:(NSString *)fileName withFormat:(int)theSaveFormat;
- (void)closeActiveFile:sender;
- (void)printFrontSeq:sender;
- (void)doPageLayout:sender;

/* methods related to being the applications delegate */
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

- (ToolMaster*)toolMaster;

//- (void)addOpenFile:sender;
- (void)boundToAll:sender;
- (void)boundToSelected:sender;

- (void)stepBack:sender;
- (void)stepForward:sender;

- (void)showInfoPanel:sender;

- (void)flushScriptCache:sender;
@end
