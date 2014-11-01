
@protocol SpreadFunctionProtocol
- (double)valueAtTime:(float)ti expectedTime:(float)tej;
- (double)constValue:(int)index;
- setConstValue:(int)index value:(double)value;
@end