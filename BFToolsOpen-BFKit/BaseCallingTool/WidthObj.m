/* "$Id: WidthObj.m,v 1.2 2006/11/21 19:39:31 smvasa Exp $" */
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

#import "WidthObj.h"
#import <GeneKit/NumericalObject.h>
#import <GeneKit/Sequence.h>

//#import "SeqList.h"

#define LOWCUTOFF	40.0          // has to be this % near minimum to count
#define HIGHCUTOFF 60.0         // has to be this % near maximum to count



#ifdef OLDCODE
float expectedMaxHeight(int channel, int location)
{
  return(maxPoly[channel][0] + maxPoly[channel][1] * (float)location +
         maxPoly[channel][2]*location*location);
}

float expectedMinHeight(int channel, int location)
{
  return(minPoly[channel][0] + minPoly[channel][1] * (float)location +
         minPoly[channel][2]*location*location);
}




int countmax(int location, float *nums, int channel)
{
//	if (nums[location] > expectedMaxHeight(channel, location) -
//							((1-HIGHCUTOFF)/100) * 
//							abs(expectedMaxHeight(channel, location)))
		return TRUE;
//	else
//		return FALSE;
}
#endif






@implementation WidthObj

- init
{
  [super init];
  thebaseList = nil;
  thedataList = nil;
  return self;
}

- initwithWeight:(float)Weight minConfidence:(float)conf
{
        [self init];
	weight = Weight;
	lowConfThresh = conf;
	return self;
}

- (void)setWeight:(float)Weight
{
	weight = Weight; 
}

- setupMinMax:(id)baseList :(id)Data
{
  return self;
}

float aveWidth;

- (void)setupConfidences:(Sequence *)baseList :(Trace *)Data
{	
  int numMaxima;
  Base	*theBase;
  int numChannels;
  int i, numFragments;
  float width, sum=0;
  NumericalObject   *numObj = [[NumericalObject new] autorelease];

  if (thebaseList)
    [thebaseList release];
  if (thedataList)
    [thedataList release];
  thebaseList = [baseList retain];
  thedataList = [Data retain];

  numMaxima = [baseList count];
  numChannels = [Data numChannels];

  aveWidth = 0;
  if (minPoly == NULL) {
    minPoly = malloc(numChannels * sizeof(float *));
    for (i = 0; i < numChannels; i++)
      minPoly[i] = calloc(POLYLEVEL, sizeof(float));
  }
  if (maxPoly == NULL) {
    maxPoly = malloc(numChannels * sizeof(float *));
    for (i = 0; i < numChannels; i++)
      maxPoly[i] = calloc(POLYLEVEL, sizeof(float));
  }
  // Set up the second order minimum and maximum curves for
  // reference.
//  NSLog(@"Width fitting");
  for (i = 0; i < numChannels; i++)
    [numObj secondOrderMaxFit:Data :i :maxPoly[i] :3];
  for (i = 0; i < numChannels; i++)
    [numObj secondOrderMinFit:Data :i :minPoly[i] :3];
  aveWidth = [self averagePeakWidth:Data :baseList];
//  NSLog(@"Width: %f\n", aveWidth);

  // Now, Allocate and fill the arrays of width information for poly fitting
  sum = 0;
  for (i = 0; i < 3; i++) {
    if(fitpoints[i] != NULL) free(fitpoints[i]);
    fitpoints[i] = (float *)calloc(numMaxima, sizeof(float));    
  }
  for (i = 0; i < numMaxima; i++) {
    theBase = (Base *)[baseList baseAt:i];
    width = (float)[self baseWidth:Data :[theBase channel] :[theBase location]];
    //numFragments = (int)rint(width/aveWidth);
    numFragments = (int)floor(width/aveWidth);
    if (numFragments <= 0)
      numFragments = 1;
    fitpoints[0][i] = (float)[theBase  location];
    fitpoints[1][i] = width/numFragments;
    fitpoints[2][i] = 1/([theBase floatConfidence]);
    sum += width/numFragments;
  }
  aveWidth = sum/numMaxima;

  [numObj polyFit:fitpoints[0] :fitpoints[1] :fitpoints[2] :numMaxima :polycoeffecients :POLYLEVEL];
}

- (float)wconfidenceAtBase:(int)base :(Sequence *)baseList :(Trace *)dataList
{
  int                location, leftmin, rightmin, numsharing=1, i, channel, count;
  float              expected, actual, *data;
  float              confidence;
  NumericalObject    *numObj = [[NumericalObject new] autorelease];


  location = [[baseList baseAt:base] location];
  expected = polycoeffecients[0] + polycoeffecients[1] * location +
    polycoeffecients[2] * location * location;
  channel = [[baseList baseAt:base] channel];
  data = [dataList sampleArrayAtChannel:channel];
  count = [dataList length];


  leftmin = [numObj lefthalfheightpoint:location :data :count];
  rightmin = [numObj righthalfheightpoint:location :data :count];

  for (i = (base-1); ((i >= 0) &&
                      ([[baseList baseAt:i] location] >= leftmin)) ; i--)
    if ([[baseList baseAt:i] channel] == channel)
      numsharing += 1;

  for (i = (base+1); ((i < [baseList count]) &&
                      ([[baseList baseAt:i] location] <= rightmin)); i++)
    if ([[baseList baseAt:i] channel] == channel)
      numsharing += 1;

  actual = (rightmin - leftmin)/numsharing;

  //	actual = baseWidth(dataList,
  //		((aBase *)[baseList elementAt:base])->channel,
  //		((aBase *)[baseList elementAt:base])->location);

  //	sprintf(tmp, "A:%f E:%f \n", actual, expected);
  //	[distributor addTextAnalysis:tmp];	
  if ((actual < expected) && (expected > 0))
    confidence = actual/expected;
  else
    confidence = 1;
  return (confidence);
}


- (float)widthAt:(int)baseNumber
{	
  int location;
  float expected;

  location = [[thebaseList baseAt:baseNumber] location];
  expected = polycoeffecients[0] + polycoeffecients[1] * location +
    polycoeffecients[2] * location * location;
  return (expected);
}


- (float)confWeight
{
	return weight;
}


- (float)returnWeightedConfidence:(int)baseNumber 
{	
  return ([self wconfidenceAtBase:baseNumber :thebaseList :thedataList]*weight);
}
	

- (float)returnConfidence:(int)baseNumber 
{	
  return [self wconfidenceAtBase:baseNumber :thebaseList :thedataList];

}


- (int) numberBasesAt:(int)baseNumber
{
	return 0;
}
- (float) returnDataConfidence:(int)location :(int)channel
{
	return 0;
}
 
 
- (float) expectedPeakWidth:(int)location :(int)channel
{
	return(polycoeffecients[0] + polycoeffecients[1] * location +
							polycoeffecients[2] * location * location);

}
- (float)peakWidth:(int)location :(int)channel
{
  NumericalObject   *numObj = [[NumericalObject new] autorelease];

  return([numObj peakwidth:location
                          :[thedataList sampleArrayAtChannel:channel] 
                          :[thedataList length]
                          :channel]);
}

- (int)baseWidth:(Trace *)theData :(int)channel :(int)location
{
  NumericalObject   *numObj = [[NumericalObject new] autorelease];
  return([numObj halfHeightPeakAveWidth:location
                                       :[theData sampleArrayAtChannel:channel]
                                       :[theData length]]);
}

-(float)averagePeakWidth:(Trace *)Data :(Sequence *)baseList
{	
  float sum=0, average;
  int count, i, channel;
  NumericalObject   *numObj = [[NumericalObject new] autorelease];

  count = [baseList count];
  for (i = 0; i < count; i++) {
    channel = [[baseList baseAt:i] channel];
    sum += [numObj halfHeightPeakAveWidth:[[baseList baseAt:i] location]
                                         :[Data sampleArrayAtChannel:channel]
                                         :[Data length]];
  }

  average = sum/count;
  return average;
}

- (void)dealloc
{
  int i;
  if (thebaseList)
    [thebaseList release];
  if (thedataList)
    [thedataList release]; 

  if (minPoly != NULL) {
    for (i = 0; i < 4; i++) free(minPoly[i]);
    free(minPoly);
  }
  if (maxPoly != NULL) {
    for (i = 0; i < 4; i++) free(maxPoly[i]);
    free(maxPoly);
  }
  if(fitpoints != NULL) for (i = 0; i < 3; i++) free(fitpoints[i]);
  [super dealloc];
}

@end 