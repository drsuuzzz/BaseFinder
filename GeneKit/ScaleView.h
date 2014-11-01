
#import <AppKit/AppKit.h>
 
@interface ScaleView:NSView
{
  float		start, end, majorDivision, minorDivision;
  BOOL		isVertical;
}

- (void)setVertical:(BOOL)value;
- (void)setStart:(float)value;
- (void)setEnd:(float)value;
- (void)setMajorDiv:(float)value;
- (void)setMinorDiv:(float)value;

@end
