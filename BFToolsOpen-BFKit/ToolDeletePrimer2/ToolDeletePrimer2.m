/* "$Id: ToolDeletePrimer2.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolDeletePrimer2.h"
#import <GeneKit/NumericalObject.h>

/****
* April 5, 1994: Jessica Hayden author
* Second generation primer peak deletion tool.  It does not require normalized data
* nor does it require the user to enter parameters.  It does allow two different
* types of primer patterns to be identified.  Most situations, there is a primer
* peak in all detector channels, but it can also work if the primer peak only occurs
* in one of the channels.
*
* The primer peak is defined as the largest magnitude peak in the data stream (or each
* channel).  After finding this peak (or the latest one if one is expected in all
* channels), the algorithm find the first minima in each channel following this peak.
* the furthest minima into the run (from all the channels) is used as the point where
* the primer peak ends (and thus is the place to delete up to).
*
*****/
/*****
* July 19, 1994 Mike Koehrsen
* Split ToolDeletePrimer2 class into ToolDeletePrimer2 and ToolDeletePrimer2Ctrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolDeletePrimer2

- init
{
  [super init];
  peakPos = -1;
  valleyPos = -1;
  signalCutoff = -1;
  dataLength = -1;
  performSignalCutoff = YES;
  return self;
}

- (void)findPrimerPeak:(Trace*)traceData
{
  int 		    i, numChannels=[traceData numChannels];
  float		    tMax=0.0, primerHeight=0.0;
  int		    chan, posMax=-1, tPos=0, pointCount;
  int 		    minPos, primerMaxoutLen;
  NumericalObject   *numObj = [NumericalObject new];

  pointCount = [traceData length] * 0.75;
  /** find the largest peak (raw values) of all channels, = the primer **/
  for (chan=0; chan<numChannels; chan++) {
    if(!useOnePeak) {
      tMax = 0.0;
      tPos = 0;
    }
    for(i=0; i<pointCount; i++) {
      if([traceData sampleAtIndex:i channel:chan] > tMax) {
        tMax = [traceData sampleAtIndex:i channel:chan];
        tPos = i;
      }
    }
    //if(!useOnePeak) fprintf(stderr,"chan:%d  peak:%f pos:%d\n",chan, tMax, tPos);
    if((posMax < 0) || ((!useOnePeak)&&(tPos < posMax))) {
      posMax = tPos;
      primerHeight = tMax;
    }
  }	
  if(useOnePeak) {
    posMax = tPos;
    primerHeight = tMax;
  }

  peakPos = posMax;

  if([self debugmode]) fprintf(stderr,"primerPos=%d, primerHeight=%f\n", posMax, primerHeight);
  
  /** check if primerHeight is 'detector maxed out' and extend to end of maxed out region
    ** assumes that maxedout region of primer only extends a max of 200 points, and that
    ** a second primer might occur within that region**/
  {
    BOOL  thisPosChange=NO;

    pointCount = [traceData length];
    tPos = peakPos;
    for(i=peakPos; ((i<pointCount-1) && (i<peakPos + 200)); i++) {
      thisPosChange = NO;
      for (chan=0; chan<numChannels; chan++) {
        //if([traceData sampleAtIndex:i channel:chan] != primerHeight) thisPosChange=YES;
        if([traceData sampleAtIndex:i channel:chan] == primerHeight) tPos = i;
      }
    }
    primerMaxoutLen = tPos - peakPos;
    if([self debugmode]) fprintf(stderr, "primerMaxoutLen=%d\n", primerMaxoutLen);
    peakPos = tPos;
    if([self debugmode]) fprintf(stderr, "newPrimer end location=%d\n", peakPos);
  }

      
  /** of the next minima inflection ocurring right after primer
  ** pick the one farthest into the run **/
  minPos = peakPos;
  pointCount = [traceData length];
  for (chan=0; chan<numChannels; chan++) {
    tPos = minPos;
    for(i=peakPos; i<pointCount-1; i++) {
      if([traceData sampleAtIndex:i channel:chan] <
         [traceData sampleAtIndex:i+1 channel:chan]) { //not == in case maxed-out detector
        tPos = i;
        break;
      }
    }
    //NSLog(@"chan:%d  min:%d\n",chan, tPos);
    if(tPos > minPos) minPos=tPos;
  }
  valleyPos = minPos;
  if([self debugmode]) fprintf(stderr,"found primer peak at %d, valley at %d\n",peakPos, valleyPos);
  [self calcBackgroundError:traceData];
  [self findLastSignal:traceData];
  [numObj release];
}

- (void)calcBackgroundError:(Trace*)traceData
{
  float    mean, min, max, stddev, variance, ftemp, avedev;
  int      i, chan, numChannels=[traceData numChannels];
  int      start, end;
		
  if(peakPos == -1) return;
  start = peakPos * 0.1;
  end = peakPos * 0.6;
  if([self debugmode]) fprintf(stderr,"calc background error from %d to %d\n", start, end);

  for (chan=0; chan<numChannels; chan++) {
    mean = min = max = [traceData sampleAtIndex:start channel:chan];
    for(i=start+1; i<=end; i++) {
      ftemp = [traceData sampleAtIndex:i channel:chan];
      if(ftemp > max) max = ftemp;
      if(ftemp < min) min = ftemp;
      mean += ftemp;
    }
    mean = mean / (end-start+1);

    variance = 0.0;
    avedev = 0.0;
    for(i=start; i<=end; i++) {
      ftemp = ([traceData sampleAtIndex:i channel:chan] - mean);
      variance += ftemp*ftemp;
      avedev += abs(ftemp);
    }
    variance = variance / (end - start);
    avedev = avedev / (end - start + 1);
    stddev = sqrt(variance);
    //fprintf(stderr,"min=%f,  max=%f,  mean=%f, var=%f\n",min,max,mean,variance);
    //fprintf(stderr," avedev=%f, stddev=%f\n", avedev, stddev);
    error[chan] = stddev;
  }
}

- (void)findLastSignal:(Trace*)traceData
{
  int     i, chan, numChannels=[traceData numChannels];
  float   signalToNoise;
  int     start, end, tPos;	
		
  if(peakPos == -1) return;
  start = valleyPos;
  end = [traceData length] - 1;
  signalCutoff = end;
  dataLength = end;

  for (chan=0; chan<numChannels; chan++) {
    end = [traceData length] - 1;
    tPos=start;
    for(i=start; i<end; i++) {
      signalToNoise = [traceData sampleAtIndex:i channel:chan] / (error[chan]*2.0);
      if(signalToNoise > 3.0) {
        tPos = i;
      }
    }
    if([self debugmode]) fprintf(stderr,"signal end %d: %d\n", chan, tPos);
    if(tPos < signalCutoff) signalCutoff=tPos;
  }	
  if([self debugmode]) fprintf(stderr,"signal cutoff at %d\n", signalCutoff);
}

- apply
{
  [self setStatusMessage:@"Deleting Primer"];
  [self findPrimerPeak:dataList];
  if([self debugmode]) fprintf(stderr,"delete primer at %d; signalCutoff:%d\n", valleyPos, signalCutoff);

  if(performSignalCutoff && (signalCutoff > 0))
    [dataList setLength:signalCutoff];
  [dataList removeSamples:valleyPos+1 atIndex:0];
  [self setStatusMessage:nil];

  return [super apply];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];
  [aDecoder decodeValuesOfObjCTypes:"i",&useOnePeak];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];
  [aCoder encodeValuesOfObjCTypes:"i",&useOnePeak];
}

- (NSString *)toolName
{
  return @"Primer Peak Deletion-2.3";
}

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"useOnePeak"))
    [archiver readData:&useOnePeak];
  else if (!strcmp(tag,"peakPos"))
    [archiver readData:&peakPos];
  else if (!strcmp(tag,"valleyPos"))
    [archiver readData:&valleyPos];
  else if (!strcmp(tag,"signalCutoff"))
    [archiver readData:&signalCutoff];
  else if (!strcmp(tag,"dataLength"))
    [archiver readData:&dataLength];
  else if (!strcmp(tag,"performSignalCutoff"))
    [archiver readData:&performSignalCutoff];
  else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&useOnePeak type:"c" tag:"useOnePeak"];
  //the following do not need to be archived; they are dynamically generated
  //[archiver writeData:&peakPos type:"i" tag:"peakPos"];
  //[archiver writeData:&valleyPos type:"i" tag:"valleyPos"];
  //[archiver writeData:&signalCutoff type:"i" tag:"signalCutoff"];
  //[archiver writeData:&dataLength type:"i" tag:"dataLength"];
  [archiver writeData:&performSignalCutoff type:"c" tag:"performSignalCutoff"];

  [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolDeletePrimer2     *dupSelf;
  int                   i;

  dupSelf = [super copyWithZone:zone];

  dupSelf->useOnePeak = useOnePeak;
  dupSelf->performSignalCutoff = performSignalCutoff;
  dupSelf->peakPos = peakPos;
  dupSelf->valleyPos = valleyPos;
  dupSelf->signalCutoff = signalCutoff;
  dupSelf->dataLength = dataLength;
  for(i=0; i<8; i++)
    dupSelf->error[i] = error[i];

  return dupSelf;
}

@end
