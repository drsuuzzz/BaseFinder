/* "$Id: HistogramExt.m,v 1.2 2006/08/04 20:31:29 svasa Exp $" */
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

#import <HistogramExt.h>


@implementation NumericalObject(HistogramExt)

- (void)histogram:(float*)array :(int)numPoints :(int*)dist
{
  /*FILE *fp;
  int total=0;*/
  double max,min, range;
  int i;


  max = [self maxVal:array numPoints:numPoints];
  min = [self minVal:array numPoints:numPoints];
  range = max - min;

  if (range == 0) {
#ifdef	DEBUG_MSG
    fprintf(stderr, "Range has zero distribution. Can't calc. Histo");
#endif
    return;
  }

  for (i = 0; i <= 100; i++)
    dist[i] = 0;
  // There isn't an "rint" for windows so We'll try it with
  // Built in C rounding and see what happens
  for (i = 0; i < numPoints; i++)
    dist[(int)(100*(array[i]-min)/range)] += 1;
}

- (void)histogram2:(float*)array :(int)numPoints :(int*)dist :(int)numSlots
{
  double max,min, range;
  int i;

  max = [self maxVal:array numPoints:numPoints];
  min = [self minVal:array numPoints:numPoints];
  range = max - min;

  if (range == 0) return;

  for (i = 0; i <= numSlots; i++)
    dist[i] = 0;
  for (i = 0; i < numPoints; i++)
    dist[(int)((numSlots*(array[i]-min))/range)] += 1;
}


- (void)cutoffHistogram:(float*)array :(int)numPoints :(float)thresh :(int)type
{
  int		dist[101];
  int 		i, total;
  float 	cutoff, min, range, max;

  [self histogram:array :numPoints :dist];

  max = [self maxVal:array numPoints:numPoints];
  min = [self minVal:array numPoints:numPoints];
  range = max - min;

  /* type is bit coded.  Bit 1 turns on/off cutoff of low hist values.
    Bit 2 turns on/off cutoff of hi hist values.
    */
  if(type&1) {
    total = 0;
    i = -1;
    do {
      i += 1;
      total += dist[i];
    } while (total < (int) (numPoints * (thresh * 0.01)));
    if (i < 0)
      i = 0;
    cutoff = min + range * ((double) i) * 0.01;

    for (i = 0; i < numPoints; i++)
      if (array[i] < cutoff)
        array[i] = cutoff;
  }

  if(type&2) {
    total = 0;
    i = 101;
    do {
      i -= 1;
      total += dist[i];
    } while (total < (int) (numPoints * (thresh * 0.01)));
    if (i > 100)
      i = 100;
    cutoff = min + range * (double) i * 0.01;

    for (i = 0; i < numPoints; i++)
      if (array[i] > cutoff)
        array[i] = cutoff;
  }
}

- (void)dumpHistogram:(float*)array :(int)numPoints
{
  int i;
  FILE *fp;	
  int	dist[101];

  [self histogram:array :numPoints :dist];
  fp = fopen("Histogram","a");
  if(fp == NULL) return;

  fprintf(fp, "\n\nHistogram:\n");
  fprintf(fp, "%% range		# Points\n");
  for (i = 0; i <= 100; i++)
    fprintf(fp, "%d		%d\n", i, dist[i]);
  fclose(fp);
}

@end
