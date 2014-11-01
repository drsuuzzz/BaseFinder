/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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
#import "gaussian.h"
#import <GeneKit/ghist.h>
#import <math.h>
#define sqr(x) ((x)*(x))
#define Sqrt2	1.4142136
#define FIT_SCALE_FACTOR 0.7

@implementation Gaussian

+ (id)GaussianWithWidth:(float)_width scale:(float)_scale center:(float)_center
{
	id temp;
	temp = [[self alloc] init];
	[temp setCenter:_center];
	[temp setWidth:_width];
	[temp setScale:_scale];
	return [temp autorelease];
}

+ (id)GaussianFittedFrom:(unsigned)start to:(unsigned)end toData:(MGMutableFloatArray *)array 
{
  Gaussian *tempgauss;

  if (array == NULL)
    return NULL;
  tempgauss = [[[Gaussian alloc] init] autorelease];
  tempgauss->residual = fitgauss([array floatArray], (long)[array count],
           start, end, &tempgauss->width, &tempgauss->center, &tempgauss->scale);
  tempgauss->width *= FIT_SCALE_FACTOR;
//  tempgauss->center += start - 1;
  return tempgauss;
 }

- init
{
  residual = 0;
	annotation = nil;
  return self;
}

- (void) dealloc
{
	if (annotation != nil)
		[annotation release];
	[super dealloc];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"{center = %f; width = %f; height = %f; residual = %f; area = %f; }", center, width, scale, residual, [self area]];
}

- (float)valueAt:(float)x
{
  return scale * (float)exp((double)(-((center - x) * (center-x))/
                                     (2*(width* width))));
}

- (float)center
{
  return center;
}

- (float)area
{
    return (scale  * width * width);
}

- (float)position
{
  return center;
}

- (float)width
{
  return width;
}

- (float)scale
{
  return scale;
}

- (float)height
{
  return scale;
}

- (NSString *)annotation
{
	return annotation;
}

- (float)error
{
  return residual;
}

- (float)fitResidual
{
  return residual;
}

- (void)setSkew:(float)skew;
{
  return;
}

- (float)skew
{
  return 0.0;
}

- (void)setCenter:(float)val;
{
	center = val;
}

- (void)setPosition:(float)pos
{
  center = pos;
}

- (void)setWidth:(float)val
{
  width = val;
}

- (void)setScale:(float)val
{
  scale = val;
}

- (void)setHeight:(float)hgt
{
  scale = hgt;
}

- (void)setAnnotation:(NSString *)aString
{
	if (annotation != nil) [annotation release];
	annotation = [[NSString alloc] initWithString:aString];
}

- (int)channel
{
  return channel;
}

- (void)setChannel:(int)chan
{
  channel = chan;
}

- (float)startExtent
{
  return (center - (width * WIDTH_CUTOFF));
}

- (float)endExtent
{
  return (center + (width * WIDTH_CUTOFF));
}


- (void)subtractFromData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff;
{
  int diff, rightlimit, leftlimit, i;
  float *data;

  diff = (int) width * sqrt(log(1/cutoff));
  rightlimit = (int) ceil((double)center + (double)diff);
  leftlimit = (int) floor((double)center - (double)diff);
  if (leftlimit < 0) leftlimit = 0;
  if (rightlimit < 0) rightlimit = 0;
  if ((rightlimit - leftlimit) <= 0)
    return;
  if (leftlimit >= (int)[theData count]) return;
  if (rightlimit >= [theData count])
    rightlimit = [theData count] - 1;
  data = [theData floatArray];
  for (i = leftlimit; i <= rightlimit; i++)
    {
    data[i] = data[i] - [self valueAt:(float)i];
    if (data[i] < 0) data[i] = 0;
    }
}

- (void)addToData:(MGMutableFloatArray *)theData withCutoff:(float)cutoff
{
  int diff, rightlimit, leftlimit, i;
  float *data;

  diff = (int) width * sqrt(log(1/cutoff));
  rightlimit = (int) ceil((double)center + (double)diff);
  leftlimit = (int) floor((double)center - (double)diff);
  if (leftlimit < 0) leftlimit = 0;
  if (rightlimit < 0) rightlimit = 0;
  if ((rightlimit - leftlimit) <= 0)
    return;
  if (leftlimit >= (int)[theData count]) return;
  if (rightlimit >= [theData count])
    rightlimit = [theData count] - 1;
  data = [theData floatArray];
  for (i = leftlimit; i <= rightlimit; i++)
    {
    data[i] = data[i] + [self valueAt:(float)i];
    if (data[i] < 0) data[i] = 0;
    }
}


- (id)copyWithZone:(NSZone *)zone
{
    Gaussian     *dupSelf;

    dupSelf = [super copyWithZone:zone];

    dupSelf -> center = center;
    dupSelf -> width = width;
    dupSelf -> scale = scale;
    dupSelf -> residual = residual;
		if (annotation != nil)
			dupSelf -> annotation = [annotation copy];

    return dupSelf;
}


@end
