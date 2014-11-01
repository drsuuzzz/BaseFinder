
/* "$Id: MobilityNonlinear.m,v 1.3 2006/06/15 04:01:13 svasa Exp $" */
/***********************************************************

Copyright (c) 1994-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "MobilityNonlinear.h"
#import <GeneKit/NumericalObject.h>

/*****
* August 9, 1994 Jessica Hayden
* Second Generation mobility shift routines.
*****/

@implementation MobilityNonlinear

- init
{
  [super init];
  mobilityFunctionID = [[MobilityFunc1 alloc] init];
  myBaseList = NULL;
  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@"\n    mobilityFunc=%@",[mobilityFunctionID description]];
  return tempString;
}

 
- (NSString *)defaultLabel
{
  return @"Default Mobility";
}

- (NSString *)toolName
{
  return @"Mobility Shift: Non Linear";
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  MobilityNonlinear     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  //if(dupSelf->mobilityFunctionID != NULL) [dupSelf->mobilityFunctionID release];
  dupSelf->mobilityFunctionID = [mobilityFunctionID copy];
  return dupSelf;
}

- (void)dealloc
{
  [mobilityFunctionID release];
  [super dealloc];
}

/****
*
* resource handling section (subclass must implement)
*
****/

- (void)writeResource:(NSString*)resourcePath
{
  AsciiArchiver   *archiver;

  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:mobilityFunctionID tag:"mobilityFunctionID"];
  [archiver writeToFile:resourcePath atomically:YES];
  [archiver release];
}

- (void)readResource:(NSString*)resourcePath
{
  AsciiArchiver   *archiver;
  id              tempFunc;
  char            tagBuf[MAXTAGLEN];
	NSScanner				*tempscan;
	NSString				*classname=@"MobilityFunc1";

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:resourcePath];
  if(!archiver) return;

  [archiver getNextTag:tagBuf];

  if(strcmp(tagBuf, "mobilityFunctionID") != 0) {
    /***
    [[controller toolMaster] log:
      @"resource file does not have a 'mobilityFunctionID' object"];
    ***/
    NSLog([NSString stringWithFormat:@"  tag='%s'\n", tagBuf]);
    return;
  }
	tempscan = [NSScanner scannerWithString:[[NSString alloc] initWithContentsOfFile:resourcePath]];
	[tempscan scanUpToString:classname intoString:nil];
	if ([tempscan isAtEnd]) {
		NSLog([NSString stringWithFormat:@"Incompatible class name\n"]);
		return;
	}
	if ((tempFunc=[archiver readObject])!=nil) {
    if(mobilityFunctionID) [mobilityFunctionID release];
    mobilityFunctionID = [tempFunc retain];
  }
  //mobilityFunctionID = [archiver readObjectWithTag:"mobilityFunctionID"];
  [archiver release];
}

/****/

- (BOOL)modifiesData { return YES; }		//to switch between processor/analyzer

- apply
{	
  int        pos, count, chan, numChannels;
  int        currentShift=0, tempShift;
  int        primerPos, primerOffset=0, dataStart=0;
  float      value;
  FILE       *fp;
  NSString   *logPath;

  logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"mobility2.log"];
  fp = fopen([logPath fileSystemRepresentation], "w");

  count = [dataList length];
  numChannels = [dataList numChannels];

  for(chan=0; chan<numChannels; chan++) {
    if(fp!=NULL) fprintf(fp,"mobilityShift for channel %d\n",chan);

    // should find primer peak and process from that point on
    // for now it's hardcoded.
    if([dataList deleteOffset] > 0) {
      // primer was already found and deleted
      primerOffset = [dataList deleteOffset];
      primerPos = primerOffset;
      dataStart = 1;
    }
    else {
      /*
      primerOffset = 0;
      primerPos = 800;
      dataStart = primerPos;
       */
      primerOffset = 850;
      primerPos = 850;
      dataStart = 0;
    }
    /*
    primerOffset = 850;
    primerPos = 850;
    dataStart = 0;
     */

    if(fp!=NULL) {
      fprintf(fp, "primerOffset:%d  primerPos:%d  dataStart:%d\n", primerOffset, primerPos, dataStart);
      fflush(fp);
    }
    
    currentShift = [mobilityFunctionID valueAt:(float)primerPos channel:chan];
    if(currentShift>0.0) {
      if(fp!=NULL) { fprintf(fp, "initial delete %d points\n", currentShift); fflush(fp); }
      [dataList removeSamples:currentShift atIndex:0 channel:chan];

    }
    else if(currentShift<0.0){
      if(fp!=NULL) { fprintf(fp, "initial insert %d points\n", currentShift); fflush(fp); }
      value = 0.0;
      [dataList insertSamples:-currentShift atIndex:0 channel:chan];
      if(fp!=NULL) { fprintf(fp, "initial insert success\n"); fflush(fp); }
    }

    for(pos=dataStart; pos<count; pos++) {
      tempShift = (int)([mobilityFunctionID valueAt:(double)(pos+primerOffset)
                                            channel:chan] + 0.5);
      if(tempShift != currentShift) {
        if(tempShift < currentShift) {
          if(fp!=NULL) {
            fprintf(fp," insert point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [mobilityFunctionID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          value = [dataList sampleAtIndex:(pos-1) channel:chan];
          value += [dataList sampleAtIndex:pos channel:chan];
          value = value / 2.0;
          //[dataChannel insertElement:&value at:pos];
          [dataList insertSamples:(currentShift-tempShift) atIndex:pos channel:chan];
        }
        else {
          if(fp!=NULL) {
            fprintf(fp," delete point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [mobilityFunctionID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          //[dataChannel removeElementAt:pos];
          if (((tempShift-currentShift)+pos) < count)
            [dataList removeSamples:(tempShift-currentShift) atIndex:pos channel:chan];
        }
        currentShift = tempShift;
      }
    }
  }
  if(fp!=NULL) fclose(fp);
  return [super apply];
}

#ifdef OLDCODE
- TESTapply
{
  id   tempID;

  tempID = [self firstDerivative:[[self dataList] objectAt:0]];
  [[self dataList] addObject:tempID];
  tempID = [self firstDerivative:tempID];
  [[self dataList] addObject:tempID];
  //[self findPeaks];
  return [super apply];
}

- ORIGapply
{	
  id         dataChannel;
  int        pos, count, chan, numChannels, i;
  int        currentShift=0, tempShift;
  int        minLength, tLength, primerPos, primerOffset=0, dataStart=0;
  float      value;

  count = [dataList length];
  numChannels = [dataList numChannels];

  for(chan=0; chan<numChannels; chan++) {
    /****
    [[controller toolMaster] log:
          [NSString stringWithFormat:@"mobilityShift for channel %d\n",chan]];
    ***/
    dataChannel = [dataList objectAt:chan];

/****** OLDCODE
  // should find primer peak and process from that point on
    // for now it's hardcoded.
    if([dataChannel respondsToSelector:@selector(deleteOffset)] &&
       [dataChannel deleteOffset] > 0) {
      // primer was already found and deleted
      primerOffset = [dataChannel deleteOffset];
      primerPos = primerOffset;
      dataStart = 1;
    }
    else {
      primerOffset = 0;
      primerPos = 800;
      dataStart = primerPos;
    }
****/
    primerOffset = 850;
    primerPos = 850;
    dataStart = 0;

    [[controller toolMaster] log:
          [NSString stringWithFormat:@"primerOffset:%d  primerPos:%d  dataStart:%d\n", primerOffset, primerPos, dataStart]];

    currentShift = [mobilityFunctionID valueAt:(float)primerPos channel:chan];
    if(currentShift>0.0) {
      [[controller toolMaster] log:
            [NSString stringWithFormat:@"initial delete %d points\n", currentShift]];
      for(i=0; i<currentShift; i++)
        [dataChannel removeElementAt:0];
    }
    else if(currentShift<0.0){
      [[controller toolMaster] log:
            [NSString stringWithFormat:@"initial insert %d points\n", currentShift]];
      value = 0.0;
      for(i=0; i<currentShift; i++)
        [dataChannel insertElement:&value at:0];
    }

    for(pos=dataStart; pos<count; pos++) {
      tempShift = (int)([mobilityFunctionID valueAt:(double)(pos+primerOffset)
                                            channel:chan] + 0.5);
      if(tempShift != currentShift) {
        if(tempShift < currentShift) {
          fprintf(fp," insert point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
          		pos, currentShift, tempShift,
          		[mobilityFunctionID valueAt:(double)pos channel:chan]);
          fflush(fp);
          value = (*(float*)([dataChannel elementAt:(pos-1)]));
          value += (*(float*)([dataChannel elementAt:pos]));
          value = value / 2.0;
          [dataChannel insertElement:&value at:pos];
        }
        else {
          fprintf(fp," delete point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
          		pos, currentShift, tempShift,
          		[mobilityFunctionID valueAt:(double)pos channel:chan]);
          fflush(fp);
          [dataChannel removeElementAt:pos];
        }
        currentShift = tempShift;
      }
    }
    fprintf(fp," new length = %d\n\n", [dataChannel count]);
  }

  minLength = [[dataList objectAt:0] count];
  for(chan=1; chan<numChannels; chan++) {
    tLength = [[dataList objectAt:chan] count];
    if(tLength < minLength) minLength=tLength;
  }
  fprintf(fp," minLength = %d\n", minLength); fflush(fp);
  for(chan=0; chan<numChannels; chan++) {
    tLength = [[dataList objectAt:chan] count];
    fprintf(fp," chan:%d  oldLength=%d  ", chan, tLength); fflush(fp);
    if(tLength > minLength) {
      for(i=0; i<(tLength-minLength); i++)
        [[dataList objectAt:chan] removeLastElement];
    }
    fprintf(fp,"newLength=%d\n", [[dataList objectAt:chan] count]); fflush(fp);
  }
  fclose(fp);
  return [super apply];
}
#endif

/****
*
* Mobility Calibration file processing section
*
****/

/*
- firstDerivative:(id)inData
{
  id		derivative;
  int		i, j, numUsed;
  float		*temp1, *temp2, derivVal;

  derivative = [[ArrayStorage alloc] initCount:0 elementSize:sizeof(float)
                                   description:"f"];
  for(i=0; i<[inData count]; i++) {
    derivVal = 0.0;
    numUsed = 0;
    for(j=-3; j<=3; j++) {
      if((i+j >= 0) && (i+j < [inData count]) && (j!=0)) {
        temp1 = (float*)[inData elementAt:i];
        temp2 = (float*)[inData elementAt:(i+j)];
        derivVal += (*temp2 - *temp1) / (float)j;
        numUsed++;
      }
    }
    if(numUsed > 0) derivVal = derivVal / numUsed;
    [derivative addElement:&derivVal];
  }
  return derivative;
}

- (void)findPeaks
{
  id       derivID;
  //id       baseID;
  float    aveHeight;
  int      i, chan;
  aBase    oneBase;
  //aBase    *tempBase;
  BOOL     wasPos;
  //FILE     *fp;
  NumericalObject   *numObj = [[NumericalObject new] autorelease];

  if(myBaseList != NULL) [myBaseList release];
  myBaseList = [[ArrayStorage alloc] initCount:0
                                 elementSize:(sizeof(aBase))
                                 description:"ifici"];
  for(chan=0; chan<[dataList numChannels]; chan++) {
    aveHeight = 0.0;
    for(i=0; i<[dataList length]; i++) {
      aveHeight += [dataList sampleAtIndex:i channel:chan];
    }
    aveHeight = aveHeight / [dataList length];

    derivID = [self firstDerivative:dataList];

    if([dataList sampleAtIndex:0 channel:chan] > 0.0) wasPos=YES;
    else wasPos = NO;

    for(i=1; i<[dataList length]; i++) {
      if(wasPos &&
         (*((float*)[derivID elementAt:i]) <= 0.0) &&
         ([dataList sampleAtIndex:i channel:chan] >= aveHeight)) {
        wasPos = NO;
        oneBase.location = i;
        oneBase.confidence = 1.0;
        oneBase.channel = chan;
        oneBase.owner = 0;	//INITIALBASEOWNER
        switch (chan) {
          case A_BASE:	oneBase.base = 'A';
            break;
          case T_BASE: oneBase.base = 'T';
            break;
          case C_BASE: oneBase.base = 'C';
            break;
          case G_BASE: oneBase.base = 'G';
            break;
        };
        [myBaseList addElement:&oneBase];
      }
      if(*((float*)[derivID elementAt:i]) > 0.0) wasPos = YES;
    }
  }


     baseID = [[SeqList alloc] init];
     for(chan=0; chan<4; chan++)
     [baseID addObject:[[Storage alloc] initCount:0 elementSize:sizeof(int)
                                      description:"i"]];

     fp = fopen("/tmp/mob.data", "w");
     for(chan=0; chan<4; chan++) {
       for(i=0; i<[myBaseList count]; i++) {
         tempBase = (aBase*)[myBaseList elementAt:i];
         if(tempBase->channel == chan) {
         }
       }
     }
     fclose(fp);
     [baseID freeList];
     **** /

  myBaseList = [numObj sortBaseList:myBaseList];
}
*/

	
/****
* ASCIIarchiver methods required for scripting
****/
-(void) beginDearchiving:archiver;
{
  [self init];
  [super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"mobilityFunctionID"))
    mobilityFunctionID = [[archiver readObject] retain];
  else return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeObject:mobilityFunctionID tag:"mobilityFunctionID"];
  [super writeAscii:archiver];
}
@end
