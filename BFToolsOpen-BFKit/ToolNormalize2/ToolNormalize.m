 /* "$Id: ToolNormalize.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolNormalize.h"
#import <GeneKit/NumericalObject.h>


@implementation ToolNormalize2

- (void)calcSignalStrength
{
  int      i, numChannels=[dataList numChannels];
  float    total;
  int      chan, pointCount;

  pointCount = [dataList length];
  for (chan=0; chan<numChannels; chan++) {
    total = 0.0;
    for(i=0; i<pointCount; i++) {
      total += [dataList sampleAtIndex:i channel:chan];
    }
    total *= 4.0;
    sigAverage[chan] = (total / pointCount);
    if([self debugmode]) fprintf(stderr," average[%d] %f\n", chan, sigAverage[chan]);
  }	
}

- (float)calcBackgroundAverage:(int)chan :(float)backPercent
{
  //to correctly adjust the observed average into a peak average we need to
  //know the background average.
  //Calc from histogrammed data.

  int               dist[1004];
  int               i, total, pointCount, count;
  float             cutoff, min, range, max;
  float             *pointArray, dataTotal=0.0;
  NumericalObject   *numObj = [NumericalObject new];

  if([self debugmode]) fprintf(stderr,"   Background average %f%%",backPercent*100.0);

  pointCount = [dataList length];
  if([dataList isProxy]) {
    pointArray=(float*)malloc(sizeof(float)*(pointCount+1));
    for(i=0; i<pointCount; i++)
      pointArray[i] = [dataList sampleAtIndex:i channel:chan];
  } else
    pointArray = [dataList sampleArrayAtChannel:chan];

  [numObj histogram2:pointArray :pointCount :dist :1000];

  max = [numObj maxVal:pointArray numPoints:pointCount];
  min = [numObj minVal:pointArray numPoints:pointCount];
  range = max - min;

  total = 0;
  i = -1;
  do {
    i += 1;
    total += dist[i];
  } while (total < (int)(pointCount * backPercent));
  if (i < 0) i = 0;
  cutoff = min + range/1000.0 * (double)i;

  if([self debugmode]) fprintf(stderr, " cutoff=%f ", cutoff);

  dataTotal = 0.0;
  count = 0;
  for (i = 0; i < pointCount; i++) {
    if (pointArray[i] < cutoff) {
      dataTotal += pointArray[i];
      count++;
    }
  }
  if([self debugmode]) fprintf(stderr, "count=%d/%d ave=%f\n",pointCount, count, dataTotal/(float)count);

  if([dataList isProxy]) free(pointArray);
  [numObj release];
  return dataTotal/(float)count;
}

- adjustToBaseContent
{
  //without this routine the signal averages are based statistically on
  //equal distributions of each base (ie 25% of each one).  If one base
  //is under-represented, its average will be lower due to the fact that
  //there is more baseline signal than on average
  int        totalBases = [baseList seqLength];
  int        baseCount[4]={0,0,0,0}, i, chan;
  Base       *tempBase;
  float      basePercent, backAve;

  if([self debugmode]) fprintf(stderr, " ajustToBaseContent (%d bases)\n", totalBases);
  for(i=0; i<totalBases; i++) {
    tempBase = (Base *)[baseList baseAt:i];
    (baseCount[[tempBase channel]])++;
  }
  for(chan=0; chan<4; chan++) {
    basePercent = (float)(baseCount[chan])/(float)totalBases;
    if([self debugmode]) fprintf(stderr, "  chan %d: %d  %f\n", chan, baseCount[chan], basePercent);
    backAve = [self calcBackgroundAverage:chan :(1.0-basePercent)];

    if([self debugmode]) fprintf(stderr, "    obsAve=%f  ", sigAverage[chan]);
    sigAverage[chan] = (sigAverage[chan] - (1.0-basePercent)*backAve)/basePercent;
    if([self debugmode]) fprintf(stderr, "peakAve=%f\n", sigAverage[chan]);
  }
  return self;
}

- apply
{	
  int                i, chan, pointCount, numChannels=[dataList numChannels];
  float              maxChanSig=0.0, scaleFactor;
  float              *pointArray=NULL;
  NumericalObject    *numObj = [NumericalObject new];
  
  //NSLog(@"%@", [self toolName]);
  //fprintf(stderr," baselist=%d\n",(int)baseList);
  [self setStatusMessage:@"Normalizing"];
  if([self debugmode]) printf("Signal Average Normalization\n");
  [self calcSignalStrength];
  if([baseList seqLength] > 0) [self adjustToBaseContent];
  for(chan=0;chan<numChannels;chan++) {
    if(sigAverage[chan] > maxChanSig) maxChanSig = sigAverage[chan];
  }
  if([self debugmode]) fprintf(stderr," maxAverage %f\n", maxChanSig); fflush(stderr);

  pointCount = [dataList length];
  if([dataList isProxy]) pointArray=(float*)malloc(sizeof(float)*(pointCount+1));
  
  for(chan=0;chan<numChannels;chan++) {
    if([dataList isProxy]) {
      for(i=0; i<pointCount; i++)
        pointArray[i] = [dataList sampleAtIndex:i channel:chan];
    } else
      pointArray = [dataList sampleArrayAtChannel:chan];

    scaleFactor = maxChanSig / sigAverage[chan];
    [numObj normalizeBy:scaleFactor :0.0 :pointArray :pointCount];

    if([dataList isProxy])
      for(i=0; i<pointCount; i++)
        [dataList setSample:pointArray[i] atIndex:i channel:chan];
  }
  if([dataList isProxy]) free(pointArray);
  [numObj release];
  [self setStatusMessage:nil];
  return [super apply];
}

- (NSString *)toolName
{
  return @"Normalization 2.1: Signal Average";
}

/*****
* NSCopying section
*   no need to implement because tool doesn't have any of it's own
*   instance variables that need to be copied. Super's copy method is fine 
******/

@end
