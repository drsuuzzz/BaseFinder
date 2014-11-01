/***********************************************************

Copyright (c) 2007 Suzy Vasa

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
NIH Center for AIDS Research

******************************************************************/

#import <float.h>
#import "MobilityRoutines.h"

@implementation Mobility3Func

/***
*
* implementation of the MobilityFuncProtocol object with 
* a fixed equation of the form 
*		f(x) = a + bx + cx^2 + dx^3
* where only the constants are archived
***/

- init
{
  int		chan;

  for(chan=0; chan<8; chan++) {
    A[chan] = B[chan] = C[chan] = D[chan] = 0.0;
  }

  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];
  int               i;

  for(i=0; i<8; i++) {
    [tempString appendFormat:@"\n      %f  + %fx  + %fx^2  + %fx^3",A[i], B[i], C[i], D[i]];    
  }
  return tempString;
}

- (double)valueAt:(double)x channel:(int)chan
{
  double		value;

  if((chan<0) || (chan >= 8)) return 0.0;
  value = A[chan] + B[chan]*x + C[chan]*x*x + D[chan]*x*x*x;
  return value;
}

- (double)constValue:(int)index channel:(int)chan
{
	double	val;
	
  if((chan<0) || (chan >= 8)) return 0.0;
	val = 0.0;
  switch(index) {
    case 0: val = A[chan]; break;
    case 1: val = B[chan]; break;
    case 2: val = C[chan]; break;
		case 3: val = D[chan]; break;
  }
  return val;
}

- (void)setConstValue:(int)index channel:(int)chan value:(double)value
{
  if((chan<0) || (chan >= 8)) return;
  switch(index) {
    case 0: A[chan]=value; break;
    case 1: B[chan]=value; break;
    case 2: C[chan]=value; break;
		case 3: D[chan]=value; break;
  }
}

/****
*
* AsciiArchiver routines
*
****/
- handleTag:(char *)tag fromArchiver:archiver
{
  int cnt;

  //printf(" handleTag='%s'\n",tag);
  if (!strcmp(tag,"A_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:A];
  } else if (!strcmp(tag,"B_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:B];
  } else if (!strcmp(tag,"C_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:C];
  } else if (!strcmp(tag,"D_const")) {
		cnt = [archiver arraySize];
		if (!cnt) {
			return nil;
		}
		[archiver readArray:D];
	} else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeArray:A size:8 type:"d" tag:"A_const"];
  [archiver writeArray:B size:8 type:"d" tag:"B_const"];
  [archiver writeArray:C size:8 type:"d" tag:"C_const"];
	[archiver writeArray:D size:8 type:"d" tag:"D_const"];

  [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  [self init];
  [super beginDearchiving:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  Mobility3Func     *dupSelf;

  dupSelf = [[[self class] allocWithZone:zone] init];
  memcpy(dupSelf->A, A, sizeof(double)*8);
  memcpy(dupSelf->B, B, sizeof(double)*8);
  memcpy(dupSelf->C, C, sizeof(double)*8);
	memcpy(dupSelf->D, D, sizeof(double)*8);
  return dupSelf;
}

@end


