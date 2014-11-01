
/* "$Id: DeconvolutionTool.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import "DeconvolutionTool.h"
#import "SpreadFunc1.h"
#import <string.h>
#import <stdio.h>
#include <sys/types.h>
#include <time.h>
#import <GeneKit/NumericalObject.h>

/*****
* August 9, 1994 Jessica Severin
* Second Generation mobility shift routines.
*****/

@implementation DeconvolutionTool

- init
{
  [super init];
  spreadFunctionID = [[SpreadFunc1 alloc] init];
  baseList = NULL;
  numIterations=25;
  alpha = 0.25;
  return self;
}

- (NSString *)defaultLabel
{
  return @"Default Spread Function";
}

- (NSString *)toolName
{
  return @"Deconvolution-0.6";
}

/****
*
* resource handling section (subclass of ResourceTool must implement)
*
****/

- (void)writeResource:(NSString*)resourcePath
{
  AsciiArchiver    *archiver;

  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:spreadFunctionID tag:"spreadFunctionID"];
  [archiver writeToFile:resourcePath atomically:YES];
  [archiver release];
}

- (void)readResource:(NSString*)resourcePath
{
  id    archiver, tempFunc;
  char  tagBuf[MAXTAGLEN];

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:resourcePath];
  if(!archiver) return;

  [archiver getNextTag:tagBuf];

  if(strcmp(tagBuf, "spreadFunctionID") != 0) {
    fprintf(stderr, "DeconvolutionTool: resource file does not have a 'spreadFunctionID' object\n");
    fprintf(stderr, "  tag='%s'\n", tagBuf);
    return;
  }

  if ((tempFunc=[archiver readObject])!=nil) {
    if(spreadFunctionID) [spreadFunctionID release];
    spreadFunctionID = [tempFunc retain];
  }
  //spreadFunctionID = [archiver readObjectWithTag:"spreadFunctionID"];
  [archiver release];
  return;
}

/****/

- (BOOL)modifiesData { return YES; }		//to switch between processor/analyzer
- (BOOL)shouldCache { return YES; }

- createSimData
{
  int      ti, numChannels;
  double   spread;
  float    tempFloat;

  numChannels = [[self dataList] numChannels];
  for(ti=1; ti<numChannels; ti++)
    [[self dataList] removeChannel:ti];
  [[self dataList] setLength:100];

  [spreadFunctionID calcScalesForRange2:0.0 :200.0];
  for(ti=0; ti<100; ti++) {
    spread = 5.0 * [spreadFunctionID valueAtTime:(float)ti  expectedTime:40.0];
    spread += 5.0 * [spreadFunctionID valueAtTime:(float)ti expectedTime:50.0];
    spread += 5.0 * [spreadFunctionID valueAtTime:(float)ti expectedTime:60.0];

    tempFloat = (float)(spread);
    [[self dataList] setSample:tempFloat atIndex:ti channel:0];
  }
  [spreadFunctionID deallocScales];
  return self;
}

- apply
{	
  Trace		     *observedData=[self dataList];
  NSMutableData      *dataCacheThis, *dataCacheNext, *tempID;
  int                numPoints, chan, numChannels, ti, tej, iteration, i;
  int                deleteOffset = [observedData deleteOffset];
  int                tejStart, tejEnd;
  double             total, spreadValue, lambda;
  float              tempFloat, maxData, *thisArray, *nextArray, *observedArray=NULL;
  time_t             startTime;

  [self setStatusMessage:@"Deconvolution: Calc. spread scaling"];

  //[self createSimData];
  //return self;

  numPoints = [observedData length];
  numChannels = [observedData numChannels];

  [spreadFunctionID calcScalesForRange2:deleteOffset :numPoints+deleteOffset];

  //[spreadFunctionID generatePlotData];
  //printf(" at 3000 = %f\n", (float)[spreadFunctionID valueAtTime:3000.0 expectedTime:3000.0]);
  //return self;

  startTime = time(NULL);
  if([observedData isProxy])
    observedArray = (float *)calloc(numPoints, sizeof(float));

  [self setStatusMessage:@"Deconvolution"];
  [self setStatusPercent:1.0];
  for(chan=0; chan<numChannels; chan++) {
    if([self debugmode]) printf("deconvolution for channel %d\n",chan);

    if([observedData isProxy]) {
      for(i=0; i<numPoints; i++)
        observedArray[i] = [observedData sampleAtIndex:i channel:chan];
    } else
      observedArray = [observedData sampleArrayAtChannel:chan];

    maxData = -FLT_MAX;
    for (i = 0; i < numPoints; i++) {
      if (observedArray[i] > maxData) maxData = observedArray[i];
    }
    if([self debugmode]) printf(" maxVal = %f\n", maxData);

    /*****
    * Start of Iteration Section
    *****/
    // At initial iteration, start with observed data
    dataCacheThis = [NSMutableData  dataWithBytes:observedArray length:sizeof(float)*numPoints];
    dataCacheNext = [NSMutableData  dataWithBytes:observedArray length:sizeof(float)*numPoints];
    thisArray = (float*)[dataCacheThis mutableBytes];
    nextArray = (float*)[dataCacheNext mutableBytes];

    for(iteration=0; iteration<numIterations; iteration++) {
      // this is to calculate the iterative deconvolution
      // f(m+1) = f(m) + lamda*(g - H . f(m))
      // where f,g are vectors and H is a matrix

      //[self setStatusMessage:
      //  [NSString stringWithFormat:@"Chan %d, Iteration %d:%d",chan+1, iteration+1, numIterations]];
      {
        float   percent;

        percent = iteration+1 + chan*numIterations;
        [self setStatusPercent:percent/(float)(numChannels*numIterations)*100.0];
        if([self debugmode]) printf("  iteration %d/%d\n", iteration, numIterations);
      }

      thisArray = (float*)[dataCacheThis mutableBytes];
      nextArray = (float*)[dataCacheNext mutableBytes];

      for(ti=0; ti<numPoints; ti++) {
        total = 0.0;

        // first do H dot_product f(m);
        // Original_full_calc: tej=0; tej<numPoints; tej++;
        tejStart=(ti-20);
        if(tejStart < 0) tejStart=0;
        tejEnd=(ti+20);
        if(tejEnd > numPoints) tejEnd=numPoints;
        for(tej=tejStart; tej<tejEnd; tej++) {
          //will probably need to reduce this loop to relevent data
          spreadValue = [spreadFunctionID valueAtTime:(float)(ti+deleteOffset)
                                         expectedTime:(float)(tej+deleteOffset)];
          //spreadValue = 0.0;
          total += spreadValue * thisArray[tej];
        }
        // printf("   H(%d, %d)=%f   fm(tej) = %f\n", ti, tej, (float)spreadValue);

        // now do g - H _dot_ f(m)
        total = observedArray[ti] - total;

        // now calc lambda and do lamda*(g - H _dot_ f(m))
        lambda = 1.0 - exp(-thisArray[ti]/(maxData*alpha));
        total = lambda * total;

        // now finish f(m) + lambda*(g - H _dot_ f(m))
        total = thisArray[ti] + total;

        // now store this in f(m+1) cache		
        tempFloat = (float)total;
        nextArray[ti] = tempFloat;
      }

      // this iteration is done, so move dataCacheNext into dataCacheThis for
      // next iteration
      tempID = dataCacheNext;
      dataCacheNext = dataCacheThis;
      dataCacheThis = tempID;
    }

    // done with this channel, so copy the final result of the iteration cache
    // back into dataList of this channel
    thisArray = (float*)[dataCacheThis mutableBytes];
    for(ti=0; ti<numPoints; ti++) {
      //tempFloat = [dataCacheThis elementAt:ti];
      tempFloat = thisArray[ti];
      [dataList setSample:tempFloat atIndex:ti channel:chan];
    }

    //[dataCacheThis release];
    //[dataCacheNext release];
  }
  if([observedData isProxy]) free(observedArray);

  if([self debugmode]) printf("deconvolve time = %f secs\n", (float)(time(NULL)-startTime));

  [self setStatusMessage:nil];  //clears status display
  [self setStatusPercent:0.0];
  [spreadFunctionID deallocScales];
  return [super apply];
}

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
  if (!strcmp(tag,"spreadFunctionID")) {
    spreadFunctionID = [[archiver readObject] retain];
  } else if (!strcmp(tag,"numIterations")) {
    [archiver readData:&numIterations];
  } else if (!strcmp(tag,"alpha")) {
    [archiver readData:&alpha];
  } else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeObject:spreadFunctionID tag:"spreadFunctionID"];
  [archiver writeData:&numIterations type:"i" tag:"numIterations"];
  [archiver writeData:&alpha type:"f" tag:"alpha"];
  [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  DeconvolutionTool     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  //if(dupSelf->spreadFunctionID != nil) [dupSelf->spreadFunctionID release];
  dupSelf->spreadFunctionID = [spreadFunctionID copy];
  dupSelf->numIterations = numIterations;
  dupSelf->alpha = alpha;
  return dupSelf;
}

- (void)dealloc
{
  [spreadFunctionID autorelease];
  [super dealloc];
}

@end
