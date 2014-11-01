/* "$Id: FirstDerivative.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import "FirstDerivative.h"
#import <GeneKit/NumericalRoutines.h>

@implementation FirstDerivative

- init
{
  [super init];
  shouldRescale = YES;
  return self;
}

- (NSString *)toolName
{
  return @"First Derivative";
}

- (BOOL)modifiesData { return YES; }		//to switch between processor/analyzer

- (void)rescaleDerivative:(Trace*)derivative
{
  // rescales to largest pos/neg peak is scaled to 1.0.
  // preserves sign, but inverts so peaks are positive and valleys are negative.

  int		channel,pos;
  float		tempVal, *tempArray;
  double	min, max, scale, powFac=0.5, val;

  if(derivative == nil) return;

  for(channel=0; channel<[derivative numChannels]; channel++) {
    for(pos=0; pos<[derivative length]; pos++) {
      tempVal = [derivative sampleAtIndex:pos channel:channel];
      val = (double)tempVal;
      val = val<0.0 ? -pow(-val, powFac) : pow(val, powFac);
      [derivative setSample:(float)val atIndex:pos channel:channel];
    }

    tempArray = [derivative sampleArrayAtChannel:channel];
    min = minVal(tempArray, [derivative length]);
    max = maxVal(tempArray, [derivative length]);
    if(fabs(min) > fabs(max)) scale=fabs(min);
    else scale=fabs(max);
    fprintf(stderr,"min=%f  max=%f  scale=%f\n",min,max,scale);

    for(pos=0; pos<[derivative length]; pos++) {
      tempVal = [derivative sampleAtIndex:pos channel:channel];
      val = (double)tempVal;
      tempVal = (float)(-val/scale);
      [derivative setSample:(float)tempVal atIndex:pos channel:channel];
    }
  }
}

- apply
{
  // applies second derivative and rescales to largest pos/neg peak is scaled to 1.0.
  // preserves sign, but inverts so peaks are positive and valleys are negative.

  Trace		*derivative;

  if(dataList == nil) return self;
  
  derivative = [self firstDerivative:dataList];

  if(shouldRescale) [self rescaleDerivative:derivative];
  [dataList release];
  dataList = [derivative retain];
  return [super apply];
}


- (Trace*)firstDerivative:(Trace*)inData
{
  Trace		*derivative;
  int		i, j, numUsed, channel;
  float		temp1, temp2, derivVal;

  derivative = [[inData copy] autorelease];
  for(channel=0; channel<[inData numChannels]; channel++) {
    for(i=0; i<[inData length]; i++) {
      derivVal = 0.0;
      numUsed = 0;
      for(j=-3; j<=3; j++) {
        if((i+j >= 0) && (i+j < [inData length]) && (j!=0)) {
          temp1 = [inData sampleAtIndex:i channel:channel];
          temp2 = [inData sampleAtIndex:(i+j) channel:channel];
          derivVal += (temp2 - temp1) / (float)j;
          numUsed++;
        }
      }
      if(numUsed > 0) derivVal = derivVal / numUsed;
      [derivative setSample:derivVal atIndex:i channel:channel];
    }
  }
  return derivative;
}

/**
- (void)findPeaks
{
  id		pointList=[self dataList], dataChannel;
  id		derivID; //, baseID;
  float		aveHeight;
  int		i, chan;
  aBase 	oneBase; //, *tempBase;
  BOOL		wasPos;
  //FILE	*fp;

  if(baseList != NULL) [baseList release];
  baseList = [[ArrayStorage alloc] initCount:0
                                 elementSize:(sizeof(aBase))
                                 description:"ifici"];
  for(chan=0; chan<[pointList count]; chan++) {
    dataChannel = [pointList objectAt:chan];

    aveHeight = 0.0;
    for(i=0; i<[dataChannel count]; i++) {
      aveHeight += *((float*)[dataChannel elementAt:i]);
    }
    aveHeight = aveHeight / [dataChannel count];

    derivID = [self firstDerivative:dataChannel];

    if(*((float*)[dataChannel elementAt:0]) > 0.0) wasPos=YES;
    else wasPos = NO;

    for(i=1; i<[dataChannel count]; i++) {
      if(wasPos &&
         (*((float*)[derivID elementAt:i]) <= 0.0) &&
         (*((float*)[dataChannel elementAt:i]) >= aveHeight)) {
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
        [baseList addElement:&oneBase];
      }
      if(*((float*)[derivID elementAt:i]) > 0.0) wasPos = YES;
    }
  }


  /****
    baseID = [[SeqList alloc] init];
  for(chan=0; chan<4; chan++)
    [baseID addObject:[[Storage alloc] initCount:0 elementSize:sizeof(int)
                                     description:"i"]];

  fp = fopen("/tmp/mob.data", "w");
  for(chan=0; chan<4; chan++) {
    for(i=0; i<[baseList count]; i++) {
      tempBase = (aBase*)[baseList elementAt:i];
      if(tempBase->channel == chan) {
      }
    }
  }
  fclose(fp);
  [baseID freeList];
  **** /

  baseList = sortBaseList(baseList);
}
***/


/****
* ASCIIarchiver methods required for scripting
****/
- (void)beginDearchiving:archiver;
{
  [self init];
  [super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"shouldRescaleAndInvert"))
    [archiver readData:&shouldRescale];
  else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&shouldRescale type:"c" tag:"shouldRescaleAndInvert"];

  [super writeAscii:archiver];
}

/*****
*
* Variable section
*
*****/

- (BOOL)shouldRescale
{
  return shouldRescale;
}

- (void)setShouldRescale:(BOOL)value
{
  shouldRescale = value;
}

@end




@implementation FirstDerivativeCtrl

- (void)inspectorDidDisplay
{
  if ([toolMaster pointStorageID] == nil) return;
  //[toolMaster registerForEventNotification:self];
}

- (BOOL)inspectorWillUndisplay
{
  //[toolMaster deregisterForEventNotification:self];
  return YES;
}

- (void)getParams
{
  [super getParams];
  [dataProcessor setShouldRescale:[scaleSwitch state]];
}

- (void)displayParams
{
  [super displayParams];
  [scaleSwitch setState:[dataProcessor shouldRescale]];
}


@end
