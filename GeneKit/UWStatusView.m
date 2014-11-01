/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/* UWStatusView.m created by jessica on Tue 17-Mar-1998 */

#import "UWStatusView.h"

@implementation UWStatusView

- (void)createEmptyTextField
{
  NSTextField  *textField;

  textField = [[NSTextField alloc] initWithFrame:NSMakeRect(2.0, 2.0, 10.0, 10.0)];
  [textField setSelectable:NO];
  [textField setDrawsBackground:NO];
  [textField setBordered:NO];
  [textField setFont:[attributes objectForKey:@"font"]];
  [textField setTextColor:[attributes objectForKey:@"textColor"]];
  [textField setStringValue:@"starting text"];
  [textField sizeToFit];

  [attributes setObject:textField forKey:@"textField"];
  [self addSubview:textField];
}

- (id)initWithFrame:(NSRect)frameRect
{
  NSRect           progressRect;
  NSProgressIndicator   *progressView;
  
  [super initWithFrame:frameRect];
  status = [[NSString stringWithFormat:@"starting text"] retain];

  progressRect = NSInsetRect([self bounds], 5.0, 5.0);
  progressRect.origin.x = 2.0;
  progressRect.origin.y = 2.0;
  progressView = [[NSProgressIndicator alloc] initWithFrame:progressRect];
  [progressView setUsesThreadedAnimation:YES];
//  progressView = [[UWProgressView alloc] initWithFrame:progressRect];
  //progressView = [[OAProgressView alloc] initWithFrame:progressRect];
  //[progressView turnOff];
  //[progressView addSubview:progressView]; //some unknown problem here

  attributes = [[NSMutableDictionary dictionary] retain];
  [attributes setObject:[NSColor blackColor] forKey:@"textColor"];
  [attributes setObject:[NSFont userFontOfSize:12.0] forKey:@"font"];
  [attributes setObject:[NSNumber numberWithFloat:100.0] forKey:@"progressWidth"];
  [attributes setObject:[NSNumber numberWithInt:UWStatusLowerLeft] forKey:@"anchor"];
  [attributes setObject:progressView forKey:@"progressView"];
  [progressView release];

  [self createEmptyTextField];
  return self;
}

- (void)sizeToFit
{
  NSTextField     *textField;
  NSRect          textRect, progressRect, totalRect, startingFrame, tempRect;
  NSPoint         anchorPoint;
  UWStatusAnchor  anchor;
  UWProgressView  *progressView;

  anchor = [[attributes objectForKey:@"anchor"] intValue];
  startingFrame = [self frame];
  switch(anchor) {
    case UWStatusUpperRight:
      anchorPoint.x = startingFrame.origin.x + startingFrame.size.width;
      anchorPoint.y = startingFrame.origin.y + startingFrame.size.height;
      break;
    case UWStatusLowerRight:
      anchorPoint.x = startingFrame.origin.x + startingFrame.size.width;
      anchorPoint.y = startingFrame.origin.y;
      break;
    case UWStatusUpperLeft:
      anchorPoint.x = startingFrame.origin.x;
      anchorPoint.y = startingFrame.origin.y + startingFrame.size.height;
      break;
    case UWStatusLowerLeft:
      anchorPoint.x = startingFrame.origin.x;
      anchorPoint.y = startingFrame.origin.y;
      break;
  }

  textField = [attributes objectForKey:@"textField"];
  [textField sizeToFit];
  textRect = [textField frame];
  progressView = [attributes objectForKey:@"progressView"];
  progressRect = [progressView frame];

  [self setAutoresizesSubviews:NO];
  if(flags.hasProgressView) {
    progressRect.origin.x = textRect.origin.x + textRect.size.width + 2.0;
    progressRect.origin.y = textRect.origin.y;
    progressRect.size.height = textRect.size.height;
    progressRect.size.width = [[attributes objectForKey:@"progressWidth"] floatValue];
    [progressView setFrame:progressRect];

    progressRect = [progressView frame];
    totalRect = NSUnionRect(progressRect, textRect);
  }
  else {
    totalRect = textRect;
  }

  totalRect = NSInsetRect(totalRect, -2.0, -2.0);

  switch(anchor) {
    case UWStatusUpperRight:
      totalRect.origin.x = anchorPoint.x - totalRect.size.width;
      totalRect.origin.y = anchorPoint.y - totalRect.size.height;
      break;
    case UWStatusLowerRight:
      totalRect.origin.x = anchorPoint.x - totalRect.size.width;
      totalRect.origin.y = anchorPoint.y;
      break;
    case UWStatusUpperLeft:
      totalRect.origin.x = anchorPoint.x;
      totalRect.origin.y = anchorPoint.y - totalRect.size.height;
      break;
    case UWStatusLowerLeft:
      totalRect.origin.x = anchorPoint.x;
      totalRect.origin.y = anchorPoint.y;
      break;
  }

  [self setFrame:totalRect];
  [self setAutoresizesSubviews:YES];

  tempRect = NSIntersectionRect(totalRect, startingFrame);  //shared area between start and end
  tempRect = NSIntersectionRect(tempRect, startingFrame);
  if(!NSEqualRects(tempRect, startingFrame)) {
    //means part of the starting frame is no longer included in area of the new frame
    //so tell superview to display, to clean up
    [[self superview] setNeedsDisplay:YES];
  }
}

- (void)drawRect:(NSRect)aRect
{
//  NSRect          myBounds = [self bounds];
//  NSColor         *backgroundColor;
  NSProgressIndicator  *progressView = [attributes objectForKey:@"progressView"];

  //NSTextField   *textField;
  
  //textField = [attributes objectForKey:@"textField"];
  //[textField setStringValue:status];

  if(status == nil) return;  //should cause UWStatusView to disappear
  
//  backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.733 alpha:1.0];
//  [backgroundColor set];
//  NSRectFill(myBounds);

  if(flags.hasProgressView) {
    float             progress;

    progress = [[attributes objectForKey:@"progressAmount"] floatValue];
//    total = [[attributes objectForKey:@"progressTotal"] floatValue];
//    [progressView processedBytes:progress ofBytes:total];
//    [progressView setMaxValue:(double)total];
//    [progressView setDoubleValue:(double)progress];
    [progressView incrementBy: (progress - [progressView doubleValue]) ];
//    [progressView displayIfNeeded];
    if(![[self subviews] containsObject:progressView])
      [self addSubview:progressView];
  }
  else {
    //[progressView turnOff];
  }
}

/******
*
* External API section
*
******/

- (void)setFont:(NSFont *)aFont
{
  NSTextField  *textField;

  if(![aFont isKindOfClass:[NSFont class]]) return;
  [attributes setObject:aFont forKey:@"font"];

  textField = [attributes objectForKey:@"textField"];
  [textField setFont:aFont];
  [self sizeToFit];
  [self setNeedsDisplay:YES];
}

- (void)setColor:(NSColor *)aColor
{
  NSTextField  *textField;

  if(![aColor isKindOfClass:[NSColor class]]) return;
  [attributes setObject:aColor forKey:@"textColor"];

  textField = [attributes objectForKey:@"textField"];
  [textField setTextColor:aColor];
  [self setNeedsDisplay:YES];
}

- (void)setStatusWidth:(float)width;
{
  if(width < 25.0) width=25.0;
  [attributes setObject:[NSNumber numberWithFloat:width] forKey:@"progressWidth"];
  [self sizeToFit];
  [self setNeedsDisplay:YES];
}

- (void)setAnchor:(UWStatusAnchor)corner
{
  [attributes setObject:[NSNumber numberWithInt:corner] forKey:@"anchor"];
}

/**** setting status ****/

- (void)setStatus:(NSString *)aStatus
{
  NSProgressIndicator  *progressView = [attributes objectForKey:@"progressView"];
  NSTextField     *textField = [attributes objectForKey:@"textField"];

  if(status != nil) { [status release]; status=nil; }
  if(aStatus == nil) {
    [textField removeFromSuperview];
    [progressView stopAnimation:self];
    [progressView removeFromSuperview];
    [[self superview] setNeedsDisplay:YES];
    return;
  }

  if(![aStatus isKindOfClass:[NSString class]]) return;
  status = [[aStatus stringByAppendingString:@" "] retain];
  if(![[self subviews] containsObject:progressView])  {
    [self addSubview:progressView];
    [progressView setIndeterminate:YES];
    [progressView startAnimation:self];
  }
  flags.hasProgressView = 1;

//  if([[self subviews] containsObject:progressView])
//    [progressView removeFromSuperview];
  if(![[self subviews] containsObject:textField])
    [self addSubview:textField];

  [textField setStringValue:status];
  [self sizeToFit];

  [self setNeedsDisplay:YES];
}

- (void)setStatus:(NSString *)aStatus withProgress:(unsigned int)amount ofTotal:(unsigned int)total
{
  NSProgressIndicator  *progressView = [attributes objectForKey:@"progressView"];
  NSTextField     *textField = [attributes objectForKey:@"textField"];

  if(status != nil) { [status release]; status=nil; }
  if(aStatus == nil) {
    [textField removeFromSuperview];
    [progressView stopAnimation:self];
    [progressView removeFromSuperview];
    [[self superview] setNeedsDisplay:YES];
    return;
  }
  if ([progressView isIndeterminate])
    [progressView setIndeterminate:NO];
  if(![aStatus isKindOfClass:[NSString class]]) return;
  status = [[aStatus stringByAppendingString:@" "] retain];

  [attributes setObject:[NSNumber numberWithInt:amount] forKey:@"progressAmount"];
  [attributes setObject:[NSNumber numberWithInt:total] forKey:@"progressTotal"];
  flags.hasProgressView = 1;

  if(![[self subviews] containsObject:progressView])  {
    [self addSubview:progressView];
    [progressView setIndeterminate:NO];
    [progressView startAnimation:self];
    [progressView setMaxValue:(double)total];
  }

  if(![[self subviews] containsObject:textField])
    [self addSubview:textField];

  [textField setStringValue:status];
  [self sizeToFit];

  [self setNeedsDisplay:YES];
}


@end



@implementation UWProgressView

- (id)initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];
  percent = 0;
  return self;
}

- (void)setPercent:(float)pcent
{
  pcent = pcent;
  if(pcent < 0.0) pcent = 0.0;
  if(pcent > 1.0) pcent = 1.0;
  percent = pcent;
  [self setNeedsDisplay:YES];
}

- (void)processedBytes:(unsigned int)amount ofBytes:(unsigned int)total;
{
  float  pcent;

  pcent = (float)amount / (float)total;
  [self setPercent:pcent];
}

- (void)drawRect:(NSRect)rects
{
    NSRect myrect,drawrect;
    
    myrect = [self bounds];
    
    drawrect = myrect;
    drawrect = NSInsetRect(drawrect , 1 , 1);
    [[NSColor lightGrayColor] set];
    NSRectFill(drawrect);
    
    [[NSColor blackColor] set];
    NSFrameRect([self bounds]);
    drawrect.size.width = drawrect.size.width * percent;
    NSRectFill(drawrect);
    
    drawrect = myrect;
    drawrect = NSInsetRect(drawrect , 1 , 1);
    NSFrameRect(drawrect);
}

@end
