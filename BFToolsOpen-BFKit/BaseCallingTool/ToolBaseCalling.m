/* "$Id: ToolBaseCalling.m,v 1.2 2006/11/21 19:39:31 smvasa Exp $" */
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

#import "ToolBaseCalling.h"
#import "CallingController.h"
//#import "SeqList.h"
#import <GeneKit/NumericalObject.h>

/*****
* July 19, 1994 Mike Koehrsen
* Split ToolBaseCalling class into ToolBaseCalling and ToolBaseCallingCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
******/

@implementation ToolBaseCalling
/*
- (void)convertDataToInternal
{
  int    i, j, numChannels, count;
  aBase  localBase;
  Base   *externBase;
  ArrayStorage  *tempArray;
  float         tempFloat;

  [localBaseList free];
  [localDataList freeList];
  localBaseList=[[ArrayStorage alloc] initCount:0 elementSize:(sizeof(aBase)) description:"ifici"];
  //convert baseList
  for(i=0; i<[baseList seqLength]; i++) {
    externBase = [baseList baseAt:i];
    localBase.location = [externBase location];
    localBase.confidence = [externBase floatConfidence];
    localBase.channel = [externBase channel];
    localBase.base = [externBase base];
    //localBase.owner
    [localBaseList addElement:&localBase];
  }

  //convert dataList
  numChannels = [dataList numChannels];
  count = [dataList length];
  localDataList = [[SeqList alloc] initCount:numChannels];
  for (i = 0; i < numChannels; ++i) {
    tempArray = [[ArrayStorage alloc] initCount:0 elementSize:sizeof(float)
                                    description:"f"];
    for(j=0; j<count; j++) {
      tempFloat = [dataList sampleAtIndex:j channel:i];
      [tempArray addElement:&tempFloat];
    }
    [localDataList addObject:tempArray];
  }
}
*/ /*
- (void)convertInternalToData
{
  int           i;
  aBase         *localBase;
  Base          *externBase;
  float         maxConf=0.0;

  if (baseList)
    [baseList release];
  //convert baseList
  for(i=0; i<[localBaseList count]; i++) {
    localBase = (aBase*)[localBaseList elementAt:i];
    if(localBase->confidence > maxConf) maxConf=localBase->confidence;
  }
  if(maxConf < 1.0) maxConf=1.0;
  
  if([self debugmode]) fprintf(stderr, "baseCall maxConf=%f\n", maxConf);
  baseList = [Sequence new];
  for(i=0; i<[localBaseList count]; i++) {
    localBase = (aBase*)[localBaseList elementAt:i];
    externBase = [Base baseWithCall:localBase->base floatConfidence:(localBase->confidence/maxConf) location:localBase->location];
    //externBase.owner
    [baseList addBase:externBase];
  }

  //don't need to convert dataList because it is not modified
}
*/
- apply 
{		
  int                  x, count;
  Base                 *tempBase;
  CallingController    *callingObj;

  callingObj = [[CallingController alloc] init];

//  [self convertDataToInternal];
  [baseList release];
  
  [callingObj setParamObj:self];	/* so the params are accessible */
  if (useBIS)
    baseList = [[callingObj indexCall:dataList :BISlane] retain];
  else
    baseList = [[callingObj dumpBases:dataList] retain];

  [[self dataList] setDefaultProcLabels];

  //There is a BUG somewhere in basecalling which does not
  //assign a base letter to every base called.  But basecalling
  //does correctly assign the correct channel, so reprocess the
  //baselist filling in the baseLetter field based on the channel
  //this was fixed somewhere else in BaseFinder, but that did not work
  //correctly from 'proclanes' so the fix has to be added in here too.
  count = [baseList count];
  for(x=0; x< count; x++) {
    tempBase = (Base *)[localBaseList baseAt:x];
    switch([tempBase channel]) {
      case A_BASE: [tempBase setBase:'A']; break;
      case C_BASE: [tempBase setBase:'C']; break;
      case G_BASE: [tempBase setBase:'G']; break;
      case T_BASE: [tempBase setBase:'T']; break;
      case UNKNOWN_BASE:
      default:
        [tempBase setBase:'N'];
        break;
    }
  }
//  [self convertInternalToData];

//  [localDataList freeList];
//  [localBaseList free];
//  localDataList = nil;
//  localBaseList = nil;

  [callingObj release];
  return [super apply];
}

- (void)returnCallingThresholds:(float *)CallQuit :(float *)FinalOut :(float *)ThrowOut
{
	*ThrowOut = throwout;
	*CallQuit = callquit;
	*FinalOut = finalout; 
}

- returnTolerances:(float *) bwtol :(float *) ewtol :(float *)sptol
{
	*bwtol = bwidthtol;
	*ewtol = ewidthtol;
	*sptol = spacetol;
	return self;
}

- (void)returnObjectWeights:(float **)Weights
{
	*Weights = weights; 
}

- (void)returnCallingInts:(int *)HighOrder :(int *)MaxIt
{
	*HighOrder = highorder;
	*MaxIt = maxit; 
}

- (BOOL)modifiesData { return NO; }
- (BOOL)shouldCache { return YES; }

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];
  [aDecoder decodeArrayOfObjCType:"f" count:5 at:weights];
  [aDecoder decodeValuesOfObjCTypes:"fffiifff",&finalout,&callquit,&throwout,
    &maxit,&highorder,
    &bwidthtol,&ewidthtol,&spacetol];
  baseList = [[aDecoder decodeObject] retain];				

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];
  [aCoder encodeArrayOfObjCType:"f" count:5 at:weights];
  [aCoder encodeValuesOfObjCTypes:"fffiifff",&finalout,&callquit,&throwout,
    &maxit,&highorder,
    &bwidthtol,&ewidthtol,&spacetol];
  /* NOTE--right now, ToolBaseCalling and SequenceEditor store baseList redundantly
     * when last tool in script is a base call
     */
  [aCoder encodeObject:baseList];
}

- (NSString *)toolName
{
  return @"Base Calling";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"weights"))
    [archiver readData:weights];
  else if (!strcmp(tag,"finalout"))
    [archiver readData:&finalout];
  else if (!strcmp(tag,"callquit"))
    [archiver readData:&callquit];
  else if (!strcmp(tag,"throwout"))
    [archiver readData:&throwout];
  else if (!strcmp(tag,"maxit"))
    [archiver readData:&maxit];
  else if (!strcmp(tag,"highorder"))
    [archiver readData:&highorder];
  else if (!strcmp(tag,"bwidthtol"))
    [archiver readData:&bwidthtol];
  else if (!strcmp(tag,"ewidthtol"))
    [archiver readData:&ewidthtol];
  else if (!strcmp(tag,"spacetol"))
    [archiver readData:&spacetol];
  else return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeArray:weights size:5 type:"f" tag:"weights"];
  [archiver writeData:&finalout type:"f" tag:"finalout"];
  [archiver writeData:&callquit type:"f" tag:"callquit"];
  [archiver writeData:&throwout type:"f" tag:"throwout"];

  [archiver writeData:&maxit type:"i" tag:"maxit"];
  [archiver writeData:&highorder type:"i" tag:"highorder"];

  [archiver writeData:&bwidthtol type:"f" tag:"bwidthtol"];
  [archiver writeData:&ewidthtol type:"f" tag:"ewidthtol"];
  [archiver writeData:&spacetol type:"f" tag:"spacetol"];

  return [super writeAscii:archiver];
}

- copyWithZone:(NSZone *)zone;
{
  ToolBaseCalling     *dupSelf;

  dupSelf = [super copyWithZone:zone];

  dupSelf->weights[0]=weights[0];
  dupSelf->weights[1]=weights[1];
  dupSelf->weights[2]=weights[2];
  dupSelf->weights[3]=weights[3];
  dupSelf->weights[4]=weights[4];
  dupSelf->finalout=finalout;
  dupSelf->callquit=callquit;
  dupSelf->throwout=throwout;
  dupSelf->maxit=maxit;
  dupSelf->highorder=highorder;
  dupSelf->bwidthtol=bwidthtol;
  dupSelf->ewidthtol=ewidthtol;
  dupSelf->spacetol=spacetol;
  dupSelf->useBIS=useBIS;
  dupSelf->BISlane=BISlane;

  return dupSelf;
}

- (void)dealloc
{
//  [localDataList freeList];
//  [localBaseList free];
  [baseList release];
  [super dealloc];
}

@end
