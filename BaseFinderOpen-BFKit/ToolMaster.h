
/* "$Id: ToolMaster.h,v 1.3 2006/11/15 15:19:55 smvasa Exp $" */

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

// These should match IB:
#define TMPROCESSLABEL @"Data Processing"
#define TMSCRIPTLABEL @"Scripting"
#define TMDISPLAYLABEL @"Display"

#import <AppKit/AppKit.h>
#import <BaseFinderKit/ResourceToolCtrl.h>

extern BOOL debugmode;
// NOTE--now that tools are implemented as class pairs rather than single classes,
// there is some ambiguity where the term "tool" is used in a variable, etc. The tools
// list is a list of tool _controllers_. The NewScript tools list is a list of tool 
// _processors_, while ToolMaster's tools list is a list of tool _controllers_.

enum ToolMasterToolStates {
  TM_noTool,
  TM_newTool,
  TM_toolInScript
};


@class GenericToolCtrl, BasesView, ScriptEditor, NewScript;

@interface ToolMaster:NSObject <BFToolMasterMethods>
{
  IBOutlet NSPanel         *toolPanel;
  IBOutlet NSBox           *inspectorBox;
  IBOutlet NSView          *emptyInspectorID;
  IBOutlet NSPopUpButton   *processorPopUp;

  IBOutlet NSButton        *toolButton1;
  IBOutlet NSButton        *toolButton2;
  IBOutlet NSButton        *toolButton3;
    
  NSMutableArray           *eventNotifyList;
  

  NSMutableArray    *tools;
  NSMutableArray    *toolnames, *libraryNames;
  ScriptEditor      *scriptEditor;
  BasesView         *baseViewingID;

  int                         currToolIx;
  NSString                    *expertMode;
  enum ToolMasterToolStates   currentToolState;
}

- init;
- (void)showTools:sender;
- (void)showBases:sender;
- (void)showScriptEditor:sender;
- (void)setInspector:(NSView*)aView;
- (void)showParamsForCurrentScriptTool;
- (void)checkForNewResourcesInScript:(NewScript*)aScript;

- (BasesView*)baseViewingID;
- (ScriptEditor*)scriptEditor;
- tools;
- (void)showTool:tool;
- (GenericToolCtrl*)controllerForClass:theClass;
- (void)setControllerForToolsInScript:(NewScript *)aScript;

- (void)updateToolInspector;

- activateToolWithIndex:(int)index;
- (void)activateTool:(id)sender;

- (void)deleteBase;

- (void)appWillInit;
- (void)switchExpertMode;
- (void)windowDidMove:(NSNotification *)aNotification;

- (void)registerForEventNotification:tool;
- (void)deregisterForEventNotification:tool;
- (void)notifyMouseEvent:(range)theRange;
- (void)notifyKeyEvent:(NSEvent*)keyEvent;

- (void)loadLibDir:(NSString *)path :(id)updateBox;
- (void)loadToolDir:(NSString *)_path :(id)updateBox;
- (void)createNewNDDSToolLink:sender;

- (void)appendTool;
- (void)replaceTool;
- (void)insertTool;
- (void)deleteTool;
- (void)toolAction1:sender;
- (void)toolAction2:sender;
- (void)toolAction3:sender;

- (int)numberChannels;

@end
