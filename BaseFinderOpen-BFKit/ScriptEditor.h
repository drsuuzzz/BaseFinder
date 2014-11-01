/* "$Id: ScriptEditor.h,v 1.2 2006/08/04 20:31:53 svasa Exp $" */

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

#import <AppKit/AppKit.h>
extern BOOL debugmode;
@class ToolMaster, NewScript;

@interface ScriptEditor:NSObject
{
  IBOutlet NSPanel          *scriptPanel;
  IBOutlet NSScrollView     *scrollView;
  NSMatrix                  *matrixView;            //matrix of scripted tool names
  NSMatrix                  *scriptPositionMatrix;
  IBOutlet NSButton         *autosaveSwitch;
  IBOutlet NSPanel          *autosavePanel;
  IBOutlet NSPopUpButton    *autosavePopUp;
  IBOutlet NSButton         *autoexecuteSwitch;
  ToolMaster                *toolMaster;
  NSButtonCell              *cellTemplate;
  NSImage                   *grayScriptArrow, *scriptArrow;

  IBOutlet NSPopUpButton    *resourceMenu;
  id	resourceLabelID;
  id	resourceSourceID;
  id	saveButtonID;
  id	saveToRootID;

  id	scriptSaveLabelID;

  NewScript     *newlyLoadedScript;
}

- init;
- (void)setToolMaster:(ToolMaster*)theToolMaster;
- (void)appWillInit;
- (void)showPanel;
- (void)switchExpertMode;
- (void)switchAutoexecute:sender;
- (void)makeCellTemplate;
- (void)makeMatrix:(NSRect)frameRect;
- (void)open:sender;
- (void)openScript:(NSString*)filename;
- (void)rollback:sender;
- (void)doubleClickSelect:sender;
- (void)showParams:sender;
//- (void)switchSaveToPublic:sender;
- (void)saveAs:sender;
- (void)stepBy:(int)inc;
- (void)truncate;

//for handling multithreaded display
- (void)changeExecutePosition:sender;
- (void)updateExecuteDisplay;
- (void)rollback:sender;
- (void)doubleClickSelect:sender;
- (void)showParams:sender;

- (void)fillView;
- (void)applyToAll:sender;
- (void)windowDidResize:(NSNotification *)aNotification;

- (NSString *)resourcePath;
- (NSString *)resourceSubdir;
- (void)getResourceList:sender;
- (void)selectResource:sender;

//autosave panel section
- (void)switchAutosave:sender;
- (void)autosavePanelOK:sender;
- (void)autosavePanelCancel:sender;

@end

@interface ScriptView : NSView
{
}
@end
