
/* "$Id: MasterView.m,v 1.5 2006/11/15 15:08:33 smvasa Exp $" */

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
#import <AppKit/Appkit.h>
#import <Cocoa/Cocoa.h>
#import "MasterView.h"
#import "SequenceEditor.h"
#import "SequenceView.h"
#import "ToolMaster.h"
#import "BasesView.h"
#import <GeneKit/StatusController.h>
#import <GeneKit/NumericalRoutines.h>
#import <objc/objc.h>
//#import <objc/List.h>
#import <stdio.h>
#import <math.h>
#ifdef WIN32
#import <winnt-pdo.h>
#endif


#define MAXVIEWSIZE 100000
#define Xspace	10	/*Space between sequence views and frame X direction*/
#define Yspace	5	/*Space between sequence views and frame Y direction*/
#define LABELHEIGHT	15
#define mouseActionSELECT 0
#define mouseActionSHIFT 1

/****
* April 8, 1994, added bug fix to -posToRawData:(int)theX :(int)theView. If numbers are 
* really small they shifted into exp float format, where truncated and looked like 
* big numbers.  Add a -setFloatingPointFormat method to force formating
*
* April 15, 1994: Redid the view min/max.  Interface is in ViewOptions, all subviews use
* the same min/max, calculated in the MasterView now, SequenceView is just set with values, 
* manual option allows to be set in the view options and is not recalcualted.
*
* April 18, 1994: Added printing option to display the data ranges for each channel
*
* August 9, 1994: Added shift-click selection and left- and right-arrow key handling. In the
* course of doing this I substantially reorganized the mouse event handling routines. Changes
* to the current selection are now made with methods anchorSelectionAt::, extendSelectionTo::,
* moveSelection:, and clearSelection.
*
* August 30, 1994: Jessica modified keyDown and moveSelection to allow for <shift> arrow to 
* move cursor in increments of 10. 
****/

@implementation MasterView

- initWithFrame:(NSRect)frameRect
{
  id 		pi;

  mouseDownView = nil;
  mouseAction = mouseActionSELECT;
  activeBases=255;			/* all bits active */
  currentSelection.start = 0;
  currentSelection.end=0;
  viewPercent = 0.0;		/* sizeToWindow */
  subviewOrigin = LABELHEIGHT;
  boundsType=0;
  normalizeType=0;	/* common scale */
  boundsSelection.start=0;
  boundsSelection.end=0;
  backgroundColor = [NSColor whiteColor];
  pi = [NSPrintInfo sharedPrintInfo];
  [pi setOrientation:NSLandscapeOrientation];
  [pi setHorizontalPagination:NSFitPagination];
  [pi setVerticalPagination:NSFitPagination];
  [pi setHorizontallyCentered:YES];
  [pi setVerticallyCentered:YES];
  //[pi setMarginLeft:9 right:9 top:9 bottom:9];		//9pts = 1/8 inch
  /* Ugly yes */
  [super initWithFrame:frameRect];
  [self setAutoresizesSubviews:YES];
  [[self superview] setAutoresizesSubviews:YES];
  [self setAutoresizingMask:255];
  [self setAutoresizesSubviews:YES];
  //[self setAutodisplay:YES];
  statusSHOWN = NO;
  //[window addToEventMask:NSKeyDownMask];

  [MasterView setVersion:5];
  masterViewTrackingTag = 0;
  hasTrackingTag = NO;
  return self;
}

- (BOOL)isOpaque { return YES; }

- (void)setOwner:sender
{
  int  i;
  NSArray   *mySubviews = [self subviews];
  
  myOwner=sender;
  for(i=0; i<[mySubviews count]; i++) {
    [[mySubviews objectAtIndex:i] setSeqEditor:myOwner];
  }
  //[[self subviews] makeObjectsPerform:@selector(setSeqEditor:) withObject:myOwner];
}

- (void)numViewsChanged:sender
{	
  int    theIndex;

  theIndex = [sender indexOfSelectedItem];
  [self changeNumViews:theIndex+1 :viewPercent]; 
}

- (void)adjustYScale:sender
{
	float yscale = [sender floatValue];
	int i;
	int	numViews;
  
  [[NSUserDefaults standardUserDefaults] setFloat:yscale forKey:@"scaleValue"];
		numViews =  (int)[[self subviews] count];
		for (i=0; i<numViews; i++) {
			[[[self subviews] objectAtIndex:i] setYScale:yscale];
		}
	
}

- (void)resetScale:sender
{
	float yscale = 1.0;
	int i;
	int	numViews = (int)[[self subviews] count];
	[scaleSlider setFloatValue:yscale];
  [[NSUserDefaults standardUserDefaults] setFloat:yscale forKey:@"scaleValue"];
	NSLog(@"Scale Reset");
	for (i=0; i<numViews; i++) {
		[[[self subviews] objectAtIndex:i] setYScale:yscale];
		}
	
}

- (void)changeNumViews:(int)numViews :(float)vPercent
{
  int        i; /*counter for each view*/
  NSRect     theFrame, masterFrame;
  id         addedView;
  unsigned   numberPoints;
  char       tmpStr[64];

  if(numViews == [[self subviews] count]) return;

  [[self window] disableFlushWindow];

  if(numViews==1) sprintf(tmpStr,"1 view");
  else sprintf(tmpStr,"%1d views",numViews);
  [numViewsID setTitle:[NSString stringWithCString:tmpStr]];
  [self clearSelection];		/* to deselect any existing highlighted region  */
  masterFrame = [self bounds];
  for(i=[[self subviews] count]-1;i>=0;i--)
    [[[self subviews] objectAtIndex:i] removeFromSuperview];
  theFrame.origin.x = 0;
  theFrame.origin.y = 0;
  theFrame.size.width = 10;
  theFrame.size.height = 10;
  numberPoints = [myOwner numberPoints];

  /* Add the new views */
  for (i=numViews; i>=1; --i) {
    addedView = [[SequenceView alloc] initWithFrame:theFrame];
    [self addSubview:addedView];
    [addedView setOrigin:0 :subviewOrigin];
    [addedView setRange:((numberPoints * ((numViews -i)-1)) / numViews)
                       :((numberPoints * (numViews - i)) / numViews - 1)];
    [addedView setSeqEditor:myOwner];
    [addedView setBackgroundColor:backgroundColor];
  }
  [self resetDataMinMax];	/* does a bounds to all */
  [self sizeToPercent:vPercent];

  [self display];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
  [[NSUserDefaults standardUserDefaults] setInteger:numViews forKey:@"NumberViews"];
}

- (void)changeViewPercent:sender
{
  float			oldPercent;

  oldPercent=viewPercent;
  switch([sender indexOfSelectedItem]) {	/* sender is of type NSPopUpButton */
    case 0: viewPercent = 2.0; break;
    case 1: viewPercent = 1.5; break;
    case 2: viewPercent = 1.25; break;
    case 3: viewPercent = 1.0; break;
    case 4: viewPercent = 0.75; break;
    case 5: viewPercent = 0.5; break;
    case 6: viewPercent = 0.25; break;
    case 7: viewPercent = 0.1; break;
    case 8: viewPercent = 0.0; break;       /* sizeToWindow */
  }
  if(oldPercent!=viewPercent) [self shouldRedraw];
  [[NSUserDefaults standardUserDefaults] setFloat:viewPercent forKey:@"ViewPercent"];
}

- (void)sizeToPercent:(float)size
{
  /** resizes MasterView and all subViews but does not cause a display event
          to occur.  Called when numberPoints changes, or viewPercent changes
  **/
  unsigned int  x,y;
  NSRect        selfBounds, superbounds;
  char          tmpStr[64];

  if(size==0.0) sprintf(tmpStr,"Fit to Window");
  else sprintf(tmpStr,"%1d%%",(int)(size*100));
  [viewSizeID setTitle:[NSString stringWithCString:tmpStr]];
  viewPercent = size;
  [self setAutoresizesSubviews:NO];
  [self setPostsFrameChangedNotifications:NO];
  if(size==0.0) {
    /* toWindow */
    NSScrollView *myScrollView = (NSScrollView*)[self superview];
    superbounds = [myScrollView documentVisibleRect];
    [self setFrameSize:NSMakeSize((superbounds.size.width), (superbounds.size.height))];
    [self setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
  }
  else {
    NSScrollView *myScrollView = (NSScrollView*)[self superview];
    int c = [[self subviews] count];
    selfBounds = [self bounds];
    superbounds = [myScrollView documentVisibleRect];
    y = superbounds.size.height;
    x = ([myOwner numberPoints] + c-1) * size / c + 2*Xspace;	
          //extra space for border on each side between masterView edge
          //and SequenceView edges. Extra points because the point on the end
          //of a view is duplicated as the first point on the next veiw
    if (x > MAXVIEWSIZE)
      x = MAXVIEWSIZE;
    [self setFrameSize:NSMakeSize(x, y)];
    [self setAutoresizingMask:(NSViewHeightSizable)];
  }
  [self myresizeSubviews];
  [self setPostsFrameChangedNotifications:YES];
  [self setAutoresizesSubviews:YES]; 
}

- (void)baseTrackButton:sender
{
  baseTrack = [sender state];
  //[[self window] makeFirstResponder:self];
}

- (void)pointTrackButton:sender
{
  int			i,j;

  pointTrack = [sender state];
  if(!pointTrack) {
    for(i=0;i<2;i++)
      for(j=0;j<4;j++)
        [[rawDataMatrixID cellAtRow:i column:j] setStringValue:@""];
  }
  //[[self window] makeFirstResponder:self];
}

// These two methods are essentially convenience methods for
// clearSelection and extendSelectionTo::
- (void)selectSubviewRange:(int)from :(int)to
{
	int i,tmp;
	
	if (from > to) {
		tmp = from;
		from = to;
		to = tmp;
	}
	
	for (i=from;i<=to;i++)
        [[[self subviews] objectAtIndex:i] selectRegion:0 :FLT_MAX];
}

- (void)deselectSubviewRange:(int)from :(int)to
{
	int i,tmp;
	
	if (from > to) {
		tmp = from;
		from = to;
		to = tmp;
	}
        if(from < 0) return;
	
	for (i=from;(i<=to)&&(i<[[self subviews] count]);i++)
		[[[self subviews] objectAtIndex:i] selectRegion:FLT_MAX :FLT_MAX]; 
}

- (void)swapSelectionPoints
{
	id tmpView = mouseDownView;
	float tmpX = mouseDownX;
	
	mouseDownView = endSelectionView;
	mouseDownX = endSelectionX;
	endSelectionView = tmpView;
	endSelectionX = tmpX; 
}

- (void)clearSelection
{
	int		c = [[self subviews] count];
	
	if (NO /* was [<view> isAutoDisplay] */)
		[[self window] disableFlushWindow];
	
	[self trackLineAt:-1 :nil];
	
	mouseDownView = endSelectionView = nil;
	mouseDownX = endSelectionX = -1;
	currentSelection.start = currentSelection.end= -1;
	
	[self deselectSubviewRange:0 :c-1];
		
	if (NO /* was [<view> isAutoDisplay] */) {
		[self displayIfNeeded]; 
		[[self window] enableFlushWindow];
		[[self window] flushWindow];
	} else
		[self setNeedsDisplay:YES]; 
}

- (void)anchorSelectionAt:(float)x :view
{
	endSelectionView = mouseDownView = view;
	endSelectionX = mouseDownX = x;
	currentSelection.start = currentSelection.end = 
								[mouseDownView pointNumber:mouseDownX]; 
}
	

- (void)extendSelectionTo:(float)x :view
{
  // NOTE--Subviews are numbered from bottom to top
  int viewIx = [[self subviews] indexOfObject:view];
  int endSelIx = [[self subviews] indexOfObject:endSelectionView];
  int mouseIx = [[self subviews] indexOfObject:mouseDownView];
  int tmp;


  // Go through every case here, in order to minimize the number of
  // subviews whose selection changes. This consolidates the logic
  // that formerly resided implicitly in updates to thisX, lastX, etc.
  if (endSelIx==mouseIx && viewIx==mouseIx)
    [view selectRegion:mouseDownX :x];
  else if (endSelIx==mouseIx && viewIx>mouseIx) {
    [self selectSubviewRange:endSelIx+1 :viewIx-1];
    [mouseDownView selectRegion:0 :mouseDownX];
    [view selectRegion:x :FLT_MAX];
  } else if (endSelIx==mouseIx && viewIx < mouseIx) {
    [self selectSubviewRange:endSelIx-1 :viewIx+1];
    [mouseDownView selectRegion:mouseDownX :FLT_MAX];
    [view selectRegion:0 :x];
  } else if (viewIx==mouseIx && endSelIx>viewIx) {
    [self deselectSubviewRange:viewIx+1 :endSelIx];
    [view selectRegion:mouseDownX :x];
  } else if (viewIx==mouseIx && endSelIx<viewIx) {
    [self deselectSubviewRange:endSelIx :viewIx-1];
    [view selectRegion:mouseDownX :x];
  } else if (viewIx==endSelIx && viewIx>mouseIx) {
    [view selectRegion:x :FLT_MAX];
  } else if (viewIx==endSelIx && viewIx<mouseIx) {
    [view selectRegion:0 :x];
  } else if (mouseIx<viewIx && viewIx<endSelIx) {
    [self deselectSubviewRange:viewIx+1 :endSelIx];
    [view selectRegion:x :FLT_MAX];
  } else if (mouseIx>viewIx && viewIx>endSelIx) {
    [self deselectSubviewRange:viewIx-1 :endSelIx];
    [view selectRegion:0 :x];
  } else if (mouseIx>endSelIx && endSelIx>viewIx) {
    [self selectSubviewRange:endSelIx :viewIx+1];
    [view selectRegion:0 :x];
  } else if (mouseIx<endSelIx && endSelIx<viewIx) {
    [self selectSubviewRange:endSelIx :viewIx-1];
    [view selectRegion:x :FLT_MAX];
  } else if (endSelIx>mouseIx && mouseIx>viewIx) {
    [self deselectSubviewRange:mouseIx+1 :endSelIx];
    [self selectSubviewRange:viewIx+1 :mouseIx-1];
    [mouseDownView selectRegion:mouseDownX :FLT_MAX];
    [view selectRegion:0 :x];
  } else if (endSelIx<mouseIx && mouseIx<viewIx) {
    [self deselectSubviewRange:endSelIx :mouseIx-1];
    [self selectSubviewRange:mouseIx+1 :viewIx-1];
    [mouseDownView selectRegion:0 :mouseDownX];
    [view selectRegion:x :FLT_MAX];
  } else // if this ever executes, this code is wrong
    printf("selectRegionTo:: shouldn't be here. viewIx==%d, mouseIx==%d, endSelIx==%d\n", viewIx, mouseIx, endSelIx);

		
  endSelectionView = view;
  endSelectionX = x;
  currentSelection.start = [mouseDownView pointNumber:mouseDownX];
  currentSelection.end = [endSelectionView pointNumber:endSelectionX];
  if (currentSelection.start > currentSelection.end) {
    tmp = currentSelection.end;
    currentSelection.end = currentSelection.start;
    currentSelection.start = tmp;
  }
}

- (void)moveSelection:(int)dist
{
	int anchorPoint = [mouseDownView pointNumber:mouseDownX], 
		movablePoint = [endSelectionView pointNumber:endSelectionX];
	id newView;
	int mouseIx = [[self subviews] indexOfObject:mouseDownView],
		endSelIx = [[self subviews] indexOfObject:endSelectionView]; 
	int newX;
	NSRect newBounds, myBounds;
		
	if ((mouseDownView==nil) || dist==0) {
		NSBeep();
		return;
	}
		
	if (anchorPoint > movablePoint) [self swapSelectionPoints]; // for convenience
	
	if (dist<0) {
		myBounds = [mouseDownView bounds];
		if (mouseDownX<myBounds.origin.x-dist) {
			if (mouseIx<[[self subviews] count]-1) {
				newView = [[self subviews] objectAtIndex:mouseIx+1];
				newBounds = [newView bounds];
				newX = newBounds.origin.x + newBounds.size.width + (mouseDownX+dist);
			} else {
				NSBeep();
				return;
			}
		} else {
			newView = mouseDownView;
			newX = mouseDownX + dist;
		}
	} else {
		myBounds = [endSelectionView bounds];
		if (endSelectionX>=myBounds.origin.x + myBounds.size.width-dist) {
			if (endSelIx>0) {
				newView = [[self subviews] objectAtIndex:endSelIx-1];
				newBounds = [newView bounds];
				newX=newBounds.origin.x + dist - (myBounds.origin.x + myBounds.size.width - endSelectionX);
			} else {
				NSBeep();
				return;
			}
		} else {
			newView = endSelectionView;
			newX = endSelectionX + dist;
		}
	}
	
	[self clearSelection];
	[self anchorSelectionAt:newX :newView];
	[self extendSelectionTo:newX :newView]; 
}

- (void)resetBounds
{
	switch(boundsType) {
		case 0:			/* whole data set */
			[self boundToAll];
			break;
		case 2:			/* to selection */
			currentSelection = boundsSelection;
			[self boundToSelected];
			[self clearSelection];
			break;
	} 
}

- (void)boundToAll
{	
	boundsType=0;
	if(normalizeType==2) return;		//manually set so don't recalc
	[self resetDataMinMax]; 
}

- (void)resetDataMinMax
{
	/** this function will reset minY, maxY to the min/max of the entire data set **/
	int     i, j, c;
	float   min,max, *thePoints;
	Trace   *traceData = [myOwner pointStorageID];
	
	max = 0;
	min = FLT_MAX;
	thePoints = (float *)calloc([traceData length], sizeof(float));
	for (j = 0; j < [traceData numChannels]; j++) {
		for(i=0; i<[traceData length]; i++)
			thePoints[i] = [traceData sampleAtIndex:i channel:j];  

		minY[j] = minVal(thePoints, [traceData length]);
		maxY[j] = maxVal(thePoints, [traceData length]);
		if(minY[j]<min) min = minY[j];
		if(maxY[j]>max) max = maxY[j];
	}
	if(normalizeType!=1) {
		for (j = 0; j < [traceData numChannels]; j++) {
			minY[j] = min;
			maxY[j] = max;
		}
	}
	free(thePoints);
	
	c = [[self subviews] count];
	for(j=0;j<c;j++) 
		[[[self subviews] objectAtIndex:j] setMin:minY Max:maxY]; 
}

- (void)boundToSelected
{
	/** determines the min/max for the selected region, and then sets all views
	to that min/max, then redisplays.
	**/
	int			i, j, tmpCount, numPoints, c;
	float		min,max, *tmpData;
	range		theRange;

	/* Since this method can be called from [SequenceEditor shouldRedraw],
	 * it must force drawing even if no range can be determined to get
	 * the bound from
	 */
	if(currentSelection.start!=currentSelection.end)
		theRange=currentSelection;
	else 
		theRange=boundsSelection;
		
	numPoints = [myOwner numberPoints];
		
	if (theRange.start >= numPoints) {
		boundsSelection.start = boundsSelection.end = -1;
		[self boundToAll];
		return;
	}
	else if (theRange.end > numPoints)
		theRange.end = numPoints;
		 
	max = 0;
	min = FLT_MAX;
	tmpCount = theRange.end - theRange.start;
	tmpData = (float *)calloc([[myOwner pointStorageID] length], sizeof(float));
	printf("for %d data points\n",tmpCount);
	for (j = 0; j < [myOwner numberChannels]; j++) {
		for(i=0; i<[[myOwner pointStorageID] length]; i++)
			tmpData[i] = [[myOwner pointStorageID] sampleAtIndex:i channel:j];  
		minY[j] = minVal(&tmpData[theRange.start], tmpCount);
		maxY[j] = maxVal(&tmpData[theRange.start], tmpCount);
		if(minY[j]<min) min = minY[j];
		if(maxY[j]>max) max = maxY[j];
	}
	free(tmpData);
	if(normalizeType==0) {
		for (j = 0; j < [myOwner numberChannels]; j++) {
			minY[j] = min;
			maxY[j] = max;
		}
	}	
	c = [[self subviews] count];
	for(j=0;j<c;j++) 
		[[[self subviews] objectAtIndex:j] setMin:minY Max:maxY];
	boundsType=2;
	boundsSelection=theRange; 
}

- (void)setDataMin:(float*)min max:(float*)max
{
	int		j, c = [[self subviews] count];
	
	for(j=0;j<c;j++) {
		[[[self subviews] objectAtIndex:j] setMin:min Max:max];
	}
	for(j=0; j<8; j++) {
		minY[j] = min[j];
		maxY[j] = max[j];
	} 
}

- (void)getDataMin:(float*)min max:(float*)max
{
	int		j;
	
	for(j=0; j<8; j++) {
		min[j] = minY[j];
		max[j] = maxY[j];
	} 
}

- (void)setChannelNorm:(int)type
{
	normalizeType = type; 
}

- (int)channelNorm
{
	return normalizeType;
}

- (void)drawRect:(NSRect)rects
{
  int 		i;
  NSRect 	myRect, tempRect;
  id		tempFont;
  float		w1, top;
//  char		str[255], tempStr[64];

  if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
    [[NSColor darkGrayColor] set];
  //  PSsetgray(NSDarkGray);
    tempRect = NSIntersectionRect([self bounds], rects);
    NSRectFill(tempRect);
  };

  myRect = [self bounds];
  myRect = NSInsetRect(myRect , 1 , 1);
  [[NSColor blackColor] set];
//  PSsetgray(NSBlack);

  if(![[NSGraphicsContext currentContext] isDrawingToScreen]) { /* printing */
    top = myRect.size.height;
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"PrintFileAsTitle"] intValue]) {
      NSDictionary *attribs;
      NSPoint p;
      
      tempFont = [[NSFontManager new] fontWithFamily:@"Times" traits:NSBoldFontMask weight:0 size:14];
      attribs = [NSDictionary dictionaryWithObjectsAndKeys:tempFont, NSFontAttributeName, nil];
//      sprintf(str,"%s",[[myOwner fileName] cString]);
      w1 = [tempFont widthOfString:[myOwner fileName]];
      p.x = (myRect.size.width-w1)/2.0;
      p.y = top-20.0;
      [[myOwner fileName] drawAtPoint:p withAttributes:attribs];
    }
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"PrintDataRange"] intValue]) {
      NSDictionary *attribs;
      NSPoint p;
      NSMutableString *theString=[NSMutableString string];
      tempFont = [NSFont userFontOfSize:10];
//      tempFont = [[NSFontManager new] fontWithFamily:@"Helvetica" traits:NSUnboldFontMask weight:0 size:10];
      attribs = [NSDictionary dictionaryWithObjectsAndKeys:tempFont, NSFontAttributeName, nil];
//      str[0] = '\0';
      for(i=0; i<[myOwner numberChannels]; i++) {
        [theString appendFormat:@"chan%d: %1.4f, %1.4f  ",i+1,minY[i],maxY[i]];
      }
      p.x = 10.0; p.y = top-15;
      [theString drawAtPoint:p withAttributes:attribs];			
    }
  }
}
	 
- (void)channelDone:(int)channel
{
	float percent;
	int c = [[self subviews] count];
	
	percent = ((float)count)/((float)c) +
		channel*(1/((float)[myOwner numberChannels]))/
		((float)c);
//	[updateBox updatePercent:self :(100*percent)]; 
}

- (void)viewDone 
{
	count += 1;
	if (count == [[self subviews] count]) {
//		[updateBox updatePercent:self :100.0];
//		[updateBox done:self];
		count = 0;
		statusSHOWN = NO;
	} 
}


- (void)showStatus
{
  char myname[20];

  if (statusSHOWN == NO) {
    statusSHOWN = YES;
    sprintf(myname, "Drawing");
//    updateBox = [StatusController connect];
 //   [updateBox processConnect:self :myname :0];
    count = 0;
  };
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize 
{	
	/** called automatically for resizing view**/
	
	if(debugmode) printf("autoResize\n");
	[[self window] disableFlushWindow];
	[self clearSelection];
	[self myresizeSubviews];
	[self display];
	[[self window] enableFlushWindow];
	[[self window] flushWindow];
}


- (void)myresizeSubviews
{
  /** resizes all subviews to correspond to the current size of MasterView
  **	plus resets the data range and scale of each subview.  Does not cause a display
  **	to occur. **/
  int       i, numberPoints, numViews, subViewHeight;
  NSRect    theFrame, masterFrame;
		
  numberPoints = [myOwner numberPoints];
  numViews =  (int)[[self subviews] count];
  masterFrame = [self bounds];
  subViewHeight = (int)((masterFrame.size.height-(numViews+1)*Yspace)/numViews);
  for (i=0; i<numViews; i++) {
    theFrame.origin.x = Xspace;
    theFrame.origin.y = ((i+1) * Yspace) + (i * subViewHeight);
    theFrame.size.height = subViewHeight;
    theFrame.size.width = masterFrame.size.width-2*Xspace;
    [[[self subviews] objectAtIndex:i] setOrigin:0 :subviewOrigin];
    [[[self subviews] objectAtIndex:i] setRange:((numberPoints * ((numViews -i)-1)) / numViews) :((numberPoints * (numViews - i)) / numViews - 1)];
    [[[self subviews] objectAtIndex:i] setFrame:*(const NSRect *)&theFrame];
  }
}


- (void)setColorWells
{
	int				x, numChannels;
	NSColor *		tempColor;

	numChannels = [myOwner numberChannels];
	for(x=0;x<8;x++) {
		if(x<numChannels) {
			tempColor = [myOwner channelColor:x];
		}
		else tempColor = [NSColor lightGrayColor];
		switch(x) {
			case 0: [color1 setColor:tempColor]; break;
			case 1: [color2 setColor:tempColor]; break;
			case 2: [color3 setColor:tempColor]; break;
			case 3: [color4 setColor:tempColor]; break;
			case 4: [color5 setColor:tempColor]; break;
			case 5: [color6 setColor:tempColor]; break;
			case 6: [color7 setColor:tempColor]; break;
			case 7: [color8 setColor:tempColor]; break;
		}
	} 
}

- (void)shouldRedraw
{
  int 			i, numberPoints, c;

  if ([[[myOwner pointStorageID] taggedInfo] objectForKey:@"phredCalls"] != nil)
    subviewOrigin = LABELHEIGHT*2.5;
  else
    subviewOrigin = LABELHEIGHT;

  [[self window] disableFlushWindow];
  [self highlightBaseAt:-1 num:-1];
  [self setColorWells];

  c = [[self subviews] count];
  numberPoints = [myOwner numberPoints];
  for (i = 0; i < c; i++) {
    [[[self subviews] objectAtIndex:i] setOrigin:0 :subviewOrigin];
    [[[self subviews] objectAtIndex:i] setRange:((numberPoints * ((c -i)-1)) / c) :((numberPoints * (c - i)) / c - 1)];
    //[[[self subviews] objectAtIndex:i] display];		/* just flushes cache */
  }	
  [self clearSelection];
  [self sizeToPercent:viewPercent];
  [self display];
  [[self window] enableFlushWindow];
  [[self window] flushWindow];
}

- (void)resetTrackingRectToVisible;
{
  NSRect  rect;

  NS_DURING
    rect = [self visibleRect];
    if(hasTrackingTag) {
      [self removeTrackingRect:masterViewTrackingTag];
      hasTrackingTag = NO;
    }
    if (debugmode) NSLog(@"tracking rect %f  By  %f\n",rect.size.width, rect.size.height);
    masterViewTrackingTag = [self addTrackingRect:rect
                                            owner:self
                                         userData:nil
                                     assumeInside:NO];
    hasTrackingTag = YES;
  NS_HANDLER
    NSLog(@"error in resetTrackingRectToVisible");
  NS_ENDHANDLER
}

- (void)clearTrackingRect
{
  NS_DURING
    if(hasTrackingTag) [self removeTrackingRect:masterViewTrackingTag];
    masterViewTrackingTag = 0;
    hasTrackingTag = NO;
  NS_HANDLER
    NSLog(@"Error in clearTrackingRect");
  NS_ENDHANDLER
}

- posToBaseNumber:(int)theX :theView
{
  Sequence    *baseList;
  int         x, numBases, index, pointNumber;
  //aBase     *baseArray, *tempBase;

  baseList = [myOwner baseStorageID];
  if(baseList == NULL) return self;

  pointNumber = [theView pointNumber:theX];
  //baseArray = (aBase *)[baseList returnDataPtr];
  numBases = [baseList seqLength];	

  x=0;
  while((x<numBases)&&([[baseList baseAt:x] location]<pointNumber)) x++;

  if(x==0) index=0;
  else if(x>=numBases) index=numBases-1;
  else if(([[baseList baseAt:x] location]-pointNumber)<
     (pointNumber-[[baseList baseAt:x-1] location])) index = x;
  else index=x-1;
  if(index<0) index=0;
  if(index >= numBases) index=numBases-1;

  [self highlightBaseAt:[[baseList baseAt:index] location] num:index+1];
  return self;
}

-posToRawData:(int)theX :theView;
{
  Trace  *traceData;
  int    bitMask, i, numChannels, pointNumber;
  float  value;

  pointNumber = [theView pointNumber:theX];
  traceData = [myOwner pointStorageID];
  numChannels = [myOwner numberChannels];

  bitMask = 1;
  for(i=0; i<numChannels; i++) {
    if([myOwner channelEnabled:i]) {		/* channel is activated */
      value = [traceData sampleAtIndex:pointNumber channel:i];
      {
      id newVar = [rawDataMatrixID cellAtRow:(i/4) column:(i%4)];
      [newVar setFloatingPointFormat:YES left:8 right:4];
      [newVar setFloatValue:value];
      }
    }
    else [[rawDataMatrixID cellAtRow:(i/4) column:(i%4)] setStringValue:@""];
    bitMask = bitMask*2;
  }
  [posNumber setIntValue:pointNumber+[traceData deleteOffset]];
  return self;
}

// extendedHitTest: is like hitTest:, with these differences:
// 1) aPoint is given in this view's coordinate system, instead of superview's
// 2) It's guaranteed to always return a subview--it does this by extending
//	  the boundaries of the subviews (thus the name)
- (NSView *)extendedHitTest:(NSPoint *)aPoint
{
	NSPoint myPoint = *aPoint;
	int i,c=[[self subviews] count];
	NSRect subFrame;
	
	myPoint = [self convertPoint:myPoint fromView:[self superview]]; 
	for (i=0;i<c-1;i++) {
		subFrame = [[[self subviews] objectAtIndex:i] frame];
		subFrame.origin.y -= Yspace/2.0;
		subFrame.size.height += Yspace;
		if (i==0 && aPoint->y<=subFrame.origin.y + subFrame.size.height)
			return [[self subviews] objectAtIndex:0]; // subviews are numbered from bottom up
		if (aPoint->y >= subFrame.origin.y && 
			aPoint->y <= subFrame.origin.y + subFrame.size.height)
			return [[self subviews] objectAtIndex:i];
	}
	
	return [[self subviews] objectAtIndex:c-1];
}


- (void)keyDown:(NSEvent *)theEvent
{
  ToolMaster     *theToolMaster = [[NSApp delegate] toolMaster];
  int            dist=0, i;
  NSString       *charString;
  unichar        thischar; //really an unsigned short

  //NSLog(@"Masterview keyEvent %@", [theEvent description]);
  [theToolMaster notifyKeyEvent:theEvent];

  // Left and right arrow keys:
  if (mouseAction == mouseActionSELECT) {
    charString = [theEvent charactersIgnoringModifiers];
    //if (debugmode) fprintf(stderr, "MasterView keyEvent unicode len=%d\n", [charString length]);
    for(i=0; i<[charString length]; i++) {
      thischar = [charString characterAtIndex:i];
      //if (debugmode) fprintf(stderr, " keyevent %d:  %X\n", i, thischar);
      if(thischar == NSLeftArrowFunctionKey) dist = -1;   // left arrow  (Symbol Set)
      if(thischar == NSRightArrowFunctionKey) dist = 1;    // right arrow (Symbol Set)
    }
    if ([theEvent modifierFlags] & NSShiftKeyMask) dist *= 10;

    if(dist != 0) {
      [self moveSelection:dist];
      [[theToolMaster baseViewingID] highlightBase:currentSelection.start];
      [self posToRawData:mouseDownX :mouseDownView];
      [self posToBaseNumber:mouseDownX :mouseDownView];
      [self centerViewOn:currentSelection.start];
    }
  }
}

- (void)mouseEntered:(NSEvent *)e
{
  if([NSApp isActive]) {
    //NSLog(@"Masterview mouseEntered\n%@", [e description]);
    [[self window] makeFirstResponder:self];
    [[self window] setAcceptsMouseMovedEvents:YES];
  }
}

- (void)mouseExited:(NSEvent *)e
{
  NSEvent  *tempEvent;

  //NSLog(@"Masterview mouseExited\n%@", [e description]);
  [[self window] setAcceptsMouseMovedEvents:NO];
  
  do {
    tempEvent = [NSApp nextEventMatchingMask:NSMouseMovedMask
                                   untilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]
                                      inMode:NSDefaultRunLoopMode
                                     dequeue:YES];
    //if(tempEvent != nil) NSLog(@"mouseExit dequeing %@",[tempEvent description]);
  } while(tempEvent != nil);
  

  [self trackLineAt:-1 :nil];
  [self highlightBaseAt:-1 num:-1];
}

- (void)mouseMoved:(NSEvent *)e
{
  id		theView;
  NSPoint	thePoint;

  thePoint = [e locationInWindow];
  thePoint = [self convertPoint:thePoint fromView:nil];
  theView = [self extendedHitTest:&thePoint];

  thePoint = [self convertPoint:thePoint toView:theView];

  [self trackLineAt:thePoint.x :theView];
  if(pointTrack) [self posToRawData:thePoint.x :theView];
  if(baseTrack) [self posToBaseNumber:thePoint.x :theView];

  [self displayIfNeeded];
}

- (void)mouseDown:(NSEvent *)e
{
  NSPoint thePoint = [e locationInWindow];
  id hitView;

  [[self window] makeFirstResponder:self];
  [[self window] setAcceptsMouseMovedEvents:YES];
  thePoint = [self convertPoint:thePoint fromView:nil];
  (hitView = [self extendedHitTest:&thePoint]);

  if (!([e modifierFlags] & NSShiftKeyMask))
    [self clearSelection];

  thePoint = [self convertPoint:thePoint toView:hitView];

  if (!([e modifierFlags] & NSShiftKeyMask))
    [self anchorSelectionAt:thePoint.x :hitView];	

  switch (mouseAction) {
    case mouseActionSELECT:
      if ([e modifierFlags] & NSShiftKeyMask) {
        int anchorPoint = [mouseDownView pointNumber:mouseDownX],
        movablePoint = [endSelectionView pointNumber:endSelectionX],
        hitPoint = [hitView pointNumber:thePoint.x];

        // The anchoring point for the selection should be the
        // end of the current selection which is further from the hit point
        if (abs(hitPoint-anchorPoint)<abs(hitPoint-movablePoint))
          [self swapSelectionPoints];
        [self trackLineAt:-1 :nil];
        [self extendSelectionTo:thePoint.x :hitView];
      }
      break;

    case mouseActionSHIFT:
      shiftChannelEnable = [myOwner channelEnabled:channelToShift];
      if(shiftChannelEnable) [mouseDownView hideChannel:channelToShift];
      [mouseDownView initSegment:channelToShift at:mouseDownX];
      [mouseDownView drawShiftSegment:mouseDownX];
      break;
  }
}

- (void)mouseDragged:(NSEvent *)e 
{
  NSPoint hitPoint, mousePoint;
#ifdef WIN32
    NSEvent *temp=NULL;
#endif
  id hitView;
  BOOL done = NO;

#ifdef WIN32
  while (temp = [[self window] nextEventMatchingMask:NSLeftMouseDraggedMask	
                                    untilDate:[NSDate dateWithTimeIntervalSinceNow:0.100]
                                       inMode:@"NSDefaultRunLoopMode"
                                      dequeue:YES])
      e = temp;
#endif

  do {
    hitPoint = [e locationInWindow];
    hitPoint = [self convertPoint:hitPoint fromView:nil];
    hitView = [self extendedHitTest:&hitPoint];
    hitPoint = [self convertPoint:hitPoint toView:hitView];

    switch(mouseAction) {
      case mouseActionSELECT:
        [self extendSelectionTo:hitPoint.x :hitView];
        break;

      case mouseActionSHIFT:
        [mouseDownView drawShiftSegment:hitPoint.x];
        break;
    }

    // This is all for handling the case where the user drags out of the
    // view, then holds the mouse with the button pressed
    mousePoint = [[self window] mouseLocationOutsideOfEventStream];
    if ([self autoscroll:e]==NO ||
        (mousePoint.x != [e locationInWindow].x ||
         mousePoint.y != [e locationInWindow].y) ||
        [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask
                           untilDate:[NSDate date]  //don't wait just see if one is there now
                              inMode:NSEventTrackingRunLoopMode
                             dequeue:NO] != NULL)
            done = YES;		
  } while (!done);
}

- (void)mouseUp:(NSEvent *)e
{
  NSPoint thePoint;
  id hitView;
  int localStart, localEnd;
  id theToolMaster = [[NSApp delegate] toolMaster];
  range	tempRange;

  thePoint = [e locationInWindow];

  switch (mouseAction) {
    case mouseActionSELECT:
      thePoint = [self convertPoint:thePoint fromView:nil];
      hitView = [self extendedHitTest:&thePoint];
      thePoint = [self convertPoint:thePoint toView:hitView];
      [self extendSelectionTo:thePoint.x :hitView];
      if (currentSelection.start==currentSelection.end) {
        [[theToolMaster baseViewingID] highlightBase:currentSelection.start];
        [self posToRawData:thePoint.x :hitView];
        [self posToBaseNumber:thePoint.x :hitView];
				[hitView selectPeak:thePoint];  //new for peak selecting
      }
      [theToolMaster notifyMouseEvent:currentSelection];
      break;

    case mouseActionSHIFT:
      thePoint = [mouseDownView convertPoint:thePoint fromView:nil];
      [mouseDownView drawShiftSegment:-1.0];
      if (shiftChannelEnable) {
        [mouseDownView showChannel:channelToShift];        
      }
      localStart = [mouseDownView pointNumber:mouseDownX];
      localEnd = [mouseDownView pointNumber:thePoint.x];
      tempRange.start = localStart;
      tempRange.end = localEnd;
      if (debugmode) NSLog(@"end shift drag, %d  %d", localStart, localEnd);
      [theToolMaster notifyMouseEvent:tempRange];  //Converts to NSRange, location & length
      [self setNeedsDisplay:YES];  //needed to reshow the hidden channel in the other views
      break;
  }
}

- (void)doShift:(int)state channel:(int)channel
{
  //printf("doShift in MasterView   state:%d\n",state);
  if(state) mouseAction=mouseActionSHIFT;
  else mouseAction=mouseActionSELECT;
  channelToShift = channel;
}

- (void)toggleShiftMode
{
	if (mouseAction!=mouseActionSHIFT)
		mouseAction = mouseActionSHIFT;
	else
		mouseAction = mouseActionSELECT; 
}

- (void)setShiftChannel:(int)channel
{
	channelToShift = channel; 
}

- (int)activeBases;
{
	return activeBases;
}

- (void)setActiveBases:(int)mask;
{
	activeBases = mask;
}

- (void)highlightBaseAt:(int)pointLoc num:(int)index
{
  int   i, c = [[self subviews] count];

  for (i=0; i<c; i++) [[[self subviews] objectAtIndex:i] highlightBaseAt:pointLoc];
  if(index == -1) [baseNumber setStringValue:@""];
  else [baseNumber setIntValue:index]; 
}

- (BOOL)centerViewOn:(int)pointLoc
{
	NSPoint tempPoint;
	NSRect	visRect;
	int			c=[[self subviews] count], whichView;
	float		temp = -1;

	visRect = [self visibleRect];
	for(whichView=0; whichView<c; whichView++) {
		temp = [[[self subviews] objectAtIndex:whichView] dataPosToViewPos:pointLoc];
		if(temp>=0.0) break;
	}
	if(temp < 0.0) return NO;
	
	tempPoint.x = temp - visRect.size.width/2;
	tempPoint.y = 0.0;
	[self scrollPoint:tempPoint];
	[[[self superview] superview] reflectScrolledClipView:(NSClipView*)[self superview]];
	return YES;
}

- (void)trackLineAt:(int)theX :theView
{
	if(theView != trackView)
		[trackView trackLineAt:-1];
	[theView trackLineAt:theX];
	trackView = theView; 
}

- (NSColor *)backgroundColor
{
	return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)thisColor
{
	int		x, c = [[self subviews] count];
	
	backgroundColor = thisColor;
	for(x=0; x<c; x++) {
		[[[self subviews] objectAtIndex:x] setBackgroundColor:thisColor];		
	}
}

- (void)dragViewBy:(int)pixels
{
	printf("drag view by %d pixels\n",pixels); 
}

- (int)numViews { return [[self subviews] count]; }
- (float)viewPercent { return viewPercent; }


/*** 
*
* service (pasteboard) providing section
*
***/

- validRequestorForSendType:(NSString *)typeSent returnType:(NSString *)typeReturned
{
    /* First, check to make sure that the types are ones
     * that we can handle. */	 
	  if((([typeSent isEqualToString:NSTabularTextPboardType])  ||
			  ([typeSent isEqualToString:NSStringPboardType]) ||
			  (typeSent == NULL)) && 
			 (typeReturned == NULL)) {
			if(currentSelection.start != currentSelection.end) return self;
    }
		/* Otherwise, return the default. */
    return [super validRequestorForSendType:typeSent returnType:typeSent];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
	int       x=0, pos, channel, numChannels;
	Trace     *dataStorage=[myOwner pointStorageID];
	NSArray   *pbTypes = [NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil];
	NSMutableData    *pbData;
	NSMutableString  *pbString;
	
	for(x=0; x<[types count]; x++) {
		if(([[types objectAtIndex:x] isEqualToString:NSStringPboardType]) || 
		   ([[types objectAtIndex:x] isEqualToString:NSTabularTextPboardType])) {
			printf("write selection to PasteBoard as Tabed Text\n");

			numChannels = [dataStorage numChannels];
			pbString = [NSMutableString stringWithCapacity:4096];
			for(pos=currentSelection.start; pos<currentSelection.end; pos++) {
				for(channel=0; channel<numChannels; channel++) {
					[pbString appendFormat:@"%f\t", [dataStorage sampleAtIndex:pos channel:channel]];
				}
				[pbString appendString:@"\n"];
			}
			
			pbData = [NSMutableData dataWithBytes:[pbString cString] length:[pbString cStringLength]];

			/* send stream to pasteboard */
			[pboard declareTypes:pbTypes owner:NULL];
			if(![pboard setData:pbData forType:NSTabularTextPboardType])
				printf("error writing tabbed stream to PB\n");
			if(![pboard setString:pbString forType:NSStringPboardType])
				printf("error writing ascii stream to PB\n");
			printf("done writing data to pasteboard\n");
			
			return YES;
		}
		else if (debugmode) printf("unknown PB type(%d) %s\n", x, [[types objectAtIndex:x] cString]);
		x++;
	}
	return NO;
}

- (void)cut:(id)sender
{
	printf("cut\n");
}

- (void)copy:(id)sender
{
	NSArray  *pbTypes = [NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil];
	id       pboard;
	
	printf("copy\n");
	pboard = [NSPasteboard generalPasteboard];	//general pasteboard
	[pboard declareTypes:pbTypes owner:NULL];
	[self writeSelectionToPasteboard:pboard types:pbTypes];
}

- (void)paste:(id)sender
{
	NSBeep();
}

- (void)selectAll:(id)sender
{
	endSelectionView = mouseDownView = [[self subviews] objectAtIndex:[[self subviews] count]-1];
	endSelectionX = mouseDownX = 0.0;
	
	currentSelection.start = currentSelection.end = 0;
	
	[self extendSelectionTo:FLT_MAX :[[self subviews] objectAtIndex:0]];
}

@end
