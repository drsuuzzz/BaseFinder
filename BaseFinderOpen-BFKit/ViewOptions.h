
/* "$Id: ViewOptions.h,v 1.6 2007/02/02 14:52:59 smvasa Exp $" */

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

#import <Foundation/NSObject.h>
#import <AppKit/AppKit.h>

@interface ViewOptions:NSObject
{
	id		channelsPanel;
	id		labelsPanel;
	id		scalePanel;
	id		chanViewPanel;
  id    dataMarkPanel;
	id		buttons;			/* a Matrix of ButtonCells */
	id		labels;				/* a Matrix of TextFieldCells */ 
	id		activeBasesID;				/* a Matrix of ButtonCells i.e. Radio */
	id		masterViewID;	/* link to the display object */
	id		normTypeID;
	id		seqEditor;
	id		chanView;	/* selections for channel spliting across */
  id    dataMarker; 
	IBOutlet NSButton	*baseLines;
	id		colorWell1;
	id		colorWell2;
	id		colorWell3;
	id		colorWell4;
	id		colorWell5;
	id		colorWell6;
	id		colorWell7;
	id		colorWell8;
	id		backgroundColorWell;
	id		minMax1ID;		/* for channels 1-4 */
	id		minMax2ID;		/* for channels 5-8 */
	char		rosettaStone[8];					/* for translating base labels */
	char		localNames[8][64];
	int			channelEnabled[8];
	int			localBases;							/* bitflags 0-7 correspond to if bases displayed */
	NSColor 	*channelColor[8], *newColor[8], *localBackgroundColor;
	float		minY[8], maxY[8];
}

- init;
- (void)awakeFromNib;
- (void)readSeqEditor;
- (void)changeColor:sender;
- (void)upDate:sender;
- (void)cancel:(id)sender;
- (void)reset;

- (void)updateScale:sender;
- (void)resetScale;
- (void)switchNormType:sender;
- (void)calcMinMaxWithCommonScale:(BOOL)useCommon;
- (void)showMinMax;
- (void)getMinMax;
- (void)setEditable:(BOOL)value;

- (void)setBaseLabels;
//- (void)parseLabels;

- (void)windowDidUpdate:(NSNotification *)notification;
- (void)windowDidBecomeKey:(NSNotification *)notification;

- (void)updateChanView:sender;     /* update option for channel splitting */
- (void)updateDataMark:sender;     /* update option for viewing sequence position or data position */

@end
