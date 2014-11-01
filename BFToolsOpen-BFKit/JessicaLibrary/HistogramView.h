
#import <AppKit/AppKit.h>
#import <GeneKit/Trace.h>

@interface HistogramView:NSView
{
  Trace*    dataList;
  int       numChannels;
  NSColor   *colors[4];
  int       Min[4], Max[4];
  int       *histogramData;
  int       numSlots, chanEnabled[4];
  id        scaleViewID;
  id        myScrollView;
  BOOL      hasHorizScale;

  /* for quick drawing with user paths */
  float     *cArray;
  char      *oArray;

}

- (void)setData:(Trace*)data;
- (void)takeNumSlots:sender;

- (void)addHorizScale;
- (void)setChan:(int)chan enabled:(BOOL)state;
- (void)switchEnabledChannels:sender;

- (BOOL)setColor:(NSColor *)color forChannel:(int)channel;
- (void)calcMinMax;
- (void)calcHistogram;

@end
