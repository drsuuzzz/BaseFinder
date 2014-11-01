/* "$Id: ConvolveExt.m,v 1.2 2006/08/04 20:31:29 svasa Exp $" */
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

#import <ConvolveExt.h>
#import <ScalingExt.h>

#define C(t, I, SIGC, A)	((I) * exp(-(1/(2 * (SIGC*SIGC))) * (t*t)) - (A))

@protocol UpdateBoxProtocol
- (BOOL)updatePercent:sender :(float)percent;
@end

@implementation NumericalObject(ConvolveExt)

- (void)Zconvolve:(float*)numbers
        numPoints:(int)numPoints :(float)FWHM :(float)M :(float)offsetPcent :(float)rangePcent
                 :(id)updateBox :(id)sender
{
  float A=0.0;
  float Ioc = 1;
  int j,k;  		/* Loop Variables */
  float  result[numPoints];
  int t, update;
  float *gaussian, *middle;


  /* calculate area A of integral */
  //A = sqrt(Pi/2) * (Ioc * FWHM / M ) * erf( M / (sqrt(2) * FWHM));
  //!Needs fixing!!	
  gaussian = calloc(((int)M)*2+1, sizeof(float));
  middle = gaussian + ((int)M);
  for (k = -(int)M; k <= (int)M; k++)
    middle[k] = C((float)k,Ioc,FWHM,A);

  /* Convolution Loop */
  update = numPoints/40;
  for (j = 0; j < numPoints; j++) {
    if ((j%update) == 0)
      [updateBox updatePercent:sender :(float)(offsetPcent*100 + rangePcent*j*100/numPoints)];	
    result[j] = 0;
    for (k = -(int)M; k <= (int)M; k ++) {
      t = (j + k);
      if (t < 0)
        t = 0;
      if (t > numPoints)
        t = numPoints;
      result[j] += numbers[t] * middle[k];
    }
    if (result[j] < 0) result[j] = 0;
  }
  [updateBox updatePercent:sender :(float)(offsetPcent*100 +
                                           rangePcent*100)];
  for (j = 0; j < numPoints; j++)
    numbers[j] = result[j];

  free(gaussian);
}

- (void)convolve:(float*)array numPoints:(long)size :(float)sig :(int)M
{

  register float sum;
  float *temp=NULL;
  int i, j;
  float *conv=NULL;
  float *center;

  temp = (float *) calloc(size, sizeof(float));
  conv = (float *) calloc(M*2+1, sizeof(float));

  center = &conv[M];
  for (j = -M; j <= M; j++)
    center[j] = C((float)j, 1, sig, 0);

  for (i = M; i < (size-M); i++) {
    //if ((i % (size / 10)) == 0)
    //fprintf(stderr,".%0.0f%%", rint(((double)i/size)*100));
    sum = 0;
    for (j = -M; j <= M; j++)
      sum += array[i + j] * center[j];
    temp[i] = sum;
  }
  for (i = M; i < (size - M); i++)
    array[i] = temp[i];

  free(temp);
  free(conv);
}

@end
