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
NIH Center for AIDS Research


******************************************************************/

#import <BaseFinderKit/GenericToolCtrl.h>
//#import <GeneKit/StatusController.h>

@interface ToolAlignCtrl:GenericToolCtrl <BFToolMouseEvent>
{
	IBOutlet	NSBox *accessoryView;
	
	id	viewButtons;
	
	id	initView;         //initialize
	id	reagentChanID;
	id	nreagentChanID;
	id	ddNTPChan1ID;
	id	ddNTPChan2ID;
	id	ddNTP1ID;
	id	ddNTP2ID;
	id	sequenceText;
	id	rangeFromID;
  id  rangeToID;
  id  seqFromID;
  id  seqToID;
	id	NTLevel1ID;
  id  NTLevel2ID;
  id  refineID;
  id  seqStartID;
	
	id	addDelView;      // add or delete peaks
	id	addDelID;
  id  tableView;
	id	addDelTextID;
	
	id integViewID;			// integration, gaussian peaks
	id integFile;
  id integFitFile;
  id optimizeID;
  id statusTextID;
  id progressIndID;
  
  id errorTextID;    //error text
  id errorWinID;

	id	blankView;
	
	int	viewInd;
	id previousView;
	
	int	addDel;  //0 delete, 1 add
	int selectedColumn;  //0 = +Reagent, 1 = -Reagent
	NSString  *openPath;
}

- init;
- (void)appWillInit;
- (IBAction)initData:(id)sender;
- (IBAction)modifyAddDel:(id)sender;
- (IBAction)integrateData:(id)sender;
- (IBAction)changeAddDelMessage:(id)sender;
- (IBAction)errorOkay:(id)sender;
- (IBAction)channelChange:(id)sender;
- (IBAction)channelChange2:(id)sender;
- (IBAction)channelChange3:(id)sender;
- (IBAction)channelChange4:(id)sender;
- (void)savePeaks:sender;
- (void)saveFit:sender;
- (void)open:sender;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)row;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
//- (void)tableView:(NSTableView *)aTableView didClickTableColumn:(NSTableColumn *)tableColumn;

- (void)getParams;
- (void)displayParams;
- (void)resetParams;
- (BOOL)inspectorWillUndisplay;
- (void)mouseEvent:(range)theRange;
- (void)fitDone;
-(void)dealloc;

NSString  *errorNTP = @"ddNTPs cannot be equal";
NSString  *errorSequence = @"Must enter a valid sequence file";
NSString  *errorRange = @"Error in trace range";
NSString  *errorAGCU = @"Error in sequence range";
NSString  *errorPath = @"Sequence file not found";

@end
