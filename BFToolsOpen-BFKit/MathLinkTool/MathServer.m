#import "MathServer.h"
#import <stdio.h>
#import <stdlib.h>
#import <GeneKit/Sequence.h>
#import <GeneKit/Trace.h>
//#import <bsd/libc.h>
#import <Foundation/Foundation.h>


@implementation MathServer

- init
{
	connected = NO;
	[super init];
	doubleArray = NULL;
	return self;
}
	
+ (MathServer *)ServerLaunchMathConnection:(NSString *)linkName KernelPath:(NSString *)kernelPath
{
	MathServer *newObj = [[[MathServer alloc] init] autorelease];
	return [newObj initLaunchMathConnection:linkName KernelPath:kernelPath];
}

+ (MathServer *)ServerConnect:(NSString *)linkName portNo:(int)port
{
	MathServer *newObj = [[[MathServer alloc] init] autorelease];
	return [newObj initConnect:linkName portNo:port];
}

- (id) initConnect:(NSString *)linkName portNo:(int)port
{
	NSString *args = [NSString stringWithFormat:@"-linkconnect %d -linkname %@ -linkprotocol tcp", port, linkName];
	long myerrno;
	
	env = MLInitialize(0);
	if (env == nil)
		return nil;
	// Now try to open the link
	link = MLOpenString(env,  [args cString],  &myerrno);
	if (link == NULL) {
		fprintf(stderr, "Failed to connect!!!!\n");
		return nil;
	}
	else
		{
		fprintf(stderr, "Seems connected!\n");
		}
	
	//Now, Test the link
	if ([self testLink]) {
		connected = YES;
		return self;
	}
	else
		return nil;
}


- (id)initLaunchMathConnection:(NSString *)linkName KernelPath:(NSString *)kernelPath
{
	//	const char *argv[3] = {"Mathlinker", "-linkname", NULL}; 
	NSString *args = [NSString stringWithFormat:@"-linklaunch %@ -linkname %@ -linkprotocol tcp", linkName, kernelPath];
	long myerrno;
	
	//	int	argc=3;
	//	char command[255];
	
/*	
	if (connected) {
		MLPutFunction(link, "Exit", 0);
		MLEndPacket(link);
		MLClose(link);
		connected = NO;
	} */
	//	sprintf(command, "math -mathlink");
	//	argv[2] = command;
	
	env = MLInitialize(0);
	if (env == nil)
		return nil;
	// Now try to open the link
	link = MLOpenString(env,  [args cString],  &myerrno);
	if (link == NULL) {
		fprintf(stderr, "Failed to connect!!!!\n");
		return nil;
	}
	else
		{
		fprintf(stderr, "Seems connected!\n");
		}
	
	//Now, Test the link
	if ([self testLink]) {
		connected = YES;
		return self;
	}
	else
		return nil;
}

/*
- (BOOL)connectToLocalMath
{
//	const char *argv[3] = {"Mathlinker", "-linkname", NULL}; 
	const char *argv = {"-linklaunch /Applications/Scientific/Mathematica 5.0.app/Contents/MacOS/MathKernel -linkname BaseFinder -linkprotocol tcp"}; 

//	int	argc=3;
//	char command[255];
	

	if (connected) {
		MLPutFunction(link, "Exit", 0);
		MLEndPacket(link);
		MLClose(link);
		connected = NO;
	}
//	sprintf(command, "math -mathlink");
//	argv[2] = command;
	
	env = MLInitialize(0);
	// Now try to open the link
	link = MLOpen(argc, argv);
	if (link == NULL) 
		fprintf(stderr, "Failed to connect!!!!\n");
	else
		{
		fprintf(stderr, "Seems connected!\n");
		}

	//Now, Test the link
	return [self testLink];
}
*/

- (BOOL)oldtestLink
{
    BOOL answer;
    int result=0;

    fprintf(stderr, "In testlink.  Putting data...");
    MLPutFunction(link, "Plus", 2);
    MLPutInteger(link, 5);
    MLPutInteger(link, 12);
    MLEndPacket(link);
    fprintf(stderr, "Waiting for return packet . . .");
    while (MLNextPacket(link) != RETURNPKT) MLNewPacket(link);
    fprintf(stderr, "Got it\n");
    MLGetInteger(link, &result);
    if (result == 17) {
        answer = YES;
        fprintf(stderr, "Confirmed Connected\n");
    }
    else {
        answer = NO;
        fprintf(stderr, "Test failed\n");
    }
    return answer;
}

- (BOOL)testLink
{
    BOOL answer, oldConnected = connected;
    int result=0;
    
    connected = YES;
    fprintf(stderr, "In testlink.  Putting data...");
    [self putFunction:@"Plus" paramCount:2];
    [self putInteger:5];
    [self putInteger:12];
    [self execute];
    [self waitForReturnPacket];
    result = [self getInteger];
    if (result == 17) {
        answer = YES;
        fprintf(stderr, "Confirmed Connected\n");
    }
    else {
        answer = NO;
        fprintf(stderr, "Test failed\n");
    }
    connected = oldConnected;
    return answer;
}

//- (BOOL)establishStandaloneLink {
//    return (connected = [self connectToLocalMath]);
//}

/* Not presently in use
- (BOOL)establishConnectedLink:(char **)argv :(char **)argvend {
    int errno;
    int res;
    
    env = MLInitialize(0);
    link = MLOpenArgv(env, argv, argvend, &errno);
//    link = MLOpenString(env, "math -linkconnect -linkname 5000", &errno);
    if (link == NULL) {
        fprintf(stderr, "Link is NULL!\n");
        return NO;
    }
    fprintf(stderr, "Errno from MLOpen: %ld\n", errno);
    fprintf(stderr, "Activating link\n");
    res = MLActivate(link);
    fprintf(stderr, "Result of activate: %d . . Now flushing link\n",res);
    if (res) res = MLFlush( link);
    fprintf(stderr, "Now testing link: %d\n",res);
    return (connected = [self testLink]);
}
*/

/*
- (BOOL)connectToMath:(NSString *)hostName
{
const char *argv = {"-link /Applications/Scientific/Mathematica 5.0.app/Contents/MacOS/MathKernel -linkname BaseFinder -linkprotocol tcp"}; 

	int	argc=3, result;
	NSString *curhostname = [[NSProcessInfo processInfo] hostName];
  char command[255]; 
	if (connected) {
		MLPutFunction(link, "Exit", 0);
		MLEndPacket(link);
		MLClose(link);
		connected = NO;
	}
  if (![curhostname isEqualToString:hostName]) 
		sprintf(command, "ssh %s math -mathlink", [hostName cString]);
	else
		sprintf(command, "math -mathlink");
	argv[2] = command; 
	
	// Now try to open the link
	
	link = MLOpen(argc, argv);
	if (link == NULL) 
		fprintf(stderr, "Failed to connect!!!!\n");
	else
		{
		fprintf(stderr, "Seems connected!\n");
		}

	//Now, Test the link
	MLPutFunction(link, "Plus", 2);
	MLPutInteger(link, 5);
	MLPutInteger(link, 12);
	MLEndPacket(link);
	while (MLNextPacket(link) != RETURNPKT) MLNewPacket(link);
	MLGetInteger(link, &result);
	if (result == 17) {
		connected = YES;
		fprintf(stderr, "Confirmed Connected\n");
	}
	else {
		connected = NO;
		fprintf(stderr, "Test failed\n");
	}
	return connected;

}
*/

- (BOOL)connected
{
	return connected;
}

// The following functions are for use to set up expressions piece by piece to be
// be evaluated. Use them carefully.

- (void)putFunction:(NSString *)symbol paramCount:(unsigned)count
{
    if ([self checkStatus]) {
//        fprintf(stderr, "Putting function %s\n", [symbol cString]);
        MLPutFunction(link, [symbol cString], count);
        }
}


- (void)putFloat:(float)number
{
    if ([self checkStatus]) {
//        fprintf(stderr, "Putting float %f\n", number);
        MLPutFloat(link, number);
        }
}

- (void)putInteger:(int)number
{
    if ([self checkStatus]) {
        MLPutInteger(link, number);
//        fprintf(stderr, "Putting Int %d\n", number);
    }
}

- (float)getFloat
{
    float temp;

    if ([self checkStatus]) {
        MLGetFloat(link, &temp);
    }
    return temp;
}

- (int)getInteger
{
    int temp;

    if ([self checkStatus]) {
       if(! MLGetInteger(link, &temp)) return 0;
    }
    return temp;

}

- (void)putString:(NSString *)string
{
    if ([self checkStatus])
        MLPutString(link, [string cString]);
}


- (void)putSymbol:(NSString *)symbol
{
    if ([self checkStatus])
        MLPutSymbol(link, [symbol cString]);
}

- (NSString *)getSymbol
{
    const char *temp;
    NSString *tempstr;
    if ([self checkStatus]) {
        if (!MLGetSymbol(link, &temp)) return NULL;
        tempstr = [NSString stringWithCString:temp];
        MLDisownSymbol(link, temp);
    }
    else
        return NULL;
    return tempstr;
}

- (NSString *)getString
{
    const char *temp;
    NSString *tempstr;
    if ([self checkStatus]) {
        if (!MLGetString(link, &temp)) return NULL;
        tempstr = [NSString stringWithCString:temp];
        MLDisownString(link, temp);
    }
    else
        return NULL;
    return tempstr;
}


- (void)putDoubleArrayData:(bycopy MGNSMutableData *)array length:(unsigned)count
{
	int i;
	double *temp;
	
//	[array swapDoubleToHost];
        doubleArray = [array retain];
	temp = (double *)[array bytes];
	fprintf(stderr, "Putting double data: ");
	for (i=0; i < count; i++)
		fprintf(stderr, "%f ", (float)temp[i]);
	if (connected) {
		MLPutRealList(link, temp, count);
		fprintf(stderr, ". . . done\n");
	}
        [doubleArray autorelease];
}

- (void)putFloatArrayData:(bycopy MGNSMutableData *)array
                   length:(unsigned)count {
    float *fldata;
    double *dldata;
    unsigned i;

    if (!connected)
        return;

//    fprintf(stderr, "Putting Float array: ");
    fldata = (float *)[array mutableBytes];

//    if (doubleArray != NULL) {
//        fprintf(stderr, "MathSrv: Double Array already allocated!\n");
//        return;
//    }
    doubleArray = [[MGNSMutableData dataWithLength:(count * sizeof(double))] setType:'d'];
    dldata = (double *)[doubleArray mutableBytes];
    for (i = 0; i < count; i++)
        dldata[i] = (double)fldata[i];
    MLPutRealList(link, dldata, count);
//     fprintf(stderr, " done\n");
}

- (bycopy MGNSMutableData *)getDoubleArrayData:(unsigned int *)count
{
        double *temp;
        long tempcount;	
        MGNSMutableData *outdata;
        int i;

        if ([self checkStatus]) {
                fprintf(stderr, "getDoubleArrayData, v0.3\n");
                fprintf(stderr, "Got it.\nNow getting Real List . . .");
                MLGetRealList(link, &temp, &tempcount);
                fprintf(stderr, "Got it, size: %ld\nCalculated Data: ", tempcount);
                for (i=0; i < tempcount; i++)
                        fprintf(stderr, "%f ", temp[i]);
                fprintf(stderr, "\nNow init'ing data . . .");
                outdata = [(MGNSMutableData *)[MGNSMutableData dataWithBytes:temp
                                      length:(sizeof(double)*tempcount)] setType:'d'];
                fprintf(stderr,
                        "Done.\nNow disallocating Mathematica storage and assigning count\n");
                MLDisownRealList(link, temp, tempcount);
                fprintf(stderr, "Returning data. The data is: ");
                for (i=0; i < tempcount; i++)
                    fprintf(stderr, "%f ", ((double *)[outdata bytes])[i]);
                *count = (unsigned int) tempcount;
                fprintf(stderr, "Count is %d\n", *count);
                return outdata;
                }
        return NULL;
}

- (bycopy MGNSMutableData *)getFloatArrayData:(unsigned int *)count
{
    MGNSMutableData *outdata;
    double *tempdbl;
    float *tempflt;
    long tempcount;
    unsigned i;

    if (![self checkStatus])
        return 0;
//    fprintf(stderr, "Getting Float Array . . .");
    MLGetRealList(link, &tempdbl, &tempcount);
    outdata = [[MGNSMutableData dataWithLength:(sizeof(float)*tempcount)] setType:'f'];
    tempflt = [outdata mutableBytes];
    for (i = 0; i < tempcount; i++)
        tempflt[i] = (float)tempdbl[i];
    *count = tempcount;
    MLDisownRealList(link, tempdbl, tempcount);
//    fprintf(stderr, "Done.  Returning data.\n");
    return outdata;
}


- (void)execute
{
	if (connected) {
// 		fprintf(stderr, "Executing.\n");
		MLEndPacket(link);
               [self flushWrite];
               [self checkError];
	}       
}

- (void)execNoReturn
{
    [self execute];
    [self waitForReturnPacket];
    [self flushRead];
}


- (void)flushWrite
{
    
    if (connected) {
        MLFlush(link);
    }
}

- (void)flushRead
{
    if (connected) {
        while (MLReady(link)) 
            MLNewPacket( link);
    }
    [self checkError];
}

- (void)flushAfterReturn
{

    if (connected) {
        [self waitForReturnPacket];
        [self flushRead];
    }
}

- (int)checkError
{
    int err;
    
    if (err = MLError(link)) {
        fprintf(stderr, "%d Math Error: %s\n", err, MLErrorMessage(link));
        MLClearError(link);
    }
    return err;
}

- (void)blockFlushRead
{
    while (!MLReady(link));
    
}

- (void)waitForReturnPacket
{
    int temp;
//    fprintf(stderr, "Waiting for return packet. . .");
    while ((temp = MLNextPacket(link)) && (temp != RETURNPKT))
        MLNewPacket(link);
//    fprintf(stderr, "got it.\n");
    [self checkError];
}


/* The following routines are designed for more "automated" interaction
   with a tool like BaseFinder */

- (void)putTrace:(bycopy Trace *)trace
{
    unsigned i;

//    [trace retain];
    if (![self checkStatus])
        return;
    fprintf(stderr, "Putting Trace . . .");
    [self putFunction:@"ClearTrace" paramCount:0];
    [self execNoReturn];
    [self putFunction:@"SetChannelCount" paramCount:1];
    [self putInteger:[trace numChannels]];
    [self execNoReturn];
    [self putFunction:@"SetTraceLength" paramCount:1];
    [self putInteger:[trace length]];
    [self execNoReturn];
    for (i = 0; i < [trace numChannels]; i++) {
        [self putFunction:@"AddChannel" paramCount:1];
        [self putFloatArrayData:[trace sampleDataAtChannel:i] length:[trace length]];
        [self execNoReturn];
    }
    [self flushWrite];
    [NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    [self flushRead];
    fprintf(stderr, "Done\n");
}

/* Put a list of lists, with entries of the form: {basetype, conf, location} */

- (void)putSequence:(bycopy Sequence *)sequence
{
    unsigned int i, len;
    char string[2];
    NSMutableString *execString = [NSMutableString localizedStringWithFormat:@"SetSequence[{"];
    id <BaseProtocol> base;

    if (![self checkStatus])
        return;
    string[1] = '\0';

    fprintf(stderr, "Putting Sequence . . .");
    [self putFunction:@"ClearSequence" paramCount:0];
    [self execNoReturn];
    len = [sequence seqLength];
    for (i =0; i< (len-1); i++) {
        base = [sequence baseAt:i];
        [execString appendFormat:@"{%c, %u, %f}, ", [base base], [base location], [base floatConfidence]];
       }
    base = [sequence baseAt:i];
    [execString appendFormat:@"{%c, %u, %f}}]", [base base], [base location], [base floatConfidence]];
 //   fprintf(stderr, "Putting expr: %s\n", [execString cString]);
    [self evaluateString:execString];
    fprintf(stderr, "Done\n");
}

- (void)oldPutSequence:(bycopy Sequence *)sequence
{
    unsigned int i, len;
    char string[2];
    id <BaseProtocol> base;

    if (![self checkStatus])
        return;
    string[1] = '\0';

    fprintf(stderr, "Putting Sequence . . .");

    [self putFunction:@"ClearSequence" paramCount:0];
    [self execNoReturn];
    len = [sequence seqLength];
    [self putFunction:@"SetSequence" paramCount:1];
    [self putFunction:@"List" paramCount:len];
    for (i = 0; i < len; i++) {
        [self putFunction:@"List" paramCount:3];
        base = [sequence baseAt:i];
        string[0] = [base base];
        [self putString:[NSString stringWithCString:string]];
        [self putInteger:(int)[base location]];
        [self putFloat:[base floatConfidence]];
    }
    [self execNoReturn];

}

- (bycopy Trace *)getTrace
{
    unsigned chanCount, length, templength, i;
    Trace *temptrace;
    MGNSMutableData *tmpData;
    char tempStr[40];

    if (![self checkStatus])
        return NULL;
    [self putFunction:@"ChannelCount" paramCount:0];
    [self execute];
    [self waitForReturnPacket];
    chanCount = [self getInteger];
    if ((chanCount < 1) || (chanCount > 8))
        return NULL;
    [self putFunction:@"TraceLength" paramCount:0];
    [self execute];
    [self waitForReturnPacket];
    length = [self getInteger];
    temptrace = [[Trace alloc] init];
    [temptrace setLength:length];
    for (i = 0; i < chanCount; i++) {
        [self putFunction:@"TraceChannel" paramCount:1];
        [self putInteger:(i+1)];
        [self execute];
        [self waitForReturnPacket];
        tmpData = [self getFloatArrayData:&templength];
        fprintf(stderr, "Getting trace channel %d length: %d\n", i, templength);
        if (templength < length) {
            length = templength;
            [temptrace setLength:length];
            fprintf(stderr, "MathServer: Contracting length to %d!\n",templength);
        }
        sprintf(tempStr, "Channel %d", i);
        [temptrace addChannelWithData:tmpData label:[NSString stringWithCString:tempStr]];
    }
    [self flushRead];
    return temptrace;
}

- (NSString *)getFunction:(unsigned *)argCount
{
    const char *temp;
    long n;
    NSString *tempString;
    
    if (![self checkStatus])
        return NULL;
    MLGetFunction(link, &temp, &n);
    if ([self checkError] || (temp == NULL))
      return nil;
    *argCount = (unsigned)n;
    tempString = [NSString stringWithCString:temp];
    MLDisownSymbol(link, temp);
    return tempString;
}

- (BOOL)checkFunction:(NSString *)name argcount:(unsigned *)argCount
{
    long n;

    *argCount = 0;
    if (![self checkStatus])
        return NO;
    if (!MLCheckFunction(link, [name cString], &n))
      return NO;
    if ([self checkError])
      return NO;
    *argCount = (unsigned)n;
    return(YES);
}


- (bycopy Sequence *)getSequence
{
    unsigned length, len, i;
    NSString  *temp;
    Sequence *newSeq;
    Base *base;
    int location;
    float conf;
    char basechar;

    fprintf(stderr, "Getting Sequence . . .");
    if (![self checkStatus])
        return NULL;
//    [self putFunction:@"SeqLength" paramCount:0];
//    [self execute];
//    [self waitForReturnPacket];
 //   length = [self getInteger];
    fprintf(stderr, "Putting Function ""ReturnSequence"" . . .");
    [self putFunction:@"ReturnSequence" paramCount:0];
    [self execute];
    [self waitForReturnPacket];
    fprintf(stderr, "Got return.\n");
    if (![self checkFunction:@"List" argcount:&len])
      return NULL;
  //  if ([funcName compare:@"List"]) {
//        fprintf(stderr, "Return value not a list\n");
//        return NULL;
 //   } else
        fprintf(stderr, "Getting list of length: %d . . .", len);
    newSeq = [[Sequence alloc] init];
    fprintf(stderr, "Now getting sublists\n");
    for (i = 0; i < len; i++) {
      if ([self checkFunction:@"List" argcount:&length]) {
        if (length != 3) {
          fprintf(stderr, "Something fishy, length of returned list not 3.\n");
          continue;
        }
        [self checkError];
        temp = [self getString];
        if (!temp)
          continue;
        basechar = [temp cString][0];
        location = [self getInteger];
        conf = [self getFloat];
        base = [Base baseWithCall:basechar floatConfidence:conf location:(unsigned)location];
        [newSeq addBase:base];   
      }
//      funcName = [self getFunction:&length];
    }
    fprintf(stderr, "Done\n");
    return newSeq;
}

- (void)evalExpression:(bycopy NSString *)expr
{
    fprintf(stderr, "Evaluating Expression: %s\n", [expr cString]);
    [self evaluateString:expr];

}

- (oneway void)evalExprNoWait:(bycopy NSString *)expr
{
  fprintf(stderr, "Evaluating Expression: %s\n", [expr cString]);
  [self evaluateString:expr];
}

- (void)evaluateString:(NSString *)string
{
    if ([self checkStatus]) {
        [self putFunction:@"ToExpression" paramCount:1];
        [self putString:string];
        [self execNoReturn];
    }
}

- (void)loadPackage:(NSString *)name
{
    if ([self checkStatus]) {
        [self putFunction:@"Get" paramCount:1];
        [self putString:name];
        [self execNoReturn];
    }
    
}

- (void)loadNotebook:(NSString *)name
{
    if ([self checkStatus]) {
        [self putFunction:@"NotebookOpen" paramCount:1];
        [self putString:name];
        [self execNoReturn];
    }
}

- (BOOL)checkStatus
{
    if (connected) {
        if  ([self checkError] == 20398) {
            [self closeLink];
            connected = NO;
        };
//        if (MLAbort)
//            fprintf(stderr, "Got abort flag\n");
    }
    return connected;
}

- (void)closeLink
{
// 	MLPutFunction(link, "Exit", 0);
//	MLEndPacket(link);
	MLClose(link);
        MLDeinitialize(env);
        connected = NO;
}

- (void)dealloc
{
    if (connected)
        [self closeLink];
    //   if (doubleArray != NULL)
    //       [doubleArray release];
}

@end
