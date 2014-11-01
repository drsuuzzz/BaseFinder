
/* "$Id: MasterView.h,v 1.2 2006/08/04 20:31:26 svasa Exp $" */

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
#import "ToolMaster.h"
extern BOOL debugmode;

@class SequenceEditor;

@interface MasterView:NSView
{
	IBOutlet SequenceEditor     *myOwner;    /* Should be set in IB - owner owns point lists too */
  NSTrackingRectTag   masterViewTrackingTag;
  BOOL                hasTrackingTag;

  float  viewPercent;
  id     updateBox;
  id     baseNumber;
  id     rawDataMatrixID;    /* for displaying the raw data values under the cursor */
  id     posNumber;
  id     numViewsID;
  id     viewSizeID;

  id     color1;
  id     color2;
  id     color3;
  id     color4;
  id     color5;
  id     color6;
  id     color7;
  id     color8;
	
	id		scaleSlider;

  int    count;
  BOOL   statusSHOWN;

  id 	trackView;  // used by trackLineAt::
	
  // x-coord mouseDownX in mouseDownView marks the anchor point of the current selection;
  // x-coord endSelectionX in endSelectionView marks the endpoint that is modified
  // by dragging and/or shift-clicking

  id mouseDownView, endSelectionView;
  float mouseDownX, endSelectionX;

  // currentSelection holds the current selection in terms of point numbers;
  // Note that currentSelection.end >=  currentSelection.start; this means that
  // currentSelection may be reversed relative to the above 4 variables that also
  // delineate the current selection

  range       currentSelection;

  int         oldMask;
  range       boundsSelection;
  int         mouseAction, channelToShift;
  int         shiftChannelEnable, baseTrack, pointTrack;
  int         activeBases;	/* which bases to display */
  NSColor *   backgroundColor;
  int         boundsType, normalizeType;
  float       minY[8], maxY[8];
  int         subviewOrigin;
}

- initWithFrame:(NSRect)frameRect;
- (void)setOwner:sender;

- (void)numViewsChanged:sender;
- (void)adjustYScale:(id)sender;
- (void)resetScale:sender;
- (void)changeNumViews:(int)numViews :(float)vPercent;
- (void)sizeToPercent:(float)size;
- (void)changeViewPercent:sender;

- (void)baseTrackButton:sender;
- (void)pointTrackButton:sender;

- (void)resetBounds;
- (void)boundToAll;
- (void)boundToSelected;
- (void)resetDataMinMax;
- (void)setDataMin:(float*)min max:(float*)max;
- (void)getDataMin:(float*)min max:(float*)max;
- (void)setChannelNorm:(int)type;
- (int)channelNorm;

- (void)drawRect:(NSRect)rects;
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize; 
- (void)myresizeSubviews;
- (void)shouldRedraw;
- (void)resetTrackingRectToVisible;
- (void)clearTrackingRect;

- (void)setColorWells;
- (void)channelDone:(int)channel;
- (void)viewDone;
- (void)showStatus;
- (void)doShift:(int)state channel:(int)channel;
- (void)toggleShiftMode;
- (void)setShiftChannel:(int)channel;
- (int)activeBases;
- (void)setActiveBases:(int)mask;
- (void)highlightBaseAt:(int)pointLoc num:(int)index;
- (BOOL)centerViewOn:(int)pointLoc;
- (void)trackLineAt:(int)theX :theView;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)thisColor;
- (void)dragViewBy:(int)pixels;
- (int)numViews;
- (float)viewPercent;

- (void)selectSubviewRange:(int)from :(int)to;
- (void)deselectSubviewRange:(int)from :(int)to;
- (void)swapSelectionPoints;
- (void)clearSelection;
- (void)anchorSelectionAt:(float)x :view;
- (void)extendSelectionTo:(float)x :view;
- (void)moveSelection:(int)dist;

@end
