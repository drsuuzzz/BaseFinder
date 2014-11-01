/* "$Id: GenericToolCtrl.h,v 1.7 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, Lloyd Smith and Mike Koehrsen

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
#import <BaseFinderKit/GenericTool.h>

#define TOOLSTREXT @"bftool"
#define CTRLSUF @"Ctrl"
#define BUNDLESEXT @"bundle"

typedef struct {
	int start, end;
} range;


@protocol BFToolMouseEvent
- (void)mouseEvent:(range)theRange;
@end

@protocol BFToolKeyEvent
- (void)keyEvent:(NSEvent*)keyEvent;
@end

@protocol BFToolMasterMethods
- (void)showTool:tool;
- (void)appendTool;
- (void)registerForEventNotification:tool;
- (void)deregisterForEventNotification:tool;
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types;

//these methods return data that is currently being displayed.
//used by controller classes to properly configure selves to data
- (int)numberChannels;
- (Trace*)pointStorageID;
- (Sequence*)baseStorageID;
- (EventLadder*)currentLadder;
- (NSColor*)colorForChannel:(int)channel;
- (void)setColorForChannel:(int)channel :(NSColor *)color;
- (void)askToRedraw;

//these methods are used to alter the display for channel shifting.
//this is used by the mobilityshift tool during calibration procedures
- (void)toggleShiftMode;
- (void)setShiftChannel:(int)channel;
- (void)doShift:(int)state channel:(int)channel;
@end

@interface GenericToolCtrl:NSObject
{
  IBOutlet NSBox  *inspectorView;
  id     channelSelID;
  id     dataProcessor;

  NSObject <NSObject, BFToolMasterMethods>     *toolMaster;
}

+ (id)newTool:(id)myToolMaster;

- (void)appWillInit;

- (NSBox*)inspectorView;
- (void)registerValue:sender;
- (void)getParams;
- (void)displayParams;
- (void)resetParams;

- (void)setDataProcessor:(GenericTool*)processor;
- (GenericTool*)dataProcessor;

- (void)resetSelChannels;

- (BOOL)inspectorWillUndisplay;
- (void)inspectorDidDisplay;

- (void)show;

@end

