/***********************************************************

Copyright (c) 2005 Suzy Vasa

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

#import "ToolAlign.h"
#include "FindPeak.h"
//#import <GeneKit/NumericalObject.h>
#import <GeneKit/Gaussian.h>
//#import <GeneKit/LadderPeak.h>
#import <GeneKit/StatusController.h>
#import <BaseFinderKit/GenericToolCtrl.h>
#import <BaseFinderKit/NewScript.h>

@interface ToolAlign (Private)
- (void)initializeData:(SPECTRA *)sp :(int)channel :(Trace *)ourData;
- (void) peakView:(Trace *)ourData :(BOOL)integrate;
- (void)findPeaks:(Trace *)ourData :(BOOL)integrate :(NSString *)saveFile :(NSString *)saveFit;
- (void)initializePeaks;
- (void)PeakLinkWithSeqTrace:(SPECTRA *)sp1 bg:(SPECTRA *)sp2 nt1:(SPECTRA *)ddnt nt2:(SPECTRA *)ddnt2 :(char *)seq :(int)alignstart :(int)seqlen :(int)seqstart;
- (int)findExtraPeak:(int)start :(int)stop :(float*)thedata :(BOOL)forward;
- (void)IntegrateFirstLast:(SPECTRA *)nmia bg:(SPECTRA*)bg first:(int)firstpeak last:(int)lastpeak :(Trace *)ourData;
- (void)IntegratedPeaks:(SPECTRA)nmia bg:(SPECTRA)bg first:(int)firstnmia last:(int)lastnmia :(NSString *)saveFile :(NSString *)saveFit :(int)traceOffset;
- (void)fitInThread;
- (void)notifyThatThreadDone:(AlignedPeaks *)thePeaks :(Sequence *)theBases :(Sequence *)theABases :(EventLadder *)theLadder;
- (void) clearMyPointers;
-(int) localAlign:(SPECTRA *)sp;
@end

@implementation ToolAlign

-init
{	
	[super init];
  [self initAgain];
	return self;
}

- (void)releaseMem
{
  [seqPath release];
  [addReagent release];
  [addnReagent release];
  [delReagent release];
  [delnReagent release];
  [add1ddNTP release];
  [del1ddNTP release];
  [add2ddNTP release];
  [del2ddNTP release];
  [self clearMyPointers];
  if (revSequence != nil) {
    [revSequence release];
  }
  if (peakFile != nil) [peakFile release];
  if (fitFile != nil) [fitFile release];
  if (tempTrace != nil) [tempTrace release];
}

- (void)initAgain
{
  int i;
  
  viewInd = 0;
	for (i=0; i<4; i++)
		chanLoc[i] = i;
	ntcomplement[0] = 'G';
	ntcomplement[1] = 'T';
	seqPath = nil;
	addReagent = [[NSMutableArray alloc] init];
	addnReagent = [[NSMutableArray alloc] init];
	delReagent = [[NSMutableArray alloc] init];
	delnReagent = [[NSMutableArray alloc] init];
  add1ddNTP = [[NSMutableArray alloc] init];
  del1ddNTP = [[NSMutableArray alloc] init];
  add2ddNTP = [[NSMutableArray alloc] init];
  del2ddNTP = [[NSMutableArray alloc] init];
	peakStuff = nil;
	seqList = nil;
	alignSeqList = nil;
	peakLadder = nil;
	revSequence = nil;
	len = 0;
	rangeBegin = -1; 
	rangeEnd = -1;
	seqstartnum = 1;
	nt1sensitivity = 2.5;
	nt2sensitivity = 2.5;
  optimize = 0;
  peakFile = nil;
  fitFile = nil;
  refinepeaks = 1;
  seqrangefrom = 0;
  seqrangeto = 0;
  applyOkay = YES;
  threadIsExecuting = NO;
  tempTrace = nil;
}

- (NSString *)toolName
{
	 return [NSString stringWithString:@"Align and Integrate"];
}

- (BOOL)shouldCache 
{ 
  return YES; 
}

- (BOOL)isInteractive
{
	return YES;
}

- apply
{
  int                i;
  BOOL               swapChannels=NO;

  [self setStatusPercent:0.0]; //don't use, just make sure it's cleared
  [self setStatusMessage:@"Aligning"];
  if (!applyOkay ) return [super apply];
  if (threadIsExecuting) return [super apply];
  for (i=0;i < 4; i++) {
    if (chanLoc[i] != i)
      swapChannels = YES;
  }
  if (swapChannels) {
    [self swapChannels:[self dataList]];
    for (i = 0; i < 4; i++) {
      chanLoc[i] = i;
    }
  }
  switch (viewInd) {
  case 0:  //setup
    [self peakView:dataList :NO];
    break;
  case 1:  //modify peaks
    [self peakView:dataList :NO];
    break;
  case 2:  //start fitting
    //fitting takes a long time
    //need to start a thread so can be done in background
    threadIsExecuting = YES;
    [controller displayParams];
    if (tempTrace != nil) 
      [tempTrace release];
    tempTrace = [dataList copy];
    [self fitInThread];
        break;
  default:
    break;
  }
  return [super apply];
}

- (void)fitInThread
{
  //this method will be called from a top level execution thread
  //the 'target' object should also be running in this same thread
   
  if(self == nil) return;
  
  threadIsExecuting = YES;
  
  [NSThread detachNewThreadSelector:@selector(runFitLoop:)
                           toTarget:self
                         withObject:self];
}

- (void) runFitLoop:(id)myObj
{
  //called by detachNewThreadSelector:
  //this method will be executing in a separate thread (no-appkit)
  NSAutoreleasePool     *pool =[[NSAutoreleasePool alloc] init];
	
  threadIsExecuting = YES;
  [myObj peakView:tempTrace :YES];
  threadIsExecuting = NO;
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];//sleep for a sec
	[pool release];
}

- (void) peakView:(Trace *)ourData :(BOOL)integrate
{	
		NewScriptCacheEntry	*myCache;
	
		[self findPeaks:ourData :integrate :peakFile :fitFile];
		if (threadIsExecuting) {
			myCache = [script currentCache];
			if (myCache != nil) {
				[myCache setLadder:(([peakLadder count] > 0) ? peakLadder: nil)];
				[myCache setSequence:(([seqList seqLength] > 0) ? seqList: nil)];
				[myCache setAlnSequence:(([alignSeqList count] > 0) ? alignSeqList: nil)];
				[myCache setPeakList:(([peakStuff length] > 0) ? peakStuff: nil)];
				[self clearMyPointers];
				[controller fitDone];
				[controller displayParams];
				threadIsExecuting = NO;
			}
		}
		else {
			[self setLadder:(([peakLadder count] > 0) ? peakLadder: nil)];
			[self setBaseList:(([seqList seqLength] > 0) ? seqList: nil)];
			[self setAlnBaseList:(([alignSeqList count] > 0) ? alignSeqList: nil)];
			[self setPeakList:(([peakStuff length] > 0) ? peakStuff: nil)];		
			[self clearMyPointers];
		}
}

- (void)swapChannels:(Trace *)channelData
/*- (void)swapChannels:(int)From :(int)To*/
{
	int			i, numPoints;
	float		*dataArray=NULL;
  float   *dataArray1=NULL;
  float   *dataArray2=NULL;
  float   *dataArray3=NULL;
	
  if (channelData == nil) return;
	numPoints = [channelData length];
	dataArray = (float *)calloc(numPoints, sizeof(float));
  dataArray1 = (float *)calloc(numPoints, sizeof(float));
	dataArray2 = (float *)calloc(numPoints, sizeof(float));
	dataArray3 = (float *)calloc(numPoints, sizeof(float));
  for (i=0; i < numPoints; i++) {
    dataArray[i] = [channelData sampleAtIndex:i channel:chanLoc[0]/*From*/];
    dataArray1[i] = [channelData sampleAtIndex:i channel:chanLoc[1]/*To*/];
    dataArray2[i] = [channelData sampleAtIndex:i channel:chanLoc[2]];
    dataArray3[i] = [channelData sampleAtIndex:i channel:chanLoc[3]];
  }
  for (i=0; i < numPoints; i++) {
    [channelData setSample:dataArray[i] atIndex:i channel:0/*To*/];
    [channelData setSample:dataArray1[i] atIndex:i channel:1/*From*/];
    [channelData setSample:dataArray2[i] atIndex:i channel:2];
    [channelData setSample:dataArray3[i] atIndex:i channel:3];
  }
  free(dataArray);
  free(dataArray1);
  free(dataArray2);
  free(dataArray3);
}

-(void)initializeData:(SPECTRA *)sp :(int)channel :(Trace *)ourData
{
	Trace *channelData = ourData;
	int		i, numPoints;
	
	numPoints = [channelData length];
	sp->data = (float *)calloc(numPoints, sizeof(float));
	sp->maxidx = (int *)calloc(numPoints, sizeof(int));
	sp->fitted = (float *)calloc(numPoints, sizeof(float));
  sp->score = (float *)calloc(numPoints, sizeof(float));
  sp->peakPos = (PEAKPOS *)calloc(3000, sizeof(PEAKPOS));

	for (i = 0; i< numPoints; i++)
	{	
		sp->data[i] = [channelData sampleAtIndex:i channel:channel];
		sp->fitted[i] = 0.0;
    sp->score[i] = 0.0;
		sp->maxidx[i] = kNoPeak;
	}
	sp->mpcnt = 0;
//	sp->maxval = 0.0;
	sp->peakcnt = 0;
	sp->firstidx = 1;
	sp->lastidx = numPoints;
}
- (void) clearMyPointers
{
	if (peakStuff != nil) {
		[peakStuff release];
		peakStuff = nil;
	}
	if (peakLadder != nil) {
		[peakLadder release];
		peakLadder = nil;
	}
	if (seqList != nil) {
		[seqList release];
		seqList = nil;
	}
	if (alignSeqList != nil) {
		[alignSeqList release];
		alignSeqList = nil;
	}
}
- (void) initializePeaks
{
	[self clearMyPointers];
	peakStuff = [[AlignedPeaks alloc] init];
	peakLadder = [[EventLadder alloc] init];
	[peakLadder setTrace:nil];
	seqList = [[Sequence alloc] init];
	alignSeqList = [[Sequence alloc] init];
}

/*new alignment routine, smv*/

-(char) convitoa:(int) value 
{
	char ch;
	
	ch = '0';
	switch (value) {
		case 0:
			ch = '0';
			break;
		case 1:
			ch = '1';
			break;
		case 2:
			ch = '2';
			break;
		case 3:
			ch = '3';
			break;
		case 4:
			ch = '4';
			break;
		case 5:
			ch = '5';
			break;
		case 6:
			ch = '6';
			break;
		case 7:
			ch = '7';
			break;
		case 8:
			ch = '8';
			break;
		case 9:
			ch = '9';
			break;
	}
	return ch;
}

-(void) setupSequence:(char *)seq1 :(char *)seq2 :(int)start1 :(int)lenA	:(SPECTRA *)sp
//This routine correctly assigns the alignment positions to the peak positions
{
	int		i, j, m, look, count;
	int		pos, incr;
	BOOL	noinc;
	Base	*tempBase;
	
	j = 0; m=start1;
	//set offset, displayed in data view window
	[seqList setbackForwards:TRUE];
	[seqList setOffset:len-start1+(seqstartnum-1)];
	pos=sp->peakPos[0].pos;
	noinc=TRUE;
	incr = 0;
	for (i = lenA-1; (i >= 0) && (j < sp->peakcnt) && (m < ([revSequence seqLength]-1)); i--) {
		//count number of consecutive gaps.  Rudamentary interpolation to make room for the gaps since they are non-existant peaks
		if ((seq2[i] == '_') && noinc) {
			look = i; count = 0;
			while (seq2[look] == '_') {
				count++;
				look--;
			}
			incr = (count == 1) ? (sp->peakPos[j+1].pos - sp->peakPos[j].pos)/2 : (sp->peakPos[j+1].pos - sp->peakPos[j].pos-2)/count;
			noinc = FALSE;
			pos =	pos+incr;
		}
		else if ((seq2[i] == '_') && !noinc) {
			pos = pos + incr;
		}
		else {
			pos = sp->peakPos[j].pos;
			noinc=TRUE;
			if (seq2[i] != '_') {  
				//here is where the 1 nucleotide offset is done, sequencing lane is 1 nucleotide longer then reagent so we shift
				sp->peakPos[j].seqnum = len-(m+1)+seqstartnum-1;
				sp->peakPos[j].nt = [revSequence charBaseAt:(m+1)];
			}
			j++;
		}
		tempBase = [[Base alloc] init];
		if (seq1[i] == '_')
			[tempBase setBase:'+'];
		else {
			[tempBase setBase:[revSequence charBaseAt:m]];
		}
		[tempBase setConf:(char)255];
		[tempBase setLocation:pos];
		[seqList addBase:tempBase];   //true sequence
		[tempBase release];
		if ((seq2[i] != 'N') && (seq2[i] != 'X')) { //seq2
			tempBase = [[Base alloc] init];
			if (seq2[i] == '_')
				[tempBase setBase:'+'];
			else {
				[tempBase setBase:seq2[i]];
			}
			[tempBase setLocation:pos];
			[tempBase setConf:(char)255];
			[alignSeqList addBase:tempBase];  //linked-aligned sequence
			[tempBase release];
		}
		else {
			if (seq2[i] == 'X') {
				if (([revSequence charBaseAt:m] == nt[0]) || ([revSequence charBaseAt:m] == nt[1])) {
					tempBase = [[Base alloc] init];
					[tempBase setBase:[revSequence charBaseAt:m]];	
					[tempBase setLocation:pos];
					[tempBase setConf:(char)255];
					[alignSeqList addBase:tempBase];  //linked-aligned sequence
					[tempBase release];					
				}
			}			
		}
		if (seq1[i] != '_') {
			m++;		
		}
	}
}

-(int) localAlign:(SPECTRA*)sp
{
//overlap alignment, global with overhanging ends
//sequence 1 must be the original RNA sequence
//sequence 2 must be the derived sequence from the trace data
//assumes sequence starts at index 1!
	int		i, j, m, p, q;
	char  *seq2;
	char	*align1, *out1, *mark;
	char	*align2, *out2, *num, *num2, *num3;
	int		starti, len1, len2, lenAlign;
	
	//allocate memory
	len2 = sp->peakcnt;
	seq2 = (char *)calloc((sp->peakcnt+2), sizeof(char));
	GetSeq(sp,seq2);
	
	len1 = [revSequence seqLength];
	align1 = (char *)malloc((len1+1)*sizeof(char));
	align2 = (char *)malloc((len1+1)*sizeof(char));
	
	if ([self debugmode]) {
		out1 = (char *)malloc((len1+1)*sizeof(char));
		out2 = (char *)malloc((len1+1)*sizeof(char));
		mark = (char *)malloc((len1+1)*sizeof(char));
		num = (char *)malloc((len1+1)*sizeof(char));
		num2 = (char *)malloc((len1+1)*sizeof(char));
		num3 = (char *)malloc((len1+1)*sizeof(char));
	}
	
	//align
	starti = [revSequence alignOverlapRNA:seq2 :len2 :nt[0] :nt[1] :align1 :align2 :&lenAlign];
	
	//debug; print alignment
	if ([self debugmode]) {
		align1[lenAlign]='\0';
		align2[lenAlign]='\0';
		NSLog(@"%@",[NSString stringWithCString:align1]);
		NSLog(@"%@",[NSString stringWithCString:align2]);
		j = 0; 
		q = len1-starti;
		p = q/100;
		m = (q-p*100)/10;
		for (i = lenAlign-1; i >=0; i--) {
			out1[j] = align1[i];
			out2[j] = align2[i];
			if (out1[j] == out2[j])
				mark[j] = '|';
			else
				mark[j] = ' ';
			num[j] = [self convitoa:(q%10)];
			if ((q%10) == 0) {
				num2[j] = [self convitoa:m];
				m = ((m == 0) ? 9 : m-1);
			}
			else
				num2[j] = ' ';
			if ((q%100) == 0) {
				num3[j] = [self convitoa:p];
				p--;
			}
			else
				num3[j] = ' ';
			j++; q--;
		}
		mark[j] = out1[j] = out2[j] = num[j] = num2[j] = num3[j] = '\0';
		NSLog(@"%d\n%s\n%s\n%s\n%s\n%s\n%s\n",lenAlign,out1,mark,out2,num,num2,num3);		
	}
	
	//attribute alignment to peaks
	[self setupSequence:align1 :align2 :starti :lenAlign :sp];
	
	//free memory
	free(align1);
	free(align2);
	if ([self debugmode]) {
		free(out1);
		free(out2);
		free(mark);
		free(num);
		free(num2);
		free(num3);
	}		
	
	return starti;
}

- (void) PeakLinkWithSeqTrace:(SPECTRA *)sp1 bg:(SPECTRA *)sp2 nt1:(SPECTRA *)ddnt nt2:(SPECTRA *)ddnt2 :(char *)seq :(int)alignstart :(int)seqlen :(int)seqstart
{
	int i;
	int offset;
	int pos1,pos2;
	int d1,d2;
	char c2,c3;
	Peak *linkings;
	Base			*tempBase;
	
	fprintf(stderr,"%s:# THE RELATIVE ddNT LANE OFFSET OF ONE PEAK COMPARED TO reagent LANE HAS *NOT* BEEN CORRECTED\n",remark);
	[seqList setbackForwards:TRUE];  //display numbering in reverse
	[seqList setOffset:(seqlen-alignstart+seqstart)]; //start display of base numbering at correct position
	for (i = 0; i< sp1->peakcnt; i++)
	{
		pos2 = d2 = offset = 0;
		pos1 = sp1->peakPos[i].pos;
		if (i != 0)
      d1 = pos1 - sp1->peakPos[i-1].pos;
    else
      d1 = -1;
		if (sp1->peakLink[i] != -1)
		{
			pos2 = sp2->peakPos[sp1->peakLink[i]].pos;
			offset = pos2 - sp1->peakPos[i].pos;
			if ((i!=0) && (sp1->peakLink[i-1] != -1))
				d2 = pos2 - sp2->peakPos[sp1->peakLink[i-1]].pos;
			else d2 = -1;
		}
		if (sp1->peakPos[i].nt != 'N') 
			c2 = sp1->peakPos[i].nt;
		else
			c2 = ' ';
	//	sp1->peakPos[i].seqnum = ((seqlen-i)-alignstart+seqstart);
	//	sp1->peakPos[i].nt = seq[i+alignstart];
    if ((0 <= (i + alignstart)) && ((i+alignstart) < seqlen))
      c3 = seq[i+alignstart];
    else
      c3 = ' ';
		fprintf(stderr,"INFO  :%5d %c %c | peak %3d (%4d) QC=%1d delta=%2d  --> ",((seqlen-i)-alignstart+seqstart),c3,c2,i,pos1,sp1->maxidx[pos1],d1);
		linkings = [[Peak alloc] init];
		[linkings addPosition:pos1];
		if (c3 != ' ') {
      tempBase = [[Base alloc] init];
      [tempBase setBase:c3];
      [tempBase setConf:(char)127];
      [tempBase setLocation:pos1];
      [seqList addBase:tempBase];
      [tempBase release];
    }
		if (c2 != ' ') {
			tempBase = [[Base alloc] init];
			[tempBase setBase:c2];
			[tempBase setLocation:pos1];
			[tempBase setConf:(char)127];
			[alignSeqList addBase:tempBase];
			[tempBase release];
		}
		
		if (sp1->peakLink[i] != -1)
		{	
			int j;
			int printed = 0;
			int printed2 = 0;
			char nt1 = 'N';
			char nt2 = 'N';
			fprintf(stderr,"%3d (%4d) QC=%1d delta=%2d  | offset = %+2d",sp1->peakLink[i],pos2,sp2->maxidx[pos2],d2,offset);
			[linkings addPosition:pos2];
			for (j = 0; j< ddnt->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt->peakPos[j].pos;
					delta2 = pos2-ddnt->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						fprintf(stderr,"    %c at pos %4d",ddnt->peakPos[j].nt,ddnt->peakPos[j].pos);
						if (ddnt->peakPos[j].nt == 'N')
              [linkings addPosition:-ddnt->peakPos[j].pos];
						else
              [linkings addPosition:ddnt->peakPos[j].pos];
						nt1 = ddnt->peakPos[j].nt;
						printed = 1;
						break;
					}
			}
			if (printed == 0) {
				fprintf(stderr,"                 ");
				[linkings addPosition:0];
			}
			for (j = 0; j< ddnt2->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt2->peakPos[j].pos;
					delta2 = pos2-ddnt2->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						fprintf(stderr,"    %c at pos %4d",ddnt2->peakPos[j].nt,ddnt2->peakPos[j].pos);
						if (ddnt2->peakPos[j].nt == 'N')
              [linkings addPosition:-ddnt2->peakPos[j].pos];
						else
              [linkings addPosition:ddnt2->peakPos[j].pos];
						nt2 = ddnt2->peakPos[j].nt;
						printed2 = 1;
						break;
					}
			}
			if (printed2 == 0) {
				fprintf(stderr,"                 ");
				[linkings addPosition:0];
			}
			if (printed || printed2)
			{
				if ((nt1 != 'N') && (nt2 == 'N'))
					fprintf (stderr,"  %c",nt1);
				else if ((nt2 != 'N') && (nt1 == 'N'))
					fprintf (stderr,"  %c",nt2);
				//else
				//	printf("  N");
			}
		}
		else {
			[linkings addPosition:0];
			[linkings addPosition:0];
			[linkings addPosition:0];
		}
		fprintf(stderr,"\n");
		[peakStuff addAlnPeak:linkings];
		[linkings release];
		if (sp1->peakLink[i] == -1)
		{
	//		PlotMissingPeak(sp2, sp2->peakPos[sp1->peakLink[i-1]].pos-15, sp2->peakPos[sp1->peakLink[i-1]].pos + 35,80);
		}
	}
} /* PrintPeakLinkWithSeqTrace */

-(int) findExtraPeak:(int)start :(int)stop :(float*)thedata :(BOOL)forward
{
	int i, value;
	
	value = 0;
	i = start;
	if (!forward) {
		while ((value == 0) && (i >  stop)) {
			if ((thedata[i] > thedata[i-1]) &&
					 (thedata[i] > thedata[i-2]) &&
					 (thedata[i] > thedata[i-3]) &&
					 (thedata[i] > thedata[i+1]) &&
					 (thedata[i] > thedata[i+2]) &&
					 (thedata[i] > thedata[i+3]))
				value = i;
			else
				i--;
		}
	}
	else {
		while ((value == 0) && (i < stop)) {
			if ((thedata[i] > thedata[i-1]) &&
					(thedata[i] > thedata[i-2]) &&
					(thedata[i] > thedata[i-3]) &&
					(thedata[i] > thedata[i+1]) &&
					(thedata[i] > thedata[i+2]) &&
					(thedata[i] > thedata[i+3]))
				value = i;
			else
				i++;
		}
	}
	return value;
}

- (void) IntegrateFirstLast:(SPECTRA *)nmia bg:(SPECTRA*)bg first:(int)firstpeak last:(int)lastpeak :(Trace *)ourData
{
	float						*nmiaData, *bgData;
	float						testwidth, testval;
	int							testpos;
	
	nmiaData = [ourData sampleArrayAtChannel:chanLoc[0]];
	bgData = [ourData sampleArrayAtChannel:chanLoc[1]];
	//first peak
	testwidth = nmia->peakPos[firstpeak+1].width;
	testpos = [self findExtraPeak:nmia->peakPos[firstpeak].pos-2 :0 :nmiaData :NO];
	testval = [ourData sampleAtIndex:testpos channel:chanLoc[0]];
	NewPeakFit(firstpeak,firstpeak,firstpeak+1,nmia,0.4*testwidth,testwidth+0.5*testwidth,0.05,testpos,testval);
	MakeGaussianPeak(nmia->fitted,nmia->peakPos[firstpeak].width,nmia->peakPos[firstpeak].area,nmia->peakPos[firstpeak].pos,testpos,nmia->peakPos[firstpeak+1].pos);
	testwidth = bg->peakPos[firstpeak+1].width;
	testpos = [self findExtraPeak:bg->peakPos[firstpeak].pos-2 :0 :bgData :NO];
	testval = [ourData sampleAtIndex:testpos channel:chanLoc[1]];
	NewPeakFit(firstpeak,firstpeak,firstpeak+1,bg,0.4*testwidth,testwidth+0.5*testwidth,0.05,testpos,testval);
	MakeGaussianPeak(bg->fitted,bg->peakPos[firstpeak].width,bg->peakPos[firstpeak].area,bg->peakPos[firstpeak].pos,testpos,bg->peakPos[firstpeak+1].pos);
	//last peak
	testwidth = nmia->peakPos[lastpeak-1].width;
	testpos = [self findExtraPeak:nmia->peakPos[lastpeak].pos+2 :[ourData length] :nmiaData :YES];
	testval = [ourData sampleAtIndex:testpos channel:chanLoc[0]];	
	NewPeakFit(lastpeak-1,lastpeak,lastpeak,nmia,0.4*testwidth,testwidth+0.5*testwidth,0.05,testpos,testval);
	MakeGaussianPeak(nmia->fitted,nmia->peakPos[lastpeak].width,nmia->peakPos[lastpeak].area,nmia->peakPos[lastpeak].pos,nmia->peakPos[lastpeak-1].pos,testpos);
	testwidth = bg->peakPos[lastpeak-1].width;
	testpos = [self findExtraPeak:bg->peakPos[lastpeak].pos+2 :[ourData length] :bgData :YES];
	testval = [ourData sampleAtIndex:testpos channel:chanLoc[1]];	
	NewPeakFit(lastpeak-1,lastpeak,lastpeak,bg,0.4*testwidth,testwidth+0.5*testwidth,0.05,testpos,testval);
	MakeGaussianPeak(bg->fitted,bg->peakPos[lastpeak].width,bg->peakPos[lastpeak].area,bg->peakPos[lastpeak].pos,bg->peakPos[lastpeak-1].pos,testpos);
}

- (void) IntegratedPeaks:(SPECTRA *)nmia bg:(SPECTRA *)bg first:(int)firstnmia last:(int)lastnmia :(NSString *)saveFile :(NSString *)saveFit
{
	int i,j, first, last;
	float diff;
	FILE *of;
  Gaussian *ladderEntry;
  Gaussian *bgLadderEntry;
	NSString *newFile;
	
	of = fopen([saveFile fileSystemRepresentation],"w");
	if (!of)
	{
		NSLog(@"WARNING: cannot write to file.  Writing to home directory.\n");
		newFile = [NSHomeDirectory() stringByAppendingPathComponent:[saveFile lastPathComponent]];
		of = fopen([newFile fileSystemRepresentation],"w");
	}
	printf("%s:# -- results of integration ---\n",remark);
	printf("%s:# THE RELATIVE ddNT LANE OFFSET OF ONE PEAK COMPARED TO reagent LANE HAS BEEN CORRECTED\n",remark);
	printf("RESULT:seqnum seq   RX.pos   RX.sigma   RX.area   RX.rms BG.pos BG.sigma BG.area BG.rms   (RX.area-BG.area)\n");
	if (of)
		fprintf(of,"seqnum\tseq\tRX.pos\tRX.sigma\tRX.area\tRX.rms\tBG.pos\tBG.sigma\tBG.area\tBG.rms\t(RX.area-BG.area)\n");
	for (i = lastnmia; i >= firstnmia; i--)
	{
		if (nmia->peakLink[i] != -1)
		{
			j = nmia->peakLink[i];
			diff = nmia->peakPos[i].area - bg->peakPos[j].area;
      ladderEntry = [Gaussian GaussianWithWidth:nmia->peakPos[i].width 
                                          scale:(nmia->peakPos[i].area/sqrt(2*3.14159265*nmia->peakPos[i].width)) 
                                         center:nmia->peakPos[i].pos];
      [ladderEntry setChannel:0];
      [peakLadder addEntry:ladderEntry];
      bgLadderEntry = [Gaussian GaussianWithWidth:bg->peakPos[j].width 
                                            scale:(bg->peakPos[j].area/sqrt(2*3.14159265*bg->peakPos[j].width))
                                           center:bg->peakPos[j].pos];
      [bgLadderEntry setChannel:1];
      [peakLadder addEntry:bgLadderEntry];
			printf("RESULT:%5d   %c   %4d %8.2f %10.1f %10.1f    %4d %6.2f %10.1f %10.1f %10.1f\n",
					nmia->peakPos[i].seqnum,nmia->peakPos[i].nt,
					nmia->peakPos[i].pos,nmia->peakPos[i].width,nmia->peakPos[i].area,nmia->peakPos[i].score,
					bg->peakPos[j].pos,bg->peakPos[j].width,bg->peakPos[j].area,bg->peakPos[j].score,
					diff);
			if (of) fprintf(of,"%5d\t%c\t%4d\t%8.2f\t%10.1f\t%10.1f\t%4d\t%6.2f\t%10.1f\t%10.1f\t%10.1f\n",
											nmia->peakPos[i].seqnum,nmia->peakPos[i].nt,
											nmia->peakPos[i].pos,nmia->peakPos[i].width,nmia->peakPos[i].area,nmia->peakPos[i].score,
											bg->peakPos[j].pos,bg->peakPos[j].width,bg->peakPos[j].area,bg->peakPos[j].score,
											diff);
			
		}
	}	
	if (of) 
		fclose(of);
  of = fopen([saveFit fileSystemRepresentation],"w");
  if (!of)
  {
			NSLog(@"cannot open fit file\n");
			newFile = [NSHomeDirectory() stringByAppendingPathComponent:[saveFit lastPathComponent]];
			of = fopen([newFile fileSystemRepresentation],"w");
  }
	if (of) {
		fprintf(of,"index\treagent_data\treagent_fit\tpercentdev\tbackground_data\tbackground_fit\n");
		first = nmia->peakPos[firstnmia].pos;
		last = nmia->peakPos[lastnmia].pos;
		for (i=first; i<=last; i++)
		{
			fprintf(of,"%6d\t%9.1f\t%9.1f\t%9.1f\t%9.1f\t%9.1f\n",i,nmia->data[i],nmia->fitted[i],nmia->score[i],bg->data[i],bg->fitted[i]);		
		}
		fclose(of);		
	}
} /* PrintIntegratedPeaks */

-(void) findPeaks:(Trace *)ourData :(BOOL)integrate :(NSString *)saveFile :(NSString *)saveFit
{
  SPECTRA nmia, background, ddnt, ddnt2;
	float		median;
	//float		peakwidthmedian;
	char		*peakseq=NULL;
  char		*maskedseq=NULL;
  int			beststart;
	int			i, error, smoothing=1;
	int largestpeakmedianinterval; // will be used to determine how far we should look for  rx and bg peaks misalignment
  NSAutoreleasePool   *pool;
  
	if ([self debugmode]) verbose = 2;
  else verbose = 0;
	if (ourData == nil) return;
	if ((revSequence == nil) && (seqPath != nil)) {
		error = [self setSequence];
		if (error != 0) {
			NSLog(@"Check sequence path name in Setup panel");
			return;
		}
	}
	else if (seqPath == nil) {
		NSLog(@"Check sequence path name in Setup panel");
		return;
	}
  pool = [[NSAutoreleasePool alloc] init];
    
  [self initializeData:&nmia :chanLoc[0] :ourData];
	[self initializeData:&background :chanLoc[1] :ourData];
	[self initializeData:&ddnt :chanLoc[2] :ourData];
	if ([ourData numChannels] >3)
		[self initializeData:&ddnt2 :chanLoc[3] :ourData];
		
	[self initializePeaks];

	SetSpectraBoundaries(&nmia,&background,&ddnt,&ddnt2);
	if (rangeBegin != -1)
	{
		printf("%s:Automatic start detection overriden by option -first %d; will start working from line %d\n",remark,rangeBegin,rangeBegin);
		nmia.firstidx = rangeBegin-[ourData deleteOffset];
		background.firstidx = rangeBegin-[ourData deleteOffset];
		ddnt.firstidx = rangeBegin-[ourData deleteOffset];
		ddnt2.firstidx = rangeBegin-[ourData deleteOffset];
	}
	
	if (rangeEnd != -1)
	{
		if ((rangeEnd-[ourData deleteOffset]) >= [ourData length]) { rangeEnd = [ourData length]-1; }
		printf("%s:Automatic end detection overriden by option -last %d; will stop working after line %d\n",remark,rangeEnd,rangeEnd);
		nmia.lastidx = rangeEnd-[ourData deleteOffset];
		background.lastidx = rangeEnd-[ourData deleteOffset];
		ddnt.lastidx = rangeEnd-[ourData deleteOffset];
		ddnt2.lastidx = rangeEnd-[ourData deleteOffset];
	}
	printf("%s:Will consider %d rows for integration\n",remark,(nmia.lastidx-nmia.firstidx+1));
	printf("%s:Analyzing reagent (rx) lane\n",remark);
	if (smoothing)
	{
		printf("%s:Smoothing rx lane from %d to %d\n",remark,nmia.firstidx, nmia.lastidx);
		SmoothSpectra(&nmia,nmia.firstidx, nmia.lastidx,2);
	}
	largestpeakmedianinterval = AnalyzeSpectra(&nmia,0);
  GatherPeaksPosition(&nmia);
  printf("%s:Analyzing background (bg) lane\n",remark);
	if (smoothing)
	{
		printf("%s:Smoothing bg lane from %d to %d\n",remark,background.firstidx, background.lastidx);
		SmoothSpectra(&background,background.firstidx, background.lastidx,2);
	}
	AnalyzeSpectra(&background,0);
	GatherPeaksPosition(&background);
  
	printf("%s:Synchronizing reagent and background lanes\n",remark);
	ResetPeakLink(&nmia);
	ResetPeakLink(&background);
	largestpeakmedianinterval /= 2;
	for (i = 0; i<=largestpeakmedianinterval; i++) /* max was originally 4 */
	{
		int m0;
		m0 = PeakLink(&nmia,&background,i);
		if (verbose > 0)
			printf("%s:detected %3d rx<->bg peaks shifted by %3d\n",remark,m0,i);
		if (i!=0)
		{
			m0 = PeakLink(&nmia,&background,-i);
			if (verbose > 0)
				printf("%s:detected %3d rx<->bg peaks shifted by %3d\n",remark,m0,-i);
		}
	}
  /* this refinement is causing problms to ABI peaks which are much larger. Special problems if peaks not well synchronized 
    probably due to lack of sync of peaks if their summit is too distant. Needs to change this? 
    added option for no refinement */
	if (refinepeaks)
	{
		HandleMissingPeakLink(&nmia,&background);  
		AutoAddDeletePeaks(&nmia,&background);   
		RefinePeakPosition(&nmia); 
    /* RefinePeakPosition(&background);  maybe should also refine background peak position? to try... 
			tried but does not seem to improve probably worse - drop it. */
	}
  if (([delReagent count] > 0) || ([addReagent count] > 0) || ([delnReagent count] > 0) || ([addnReagent count] > 0))
		printf("%s:Adding/Deleting user provided peaks\n",remark);

  for (i=0; i< [delReagent count]; i++)
	{
		DeletePeak(&nmia,[[delReagent objectAtIndex:i] intValue]-[ourData deleteOffset],"rx");
	}
	if ([delReagent count] > 0)
	{
		GatherPeaksPosition(&nmia);
		//while(RefineAddedPeaksPosition(&nmia));
	}
	for (i=0; i< [addReagent count]; i++)
	{
		AddPeak(&nmia,[[addReagent objectAtIndex:i] intValue]-[ourData deleteOffset],"rx");
	}
	GatherPeaksPosition(&nmia);
	if (smoothing)
		UnsmoothSpectra(&nmia,nmia.firstidx, nmia.lastidx);
	printf("%s:Reagent final peakCount = %d\n",remark,nmia.peakcnt);
  
  for (i=0; i< [delnReagent count]; i++)
	{
		DeletePeak(&background,[[delnReagent objectAtIndex:i] intValue]-[ourData deleteOffset],"bg");
	}
	if ([delnReagent count] > 0)
	{
		GatherPeaksPosition(&background);
		//while(RefineAddedPeaksPosition(&background));
	}
	for (i=0; i< [addnReagent count]; i++)
	{
		AddPeak(&background,[[addnReagent objectAtIndex:i] intValue]-[ourData deleteOffset],"bg");
	}
	GatherPeaksPosition(&background);
  if (smoothing)
		UnsmoothSpectra(&background,background.firstidx, background.lastidx);
	printf("%s:background final peakCount = %d\n",remark,background.peakcnt);
  
	if (ntcomplement[0] != ' ')
	{
		printf("%s:Analyzing dd%c Sequencing Lane\n",remark,ntcomplement[0]);
		IdentifyBestPeaks(&ddnt,ddnt.firstidx, ddnt.lastidx,0);
		GatherPeaksPosition(&ddnt);
		for (i=0; i< [del1ddNTP count]; i++)
		{
			DeletePeak(&ddnt,([[del1ddNTP objectAtIndex:i] intValue]-[ourData deleteOffset]),"nt1");
		}
		if ([del1ddNTP count] > 0)
		{
			GatherPeaksPosition(&ddnt);
		}
		for (i=0; i< [add1ddNTP count]; i++)
		{
			AddPeak(&ddnt,([[add1ddNTP objectAtIndex:i] intValue]-[ourData deleteOffset]),"nt1");
		}
		GatherPeaksPosition(&ddnt);
		printf("%s:dd%c peakCount = %d\n",remark,ntcomplement[0],ddnt.peakcnt);
		median = ListPeakPos(&ddnt,ddnt.firstidx,ddnt.lastidx);
		IdentifyNT(&ddnt,median,nt1sensitivity,nt[0],ntcomplement[0]);
	}
	
	if (ntcomplement[1] != ' ')
	{
		printf("%s:Analyzing dd%c Sequencing Lane\n",remark,ntcomplement[1]);
		IdentifyBestPeaks(&ddnt2,ddnt2.firstidx, ddnt2.lastidx,0);
		GatherPeaksPosition(&ddnt2);
		for (i=0; i< [del2ddNTP count]; i++)
		{
			DeletePeak(&ddnt2,([[del2ddNTP objectAtIndex:i] intValue]-[ourData deleteOffset]),"nt2");
		}
		if ([del2ddNTP count] > 0)
		{
			GatherPeaksPosition(&ddnt2);
		}
		for (i=0; i< [add2ddNTP count]; i++)
		{
			AddPeak(&ddnt2,([[add2ddNTP objectAtIndex:i] intValue]-[ourData deleteOffset]),"nt2");
		}
		GatherPeaksPosition(&ddnt2);
		printf("%s:dd%c peakCount = %d\n",remark,ntcomplement[1],ddnt2.peakcnt);
		median = ListPeakPos(&ddnt2,ddnt2.firstidx,ddnt2.lastidx);
		IdentifyNT(&ddnt2,median,nt2sensitivity,nt[1],ntcomplement[1]);
	}

	printf("%s:Synchronizing reagent and background lanes using maximum shift of %d (half median peak intervall)\n",remark,largestpeakmedianinterval);
	ResetPeakLink(&nmia);
	ResetPeakLink(&background);
	for (i = 0; i<=largestpeakmedianinterval; i++) /* max was originally 4 */
	{
		int m0;
		m0 = PeakLink(&nmia,&background,i);
		if (verbose > 0)
			printf("%s:detected %3d rx<->bg peaks shifted by %3d\n",remark,m0,i);
		if (i!=0)
		{
			m0 = PeakLink(&nmia,&background,-i);
			if (verbose > 0)
				printf("%s:detected %3d rx<->bg peaks shifted by %3d\n",remark,m0,-i);
		}
	}
	HandleMissingPeakLink(&nmia,&background);
				
	AttributeNT(&nmia,&background,&ddnt,&ddnt2);
  peakseq = (char *)calloc((nmia.peakcnt+1), sizeof(char));
	GetSeq(&nmia,peakseq);
  maskedseq = (char *)calloc(len+1, sizeof(char));
	[revSequence getCStringSeqRep:maskedseq];
	
	NSLog(@"%s:Attributing Sequence to Peaks\n",remark);
	peakseq[nmia.peakcnt] = '\0';
//	maskedseq[len]='\0';
//	NSLog(@"%d\n%s\n%d\n%s\n",nmia.peakcnt,peakseq,len,maskedseq);
	//beststart = [self localAlign:maskedseq :len :peakseq :nmia.peakcnt :nt[0] :nt[1] :&nmia];
	//printf("beststart = %d\n",beststart);
	
  beststart = Align(peakseq,nmia.peakcnt,maskedseq,len);
	//printf("beststart = %d\n",beststart);
	//beststart--;
	printf("%s:------------------------------------------------------------------------------------------------\n",remark);  
	[self PeakLinkWithSeqTrace:&nmia bg:&background nt1:&ddnt nt2:&ddnt2 :maskedseq :beststart :len :(seqstartnum-1)];
  //printf("%s:------------------------------------------------------------------------------------------------\n",remark);
	if (integrate)
	{
		int firstpeak=0,lastpeak=0;
		int firstbgpeak=0,lastbgpeak=0;
		
		ResetFit(&nmia,[ourData length]);
		ResetFit(&background,[ourData length]);
		FindLongestSyncStretch(&nmia,&firstpeak,&lastpeak,&firstbgpeak,&lastbgpeak);

		if (lastbgpeak < (firstbgpeak+2))
		{
			printf("%s:Cannot identify a region matching the sequence (no integration will be performed)\n",remark);
		}
    else
		{
			SetSeqIntoNMIA(&nmia,maskedseq /*seqc*/,beststart,len,(seqstartnum-1));
			printf("%s:Integrating reagent peaks [ %3d - %3d ]\n",remark,firstpeak,lastpeak);
			IntegratePeaks(&nmia,firstpeak,lastpeak,optimize,"reagent");
      
			printf("%s:Integrating background peaks [ %3d - %3d ]\n",remark,firstbgpeak,lastbgpeak);
			IntegratePeaks(&background,firstbgpeak,lastbgpeak,optimize,"background");
			
			[self IntegrateFirstLast:&nmia bg:&background first:firstpeak last:lastpeak :ourData];
			
			//PrintIntegratedPeaks(&nmia,&background,firstpeak,lastpeak,ifn);
			[self IntegratedPeaks:&nmia bg:&background first:firstpeak last:lastpeak :saveFile :saveFit];

		}
	} // if(integrate)
  
  if (peakseq != NULL) free(peakseq);
  if (maskedseq != NULL) free(maskedseq);
	FreeSpectra(&nmia);
	FreeSpectra(&background);
	FreeSpectra(&ddnt);
	FreeSpectra(&ddnt2);
  
  [pool release];
}

/****
*
*  Store data
*
*****/
- (void)doApply:(BOOL)canApply
{
  applyOkay = canApply;
}


- (int)setSequence
{
	
  if (seqPath == nil) return NO;
	if (revSequence != nil)
		[revSequence release];
	revSequence = [[Sequence alloc] initWithContentsOfFile:seqPath];
	if ([revSequence seqLength] == 0) {
		[revSequence release];
		revSequence = nil;
    return 2;
  }
	if ((seqrangefrom != 0) || (seqrangeto != 0)) // user wants to consider only subset 
	{
		if (((seqrangeto-seqrangefrom) > [revSequence seqLength]) || (seqrangefrom > [revSequence seqLength]) || (seqrangeto > [revSequence seqLength]) ||(seqrangefrom >= seqrangeto) )
		{
			if ([self debugmode]) NSLog(@"FATAL ERROR:-seqrange specified out of range, sequence length = %u",[revSequence seqLength]);
      len = 0;
			[revSequence release];
			revSequence = nil;
			return 4; 
		}
		[revSequence partialSequenceFrom:seqrangefrom to:seqrangeto];
	}
	[revSequence reverseSequence:self];
	len = [revSequence seqLength];
	return 0;
}

- (void)setFilePath:(NSString *)filepath;
{
  if (filepath != nil) {
    if (seqPath != nil) [seqPath release];
    seqPath = [filepath copy];
  }
}

-(NSString *)getFilePath
{  
	return seqPath;
}

- (void)setChanLoc:(int *)chanloc
{
	int i;
	
	for (i=0; i<4; i++)
		chanLoc[i] = chanloc[i];
}

- (void)getChanLoc:(int *)chanloc;
{
	int i;

	for (i=0; i<4; i++)
		chanloc[i] = chanLoc[i];
}		
		
- (void)setddNTP:(char)ddNTPa :(char)ddNTPb;
{
	int	i;
	
	ntcomplement[0] = ddNTPa;
	ntcomplement[1] = ddNTPb;
	for (i = 0; i < 2; i++) {
		switch (ntcomplement[i]) {
		case 'T': nt[i] = 'A'; break;
		case 'U': nt[i] = 'A'; break;
		case 'C': nt[i] = 'G'; break;
		case 'G': nt[i] = 'C'; break;
		case 'A': nt[i] = 'U'; break;
		case ' ': nt[i] = ' '; break;
		}
	}
}

- (void)getddNTP:(char *)ddNTPa :(char *)ddNTPb
{
	ddNTPa[0] = ntcomplement[0];
	ddNTPb[0] = ntcomplement[1];
}

- (void) setViewInd:(int)xview
{
	viewInd = xview;
}

- (int) getViewInd
{
	return viewInd;
}

- (NSMutableArray *)getDelPeak:(int)channel
{
  NSMutableArray  *pArray;
  
  pArray = delReagent;
  switch (channel) {
    case 0: //+reagent
      break;
    case 1: //-reagent
      pArray = delnReagent;
      break;
    case 2: //ddntp1
      pArray = del1ddNTP;
      break;
    case 3: //ddntp2
      pArray = del2ddNTP;
      break;
  }
  return pArray;
}

-(void) addDelPeak:(NSNumber *)peak :(int)channel
{
  int i;
  BOOL found = NO;
  
  switch (channel) {
    case 0: //+reagent
      for (i=0; i < [delReagent count]; i++)
        if ([peak intValue] == [[delReagent objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
      if (!found)
        [delReagent addObject:peak];
      break;
    case 1: //-reagent
      for (i=0; i<[delnReagent count];i++) 
        if ([peak intValue] == [[delnReagent objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
      if (!found)
        [delnReagent addObject:peak];
      break;
    case 2: //ddntp1
      for (i=0; i<[del1ddNTP count];i++) 
        if ([peak intValue] == [[del1ddNTP objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
      if (!found)
        [del1ddNTP addObject:peak];
      break;
    case 3: //ddntp2
      for (i=0; i<[del2ddNTP count];i++) 
        if ([peak intValue] == [[del2ddNTP objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
      if (!found)
        [del2ddNTP addObject:peak];
      break;
  }
}

-(void) remDelPeak:(int)index anObject:theObject :(int)channel
{
	int	value;
  
  switch (channel) {
    case 0: //+reagent
      value = [theObject intValue];
      if (value == 0) {
        if ([delReagent count] > index)
          [delReagent removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([delReagent count] > index)
            [delReagent replaceObjectAtIndex:index withObject:theObject];
        }
        break;
    case 1: //-reagent
      value = [theObject intValue];
      if (value == 0) {
        if ([delnReagent count] > index)
          [delnReagent removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([delnReagent count] > index)
            [delnReagent replaceObjectAtIndex:index withObject:theObject];
        }	
        break;
    case 2: //ddntp1
      value = [theObject intValue];
      if (value == 0) {
        if ([del1ddNTP count] > index)
          [del1ddNTP removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([del1ddNTP count] > index)
            [del1ddNTP replaceObjectAtIndex:index withObject:theObject];
        }	
        break;
    case 3: //ddntp2
      value = [theObject intValue];
      if (value == 0) {
        if ([del2ddNTP count] > index)
          [del2ddNTP removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([del2ddNTP count] > index)
            [del2ddNTP replaceObjectAtIndex:index withObject:theObject];
        }	
        break;
  }
	
}

- (NSMutableArray *)getAddPeak:(int)channel
{
  NSMutableArray  *pArray;
  
  pArray = addReagent;
  switch (channel) {
    case 0: //+reagent
      break;
    case 1: //-reagent
      pArray = addnReagent;
      break;
    case 2: //ddntp1
      pArray = add1ddNTP;
      break;
    case 3: //ddntp2
      pArray = add2ddNTP;
      break;
  }
  return pArray;
}

-(void) addAddPeak:(NSNumber *)peak :(int)channel
{
  int i;
  BOOL found = NO;
  
  switch (channel) {
    case 0: //+reagent
      for (i=0; i<[addReagent count]; i++)
        if ([peak intValue] == [[addReagent objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
          if (!found)
            [addReagent addObject:peak];
      break;
    case 1: //-reagent
      for (i=0; i<[addnReagent count]; i++)
        if ([peak intValue] == [[addnReagent objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
          if (!found)
            [addnReagent addObject:peak];
      break;
    case 2: //ddntp1
      for (i=0; i<[add1ddNTP count]; i++)
        if ([peak intValue] == [[add1ddNTP objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
          if (!found)
            [add1ddNTP addObject:peak];
      break;
    case 3: //ddntp2
      for (i=0; i<[add2ddNTP count]; i++)
        if ([peak intValue] == [[add2ddNTP objectAtIndex:i] intValue]) {
          found = YES;
          break;
        }
          if (!found)
            [add2ddNTP addObject:peak];
      break;
  }
}

-(void) remAddPeak:(int)index anObject:theObject :(int)channel
{
	int	value;
  
  switch (channel) {
    case 0: //+reagent
      value = [theObject intValue];
      if (value == 0) {
        if ([addReagent count] > index)
          [addReagent removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([addReagent count] > index)
            [addReagent replaceObjectAtIndex:index withObject:theObject];
        }
        break;
    case 1: //-reagent
      value = [theObject intValue];
      if (value == 0) {
        if ([addnReagent count] > index)
          [addnReagent removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([addnReagent count] > index)
            [addnReagent replaceObjectAtIndex:index withObject:theObject];
        }
        break;
    case 2: //ddntp1
      value = [theObject intValue];
      if (value == 0) {
        if ([add1ddNTP count] > index)
          [add1ddNTP removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([add1ddNTP count] > index)
            [add1ddNTP replaceObjectAtIndex:index withObject:theObject];
        }
        break;
    case 3: //ddntp2
      value = [theObject intValue];
      if (value == 0) {
        if ([add2ddNTP count] > index)
          [add2ddNTP removeObjectAtIndex:index];
      }
        else if (value > 0) {
          if ([add2ddNTP count] > index)
            [add2ddNTP replaceObjectAtIndex:index withObject:theObject];
        }
        break;
  }
	
}

- (void)getRange:(int *)xBegin :(int *)xEnd :(int *)seqFrom :(int *)seqTo :(int *)seqStNo
{
	*xBegin = rangeBegin;
	*xEnd = rangeEnd;
	*seqFrom = seqrangefrom;
  *seqTo = seqrangeto;
  *seqStNo = seqstartnum;
}

- (void)setRange:(int)xBegin :(int)xEnd
{
	if ((xBegin != xEnd) || (xBegin == -1 && xEnd == -1)) {
		rangeBegin = xBegin;
		rangeEnd = xEnd;
	}
}

- (void)setSeqRange:(int)sBegin :(int)sEnd
{
  if ((sBegin != sEnd) || ((sBegin == 0) && (sBegin == 0))) {
    seqrangefrom = sBegin;
    seqrangeto = sEnd;
  }
}

- (void)setSeqNo:(int)seqno
{
	seqstartnum = seqno;
}

- (void)getNTSens:(float *)NTSens1 :(float *)NTSens2
{
	*NTSens1 = nt1sensitivity;
	*NTSens2 = nt2sensitivity;
}
- (void)setNTSens:(float)NTSens1 :(float)NTSens2
{
	nt1sensitivity = NTSens1;
	nt2sensitivity = NTSens2;
}

-(void)setOptimizeFlag:(int)flag
{
  optimize = flag;
}

-(int) getOptimizeFlag
{
  return optimize;
}

-(void)savePeakFile:(NSString *)saveFile
{
  if (saveFile != nil) {
    if (peakFile != nil) [peakFile release];
    peakFile = [saveFile copy];
  }
}
-(NSString *)getPeakFile
{
  return peakFile;
}
-(void)saveFitFile:(NSString *)saveFile
{
  if (saveFile != nil) {
    if (fitFile != nil) [fitFile release];
    fitFile = [saveFile copy];
  }
}
-(NSString *)getFitFile
{
  return fitFile;
}
-(void)setRefine:(int)ref
{
  refinepeaks = ref;
}

-(int)getRefine
{
  return refinepeaks;
}

- (BOOL)fitOngoing
{
  return threadIsExecuting;
}

- (void)fitDone
//needed so ui controller can turn off barber poll
{
	threadIsExecuting = NO;
}

/***
*
* coder
*
***/

		
//- (id)initWithCoder:(NSCoder *)aDecoder
//{
  //[super initWithCoder:aDecoder];
  
//  return self;
//}

//- (void)encodeWithCoder:(NSCoder *)aCoder
//{
  //[super encodeWithCoder:aCoder];
  
//}

/****
*
* ascii archiver stuff
*
****/

- (void)beginDearchiving:archiver
{
  [self init];
  [super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver
{
	char *tempChar;
	int		i, cnt;
	int		*tempArray;
	
	if (!strcmp(tag,"delReagent")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[delReagent addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"addReagent")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[addReagent addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"delnReagent")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[delnReagent addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"addnReagent")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[addnReagent addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"del1ddNTP")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[del1ddNTP addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"add1ddNTP")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[add1ddNTP addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"del2ddNTP")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[del2ddNTP addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"add2ddNTP")) {
		cnt = [archiver arraySize];
		tempArray = (int *)calloc(cnt,sizeof(int));
		[archiver readData:tempArray];
		for (i=0; i < cnt; i++)
			if (tempArray[i] > 0)
				[add2ddNTP addObject:[NSNumber numberWithInt:tempArray[i]]];
		free(tempArray);
	}
	else if (!strcmp(tag,"chanLoc"))
		[archiver readData:chanLoc];
	else if (!strcmp(tag,"ntcomplement"))
		[archiver readData:ntcomplement];
	else if (!strcmp(tag,"nt"))
		[archiver readData:nt];
	else if (!strcmp(tag,"seqPath")) {
		cnt = [archiver arraySize];
		tempChar = (char *)calloc(cnt,sizeof(char));
		[archiver readData:tempChar];
    seqPath = [[NSString alloc] initWithString:[NSString stringWithCString:tempChar]];
		free(tempChar);
	}
	else if (!strcmp(tag,"fitFile")) {
		cnt = [archiver arraySize];
		tempChar = (char *)calloc(cnt,sizeof(char));
		[archiver readData:tempChar];
    fitFile = [[NSString alloc] initWithString:[NSString stringWithCString:tempChar]];
		free(tempChar);
	}
  else if (!strcmp(tag,"peakFile")) {
		cnt = [archiver arraySize];
		tempChar = (char *)calloc(cnt,sizeof(char));
    [archiver readData:tempChar];
    peakFile = [[NSString alloc] initWithString:[NSString stringWithCString:tempChar]];
		free(tempChar);
  }
  else if (!strcmp(tag,"len"))
		[archiver readData:&len];
	else if (!strcmp(tag,"viewInd"))
		[archiver readData:&viewInd];
	else if (!strcmp(tag,"seqstartnum"))
		[archiver readData:&seqstartnum];
	else if (!strcmp(tag, "rangeBegin"))
		[archiver readData:&rangeBegin];
	else if (!strcmp(tag, "rangeEnd"))
		[archiver readData:&rangeEnd];
	else if (!strcmp(tag, "nt1sensitivity"))
		[archiver readData:&nt1sensitivity];
	else if (!strcmp(tag, "nt2sensitivity"))
		[archiver readData:&nt2sensitivity];
  else if (!strcmp(tag, "optimize"))
    [archiver readData:&optimize];
  else if (!strcmp(tag, "seqrangefrom"))
    [archiver readData:&seqrangefrom];
  else if (!strcmp(tag, "seqrangeto"))
    [archiver readData:&seqrangeto];
  else if (!strcmp(tag, "refinepeaks"))
    [archiver readData:&refinepeaks];
	else if (!strcmp(tag, "smoothing")) //throw away, legacy
    [archiver readData:&i];
  else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
	char *tempChar;
	int	 i;
	int		*tempArray;
	
	if ([delReagent count] > 0) {
		tempArray=(int *)calloc([delReagent count],sizeof(int));
		for (i=0; i < [delReagent count]; i++)
			tempArray[i] = [[delReagent objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[delReagent count] type:"i" tag:"delReagent"];
		free(tempArray);
	}
	if ([addReagent count] > 0) {
		tempArray=(int *)calloc([addReagent count],sizeof(int));
		for (i=0; i < [addReagent count]; i++)
			tempArray[i] = [[addReagent objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[addReagent count] type:"i" tag:"addReagent"];
		free(tempArray);
	}
	if ([delnReagent count] > 0) {
		tempArray=(int *)calloc([delnReagent count],sizeof(int));
		for (i=0; i < [delnReagent count]; i++)
			tempArray[i] = [[delnReagent objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[delnReagent count] type:"i" tag:"delnReagent"];
		free(tempArray);
	}
	if ([addnReagent count] > 0) {
		tempArray=(int *)calloc([addnReagent count],sizeof(int));
		for (i=0; i < [addnReagent count]; i++)
			tempArray[i] = [[addnReagent objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[addnReagent count] type:"i" tag:"addnReagent"];
		free(tempArray);
	}
  if ([add1ddNTP count] > 0) {
		tempArray=(int *)calloc([add1ddNTP count],sizeof(int));
		for (i=0; i < [add1ddNTP count]; i++)
			tempArray[i] = [[add1ddNTP objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[add1ddNTP count] type:"i" tag:"add1ddNTP"];
		free(tempArray);
	}  
  if ([del1ddNTP count] > 0) {
		tempArray=(int *)calloc([del1ddNTP count],sizeof(int));
		for (i=0; i < [del1ddNTP count]; i++)
			tempArray[i] = [[del1ddNTP objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[del1ddNTP count] type:"i" tag:"del1ddNTP"];
		free(tempArray);
	}  
  if ([add2ddNTP count] > 0) {
		tempArray=(int *)calloc([add2ddNTP count],sizeof(int));
		for (i=0; i < [add2ddNTP count]; i++)
			tempArray[i] = [[add2ddNTP objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[add2ddNTP count] type:"i" tag:"add2ddNTP"];
		free(tempArray);
	}  
  if ([del2ddNTP count] > 0) {
		tempArray=(int *)calloc([del2ddNTP count],sizeof(int));
		for (i=0; i < [del2ddNTP count]; i++)
			tempArray[i] = [[del2ddNTP objectAtIndex:i] intValue];
		[archiver writeArray:tempArray size:[del2ddNTP count] type:"i" tag:"del2ddNTP"];
		free(tempArray);
	}  
	[archiver writeArray:chanLoc size:4 type:"i" tag:"chanLoc"];
	[archiver writeArray:ntcomplement size:2 type:"c" tag:"ntcomplement"];
	[archiver writeArray:nt size:2 type:"c" tag:"nt"];
	//[archiver writeNSString:seqPath tag:"seqPath"];  //not workin'
  if (seqPath != nil) {
		tempChar=(char *)calloc([seqPath length]+1,sizeof(char));
    [seqPath getCString:tempChar];
    [archiver writeArray:tempChar size:([seqPath length]+1) type:"c" tag:"seqPath"];
		free(tempChar);
  }
	[archiver writeData:&viewInd type:"i" tag:"viewInd"];
	[archiver writeData:&seqstartnum type:"i" tag:"seqstartnum"];
	[archiver writeData:&rangeBegin type:"i" tag:"rangeBegin"];
	[archiver writeData:&rangeEnd type:"i" tag:"rangeEnd"];
	[archiver writeData:&nt1sensitivity type:"f" tag:"nt1sensitivity"];
	[archiver writeData:&nt2sensitivity type:"f" tag:"nt2sensitivity"];
  [archiver writeData:&optimize type:"i" tag:"optimize"];
  [archiver writeData:&seqrangefrom type:"i" tag:"seqrangefrom"];
  [archiver writeData:&seqrangeto type:"i" tag:"seqrangeto"];
  [archiver writeData:&refinepeaks type:"i" tag:"refinepeaks"];
  if (fitFile != nil) {
		tempChar=(char *)calloc([fitFile length]+1,sizeof(char));
    [fitFile getCString:tempChar];
    [archiver writeArray:tempChar size:([fitFile length]+1) type:"c" tag:"fitFile"];
		free(tempChar);
  }
  if (peakFile != nil) {
		tempChar=(char *)calloc([peakFile length]+1,sizeof(char));
    [peakFile getCString:tempChar];
    [archiver writeArray:tempChar size:([peakFile length]+1) type:"c" tag:"peakFile"];
		free(tempChar);
  }
  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolAlign     *dupSelf;
	int i;

	dupSelf = [super copyWithZone:zone];
	dupSelf->viewInd = viewInd;
	for (i=0; i<4; i++)
		dupSelf->chanLoc[i] = chanLoc[i];
	dupSelf->nt[0] = nt[0];
	dupSelf->nt[1] = nt[1];
	dupSelf->ntcomplement[0] = ntcomplement[0];
	dupSelf->ntcomplement[1] = ntcomplement[1];
	dupSelf->len = len;
	if (revSequence != nil)
		dupSelf->revSequence = [revSequence copyWithZone:zone];
  dupSelf->seqPath= [seqPath copy];
	for (i=0; i < [delReagent count]; i++)
		[dupSelf->delReagent addObject:[delReagent objectAtIndex:i]];
	for (i=0; i < [addReagent count]; i++)
		[dupSelf->addReagent addObject:[addReagent objectAtIndex:i]];
	for (i=0; i < [delnReagent count]; i++)
		[dupSelf->delnReagent addObject:[delnReagent objectAtIndex:i]];
	for (i=0; i < [addnReagent count]; i++)
		[dupSelf->addnReagent addObject:[addnReagent objectAtIndex:i]];
  for (i=0; i < [del1ddNTP count]; i++)
		[dupSelf->del1ddNTP addObject:[del1ddNTP objectAtIndex:i]];
	for (i=0; i < [add1ddNTP count]; i++)
		[dupSelf->add1ddNTP addObject:[add1ddNTP objectAtIndex:i]];
	for (i=0; i < [del2ddNTP count]; i++)
		[dupSelf->del2ddNTP addObject:[del2ddNTP objectAtIndex:i]];
	for (i=0; i < [add2ddNTP count]; i++)
		[dupSelf->add2ddNTP addObject:[add2ddNTP objectAtIndex:i]];
	dupSelf->rangeBegin = rangeBegin;
	dupSelf->rangeEnd = rangeEnd;
	dupSelf->seqstartnum = seqstartnum;
	dupSelf->nt1sensitivity = nt1sensitivity;
	dupSelf->nt2sensitivity = nt2sensitivity;
  dupSelf->optimize = optimize;
  dupSelf->fitFile = [fitFile copy];
  dupSelf->peakFile = [peakFile copy];
  dupSelf->seqrangefrom = seqrangefrom;
  dupSelf->seqrangeto = seqrangeto;
  dupSelf->refinepeaks = refinepeaks;
  dupSelf->applyOkay = applyOkay;
  dupSelf->threadIsExecuting = threadIsExecuting;
	if (peakStuff != nil) {
		dupSelf->peakStuff = [peakStuff copyWithZone:zone];
	}
	if (peakLadder != nil) {
		dupSelf->peakLadder = [peakLadder copyWithZone:zone];
	}
	if (seqList != nil) {
		dupSelf->seqList = [seqList copyWithZone:zone];
	}
	if (alignSeqList != nil) {
		dupSelf->alignSeqList = [alignSeqList copyWithZone:zone];
	}
	
  return dupSelf;
}

/***
*
* Release memory
*
***/
-(void)dealloc
{
	if (revSequence != nil) 
		[revSequence release];
	[self clearMyPointers];
	[seqPath release];
	[delReagent release];
	[delnReagent release];
	[addReagent release];
	[addnReagent release];
  [add1ddNTP release];
  [add2ddNTP release];
  [del1ddNTP release];
  [del2ddNTP release];
  if (tempTrace != nil)
    [tempTrace release];
	[super dealloc];
}

@end
