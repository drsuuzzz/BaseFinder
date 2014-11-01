
/* "$Id: SequenceEditor.h,v 1.4 2006/08/04 20:31:53 svasa Exp $" */

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

#import <Foundation/Foundation.h>
#import "Distributor.h"
#import <GeneKit/Trace.h>
#import <GeneKit/UWStatusView.h>
#import <BaseFinderKit/NewScript.h>
#import <BaseFinderKit/LanesFile.h>
extern BOOL debugmode;
extern id GSeqEdit; // global holding currently active SequenceEditor instance

#define  MAX_PTS 200000

@class Distributor, MasterView;

@interface SequenceEditor:NSObject
{
  /* set in nib file:*/
  IBOutlet NSWindow        *theSequenceWindow;
  IBOutlet MasterView      *myMasterView;
  UWStatusView             *statusDisplayer;
  id    multiLaneBoxID;
  id    laneNumID;
  id    numLanesID;
  id    rawProcBoxID;
  id    rawProcSelectorID;
  id    printWindow;            //printView needs a window in order to draw


  /* from interface: */
  id            viewOptionsID;
  NSString      *fileName;
  int		numViews;
  float		viewPercent;
  NSColor *	backgroundColor;
  char		channelNames[8][64];
  int		channelEnabled[8];
  NSColor *	channelColor[8];

  /* from data (will probably move): */
  LanesFile  *laneFileObj;

  NSTimer   *statusTimer;
  BOOL      statusNeedsDisplay;
	int					channelSplit;   /* 0=all, 1=dual, 2=single */
}

+ (SequenceEditor*)activeSequenceEditor;
- (BOOL)debugMode;

- setLanesFile:(LanesFile *)thisLaneFileObject;
- (LanesFile *)lanesFile;

- (void)setFileName:(NSString*)aName;
- (NSString*)fileName;

- (Trace*)pointStorageID;
- (Trace*)trace;
- (Sequence*)baseStorageID;
- (EventLadder*)currentLadder;
- (AlignedPeaks*)peakListStorageID;
- (Sequence*)alnBaseStorageID;


- (int)numberChannels;
- (unsigned int)numberPoints;

- (void)printSelf;
- (id)masterViewID;
- (void)shouldRedraw;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)thisColor;

- (void)setCurrentScript:(NewScript*)theScript;
- (NewScript*)currentScript;

- (LanesFile*)dataManager;

- (void)show:sender;
- (void)hide:sender;
- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)windowWillClose:(NSNotification *)notification;
- (id)returnWindowID;

/*** Multi-lane switching section ***/
- (void)switchToMultiLane:(BOOL)value;
- (BOOL)switchToLane:(int)value;
- (void)switchRawProc:sender;
- (void)increaseLaneNumber:sender;
- (void)decreaseLaneNumber:sender;
- (void)changeLaneNumber:sender;
- (int)currentLane;
- (int)numLanes;

/*** Display Attributes ***/
- (BOOL)channelEnabled:(int)channel;
- (BOOL)setEnabled:(BOOL)value channel:(int)channel;
- (NSColor *)channelColor:(int)channel;
- (BOOL)setColor:(NSColor *)color channel:(int)channel;
- (void)setDefaultColors;

/*** new script status methods ***/
- (void)updateScriptStatus:(NSNotification *)notification;
- (void)updateScriptStatusDisplay;

@end
