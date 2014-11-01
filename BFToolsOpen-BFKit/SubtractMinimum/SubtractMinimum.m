/* "$Id: SubtractMinimum.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "SubtractMinimum.h"
#import <GeneKit/NumericalRoutines.h>


@implementation SubtractMinimum

- init
{
  return [super init];
}

- apply
{	
  int		channel, numPoints, i;
  float		min, *dataArray=NULL;

  fprintf(stderr,"SubtractMinimum ");
  numPoints = [dataList length];
  if([dataList isProxy])
    dataArray = (float *)calloc(numPoints, sizeof(float));
  
  for(channel=0; channel<[dataList numChannels]; channel++) {
    if(selChannels[channel]) {
      if([dataList isProxy]) {
        for(i=0; i<numPoints; i++) dataArray[i] = [dataList sampleAtIndex:i channel:channel];
      } else
        dataArray = [dataList sampleArrayAtChannel:channel];
      min = minVal(dataArray, numPoints);
      fprintf(stderr, "%d:%f  ", channel, min);

      for(i=0; i<numPoints; i++) {
        [dataList setSample:(dataArray[i]-min) atIndex:i channel:channel];
      }
    }
  }
  fprintf(stderr,"\n");
  return [super apply];
}

- (NSString *)toolName
{
  return @"Subtract Minimum";
}
@end
