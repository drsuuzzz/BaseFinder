
#import <Foundation/Foundation.h>
#import "MobilityFuncProtocol.h"
#import <GeneKit/AsciiArchiver.h>


@interface Mobility3Func:NSObject <NSCopying, MobilityFunctionProtocol, AsciiArchiving>
{	
  double    A[8], B[8], C[8], D[8];
}

- (double)constValue:(int)index channel:(int)chan;
- (void)setConstValue:(int)index channel:(int)chan value:(double)value;
@end

