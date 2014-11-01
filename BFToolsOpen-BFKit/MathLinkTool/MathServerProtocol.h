#import <Foundation/Foundation.h>
#import <GeneKit/MGNSMutableData.h>
#import <GeneKit/Trace.h>
#import <GeneKit/Sequence.h>

@protocol MathServerProtocol
- (void)putDoubleArrayData:(bycopy MGNSMutableData *)array length:(unsigned)count;
- (void)putFloatArrayData:(bycopy MGNSMutableData *)array
                   length:(unsigned int)count;
- (bycopy MGNSMutableData *)getDoubleArrayData:(unsigned int *)count;
- (bycopy MGNSMutableData *)getFloatArrayData:(unsigned int *)count;
- (void)putSequence:(bycopy Sequence *)sequence;
- (void)putTrace:(bycopy Trace *)trace;
- (bycopy Trace *)getTrace;
- (bycopy Sequence *)getSequence;
- (void)evalExpression:(bycopy NSString *)expr;
- (void)loadPackage:(NSString *)name;
- (void)loadNotebook:(NSString *)name;
- (void)oldPutSequence:(bycopy Sequence *)sequence;
- (BOOL)connected;
@end

