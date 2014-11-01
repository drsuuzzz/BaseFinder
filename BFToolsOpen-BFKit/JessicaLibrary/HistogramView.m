
#import "HistogramView.h"
#import "ScaleView.h"
#import <GeneKit/NumericalObject.h>

#ifdef WINNTHACK

float maxVal(float *array, int numPoints)
{
  float max=-FLT_MAX;
  int i;

  for (i = 0; i < numPoints; i++) {
    if (array[i] > max) max = array[i];
  }
  return max;
}

float minVal(float *array, int numPoints)
{
  float min=FLT_MAX;
  int i;

  for (i = 0; i < numPoints; i++) {
    if (array[i] < min) min = array[i];
  }
  return min;
}

void histogram2(float *array, int numPoints, int *dist, int numSlots)
{
  double max,min, range;
  int i;

  max = maxVal(array,numPoints);
  min = minVal(array,numPoints);
  range = max - min;

  if (range == 0) return;

  for (i = 0; i <= numSlots; i++)
    dist[i] = 0;
  for (i = 0; i < numPoints; i++)
    dist[(int)((numSlots*(array[i]-min))/range)] += 1;
}

#endif


@implementation HistogramView

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
  //[self calcColors];
  [self calcHistogram];
  [self display];
}

- (void)addHorizScale
{
	NSRect	tempFrame;
	
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

- resetScaleView
{
  float             min, range, max, temp;
  float            *dataPtr;
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

- (void)takeNumSlots:(id)sender
{
	NSRect		tempBounds;
	
	numSlots = [sender intValue];
	[self setFrameSize:NSMakeSize((numSlots+1)*2.0, [self bounds].size.height)];

	[self setData:dataList];

	//accompaning ScaleView
	tempBounds = [scaleViewID bounds];
	[scaleViewID setFrameSize:NSMakeSize((numSlots+1)*2.0, tempBounds.size.height)];
	[self resetScaleView];
	[[self window] display]; 
}

- (void)setChan:(int)chan enabled:(BOOL)state
{
	if(chan<0) return;
	if(chan>3) return;
	chanEnabled[chan] = state; 
}

- (void)switchEnabledChannels:sender
{
	int		i;
	
	for(i=0; i<4; i++) {
		[self setChan:i enabled:[[sender cellAtRow:0 column:i] state]];
	}
	[self display]; 
}

/*
- (void)calcColors
{
  int       i;
  NSColor   *tempColor;
  id        attachment;

  if(dataList == NULL) return;
  attachment = [dataList attachment];
  if(attachment == NULL) return;
  
  //printf("calculating histogram colors\n");
  for(i=0; i<numChannels; i++) {
    tempColor = [[[dataList attachment] channelColor:i] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if(colors[i] != NULL) [colors[i] release];
    colors[i] = [tempColor retain];
    //colors[i] = [[tempColor colorWithAlphaComponent:0.5] retain];
  }
}
*/

- (BOOL)setColor:(NSColor *)color forChannel:(int)channel
{
  if(channel<0) return NO;
  if(channel>3) return NO;
  if(colors[channel] != NULL) [colors[channel] release];
  colors[channel] = [color retain];
  return YES;
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
	int						x, channel;
	int						min, max, temp;
	
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
//  int       oi=0,ci=0;
//  float     bbox[4];
  NSRect    bounds;
  NSBezierPath *path = [NSBezierPath bezierPath];
  NSPoint p;

  if(dataList == NULL) return;
  if(![[self window] isVisible]) return;

  [[NSColor lightGrayColor] set];
 // PSsetgray(NSLightGray);
  NSRectFill([self bounds]);

  for(channel=0; channel<numChannels; channel++) {
    if(chanEnabled[channel]) {
  //    oi=0;
  //    ci=0;
//      oArray[oi++] = dps_ucache;
//      oArray[oi++] = dps_setbbox;
      [colors[channel] set];
      
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
          p.x = (float)x*2.0; p.y = 0.0;
          [path moveToPoint:p];
       /*   cArray[ci++] = (float)x*2.0;
          cArray[ci++] = (float)0.0;
          oArray[oi++] = dps_moveto; */
          p.y = temp;
          [path lineToPoint:p];
       /*   cArray[ci++] = (float)x*2.0;
          cArray[ci++] = (float)temp;
          oArray[oi++] = dps_lineto; */
          p.x = (float)x*2.0+1; p.y = 0;
          [path moveToPoint:p];
          p.y = temp;
          [path lineToPoint:p];
         /* cArray[ci++] = (float)x*2.0+1;
          cArray[ci++] = (float)0.0;
          oArray[oi++] = dps_moveto;
          cArray[ci++] = (float)x*2.0+1;
          cArray[ci++] = (float)temp;
          oArray[oi++] = dps_lineto; */
        }
      }
      [path stroke];
   /*   bounds = [self bounds];
      bbox[0] = bounds.origin.x;
      bbox[1] = bounds.origin.y;
      bbox[2] = bounds.origin.x+bounds.size.width;
      bbox[3] = bounds.origin.y+bounds.size.height;
      PSDoUserPath(cArray,ci,dps_float,oArray,oi,bbox,dps_ustroke); */
    }
  }
}


@end
