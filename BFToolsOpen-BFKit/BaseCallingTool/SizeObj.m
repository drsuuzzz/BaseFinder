/* "$Id: SizeObj.m,v 1.2 2007/01/24 19:34:07 smvasa Exp $" */
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

#import "SizeObj.h"
#import <GeneKit/NumericalObject.h>
//#import "SeqList.h"


@implementation SizeObj


- initwithWeight:(float)Weight minConfidence:(float)conf
{
  [super init];
  weight = Weight;
  lowConfThresh = conf;
  counts = NULL;
  return self;
}

- (void)dealloc
{
  if (xArray != NULL) free(xArray);
  if (yArray != NULL) free(yArray);
  if (weightArray != NULL) free(weightArray);
  if (coeffecients != NULL) free(coeffecients);
  [super dealloc];
}

- (void)setupConfidences:(Sequence *)baseList :(Trace *)Data
{
  int numChannels,i, numMaxima, channel, index;
//  aBase *theBase;
  Base *theBase;
//  FILE *fp;
  NumericalObject   *numObj = [[NumericalObject new] autorelease];
  
  numMaxima = [baseList count];
  numChannels = [Data numChannels];

  if (xArray != NULL) free(xArray);
  if (yArray != NULL) free(yArray);
  if (weightArray != NULL) free(weightArray);
  //if (sizes != NULL) free(sizes);
  if (coeffecients != NULL) free(coeffecients);

  counts = calloc(numChannels, sizeof(int));
  xArray = calloc(numChannels * numMaxima, sizeof(float));
  yArray = calloc(numChannels * numMaxima, sizeof(float));
  weightArray = calloc(numChannels * numMaxima, sizeof(float));
  coeffecients = calloc(numChannels * 3, sizeof(float));

  for (i = 0; i < numMaxima; i++) {
    theBase = (Base *)[baseList baseAt:i];
    channel = [theBase channel];
    index = channel*numMaxima + counts[channel];
    xArray[index] = [theBase location];
    yArray[index] = [Data sampleAtIndex:[theBase location] channel:[theBase channel]];
//    *(float *)[(Storage*)[Data objectAt:channel] elementAt:theBase->location];
    weightArray[index] = 1/([theBase floatConfidence]);
    counts[channel] += 1;
  }

//  fp = fopen("sizes.out","a");
//  if(fp!=NULL) {
//    fprintf(fp, "------------\n");
    for (i = 0; i < numChannels; i++) {
      [numObj polyFit:&xArray[i*numMaxima]
                     :&yArray[i*numMaxima]
                     :&weightArray[i*numMaxima]
                     :counts[i]
                     :&coeffecients[3*i]
                     :3];
    }
//      fprintf(fp, "%e + %ex + %ex^2\n",
//              coeffecients[3*i],coeffecients[3*i+1], coeffecients[3*i+2]);
//    }
//    fclose(fp);
   
  
  thebaseList = baseList;
  thedataList = Data;
}

- (void)setWeight:(float)Weight
{
  weight = Weight;
}

- (float)confWeight
{
  return weight;
}

- (float)baseConfidence:(int)location :(int)channel :(Trace *)data
{
  int count, i;
  float sum=0, peak_size, target, absolute, response;

  count = [data numChannels];
  target = (coeffecients[3*channel] + coeffecients[3*channel+1] * location +
            coeffecients[3*channel+2] * location*location);
  response = [data sampleAtIndex:location channel:channel];
//  *(float *)[(Storage*)[data objectAt:channel] elementAt:location];
  peak_size = response/target;

  for (i = 0; i < count; i++) {
    if (!(((channel == 0) && (i == 2)) || ((channel == 2) && (i == 0))))
      sum += [data sampleAtIndex:location channel:i]/
//      ((Storage*)[data objectAt:i] elementAt:location])/
        (coeffecients[3*i] + coeffecients[3*i+1] * location +
         coeffecients[3*i+2] * location*location);
    else
      sum += 0.5 * [data sampleAtIndex:location channel:i]/
        (coeffecients[3*i] + coeffecients[3*i+1] * location +
         coeffecients[3*i+2] * location*location);
  }

  if (response < target)
    absolute = 1- fabs(response - target)/target;
  else
    absolute = 1;
  if (absolute < 0) absolute = 0;
  if (sum == 0)
    return 0;

  return( 	absolute * (peak_size / sum));
}


- (float)returnWeightedConfidence:(int)baseNumber
{	

  return ([self returnConfidence:baseNumber] * weight);
}


- (float)returnConfidence:(int)baseNumber
{


/*  int  location, channel;

  channel = [[theBaseList baseAt:baseNumber] channel];
  location = [[theBaseList baseAt:baseNumber] location]; */


  return [self baseConfidence:[[thebaseList baseAt:baseNumber] location] :[[thebaseList baseAt:baseNumber] channel] :thedataList];
}



- (float) returnDataConfidence:(int)location :(int)channel
{
  /*	int count, i;
  float sum=0, peak_size, target, absolute, response;

  count = [thedataList count];
  target = (coeffecients[3*channel] + coeffecients[3*channel+1] * location +
            coeffecients[3*channel+2] * location*location);
  response = *(float *)[[thedataList objectAt:channel] elementAt:location];
  peak_size = response/target;

  for (i = 0; i < count; i++) {
    sum += (*(float *)[[thedataList objectAt:i] elementAt:location])/
    (coeffecients[3*i] + coeffecients[3*i+1] * location +
     coeffecients[3*i+2] * location*location);
  }

  if (response < target)
  absolute = 1- fabs(response - target)/target;
  else
  absolute = 1;
  if (absolute < 0) absolute = 0;
  if (sum == 0)
  return 0;


  return( 	absolute * (peak_size / sum));

  */

  return [self baseConfidence:location :channel :thedataList];
}



- (void)setConfThresh:(float)thresh
{
  lowConfThresh = thresh;
}


@end
