
/* "$Id: BoxView.m,v 1.2 2006/08/04 20:31:32 svasa Exp $" */
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

#import "BoxView.h"

@implementation BoxView

+ new 
{	
  BoxView    *newSelf;

  newSelf = [[super alloc] init];
  newSelf->percent = 20;
  return newSelf;
}

- init
{
  percent = 0;
  return self;
}

- (void)setPercent:(float)pcent
{
  if(pcent < 1.0) pcent = 1.0;
  if(pcent > 100.0) pcent = 100.0;
  percent = pcent;
}


- (void)drawRect:(NSRect)rects
{
  NSRect myrect,drawrect;

  myrect = [self bounds];

  drawrect = myrect;
  drawrect = NSInsetRect(drawrect , 1 , 1);
  [[NSColor darkGrayColor] set];
  NSRectFill(drawrect);

  [[NSColor blackColor] set];
  drawrect.size.width = drawrect.size.width * (percent/100.0);
  NSRectFill(drawrect);

  drawrect = myrect;
  drawrect = NSInsetRect(drawrect , 1 , 1);
  NSFrameRect(drawrect);
}

@end
