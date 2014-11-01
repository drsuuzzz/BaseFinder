
/* "$Id: SpreadFunc1.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import "SpreadFunc1.h"
#import <float.h>

@implementation SpreadFunc1

/***
*
* implementation of the SpreadFunctionProtocol object with 
* a fixed equation of the form 
*   sigma(tej) = a + bx + cx^2;
*		h(ti, tej) = N(tej) * Exp(-1*(ti - tej)^2/sigma(tej)^2)
*   N(tej) = 1 / Sum(ti=1,n)(h(ti,tej))
* where only the constants are archived
***/

- init
{
  A = 2.2951;
  B = 0.0006147;
  C = 0.0;
  scale=NULL;
  return self;
}

- (void)dealloc
{
  if(scale != NULL) free(scale);
  [super dealloc];
}

- (void)deallocScales
{
  if(scale != NULL) free(scale);
  scale = NULL;
}

- (void)calcScalesForRange:(int)start :(int)end
{
  int       ti, tej;
  double    sigma, sigma2, spread, total;

  if(scale != NULL) free(scale);
  //scale = (double*)malloc(sizeof(double) * (end-start+16));
  scale = (double*)malloc(sizeof(double) * (end+16));
  minRange = start;
  maxRange = end;

  for(tej=minRange; tej<maxRange; tej++) {
    sigma = A + B * tej + C*tej*tej;
    total = 0.0;
    sigma2 = sigma * sigma;
    for(ti=minRange-2*sigma; ti<maxRange+2*sigma; ti++) {
      spread = exp(-1 * (ti-tej)*(ti-tej)/sigma2);
      total += spread;
    }
    scale[tej] = 1.0 / total;
  }
}

- (void)calcScalesForRange2:(int)start :(int)end
{
  //reduce calculation by calculating the area under the sigma
  //by only calcing a multiple of sigma around the peak.
  //4*sigma is 7x orders of magnitude smaller than the peak
  //so that should be sufficiently small enough to stop.
  int       ti, tej;
  double    sigma, sigma2, spread, total;

  if(scale != NULL) free(scale);
  //scale = (double*)malloc(sizeof(double) * (end-start+16));
  scale = (double*)malloc(sizeof(double) * (end+16));
  minRange = start;
  maxRange = end;

  for(tej=minRange; tej<maxRange; tej++) {
    sigma = A + B * tej + C*tej*tej;
    total = 0.0;
    sigma2 = sigma * sigma;
    for(ti=tej-4*sigma; ti<tej+4*sigma; ti++) {
      spread = exp(-1 * (ti-tej)*(ti-tej)/sigma2);
      total += spread;
    }
    scale[tej] = 1.0 / total;
  }
}

- (void)generatePlotData;
{
  FILE    *fp;
  float   ti, tej, value, interval=(float)(maxRange-minRange)/50.0;

  fp = fopen("spreadFunc.data", "w");
  if(fp != NULL) {
    for(tej=minRange; tej<maxRange; tej+=interval) {
      for(ti=minRange; ti<maxRange; ti++) {
        value = (float)[self valueAtTime:ti expectedTime:tej];
        fprintf(fp,"%f \t %f \t %f\n", ti, tej, value);
      }
    }
    fclose(fp);    
  }
}

- (double)valueAtTime:(float)ti expectedTime:(float)tej;
{
  double		sigma, sigma2, spread;

  if(scale == NULL) return 0.0;

  if(ti<minRange) ti = minRange;
  if(ti>maxRange) ti = maxRange;
  if(tej<minRange) tej = minRange;
  if(tej>maxRange) tej = maxRange;

  sigma = A + B * tej + C*tej*tej;
  sigma2 = sigma * sigma;

  spread = scale[(int)tej] * exp(-1 * (ti-tej)*(ti-tej)/sigma2);

  return spread;
}

- (double)constValue:(int)index
{
  switch(index) {
    case 0: return A;
    case 1: return B;
    case 2: return C;
  }
  return 0.0;
}

- setConstValue:(int)index value:(double)value
{
  switch(index) {
    case 0: A=value; break;
    case 1: B=value; break;
    case 2: C=value; break;
  }
  return self;
}

/****
*
* AsciiArchiver routines
*
****/
- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"A_const")) {
    [archiver readData:&A];
  } else if (!strcmp(tag,"B_const")) {
    [archiver readData:&B];
  } else if (!strcmp(tag,"C_const")) {
    [archiver readData:&C];
  } else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeData:&A type:"d" tag:"A_const"];
  [archiver writeData:&B type:"d" tag:"B_const"];
  [archiver writeData:&C type:"d" tag:"C_const"];

  [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  //printf(" beginDearchive\n");
  [self init];
  [super beginDearchiving:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  id     dupSelf;
  struct myDefs { @defs(SpreadFunc1) } *newDefs;

  dupSelf = [[[self class] allocWithZone:zone] init];
  newDefs = (struct myDefs *)dupSelf;
  newDefs->A = A;
  newDefs->B = B;
  newDefs->C = C;
  newDefs->maxRange = maxRange;
  newDefs->minRange = minRange;

  if(scale != NULL) {
    newDefs->scale = (double*)malloc(sizeof(double) * (maxRange+16));
    memcpy(newDefs->scale, scale, sizeof(double)*(maxRange+16));
  }
  return dupSelf;
}

@end


