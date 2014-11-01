
/* "$Id: ToolSignalDecayCtrl.h,v 1.4 2007/04/11 02:06:35 smvasa Exp $" */
/***********************************************************

Copyright (c) 2006 Suzy Vasa

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
NIH Center for AIDS research

******************************************************************/

#import <BaseFinderKit/GenericToolCtrl.h>


@interface ToolSignalDecayCtrl:GenericToolCtrl <BFToolMouseEvent>
{
  IBOutlet  NSTextField	*scaleID;
	IBOutlet	NSTextField	*fromID;
	IBOutlet	NSTextField *toID;
	IBOutlet	NSForm			*coeffsID;
}

- init;
- (void)getParams;
- (void)displayParams;
- (void)resetParams;
- (void)awakeFromNib;
- (void)inspectorDidDisplay;
- (BOOL)inspectorWillUndisplay;
- (void)mouseEvent:(range)theRange;
- (void)resetSelChannels;
@end
