/* "$Id: PrintView.m,v 1.5 2007/06/05 13:00:44 smvasa Exp $" */

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

#import "PrintView.h"
#import "SequenceEditor.h"
#import "SequenceView.h"
#import "MasterView.h"
#import <GeneKit/StatusController.h>
#import <GeneKit/NumericalRoutines.h>
#import <stdio.h>

/****
* April 25, 1994: first creation.  Goal is make a view above the master view level
* which will handle multi-page printing, making a better header on each page (more like
* the abi header)
****/

@implementation PrintView

+ new
{
  NSRect     paperRect;
	id				 thePtr;

	thePtr = [[self alloc] init];
  [thePtr preparePageInfo:&paperRect];
  [thePtr initWithFrame:paperRect];
  return thePtr;
}

- init
{
	[super init];
	return self;
}

- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  if (debugmode) fprintf(stderr, "frameRect w:%f   h:%f\n",frameRect.size.width, frameRect.size.height);

  [self setAutoresizesSubviews:YES];
  [[self superview] setAutoresizesSubviews:YES];
  [self setAutoresizingMask:255];
  [self setAutoresizesSubviews:YES];
  viewList = [[NSMutableArray alloc] initWithCapacity:0];
  totalPages = 1;
  viewsPerPage = 4;
  viewScale = 0.5;		// two time point to one 72dpi pixel
  return self;
}

- (BOOL)isOpaque { return YES; }

- (int)activeBases
{
  return activeBases;
}

- (void)setActiveBases:(int)mask;
{
  activeBases = mask;
}


- (void)preparePageInfo:(NSRect*)printRect
{
  NSPrintInfo    *pi;
  float          left,right,top,bottom;
  NSSize         paperSize;

  pi = [NSPrintInfo sharedPrintInfo];
  [pi setOrientation:NSLandscapeOrientation];
  [pi setHorizontalPagination:NSClipPagination];
  [pi setVerticalPagination:NSClipPagination];
  [pi setHorizontallyCentered:YES];
  [pi setVerticallyCentered:YES];

  [pi setLeftMargin:27];
  [pi setRightMargin:27];
  [pi setTopMargin:18];
  [pi setBottomMargin:18];		//9pts = 1/8 inch

  left = [pi leftMargin];    //9pts = 1/8 inch
  right = [pi rightMargin];  //9pts = 1/8 inch
  top = [pi topMargin];      //9pts = 1/8 inch
  bottom = [pi bottomMargin];
  
  if (debugmode) fprintf(stderr, "margins l:%f  r:%f  t:%f  b:%f\n",left,right,top,bottom);

  paperSize = [pi paperSize];
  if (debugmode) fprintf(stderr, "paperSize w:%f  h:%f\n",paperSize.width, paperSize.height);
  printRect->size.width = paperSize.width - (left + right);
  printRect->size.height = paperSize.height - (top + bottom);
  printRect->origin.x = 0.0;
  printRect->origin.y = 0.0; 
}

- (void)setOwner:sender
{	
  seqEditor=sender;
}

- (void)setDataMin:(float*)min max:(float*)max
{
  int   j;

  for(j=0; j<8; j++) {
    minY[j] = min[j];
    maxY[j] = max[j];
  }
}

- (void)addIcon
{
  NSRect       myRect, tempRect;
  NSImageView  *iconImage;
  float        top;

  myRect = [self bounds];
  top = myRect.size.height + myRect.origin.y;

  tempRect = NSMakeRect(1.0, top-53.0, 52.0, 52.0);
  iconImage = [[NSImageView alloc] initWithFrame:tempRect];
  [iconImage setEditable:NO];
  [iconImage setImageAlignment:NSImageAlignTopLeft];
  [iconImage setImageScaling:NSScaleNone];
  [iconImage setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
  [self addSubview:iconImage];
}

- drawHeader
{
  int       i;
  NSRect    myRect;
  NSFont    *tempFont;
  float    top;
  NSString  *tempNSString;
  NSDictionary *attribs;
  NSPoint p;
  NSMutableString *temp;  

  myRect = [self bounds];
  top = myRect.size.height + myRect.origin.y;

  tempFont = [NSFont userFontOfSize:10];
  attribs = [NSDictionary dictionaryWithObjectsAndKeys:tempFont, NSFontAttributeName,nil];
//  [tempFont set];
  //if (debugmode) fprintf(stderr, "font='%s'\n",[tempFont name]);

  /**** Prog name and version ****/
//  temp= [NSString  appendFormat:@"Base
  p.x = 1.0; p.y = top-58;
  [@"BaseFinder" drawAtPoint:p withAttributes:attribs];
  p.y = top - 70;
  [@"Release 3.0" drawAtPoint:p withAttributes:attribs];
//  sprintf(str, "BaseFinder");
//  PSmoveto(1.0, top-58);
//  PSshow(str);
//  sprintf(str, "Release 3.0");
//  PSmoveto(1.0, top-70);
//  PSshow(str);
//  PSstroke();

  /**** Page Number ****/
  p.x = myRect.size.width - 72; p.y = top - 26;
  [[NSString stringWithFormat:@"Page %d of %d",currentPage, totalPages] drawAtPoint:p withAttributes:attribs];
/*  sprintf(str,"Page %d of %d",currentPage, totalPages);
  PSmoveto(myRect.size.width - 72, top - 26);
  PSshow(str);
  PSstroke(); */

  /**** Lane info ****/
  p.x = 108.0; p.y = top - 26;
  [NSString stringWithFormat:@"Lane %d of %d",[seqEditor currentLane], [seqEditor numLanes]];
/*  sprintf(str, "Lane %d of %d",[seqEditor currentLane], [seqEditor numLanes]);
  PSmoveto(108.0, top - 26);
  PSshow(str);  */

  /**** Data min/max ranges ****/
  temp = [NSMutableString stringWithString:@"Signal: "];
//  strcpy(str, "Signal:  ");
  for(i=0; i<[seqEditor numberChannels]; i++) {
    switch(i) {
      case 0: [temp appendString:@"C: "];  //strcat(str, "C: "); 
        break;
      case 1: [temp appendString:@"A: "];  //strcat(str, "A: "); 
        break;
      case 2: [temp appendString:@"G: "];  //strcat(str, "G: "); 
        break;
      case 3: [temp appendString:@"T: "];  //strcat(str, "T: "); 
        break;
    }
    [temp appendFormat:@"%1.2f to %1.2f  ",minY[i],maxY[i]];
   // sprintf(tempStr,"%1.2f to %1.2f  ",minY[i],maxY[i]);
   // strcat(str,tempStr);
  }			
  p.x = 108.0; p.y = top-70;
  [temp drawAtPoint:p withAttributes:attribs];
/*  PSmoveto(108.0,top-70);
  PSshow(str);
  PSstroke();  */

  /**** Data min/max ranges ****/
  /***
  for(i=0; i<[seqEditor numberChannels]; i++) {
    sprintf(str,"chan%d",i+1);
    PSmoveto(108.0 + 100*i,top-46);
    PSshow(str);
    sprintf(str,"%1.4f",maxY[i]);
    PSmoveto(108.0 + 100*i,top-58);
    PSshow(str);
    sprintf(str,"%1.4f",minY[i]);
    PSmoveto(108.0 + 100*i,top-70);
    PSshow(str);
  }			
  PSstroke();
  ***/

  /**** Title ****/
  tempFont = [NSFont fontWithName:@"Times-Bold" size:14];
  attribs = [NSDictionary dictionaryWithObjectsAndKeys:tempFont, NSFontAttributeName,nil];
  //if (debugmode) fprintf(stderr, "font='%s'\n",[tempFont name]);
//  [tempFont set];
  tempNSString = [seqEditor fileName];
  p.x = 108.0; p.y = top-14.0;
  [[NSString stringWithFormat:@"%@ --- %@", [tempNSString lastPathComponent], [tempNSString stringByDeletingLastPathComponent]] drawAtPoint:p withAttributes:attribs];
/*  sprintf(str,"%s --- %s", [[tempNSString lastPathComponent] cString],
          [[tempNSString stringByDeletingLastPathComponent] cString]);
  w1 = [tempFont widthOfString:[NSString stringWithCString:str]];
  //PSmoveto((myRect.size.width-w1)/2.0,top-20.0);
  PSmoveto(108.0,top-14.0);
  PSshow(str);
  PSstroke();  */

  /**** Border ****
  PSmoveto(0.0, myRect.size.height-72.0);
  PSrlineto(myRect.size.width, 0.0);
  PSstroke();
  ***/
  return self;
}


- drawSubviewFrames
{
  int 		x;
  NSRect 	theRect;

  [[NSColor blackColor] set];
//  PSsetgray(NSBlack);
  [NSBezierPath setDefaultLineWidth:0.5];
  //PSsetlinewidth(0.5);
  for (x=0; x<[viewList count]; x++) {
    theRect = [[viewList objectAtIndex:x] frame];
    theRect.size.width+=2;
    theRect.size.height+=2;
    theRect.origin.x--;
    theRect.origin.y--;
    [NSBezierPath strokeRect:theRect];
/*    PSrectstroke(theRect.origin.x, theRect.origin.y,
                 theRect.size.width, theRect.size.height);
    if (debugmode) fprintf(stderr, "subview %f %f %f %f\n", theRect.origin.x, theRect.origin.y,
            theRect.size.width, theRect.size.height);  */
    }
  return self;
}


- (void)addSequenceViews
{
  int            x, pointsPerView;
  int            startRange, endRange;
  NSRect         theFrame, printRect;
  float          subViewHeight, yScaleValue;
  SequenceView   *addedView;
  unsigned       numberPoints;

  if (debugmode) fprintf(stderr, "adding sequenceViews page %d\n",currentPage);
  /* remove subviews from view hierarchy and free */
  for(x=0; x<[viewList count]; x++) {
    [[viewList objectAtIndex:x] removeFromSuperview];
  }
  [viewList removeAllObjects];

  printRect = [self bounds];
  if(atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"PrintHeader"] cString]))
    printRect.size.height -= 72;	// header space
  printRect = NSInsetRect(printRect , 1.0 , 1.0);
  subViewHeight = (printRect.size.height) / viewsPerPage;

  numberPoints = [seqEditor numberPoints];
  pointsPerView = (int)(printRect.size.width / viewScale);
  yScaleValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"scaleValue"] floatValue];
  if (yScaleValue == 0) yScaleValue = 1.0;
  /* Add the new views */
  for (x=0; x<viewsPerPage; x++) {
    startRange = (currentPage-1)*viewsPerPage*pointsPerView + pointsPerView*x;
    endRange = startRange + pointsPerView;
    if(endRange >= numberPoints) endRange = numberPoints - 1;
    if(startRange < numberPoints) {
      theFrame.origin.x = printRect.origin.x;
      theFrame.origin.y = printRect.origin.y + (viewsPerPage-x-1)*subViewHeight;
      theFrame.size.width = (endRange-startRange) * viewScale;
      theFrame.size.height = subViewHeight-5.0;
      addedView = [[SequenceView alloc] initWithFrame:theFrame];
      [self addSubview:addedView];
      [viewList addObject:addedView];
      [addedView setOrigin:0 :15];
      [addedView setRange:startRange :endRange];
      [addedView setSeqEditor:seqEditor];
      [addedView setBackgroundColor:[NSColor whiteColor]];
    }
  }

  for(x=0; x<[viewList count]; x++) {
    [[viewList objectAtIndex:x] setMin:minY Max:maxY];
    [[viewList objectAtIndex:x] setYScale:yScaleValue];
  }
}


/***
* 
* display, pagination, and printing routines
*
***/

- (void)drawRect:(NSRect)rects
{
  NSRect 	myRect;

  myRect = [self bounds];
  if (debugmode) fprintf(stderr, "drawSelf rect %f  %f  %f  %f\n",myRect.origin.x, myRect.origin.y,
          myRect.size.width, myRect.size.height);
  [[NSColor blackColor] set];
  [NSBezierPath setDefaultLineWidth:0.5];

//  PSsetgray(NSBlack);
//  PSsetlinewidth(0.5);

  //NXFrameRect(&myRect);

  if([[[NSUserDefaults standardUserDefaults] objectForKey:@"PrintHeader"] intValue])
    [self drawHeader];
  [self drawSubviewFrames];
}

- (BOOL)knowsPagesFirst:(int *)firstPageNum last:(int *)lastPageNum
{
  NSRect          tempRect;
  int             numPoints = [seqEditor numberPoints];
  NSUserDefaults  *myDefs;

  myDefs = [NSUserDefaults standardUserDefaults];
  /** this action is called after the print panel leaves, but before any drawing **/
  if(atoi([[myDefs objectForKey:@"PrintHeader"] cString]))
    [self addIcon];

  viewsPerPage = (int)atoi([[myDefs objectForKey:@"PrintViewsPerPage"] cString]);
  viewScale = (float)atof([[myDefs objectForKey:@"PrintViewScale"] cString]);
  tempRect = [self bounds];
  if(viewScale == 0.0) {
    // fit to one page
    viewScale = (viewsPerPage * (tempRect.size.width-2))/numPoints;
  }
  if (debugmode) fprintf(stderr, "viewsPerPage=%d   viewScale=%f\n",viewsPerPage, viewScale);

  totalPages = (numPoints-1) / (viewsPerPage * ((tempRect.size.width-2)/viewScale)) + 1;
  if (debugmode) fprintf(stderr, "knows pages 1 to %d\n", totalPages);
  *firstPageNum = 1;
  *lastPageNum = totalPages;
  return YES;
}

- (NSRect)rectForPage:(int)page
{

  NSRect   theRect;
  NSRect   tempRect;

  tempRect = [self bounds];
  theRect = NSMakeRect(tempRect.origin.x, tempRect.origin.y, tempRect.size.width, tempRect.size.height);
  if (debugmode) fprintf(stderr, "getRectForPage %d\n",page);
  currentPage = page;
  [self addSequenceViews];
  return theRect;
}


@end
