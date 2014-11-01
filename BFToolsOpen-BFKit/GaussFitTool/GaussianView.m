/***********************************************************

Copyright (c) 1997-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "GaussianView.h"
#import <GeneKit/ScaleView.h>

@implementation GaussianView

- initWithFrame:(NSRect)frameRect
{	
  [super initWithFrame:frameRect];
  numDataPoints=0;
  gaussianData=NULL;
  cArray = NULL;
  oArray = NULL;
  hasHorizScale = NO;
  scale = 0.0;
  mu = 10.0;
  sigma = 1.0;
  return self;
}

- (void)setData:(float*)data :(int)numdata
{
  NSRect   myFrame = [self frame];

  myFrame.size.width = numdata*2+10;
  [self setFrame:myFrame];
  if(gaussianData != NULL) {
    free(cArray);
    free(oArray);
    gaussianData = NULL;
  }
  gaussianData = data;
  numDataPoints = numdata;
  if(data==NULL) return;

  cArray = (float*)malloc(8*(numDataPoints*1.5)*sizeof(float));
  oArray = (char*)malloc(4*(numDataPoints*1.5));

  [self calcMinMax];
  [self display];
  [[self enclosingScrollView] display];
}

- (void)setFittedMu:(float)val1 sigma:(float)val2 scale:(float)val3;
{
  scale = val3;
  mu = val1;
  sigma = val2;
}


- (void)addHorizScale
{
  NSRect    tempFrame;

  if(hasHorizScale) return;
  [self translateOriginToPoint:NSMakePoint(0.0, 30.0)];
  tempFrame.origin.x = 0.0;
  tempFrame.origin.y = -30.0;
  tempFrame.size.width = 100.0;
  tempFrame.size.height = 30.0;
  scaleViewID = [[ScaleView alloc] initWithFrame:tempFrame];
  [self addSubview:scaleViewID];
  //[self translate:0.0 :30.0];
  hasHorizScale = YES;
}

#ifdef OLDCODE
- resetScaleView
{
  float   min, range, max, temp;
  float   *dataPtr;
  int     chan, count;

  if(scaleViewID == NULL) return NULL;
  if(dataList == NULL) return NULL;

  dataPtr = (float*)[[dataList objectAt:0] returnDataPtr];
  count = [[dataList objectAt:0] count];
  max = maxVal(dataPtr,count);
  min = minVal(dataPtr,count);

  for(chan=1; chan<[dataList count]; chan++) {
    dataPtr = (float*)[[dataList objectAt:chan] returnDataPtr];
    count = [[dataList objectAt:0] count];
    temp = maxVal(dataPtr,count);
    if(temp>max) max=temp;
    temp = minVal(dataPtr,count);
    if(temp<min) min=temp;
  }
  range = max - min;

  [scaleViewID setStart:min];
  [scaleViewID setEnd:max];
  //[scaleViewID setMajorDiv:range/(numDataPoints/10)];
  //[scaleViewID setMinorDiv:range/(numDataPoints/2)];
  [scaleViewID setMajorDiv:range/10];
  [scaleViewID setMinorDiv:range/(numDataPoints/2)];
  [scaleViewID display];

  return self;
}
#endif

- (void)calcMinMax
{
  int       x;
  float     temp;

  if(gaussianData == NULL) return;

  dataMin = gaussianData[0];
  dataMax = gaussianData[0];
  for(x=1; x<=numDataPoints; x++) {
    temp = gaussianData[x];
    if(temp < dataMin) dataMin=temp;
    if(temp > dataMax) dataMax=temp;
  }
  printf("GaussView min:%f  max:%f\n", dataMin, dataMax);
}

- (void)drawFittedGaussian
{
  int      x;
  float    temp;
//  int      oi=0,ci=0;
  NSRect   selfrect=[self bounds];
  float    bbox[4];
  NSBezierPath *path = [NSBezierPath bezierPath];
  NSPoint p;

  printf("Fitted scale=%f  mean=%f  sigma=%f\n",scale,mu,sigma);
  if(scale == 0.0 || sigma==0.0) return;
  [[NSColor redColor] set];
//  PSsetrgbcolor(1.0, 0.0, 0.0);
  bbox[0] = selfrect.origin.x;
  bbox[1] = selfrect.origin.y;
  bbox[2] = selfrect.origin.x+selfrect.size.width;
  bbox[3] = selfrect.origin.y+selfrect.size.height;

//  oi=0;
//  ci=0;
//  oArray[oi++] = dps_ucache;
//  oArray[oi++] = dps_setbbox;
  for(x=0; x<=numDataPoints; x++) {
    if(dataMin != dataMax) {
      temp = scale * exp(-1 * pow(x-mu, 2.0)/pow(sigma,2.0));
      temp = ((temp - dataMin)
              * (float)([self bounds].size.height-6.0)) /
        (float)(dataMax-dataMin);
      }
    else temp=0.0;
    if(temp>(float)[self bounds].size.height-1) {
      temp=[self bounds].size.height - 1.0;
      }
    if(temp<0) temp=0;

    if(x==0) {
      p.x = (float)x*2;
      p.y = (float)temp;
      [path moveToPoint:p];
/*     cArray[ci++] = (float)x * 2;
      cArray[ci++] = (float)temp;
      oArray[oi++] = dps_moveto; */
      }
    else {
      p.x = (float)x*2;
      p.y = (float)temp;
      [path moveToPoint:p];

 /*     cArray[ci++] = (float)x*2;
      cArray[ci++] = (float)temp;
      oArray[oi++] = dps_lineto; */
      }
    }
    [path stroke];
//  PSDoUserPath(cArray,ci,dps_float,oArray,oi,bbox,dps_ustroke);
}


- (void)drawRect:(NSRect)rects
{
  int      x;
  float    temp;
//  int      oi=0,ci=0;
  NSRect   selfrect=[self bounds];
  float    bbox[4];
  NSBezierPath *path = [NSBezierPath bezierPath];
  NSPoint p1;

  if(gaussianData == NULL) return;
  if(![[self window] isVisible]) return;
  
  [[NSColor whiteColor] set];
  NSRectFill([self bounds]);

  [self drawFittedGaussian];

  bbox[0] = selfrect.origin.x;
  bbox[1] = selfrect.origin.y;
  bbox[2] = selfrect.origin.x+selfrect.size.width;
  bbox[3] = selfrect.origin.y+selfrect.size.height;
  [[NSColor blackColor] set];
//  PSsetgray(NSBlack);
//  oi=0;
//  ci=0;
//  oArray[oi++] = dps_ucache;
//  oArray[oi++] = dps_setbbox;
  for(x=0; x<=numDataPoints; x++) {
    if(dataMin != dataMax) {
      temp = ((gaussianData[x] - dataMin)
              * (float)([self bounds].size.height-6.0)) /
      (float)(dataMax-dataMin);
    }
    else temp=0.0;
    if(temp>(float)[self bounds].size.height) {
      temp=[self bounds].size.height;
    }
    if(temp<0) temp=0;

    if(temp > 0) {
      p1.x = (float)x*2;
      p1.y = (float)temp;
      [path moveToPoint:p1];
//      cArray[ci++] = (float)x*2;
//      cArray[ci++] = (float)temp;
//      oArray[oi++] = dps_moveto;
      [path appendBezierPathWithArcWithCenter:p1 radius:1.0 startAngle:0 endAngle:360];
 //     cArray[ci++] = (float)x*2;     // x
 //     cArray[ci++] = (float)temp;    // y
 //     cArray[ci++] = (float)1.0;     // r
 //     cArray[ci++] = (float)0;       // ang1
 //     cArray[ci++] = (float)360;     // ang2
 //     oArray[oi++] = dps_arc;
    }
  }

  //DPSDoUserPath(cArray,ci,dps_float,oArray,oi,&bounds,dps_ustroke);
//  PSDoUserPath(cArray,ci,dps_float,oArray,oi,bbox,dps_ufill);
  [path stroke];
}


@end
