
/* "$Id: BasesView.m,v 1.7 2008/04/15 20:50:22 smvasa Exp $" */

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

#import "BasesView.h"
#import <GeneKit/NumericalRoutines.h>
#import "SequenceEditor.h"
#import "MasterView.h"
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

@interface BasesView (PrivateBasesView)
- (void)synchronizeToScript;
@end

@implementation BasesView

+ new
{
  BasesView    *newSelf = [super alloc];
  [NSBundle loadNibNamed:@"BasesView.nib" owner:newSelf];
  [newSelf init];
  return newSelf;
}

- init
{
  baseCache.next = NULL;
  currentSeqEdit = NULL;
  currentBaseList = NULL;
  matrixView = NULL;
  [self makeCellTemplate];
  appClosing=NO;
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (currentSeqEdit)
    [currentSeqEdit autorelease];
  if (currentBaseList) 
    [currentBaseList autorelease];
  if (matrixView)
    [matrixView autorelease];
  if (cellTemplate)
    [cellTemplate release];
  [super dealloc];
}

- (void)appWillInit
{
  BOOL    showBases;
  NSNotificationCenter  *defCenter;
  NSDictionary *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"YES", @"ShowBasesPanel",
    nil];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
  [[NSUserDefaults standardUserDefaults] synchronize];
  showBases = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBasesPanel"];

  [panelID setDelegate:self];
  [panelID setFrameUsingName:@"BasesPanel"];
  [panelID display];
  [panelID setFrameAutosaveName:@"BasesPanel"];
  [panelID display];
  if(showBases) [panelID orderFront:self];
  else [panelID orderOut:self];

  defCenter = [NSNotificationCenter defaultCenter];
  [defCenter addObserver:self
                selector:@selector(appClosing)
                    name:NSApplicationWillTerminateNotification
                  object:nil];
  [defCenter addObserver:self
                selector:@selector(synchronizeToScript)
                    name:@"BFSynchronizeScriptAndTools"
                  object:nil];
  [defCenter addObserver:self
                selector:@selector(synchronizeToScript)
                    name:@"BFSynchronizeScript"
                  object:nil];
  [scrollView setDocumentView:nil];
  [scrollView display];


}

- (void)showPanel:sender
{
  [panelID orderFront:self];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowBasesPanel"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)appClosing
{
  appClosing=YES;
}

- (void)makeCellTemplate
{
	int test;
	
  cellTemplate = [[NSButtonCell alloc] init];
  [cellTemplate setFont:[NSFont userFixedPitchFontOfSize:12]];
  [cellTemplate setButtonType:NSToggleButton];
  [cellTemplate setBezeled:NO];
  [cellTemplate setBordered:NO];
  [cellTemplate setHighlightsBy:NSChangeGrayCellMask/*NSChangeBackgroundCellMask*/];
  //[cellTemplate setShowsStateBy:NSChangeGrayCellMask];
  [cellTemplate setTitle:@"     A           A            A           A    "];
  [cellTemplate setAlignment:NSLeftTextAlignment];
	test = [cellTemplate state];
  //[cellTemplate setSelectable:YES];
}

- (NSMatrix*)makeMatrix:(id)baseList
{
  int         count, x;
  Base        *thisBase;
  NSString    *tempStr;
  NSMatrix    *_matrixView;
  NSRect      tempRect;
  NSSize      tempSize;
	int					offset, num, index;
	BOOL				backwards;

  if(baseList == NULL) return NULL;
  currentBaseList = baseList;

  count = [baseList seqLength];	
	offset = [baseList getOffset];
	backwards = [baseList getbackForwards];
  tempSize = [cellTemplate cellSize];
//  tempSize.width = 200.0;
//  tempSize.height = 12.0;
//  tempSize.width = 165.0;
//  tempRect = [scrollView documentVisibleRect];
  tempRect = NSMakeRect(0, 0, tempSize.width, count*tempSize.height);
  _matrixView = [[NSMatrix alloc] initWithFrame:tempRect
                                          mode:NSListModeMatrix //NSRadioModeMatrix
                                     prototype:cellTemplate
                                  numberOfRows:count
                               numberOfColumns:1];
  tempSize.width = 0.0;
  tempSize.height = 0.0;
  [_matrixView setIntercellSpacing:tempSize];
  [_matrixView setBackgroundColor:[[_matrixView window] backgroundColor]];
  [_matrixView setCellBackgroundColor:[[_matrixView window] backgroundColor]];
  tempSize = [cellTemplate cellSize];
//  tempSize.width = 165.0;
//  tempSize.height = 12.0;
//  tempSize.width = 2000;
  [_matrixView setCellSize:tempSize];
  [_matrixView setFont:[NSFont userFixedPitchFontOfSize:12]];
  [_matrixView setAutoscroll:YES];
  [_matrixView setScrollable:YES];
  [_matrixView setTarget:self];
  [_matrixView setAction:@selector(cellSelected:)];
  [_matrixView setDoubleAction:@selector(cellSelected:)];
  [_matrixView setAutosizesCells:YES];
  [_matrixView sizeToCells];
	
	num = (offset > 0) ? offset : 1;
  for(x=0;x<count;x++) {
		if (backwards)
			index = num-x;
		else
			index = num+x;
    thisBase = (Base *)[currentBaseList baseAt:x];
//    tempStr = [NSString stringWithFormat:@"%4d  %c  %4.2f  %d\n",x+1, [thisBase base], [thisBase floatConfidence], [thisBase location]];
    tempStr = [NSString stringWithFormat:@"%4d   %c    %4.2f     %d",index, [thisBase base], [thisBase floatConfidence], ([thisBase location]+[[currentSeqEdit trace] deleteOffset])];
    //sprintf(tempStr,"%4d  %c  %6.4f  %d\n",x+1, [thisBase base], [thisBase confidence],
    //        [thisBase location]);
    [[_matrixView cellAtRow:x column:0] setTitle:tempStr];
//      [[_matrixView cellAtRow:x column:0] setTitle:@"Fred"];
  }

  return _matrixView;
}

- MATRIXrecalc:(int)start
{
  /* recalc the currentBaseList into the currentMatrix starting at base 'start'*/
  int         count, x;
  Base        *thisBase;
  NSString    *tempStr;

  count = [currentBaseList seqLength];	
//  matrixView = currentCache->matrixView;
  if([[matrixView cells] count] != count) {
   if (debugmode) printf("many deleted so full recalc\n");
    [matrixView renewRows:count columns:1];
    [matrixView sizeToCells];
    start = 0;		/* because we don't know where the deleted base(s) are */
  }
		
  for(x=start;x<count;x++) {
    thisBase = (Base *)[currentBaseList baseAt:x];
    tempStr = [NSString stringWithFormat:@"%4d   %c    %4.2f     %d", x+1, [thisBase base], [thisBase floatConfidence],
      [thisBase location]];
    //sprintf(tempStr,"%4d  %c  %6.4f  %d\n",x+1, [thisBase base], [thisBase confidence],
    //        [thisBase location]);
    [[matrixView cellAtRow:x column:0] setTitle:tempStr];
  }
  return self;		
}

- MATRIXsetBaseSequence:(id)seqEdit reset:(BOOL)resetFlag
{
//  struct baseCacheStruct    *tempCache;
  Sequence                  *baseList;


  if((seqEdit==NULL) || ([seqEdit baseStorageID] == NULL)) {
    //[panelID orderOut:self];
    //tempCache->baseList = baseList;
//    currentCache = NULL; //tempCache;
    if (currentBaseList)
      [currentBaseList release];
//    if (currentSeqEdit)
//      [currentSeqEdit release];
    if (matrixView)
      [matrixView autorelease];
    currentBaseList = NULL;
    currentSeqEdit = NULL;
    matrixView = NULL;
    [scrollView setDocumentView:matrixView];
    [scrollView setBackgroundColor:[[scrollView window] backgroundColor]];
    [[scrollView verticalScroller] setEnabled:NO];
    [scrollView display];
    [aveConfidence setStringValue:@""];
    return self;
  }
  if ([seqEdit baseStorageID] == currentBaseList)
    return self;
    
  baseList = [seqEdit baseStorageID];

    if (currentSeqEdit)
      [currentSeqEdit release];
    if (currentBaseList) 
      [currentBaseList release];
    if (matrixView)
      [matrixView autorelease];
    currentSeqEdit = [seqEdit retain];
    matrixView = [self makeMatrix:baseList];
    currentBaseList = [baseList retain];

  //[panelID orderFront:self];
//  currentCache = tempCache;
//  currentBaseList = baseList;

/*  if((tempCache->baseList != baseList) || resetFlag) {
    tempCache->baseList = baseList;
    if(tempCache->matrixView == NULL) {
      tempCache->matrixView = [self makeMATRIX:baseList];
    }
    else {
      currentCache = tempCache;
      [self MATRIXrecalc:0];
    }
  }
*/
  [[scrollView verticalScroller] setEnabled:YES];
  //[scrollView setBackgroundColor:[[scrollView window] backgroundColor]];
  [scrollView setDocumentView:matrixView];
  [scrollView display];
  [self setAveConfidence];
  return self;
}

- MATRIXhighlightBase:(int)pointNumber
{
  int     x, count, index;

  if(currentBaseList == NULL) return self;

  count = [currentBaseList seqLength];	

  x=0;
  while((x<count)&&([[currentBaseList baseAt:x] location]<pointNumber)) x++;

  if(x==0) index=0;
  else if(x>=count) index=count-1;
  else if(([[currentBaseList baseAt:x] location]-pointNumber)<
     (pointNumber-[[currentBaseList baseAt:(x-1)] location])) index = x;
  else index= x-1;
  if(index<0) index=0;

  [matrixView selectCellAtRow:index column:0];
  [matrixView scrollCellToVisibleAtRow:index column:0];

  return self;
}

- (void)highlightBase:(int)pointNumber
{
  [self MATRIXhighlightBase:pointNumber];
}

- (void)synchronizeToScript
{
  currentSeqEdit = GSeqEdit;
  [self MATRIXsetBaseSequence:GSeqEdit reset:NO];
}

- (void)resetSeqEdit:(id)seqEditor
{
  currentSeqEdit = seqEditor;
  [self MATRIXsetBaseSequence:seqEditor reset:YES];
}

- (void)setAveConfidence
{
  float   total=0.0;
  int     count,x;

  count = [currentBaseList seqLength];
  for(x=0; x<count; x++) {
    total += [[currentBaseList baseAt:x] floatConfidence];
  }
  [aveConfidence setFloatValue:(total/(float)count)];
}

- (void)cellSelected:sender
{	
  Base   *tempBase;
  int    selectedBase;
  id     masterViewID;
	int		 test;
	
	test = [[matrixView selectedCell] state];

  selectedBase = [matrixView selectedRow];
  [matrixView highlightCell:YES atRow:selectedBase column:0];
  tempBase = (Base *)[currentBaseList baseAt:selectedBase];
  masterViewID = [currentSeqEdit masterViewID];
  [masterViewID highlightBaseAt:[tempBase location] num:selectedBase+1];
  [masterViewID centerViewOn:[tempBase location]];
}

- (void)deleteSelectedBase
{
  int   index,count;

//  matrixView = currentCache->matrixView;
  index = [matrixView selectedRow];

  [currentBaseList removeBaseAt:index];
  count = [currentBaseList seqLength];
  [matrixView removeRow:index];
  [matrixView sizeToCells];
  [self MATRIXrecalc:index];
  if(index>count) index=count;		/* for case of deleting last element in array */
  [matrixView selectCellAtRow:index column:0];
  [matrixView display];
  [self setAveConfidence];
  [[currentSeqEdit masterViewID] shouldRedraw];
}


- (id)panelID { return panelID; }

- (void)windowWillClose:(NSNotification *)aNotification
{
  if(!appClosing) {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowBasesPanel"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

@end
