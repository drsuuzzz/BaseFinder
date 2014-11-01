/* "$Id: ScalingExt.m,v 1.2 2006/08/04 20:31:56 svasa Exp $" */
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

#import <ScalingExt.h>


@implementation NumericalObject(ScalingExt)

- (float)maxVal:(float*)array  numPoints:(int)numPoints
{
  float max=-FLT_MAX;
  int i;

  for (i = 0; i < numPoints; i++) {
    if (array[i] > max)
      max = array[i];
  }
  return max;
}

- (float)minVal:(float*)array numPoints:(int)numPoints
{
  float min=FLT_MAX;
  int i;

  for (i = 0; i < numPoints; i++) {
    if (array[i] < min)
      min = array[i];
  }
  return min;
}

- (float)geommean:(float*)values :(float*)weights :(int)count :(float)sum
{
  float denom=0;
  int i;

  for (i = 0; i < count; i++)
    if (values[i] != 0.0)
      denom	+= (1/values[i])*weights[i];
  if (denom == 0)
      return 0;
  else
      return(sum/denom);
}

- (float)wmean:(float*)values :(float*)weights :(int)count
{
    float denom=0, num=0;
    int i;

    for (i = 0; i < count; i++) {
        num	+= values[i]*weights[i];
        denom 	+= weights[i];
    }
    if (denom == 0)
        return 0;
    else
        return(num/denom);

}



- (float)scaleFactor:(float)lowBound :(float)highBound :(float*)array :(int)numPoints
{
  float max, min, multiplier,width;

  max = [self maxVal:array numPoints:numPoints];
  min = [self minVal:array numPoints:numPoints];
  width = max - min;
  if (width == 0)
    multiplier = 0;
  else
    multiplier = (float)fabs((double)highBound-lowBound)/width;

  return multiplier;
}

- (void)normalizeBy:(float)scale :(float)lowBound :(float*)array :(int)numPoints
{
  int i;
  float min;

  min = [self minVal:array numPoints:numPoints];

  for (i = 0; i < numPoints; i++)
    array[i] = (array[i]-min)  * scale + lowBound;
}

- (void)normalizeWithCommonScale:(Trace*)data
{	
  float 	scale, *dataArray;
  float 	smallestscale=FLT_MAX;
  int 		channel, j, numChannels, numPoints;

  numChannels = [data numChannels];
  numPoints = [data length];
  dataArray = (float *)calloc(numPoints, sizeof(float));
  for (channel=0; channel<numChannels; channel++) {
    for(j=0; j<numPoints; j++)
      dataArray[j] = [data sampleAtIndex:j channel:channel];
    scale = [self scaleFactor:0.0 :1.0 :dataArray :numPoints];
    if (scale < smallestscale)
      smallestscale = scale;
  }
  if (smallestscale!=1.0) {
    for (channel=0; channel<numChannels; channel++) {
      for(j=0; j<numPoints; j++)
        dataArray[j] = [data sampleAtIndex:j channel:channel];
      [self normalizeBy:smallestscale :0.0 :dataArray :numPoints];

      //[[data objectAt:channel] autoCalcParams];
      for(j=0; j<numPoints; j++)
        [data setSample:dataArray[j] atIndex:j channel:channel];
    }
  }
  free(dataArray);
}

@end
