
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#ifndef MACOSX

#import "UWHistogramView.h"
#import "UWScaleView.h"
#import "NumericalObject.subproj/NumericalObject.h"
#import "NumericalRoutines.h"
#import "Trace.h"


@implementation UWHistogramView

- init
{
  [super init];
  dataList = NULL;
  return self;
}

- initWithFrame:(NSRect)frameRect
{
  int   i;

  [super initWithFrame:frameRect];
  if([[self superview] isKindOfClass:[NSClipView class]]) {
    [self setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:[self superview]
                                             selector:@selector(viewFrameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    //[self notifyAncestorWhenFrameChanged:YES];
    //[[self superview] notifyAncestorWhenFrameChanged:YES];
  }
  //printf("HistView's superView is a '%s'\n",[[[self superview] description] cString]);
  dataList = NULL;
  numChannels=1;
  numSlots=100;
  histogramData=NULL;
  cArray = NULL;
  oArray = NULL;
  hasHorizScale = NO;
  for(i=0; i<4; i++) chanEnabled[i]=YES;
  colors = [[NSArray arrayWithObject:[NSColor blackColor]] retain];
  return self;
}

- (void)setData:(Trace*)data
{
  NSObject    *tempObj;
  
  if([[self superview] isKindOfClass:[NSClipView class]]) {
    [self setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:[self superview]
                                             selector:@selector(viewFrameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    //[self notifyAncestorWhenFrameChanged:YES];
    //[[self superview] notifyAncestorWhenFrameChanged:YES];
  }
  tempObj = (NSObject*)[self class];
  //printf("HistView's is a '%s'\n",[[tempObj description] cString]);
  tempObj = (NSObject*)[[self superview] class];
  //printf("HistView's superView is a '%s'\n",[[tempObj description] cString]);

  if(histogramData != NULL) {
    free(histogramData);
    free(cArray);
    free(oArray);
    histogramData = NULL;
  }
  dataList = data;
  if(data==NULL) return;

  numChannels = [data numChannels];

  histogramData = (int*)malloc((numSlots+1)*numChannels*sizeof(int));
  cArray = (float*)malloc(8*(numSlots*1.5)*numChannels*sizeof(float));
  oArray = (char*)malloc(4*(numSlots*1.5)*numChannels);

  [self calcHistogram];
  [self setNeedsDisplay:YES];
}

- (void)setColors:(NSArray*)colorArray;
{
  //probably overkill, but at least its safer
  int              i;
  NSMutableArray   *tempArray;
  
  if(colors != nil) [colors release];
  tempArray = [colorArray mutableCopy];
  for(i=0; i<[tempArray count]; i++) {
    if(![[tempArray objectAtIndex:i] isKindOfClass:[NSColor class]])
      [tempArray replaceObjectAtIndex:i withObject:[NSColor blackColor]];
  }
  colors = tempArray;
}

- (void)addHorizScale
{
  NSRect   tempFrame;

  if(hasHorizScale) return;
  [self translateOriginToPoint:NSMakePoint(0.0, 30.0)];
  tempFrame.origin.x = 0.0;
  tempFrame.origin.y = -30.0;
  tempFrame.size.width = 100.0;
  tempFrame.size.height = 30.0;
  scaleViewID = [[UWScaleView alloc] initWithFrame:tempFrame];
  [self addSubview:scaleViewID];
  //[self translate:0.0 :30.0];
  hasHorizScale = YES;
}

- resetScaleView
{
  float             min, range, max, temp;
  float             *dataPtr;
  int               chan, count, i;
  NumericalObject   *numObj=[NumericalObject new];

  if(scaleViewID == NULL) return NULL;
  if(dataList == NULL) return NULL;

  count = [dataList length];
  if([dataList isProxy]) {
    dataPtr = (float*)malloc(sizeof(float)*count);
    for(i=0; i<count; i++) dataPtr[i]=[dataList sampleAtIndex:i channel:0];  
  } else
    dataPtr = [dataList sampleArrayAtChannel:0];
  max = [numObj maxVal:dataPtr numPoints:count];
  min = [numObj minVal:dataPtr numPoints:count];

  for(chan=1; chan<[dataList numChannels]; chan++) {
    if([dataList isProxy]) {
      for(i=0; i<count; i++) dataPtr[i]=[dataList sampleAtIndex:i channel:chan];
    } else
      dataPtr = [dataList sampleArrayAtChannel:chan];
    temp = [numObj maxVal:dataPtr numPoints:count];
    if(temp>max) max=temp;
    temp = [numObj minVal:dataPtr numPoints:count];
    if(temp<min) min=temp;
  }
  range = max - min;

  [scaleViewID setStart:min];
  [scaleViewID setEnd:max];
  //[scaleViewID setMajorDiv:range/(numSlots/10)];
  //[scaleViewID setMinorDiv:range/(numSlots/2)];
  [scaleViewID setMajorDiv:range/10];
  [scaleViewID setMinorDiv:range/(numSlots/2)];
  [scaleViewID display];

  if([dataList isProxy]) free(dataPtr);
  [numObj release];
  return self;
}

- (void)setNumSlots:(int)value
{
  NSRect     tempBounds;

  numSlots = value;
  [self setFrameSize:NSMakeSize((numSlots+1)*2.0, [self bounds].size.height)];

  [self setData:dataList];

  //accompaning ScaleView
  if(scaleViewID == NULL) return;
  tempBounds = [scaleViewID bounds];
  [scaleViewID setFrameSize:NSMakeSize((numSlots+1)*2.0, tempBounds.size.height)];
  [self resetScaleView];
  [[self window] display];
}

- (void)setChannel:(int)chan enabled:(BOOL)state
{
  if(chan<0) return;
  if(chan>3) return;
  chanEnabled[chan] = state;
}

- (void)calcHistogram
{
  int               i, chan, count;
  float             *dataPtr;
  NumericalObject   *numObj=[NumericalObject new];
  
  if(dataList == NULL) return;

  //printf("calculating histogram\n");
  //if([dataList isProxy])
  dataPtr = (float*)malloc(sizeof(float)*[dataList length]);
  count = [dataList length];
  for(chan=0; chan<numChannels; chan++) {
    for(i=0; i<count; i++) dataPtr[i]=[dataList sampleAtIndex:i channel:chan];
    /***
       if([dataList isProxy]) {
         for(i=0; i<count; i++) dataPtr[i]=[dataList sampleAtIndex:i channel:chan];
       } else
       dataPtr = [dataList sampleArrayAtChannel:chan];
       ***/
    [numObj histogram2:dataPtr :count :&(histogramData[(numSlots+1)*chan]) :numSlots];
  }
  [self calcMinMax];
  //if([dataList isProxy])
  free(dataPtr);
  [numObj release];
}

- (void)calcMinMax
{
  int     x, channel;
  int     min, max, temp;

  if(dataList == NULL) return;

  for(channel=0; channel<numChannels; channel++) {
    min = USHRT_MAX;
    max = 0;
    for(x=0; x<=numSlots; x++) {
      temp = (int)histogramData[channel*(numSlots+1) + x];
      if(temp < min) min=temp;
      if(temp > max) max=temp;
    }
    Min[channel] = min;
    Max[channel] = max;
    //printf("hist ch:%d  min:%d  max:%d\n",channel, min, max);
  }
}

- (void)drawRect:(NSRect)rects
{
  int       channel, x;
  float     temp;
  int       oi=0,ci=0;
  float     bbox[4];
  NSRect    bounds;

  if(dataList == NULL) return;
  if(![[self window] isVisible]) return;

  PSsetgray(NSLightGray);
  NSRectFill([self bounds]);

  for(channel=0; channel<numChannels; channel++) {
    if(chanEnabled[channel]) {
      oi=0;
      ci=0;
      oArray[oi++] = dps_ucache;
      oArray[oi++] = dps_setbbox;
      if(channel < [colors count])
        [[colors objectAtIndex:channel] set];
      else
        [[NSColor blackColor] set];
      
      for(x=0; x<=numSlots; x++) {
        if(Min[channel]!=Max[channel]) {
          temp = ((histogramData[channel*(numSlots+1)+x] - Min[channel])
                  * (float)[self bounds].size.height) /
          (float)(Max[channel]-Min[channel]);
        }
        else temp=0;
        if(temp>(float)[self bounds].size.height) {
          //printf("ch:%d hist overBounds\n",channel);
          temp=(int)[self bounds].size.height;
        }
        if(temp<0) temp=0;

        if(temp > 0) {
          cArray[ci++] = (float)x*2.0;
          cArray[ci++] = (float)0.0;
          oArray[oi++] = dps_moveto;
          cArray[ci++] = (float)x*2.0;
          cArray[ci++] = (float)temp;
          oArray[oi++] = dps_lineto;
          cArray[ci++] = (float)x*2.0+1;
          cArray[ci++] = (float)0.0;
          oArray[oi++] = dps_moveto;
          cArray[ci++] = (float)x*2.0+1;
          cArray[ci++] = (float)temp;
          oArray[oi++] = dps_lineto;
        }
      }
      bounds = [self bounds];
      bbox[0] = bounds.origin.x;
      bbox[1] = bounds.origin.y;
      bbox[2] = bounds.origin.x+bounds.size.width;
      bbox[3] = bounds.origin.y+bounds.size.height;
      PSDoUserPath(cArray,ci,dps_float,oArray,oi,bbox,dps_ustroke);
    }
  }
}


@end
#endif