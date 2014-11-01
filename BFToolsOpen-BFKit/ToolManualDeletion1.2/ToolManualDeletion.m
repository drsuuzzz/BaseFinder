/* "$Id: ToolManualDeletion.m,v 1.4 2007/06/13 15:31:06 smvasa Exp $" */
/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "ToolManualDeletion.h"
#import <GeneKit/Gaussian.h>

/*****
* July 19, 1994 Mike Koehrsen
* Split ToolManualDeletion class into ToolManualDeletion and ToolManualDeletionCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*
* August 16, 1994 Jessica Hayden
* Added ability to specify deletion relative to end of data, independent of data
* length.  Uses '$' symbol to specify end of data, and '$-#' to subtract #points
* from end (eg from:$-10 to:$).
*
* February 1996 Jessica Severin
* Added back in the ability to delete data and the associated basecall 
* simultaneously.  Also required a small change to GenericTool.
*
* Nov 10, 1998 Jessica Severin
* split into two separate files
**/

@implementation ToolManualDeletion

- init
{
  baseList=NULL;
  return [super init];
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@"    firstLoc=%s   lastLoc=%s",firstLoc, lastLoc];
  return tempString;
}

- apply
{
  int pointCount=[dataList length],i,j;
  int	delete;
  int firstPoint, lastPoint;
	
  firstPoint = [self convertDescript:firstLoc];
  lastPoint = [self convertDescript:lastLoc];

  if([self debugmode]) fprintf(stderr,"manualDelete %d:%d  #pts=%d\n",firstPoint, lastPoint, pointCount);
  if(firstPoint<0) firstPoint=0;
  if(lastPoint<0) lastPoint=0;
  if(firstPoint>pointCount-1) firstPoint=pointCount-1;
  if(lastPoint>pointCount-1) lastPoint=pointCount-1;
  if([self debugmode]) fprintf(stderr,"  converted to %d:%d\n",firstPoint, lastPoint);
  if(firstPoint > lastPoint) {
    if([self debugmode]) fprintf(stderr,"  nothing to delete\n");
    return NULL;
  }

  delete = ((firstPoint==0) || (lastPoint==pointCount));
  if (delete || !leaveSpace) {
    [dataList removeSamples:(lastPoint-firstPoint+1) atIndex:firstPoint];
    [self deleteBases:firstPoint :lastPoint];
    [self shiftBasesAfterDelete:firstPoint :lastPoint];
		for (i = 0; i < [dataList numChannels]; i++)
			delChannels[i] = 1;
  }
  else {
    for(i=firstPoint; i<=lastPoint; i++)
      for(j=0; j<[dataList numChannels]; j++)
				if (delChannels[j] != 0)
         [dataList setSample:0.0 atIndex:i channel:j];
    [self deleteBases:firstPoint :lastPoint];
  }

  return [super apply];
}

- (int)convertDescript:(char*)input
{
  //cleans up *input, and returns the cleaned up string back into input
  //also converts input string into numerical position.

  int    pointCount=[dataList length]-1;
  int    value=0.0, state=0, i=0, len=strlen(input);
  char   initStr[64];

  strcpy(initStr, input);

  while(state>=0 && state<10) {
    while(((initStr[i] == ' ') || (initStr[i] == '\t')) && i<len) i++;
    switch(state) {
      case 0: // expect $
        if(initStr[i] == '$') state = 1;
        else state = -1; //either a number or syntax error
        i++;
        break;
      case 1: // expect '-' or nothing else error
        if(i>=len || initStr[i]!='-') {
          // just '$' == end of data
          value = pointCount;
          state = 10; //end
          strcpy(input, "$");
        } else
          if(initStr[i] == '-') {
            state=2;
            i++;
          }
        else state=-1;
        break;
      case 2: //expect <number>
        value = atoi(&(initStr[i]));
        sprintf(input, "$-%d",value);
        value = pointCount-value;
        state = 10;
        break;
    }
  }

  if(state == -1) {
    value = atoi(input);
    sprintf(input,"%d",value);
  }
  return value;
}

- (NSString *)toolName
{
  return @"Manual Deletion 1.2";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  int firstPoint, lastPoint;

  if (!strcmp(tag,"firstPoint")) {
    [archiver readData:&firstPoint];
    sprintf(firstLoc,"%d",firstPoint);
  }
  else if (!strcmp(tag,"lastPoint")) {
    [archiver readData:&lastPoint];
    sprintf(lastLoc,"%d", lastPoint);
  }
  else if (!strcmp(tag,"firstLoc")) {
    [archiver readString:firstLoc maxLength:32];
  }
  else if (!strcmp(tag,"lastLoc")) {
    [archiver readString:lastLoc maxLength:32];
  }
  else if (!strcmp(tag,"leaveSpace"))
    [archiver readData:&leaveSpace];
	else if (!strcmp(tag,"delChannels"))
		[archiver readData:delChannels];
  else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  //[archiver writeData:&firstPoint type:"i" tag:"firstPoint"]; //old
  //[archiver writeData:&lastPoint type:"i" tag:"lastPoint"]; //old

  [archiver writeString:firstLoc tag:"firstLoc"];
  [archiver writeString:lastLoc tag:"lastLoc"];
  [archiver writeData:&leaveSpace type:"c" tag:"leaveSpace"];
  [archiver writeArray:delChannels size:8 type:"f" tag:"delChannels"];

  [super writeAscii:archiver];
}

- (int)getDelChans:(int)channel;
{
	return delChannels[channel];
}

- (void)setDelChans:(int)val at:(int)index
{
	delChannels[index] = val;
}
/****
* Special Case. Manual Deletion tool allows for baseList to
* come in and be deleted along with the data and then be
* passed out for the next tool or for display.
****/

- (void)deleteBases:(int)firstPoint :(int)lastPoint
{
  Base    *tempBase;
	Gaussian *tempG;
  int     i, pos;

  if(baseList == NULL) return;	
  i=0;
  while(i<[baseList seqLength]) {
    tempBase = (Base *)[baseList baseAt:i];
    if(([tempBase location] >= firstPoint) && ([tempBase location] <= lastPoint)) {
      [baseList removeBaseAt:i];
    }
    else
      i++;
  }
	if (alnBaseList != nil) {
		i = 0;
		while(i<[alnBaseList seqLength]) {
			tempBase = (Base *)[alnBaseList baseAt:i];
			if(([tempBase location] >= firstPoint) && ([tempBase location] <= lastPoint)) {
				[alnBaseList removeBaseAt:i];
			}
			else
				i++;
		}		
	}
	if (peakList != nil) {
		i = 0;
		while (i < [peakList length]) {
			pos = [peakList valueAt:i :0];
			if ((pos >= firstPoint) && (pos <= lastPoint)) {
				[peakList removeLinkedPeaksAt:i];				
			}
			else
				i++;
		}
	}
	if (ladder != nil) {
		i = 0;
		while (i < [ladder count]) {
			tempG = [ladder objectAtIndex:i];
			if (([tempG center] >= firstPoint) && ([tempG center] <= lastPoint)) {
				[ladder removeEntryAt:i];
			}
			else
				i++;
		}
	}
}

- (void)shiftBasesAfterDelete:(int)firstPoint :(int)lastPoint
{
  //Since the [ArrayStorage -deleteData::] method is an inclusive
  //delete, the data is shifted (lastPoint-firstPoint+1) data points
  Base     *tempBase;
	Gaussian *tempG;
  int      i, shift=(lastPoint-firstPoint+1);
	int			 pos1, pos2, pos3, pos4;

  if(baseList == NULL) return;	
  if(firstPoint > lastPoint) return;
  if([self debugmode]) fprintf(stderr, "shiftBasesAfterDelete %d\n", shift);
  for(i=0; i<[baseList seqLength]; i++) {
    tempBase = (Base *)[baseList baseAt:i];
    if([tempBase location] > lastPoint)
      [tempBase setLocation:([tempBase location] - shift)];
    }
	if (alnBaseList != nil) {
		if ([self debugmode]) NSLog(@"Shift Align Bases After Delete %d\n", shift);
		for (i = 0; i < [alnBaseList seqLength]; i++) {
			tempBase = (Base *)[alnBaseList baseAt:i];
			if ([tempBase location] > lastPoint)
				[tempBase setLocation:([tempBase location] - shift)];
		}		
	}
	if (peakList != nil) {
		if ([self debugmode]) NSLog(@"Shift Peak List After Delete %d\n", shift);
		for (i = 0; i < [peakList length]; i++) {
			pos1 = [peakList valueAt:i :0];
			pos2 = [peakList valueAt:i :1];
			pos3 = [peakList valueAt:i :2];
			pos4 = [peakList valueAt:i :3];
			if (pos1 > lastPoint)
				[peakList replacePosition:i atPeak:0 with:(pos1-shift)];
			if (pos2 > lastPoint)
				[peakList replacePosition:i atPeak:1 with:(pos2-shift)];
			if (abs(pos3) > lastPoint) {
				if (pos3 < 0)
					[peakList replacePosition:i atPeak:2 with:-(abs(pos3)-shift)];
				else
					[peakList replacePosition:i atPeak:2 with:(pos3-shift)];
			}
			if (abs(pos4) > lastPoint) {
				if (pos4 < 0)
					[peakList replacePosition:i atPeak:3 with:-(abs(pos4)-shift)];
				else
					[peakList replacePosition:i atPeak:3 with:(pos4-shift)];
			}
		}		
	}
	if (ladder != nil) {
		if ([self debugmode]) NSLog(@"Shift Ladder List After Delete %d\n",shift);
		for (i = 0; i < [ladder count]; i++) {
			tempG = [ladder objectAtIndex:i];
			if ([tempG center] > lastPoint)
				[tempG setCenter:([tempG center]-shift)];
		}
	}
}

- (id)copyWithZone:(NSZone *)zone
{
  ToolManualDeletion     *dupSelf;
	int										 i;

  dupSelf = [super copyWithZone:zone];

  strncpy(dupSelf->firstLoc, firstLoc, 32);
  strncpy(dupSelf->lastLoc, lastLoc, 32);
  dupSelf->leaveSpace = leaveSpace;
	for (i=0; i < 8; i++) 
		dupSelf->delChannels[i] = delChannels[i];

  return dupSelf;
}

@end

