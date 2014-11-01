/* "$Id: MGNSMutableData.h,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

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

/* MGNSMutableData.h created by giddings on Tue 04-Feb-1997 */

//Written By Morgan Giddings, 1996 and 1997

//More notes are in the .m file


#import <Foundation/Foundation.h>

#define BIGENDIAN	0
#define LITTLEENDIAN	1


@interface MGNSMutableData : NSObject <NSCoding>
{
    unsigned char byteOrder;
    unsigned char type;
    NSMutableData *data;
}
+ (MGNSMutableData *)data;
+ (MGNSMutableData *)dataWithCapacity:(unsigned int)aNumItems;
+ (MGNSMutableData *)dataWithLength:(unsigned int)length;
+ (MGNSMutableData *)dataWithBytes:(const void *)bytes length:(unsigned int)length;
+ (MGNSMutableData *)dataWithBytesNoCopy:(void *)bytes length:(unsigned int)length;
+ (MGNSMutableData *)dataWithContentsOfFile:(NSString *)path;
+ (MGNSMutableData *)dataWithContentsOfMappedFile:(NSString *)path;
+ (MGNSMutableData *)dataWithData:(NSMutableData *)aData;

- (MGNSMutableData *)initWithCapacity:(unsigned int)capacity;
- (MGNSMutableData *)initWithLength:(unsigned int)length;

- (id)init;
- (id)initWithBytes:(const void *)bytes length:(unsigned int)length;
- (id)initWithBytesNoCopy:(void *)bytes length:(unsigned int)length;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfMappedFile:(NSString *)path;
- (MGNSMutableData *)initWithData:(NSMutableData *)thedata;

- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;

- (MGNSMutableData *)setType:(unsigned char)thetype;
-(unsigned char)type;
- (unsigned char)hostOrder;
- (void)setByteOrder:(unsigned char)order;
- (unsigned char)byteOrder;

//Methods reimplemented from NSMutableData due to static typing requirements
- (unsigned int)length;
- (const void *)bytes;
- (void *)mutableBytes;
- (void)setLength:(unsigned int)length;
- (void)increaseLengthBy:(unsigned int)extraLength;

- (void)dealloc;

//For forwarding to embedded NSData
- (void)forwardInvocation:(NSInvocation *)anInvocation;


- (void)swapDoubleToHost;
- (void)swapFloatToHost;
- (void)swapLongToHost;
- (void)swapIntToHost;
- (void)swapShortToHost;
- (void)swapToHost;


@end
