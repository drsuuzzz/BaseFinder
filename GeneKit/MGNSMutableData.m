/* "$Id: MGNSMutableData.m,v 1.3 2007/05/25 20:21:01 smvasa Exp $" */

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

/* MGNSMutableData.m created by giddings on Tue 04-Feb-1997 */

//Written By Morgan Giddings, 1996 and 1997

//MGNSMutableData
//The purpose of this "subclass" of MGNSMutableData is to handle some
//byte order swapping when using and NSMutableData to store arrays of
//Floats, Doubles, and Ints.

//The primary thing to remember about using this class is that you must
//tell it what type to use when you create it, otherwise it can't really
//know how to change byte order when appropriate.  You set this by sending
//it a -setType message, with a single character type code of i (int), 
//d (double-float), f (float), l (long int)

//This class may also be useful because it demonstrates (somewhat) how
//to effectively subclass an abstract class cluster, which is something
//I had difficulty getting to work at first.  That is the one downside
//of class clusters.  Anyway, for someone wishing to create their own
//subclass of NSMutableData, this gets you a substantial way there.


#import "MGNSMutableData.h"

@implementation MGNSMutableData

+ (id)allocWithZone:(NSZone *)zone
{
    return [super allocWithZone:zone];
}

+ (MGNSMutableData *)data
{
    return [[[self alloc] init] autorelease];
}

+ (MGNSMutableData *)dataWithBytes:(const void *)bytes length:(unsigned int)length
{
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

+ (MGNSMutableData *)dataWithBytesNoCopy:(void *)bytes length:(unsigned int)length
{
    return [[[self alloc] initWithBytesNoCopy:bytes length:length] autorelease];
}

+ (MGNSMutableData *)dataWithContentsOfFile:(NSString *)path
{
    return [[[MGNSMutableData alloc] initWithContentsOfFile:path] autorelease];
}

+ (MGNSMutableData *)dataWithContentsOfMappedFile:(NSString *)path
{
    return [[[MGNSMutableData alloc] initWithContentsOfMappedFile:path] autorelease];
}

+ (MGNSMutableData *)dataWithData:(NSMutableData *)aData
{
    MGNSMutableData *temp = [MGNSMutableData alloc];
    return ([[temp initWithData:aData] autorelease]);
}


+ (MGNSMutableData *)dataWithCapacity:(unsigned int)aNumItems
{
    return [[[MGNSMutableData alloc] initWithCapacity:aNumItems] autorelease];
}

+ (MGNSMutableData *)dataWithLength:(unsigned int)length;
{
    return [[[MGNSMutableData alloc] initWithLength:length] autorelease];
}

- init
{
    type = 0;
    [super init];
    data = [[NSMutableData allocWithZone:[self zone]] init];
    byteOrder = [self hostOrder];
    return self;
}

- (MGNSMutableData *)initWithCapacity:(unsigned int)capacity
{
    [super init];
    byteOrder = [self hostOrder];
    data = [[NSMutableData allocWithZone:[self zone]] initWithCapacity:capacity];
    return self;
}

- (MGNSMutableData *)initWithLength:(unsigned int)length{
    [super init];
    byteOrder = [self hostOrder];
    data = [[NSMutableData allocWithZone:[self zone]] initWithLength:length];
    return self;
}

- (id)initWithBytes:(const void *)bytes length:(unsigned int)length
{
    type = 0;
    [super init];
    data = [[NSMutableData allocWithZone:[self zone]] initWithBytes:bytes length:length];
    byteOrder = [self hostOrder];
    return self;
}

- (id)initWithBytesNoCopy:(void *)bytes length:(unsigned int)length{
    type = 0;
    [super init];
    data = [[NSMutableData allocWithZone:[self zone]] initWithBytesNoCopy:bytes length:length];
    byteOrder = [self hostOrder];
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    type = 0;
    [super init];
    data = [[NSMutableData allocWithZone:[self zone]] initWithContentsOfFile:path];
    byteOrder = [self hostOrder];
    return self;
}

- (id)initWithContentsOfMappedFile:(NSString *)path
{
    type = 0;
    [super init];
    data = [[NSMutableData allocWithZone:[self zone]] initWithContentsOfMappedFile:path];
    byteOrder = [self hostOrder];
    return self;
}

- (MGNSMutableData *)initWithData:(NSMutableData *)thedata
{
    type = 0;
    [super init];
    data = [thedata mutableCopy];
//[NSMutableData allocWithZone:[self zone]] initWithData:thedata];
    byteOrder = [self hostOrder];
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    MGNSMutableData *copy = [MGNSMutableData allocWithZone:zone];
    [copy initWithData:data];

    [copy setByteOrder:[self byteOrder]];
    [copy setType:[self type]];
    return copy;
}


- (MGNSMutableData *)setType:(unsigned char)thetype
{
    if ((thetype == 'i') || (thetype == 'l') || (thetype == 'd') || (thetype == 'f'))
        type = thetype;
    return self;
}

-(unsigned char)type
{
    return type;
}

- replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy])
        return self;
    else
        return [super replacementObjectForPortCoder:encoder];
}

- (void)setByteOrder:(char unsigned)order
{
    byteOrder=order;
}

-(NSMutableData *)data
{
    return data;
}

- (unsigned char)byteOrder
{
    return byteOrder;
}

- (void)dealloc
{
//fprintf(stderr, "Freeing myself (MGNSMutableData)\n");
    if (data != NULL)
        [data release];
    [super dealloc];
}

- (unsigned char)hostOrder
{
    #ifdef __BIG_ENDIAN__
    return BIGENDIAN;
    #else
        return LITTLEENDIAN;
    #endif
}


- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    else if ([data respondsToSelector:aSelector])
        return YES;
    else
        return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *result = [super methodSignatureForSelector:sel];

    if (nil == result)
        result = [data methodSignatureForSelector:sel];
    return result;
}


- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([data respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:data];
    else
      {
        [self doesNotRecognizeSelector:[invocation selector]];
        //fprintf(stderr, "Cannot forward message, selector not recognized.\n");
      }

}


- (unsigned int)length
{
    return [data length];
}

- (const void *)bytes
{
    return [data bytes];
}

- (void *)mutableBytes
{
    return [data mutableBytes];
}

- (void)setLength:(unsigned int)length
{
    [data setLength:length];
}

- (void)increaseLengthBy:(unsigned int)extraLength
{
  [data increaseLengthBy:extraLength];
}


- (void)swapDoubleToHost
{
    unsigned char curHostOrder = [self hostOrder];

    if (byteOrder != curHostOrder) {
        NSSwappedDouble *temp1 = (NSSwappedDouble *)[data bytes];
        double *temp = (double *)[data mutableBytes];
        unsigned i, count = ([data length] / sizeof(double));

        if (byteOrder == BIGENDIAN) {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapBigDoubleToHost(temp1[i]);
            [self setByteOrder:LITTLEENDIAN];
            }
        else
          {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapLittleDoubleToHost(temp1[i]);
            [self setByteOrder:LITTLEENDIAN];
          }
    }
}

- (void)swapFloatToHost
{
    unsigned char curHostOrder = [self hostOrder];

    if (byteOrder != curHostOrder) {
        NSSwappedFloat *temp1 = (NSSwappedFloat *)[data bytes];
        float *temp = (float *)[data mutableBytes];
        unsigned i, count = ([data length] / sizeof(float));

        if (byteOrder == BIGENDIAN) {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapBigFloatToHost(temp1[i]);
            [self setByteOrder:LITTLEENDIAN];
            }
        else
          {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapLittleFloatToHost(temp1[i]);
            [self setByteOrder:LITTLEENDIAN];
          }
    }
}

- (void)swapLongToHost
{
    unsigned char curHostOrder = [self hostOrder];

    if (byteOrder != curHostOrder) {
        long *temp = (long *)[data mutableBytes];
        unsigned i, count = ([data length] / sizeof(long));

        if (byteOrder == BIGENDIAN) {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapBigLongToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
            }
        else
          {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapLittleLongToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
          }
    }
}
- (void)swapIntToHost
{
    unsigned char curHostOrder = [self hostOrder];

    if (byteOrder != curHostOrder) {
        int *temp = (int *)[data mutableBytes];
        unsigned i, count = ([data length] / sizeof(int));

        if (byteOrder == BIGENDIAN) {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapBigIntToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
            }
        else
          {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapLittleIntToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
          }
    }
}

- (void)swapShortToHost
{
    unsigned char curHostOrder = [self hostOrder];

    if (byteOrder != curHostOrder) {
        short *temp = (short *)[data mutableBytes];
        unsigned i, count = ([data length] / sizeof(short));

        if (byteOrder == BIGENDIAN) {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapBigShortToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
            }
        else
          {
            for (i = 0; i < count; i++)
                temp[i] = NSSwapLittleShortToHost(temp[i]);
            [self setByteOrder:LITTLEENDIAN];
          }
    }
}

- (void)swapToHost{
    if (type) {
        switch (type) {
            case 'i' : [self swapIntToHost];
                break;
            case 'l' : [self swapLongToHost];
                break;
            case 's' : [self swapShortToHost];
                break;
            case 'f' : [self swapFloatToHost];
                break;
            case 'd' : [self swapDoubleToHost];
                break;
        }
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
//    NSData *temp;
//    temp = [NSData dataWithBytes:[data mutableBytes] length:[data //length]];
    [coder encodeValueOfObjCType:@encode(unsigned char) at:&byteOrder];
    [coder encodeValueOfObjCType:@encode(unsigned char) at:&type];
    [coder encodeDataObject:data];
}

- (id)initWithCoder:(NSCoder *)coder
{
    NSData *temp;
    [coder decodeValueOfObjCType:@encode(unsigned char) at:&byteOrder];
    [coder decodeValueOfObjCType:@encode(unsigned char) at:&type];
    temp = [coder decodeDataObject];
    data = [[NSMutableData dataWithBytes:[temp bytes] length:[temp length]] retain];
    [self swapToHost];
    return self;
}
@end
