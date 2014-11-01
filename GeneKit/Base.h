/* "$Id: Base.h,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

//#import <Foundation/NSDictionary.h>
//#import <Foundation/NSObject.h>
//#import <Foundation/NSRange.h>
//#import <Foundation/NSArchiver.h>

#import <Foundation/Foundation.h>
#import "LadderPeak.h"

/* base channels */
#define UNKNOWN_BASE -1
#define A_BASE	1
#define T_BASE	3
#define G_BASE	2
#define C_BASE	0

@protocol BaseProtocol
+ baseWithCall:(char)theBase confidence:(unsigned char)confidence;
+ baseWithCall:(char)theBase floatConfidence:(float)confidence location:(unsigned int)loc;
+ baseWithCall:(char)theBase confA:(unsigned char)confA confC:(unsigned char)confC confG:(unsigned char)confG confT:(unsigned char)confT;
+ baseWithChannel:(unsigned)channel floatConfidence:(float)confidence location:(unsigned int)loc peak:(id <LadderPeak>)_peak;
+ baseWithChannel:(unsigned)channel floatConfidence:(float)confidence location:(unsigned int)loc;

+ newWithChar:(char)thebase;
+(BOOL)validBase:(char)thebase;
+ newBase;

- (char)base;
- (NSString *)strBase;
- (int)channel;
- (unsigned char)confA;
- (unsigned char)confC;
- (unsigned char)confG;
- (unsigned char)confT;
- (unsigned char)confidence;
- (float)floatConfidence;
- (unsigned int)location;
- (id <LadderPeak>)peak;
- (unsigned char)retConf;
- (char)retBase;

- (void)setBase:(char)base;
- (void)setChannel:(int)_channel;
- (void)setConf:(unsigned char)confidence;
- (void)setConfA:(unsigned char)confidence;
- (void)setConfC:(unsigned char)confidence;
- (void)setConfT:(unsigned char)confidence;
- (void)setConfG:(unsigned char)confidence;
- (void)setFloatConf:(float)confidence;
- (void)setLocation:(unsigned int)loc;
- (void)setPeak:(id <LadderPeak>)_peak;

- (NSComparisonResult)comparePosition:(id <BaseProtocol>)obj;

- (void)setAnnotation:(id)obj forKey:(NSString *)key;
- (void)addKeyValuePair:(NSString *)key value:(id)value;
- (void)changeAnnotationForKey:(NSString *)key value:(id)value;
- (id)valueForKey:(NSString *)key;
@end

@interface Base:NSObject <NSCoding, NSCopying, BaseProtocol>
{
  char                  base;                //Called base letter
  unsigned char         conf;	             //Confidence of the base
  char			channel;	     //Trace data channel that base originated from
  unsigned char         confidences[4];      //Confidences for the bases in the order A,C,G,T
  unsigned int          location;
  id 			peak;
  NSMutableDictionary	*other_annotation;   //Unlimited annotation potential
}

- init;
- (void)dealloc;

@end
