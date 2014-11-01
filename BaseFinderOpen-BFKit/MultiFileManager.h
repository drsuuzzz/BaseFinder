/* "$Id: MultiFileManager.h,v 1.2 2006/08/04 20:31:26 svasa Exp $" */

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
#import "SequenceEditor.h"
#import <GeneKit/UWStatusView.h>

extern BOOL debugmode;
@class LanesFile, NewScript;

@interface MultiFileManager:NSResponder
{
  IBOutlet NSPanel        *panel;
  IBOutlet NSScrollView   *scrollView;
  IBOutlet NSMatrix       *matrixView;

  NSButtonCell            *cellTemplate;
  NSMutableArray          *loadedFileArray;
  UWStatusView            *statusDisplayer;
}

- init;
- (void)addLanesFile:(LanesFile*)newSeqEdit;
- (LanesFile*)currentLanesFile;
- (NSMutableArray *)selectedLanesFiles;
- (NSMutableArray *)allLanesFiles;

- (void)closeActiveFile:sender;
- (NSApplicationTerminateReply)closeAllFiles;

- (void)showPanel;
- (void)selectFile:sender;
//- (void)keyDown:(NSEvent *)theEvent;

- (void)applyScript:(NSNotification *)aNotification;
- (void)applyScript:(NewScript*)script toAllWithAutoSave:(BOOL)autosave;
- (void)applyNoThreadScript:(NewScript*)script toAllWithAutoSave:(BOOL)autosave;
- (void)updateView;
- (void)setupStatusView;
- (void)updateScriptStatus:(NSNotification *)notification;

@end
