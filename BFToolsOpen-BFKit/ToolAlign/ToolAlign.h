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

#import <BaseFinderKit/GenericTool.h>
#import <GeneKit/EventLadder.h>

@interface ToolAlign:GenericTool
{
	NSMutableArray	*delReagent;
	NSMutableArray	*addReagent;
	NSMutableArray	*delnReagent;
	NSMutableArray	*addnReagent;
  NSMutableArray  *del1ddNTP, *add1ddNTP;
  NSMutableArray  *del2ddNTP, *add2ddNTP;
	char	ntcomplement[2];
	char	nt[2];
	int		chanLoc[4];
	Sequence *revSequence;
	NSString *seqPath;
	int		len;
	int		viewInd;
	int		rangeBegin;
	int		rangeEnd;
	int		seqstartnum;
	float	nt1sensitivity;
	float	nt2sensitivity;
  int   optimize;
  int   seqrangefrom;		// from which number... 
	int   seqrangeto;			// to which number do we consider sequence when we loo
  int   refinepeaks;        // improve spread of peaks after detection (default is 1, but can cause problems with ABI peaks if rx is not well sync with bg)
	AlignedPeaks  		*peakStuff;         //array of aligned peaks
	Sequence					*seqList;           //Whole sequence aligned with reagent
	Sequence					*alignSeqList;      //Bases aligned with ddNTP channels
  EventLadder       *peakLadder;        //Gaussians for reagent and background
  NSString          *peakFile, *fitFile;
  BOOL  applyOkay;
  
  BOOL    threadIsExecuting;
  Trace*  tempTrace;
}

- apply;
- init;
- (BOOL)shouldCache;
- (BOOL)isInteractive;
- (void)initAgain;
- (void)releaseMem;
- (void)doApply:(BOOL)canApply;
- (void)setChanLoc:(int *)chanloc;
- (void)getChanLoc:(int *)chanloc;
- (void)setddNTP:(char)ddNTPa :(char)ddNTPb;
- (void)getddNTP:(char *)ddNTPa :(char *)ddNTPb;
- (int)setSequence;
- (void)setFilePath:(NSString *)filepath;
-(NSString *)getFilePath;
- (void)swapChannels:(Trace *)channelData;
//- (void)swapChannels:(Trace *)channelData :(int)From :(int)To;
- (void)setViewInd:(int)xview;
- (int) getViewInd;
- (NSMutableArray *)getDelPeak:(int)channel;
- (void) addDelPeak:(NSNumber *) peak :(int) channel;
- (void) remDelPeak:(int)index anObject:theObject :(int)channel;
- (NSMutableArray *)getAddPeak:(int)channel;
- (void) addAddPeak:(NSNumber *) peak :(int) channel;
- (void) remAddPeak:(int)index anObject:theObject :(int)channel;
- (void)setRange:(int)xBegin :(int)xEnd;
- (void)getRange:(int *)xBegin :(int *)xEnd :(int *)seqFrom :(int *)seqTo :(int *)seqStNo;
- (void)setSeqRange:(int)sBegin :(int)sEnd;
- (void)setSeqNo:(int)seqno;
- (void)getNTSens:(float *)NTSens1 :(float *)NTSens2;
- (void)setNTSens:(float)NTSens1 :(float)NTSens2;
-(void)setOptimizeFlag:(int)flag;
-(int) getOptimizeFlag;
-(void)savePeakFile:(NSString *)saveFile;
-(NSString *)getPeakFile;
-(void)saveFitFile:(NSString *)saveFile;
-(NSString *)getFitFile;
-(void)setRefine:(int)ref;
-(int)getRefine;
- (BOOL)fitOngoing;
- (void)fitDone;

//- (id)initWithCoder:(NSCoder *)aDecoder;
//- (void)encodeWithCoder:(NSCoder *)aCoder;
- (void)beginDearchiving:archiver;
- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

-(void)dealloc;

@end
