#import <Foundation/Foundation.h>
#import <mathlink.h>
#import <GeneKit/MGNSMutableData.h>
#import "MathServerProtocol.h"
#import <GeneKit/Sequence.h>
#import <GeneKit/Trace.h>


@interface MathServer:NSObject <MathServerProtocol>
{		
    MLINK link;
    MLENV env;
    BOOL connected;

    id doubleArray;
}

+ (MathServer *)ServerLaunchMathConnection:(NSString *)linkName KernelPath:(NSString *)kernelPath;
+ (MathServer *)ServerConnect:(NSString *)linkName portNo:(int)port;
- init;
- (id)initLaunchMathConnection:(NSString *)linkName KernelPath:(NSString *)kernelPath;
- (id) initConnect:(NSString *)linkName portNo:(int)port;
- (void)closeLink;

- (void)putFunction:(NSString *)symbol paramCount:(unsigned)count;
- (void)putFloat:(float)number;
- (void)putInteger:(int)number;
- (float)getFloat;
- (int)getInteger;
- (void)putSymbol:(NSString *)symbol;
- (NSString *)getSymbol;
- (void)putString:(NSString *)string;
- (NSString *)getString;
- (void)execute;
- (void)execNoReturn;
- (void)waitForReturnPacket;
- (int)checkError;
- (BOOL)checkStatus;
- (NSString *)getFunction:(unsigned *)argCount;
- (BOOL)checkFunction:(NSString *)name argcount:(unsigned *)argCount;
- (void)evaluateString:(NSString *)string;
- (void)loadNotebook:(NSString *)name;

- (void)flushWrite;
- (void)flushRead;
- (void)flushAfterReturn;


//- (BOOL)establishStandaloneLink;
//- (BOOL)establishConnectedLink:(char **)argv :(char **)argvend;
//- (BOOL)connectToMath:(NSString *)hostName;
//- (BOOL)connectToLocalMath;
- (BOOL)testLink;
@end
