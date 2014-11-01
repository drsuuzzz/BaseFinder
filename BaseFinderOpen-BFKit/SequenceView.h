
/* "$Id: SequenceView.h,v 1.7 2006/08/29 01:45:47 svasa Exp $" */

/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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
#import <GeneKit/EventLadder.h>
#import <GeneKit/Gaussian.h>
#import <GeneKit/Sequence.h>
#import <GeneKit/Peak.h>

#define MAXGRAPHPOINTS	200
#define ORIGX	0
#define ORIGY	0
#define CURVE_EXTENT 3
@interface SequenceView:NSView
{
  id        seqEditor;
  float     xScale, yScale;
  float     axisY;
  float     minY[8], maxY[8];
  float     xOrigin, yOrigin;
  int       startPoint, endPoint;
  NSRect    selectRect, trackRect, highlightedBaseRect;
  int       lastHighlightBase, lastTrackLine;
  int       oldMask;
  int       count;
  NSColor   *backColor;
  int       lastShiftX, startX;
  int segChannel;
	NSImage			*handleImage;
	NSImage			*handleImage2;
}

- initWithFrame:(NSRect)frameRect;
- (void)drawRect:(NSRect)aRect;
- (void)setOrigin:(float)x :(float)y;
- (void)setMin:(float*)min Max:(float*)max;
- (void)setYScale:(float)scaleValue;
- (BOOL)scaleSelftoFitView;
- (void)setRange:(int)start :(int)end;
- (void)setSeqEditor:(id)editor;
- (void)setBackgroundColor:(NSColor *)theColor;
- (void)selectRegion:(float)from :(float)to;
- (void)hideChannel:(int)channel;
- (void)showChannel:(int)channel;
- (void)initSegment:(int)channel at:(float)thisX;
- (void)drawShiftSegment:(float)thisX;
- (void)highlightBaseAt:(int)pointLoc;
- (void)trackLineAt:(int)thisX;
- (int)pointNumber:(float)x;
- (float)dataPosToViewPos:(int)dataPos;
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)dealloc;

- (void)selectPeak:(NSPoint)ourPoint;

@end
