
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

#import "MGMutableFloatArray.h"

@implementation MGMutableFloatArray
+ (MGMutableFloatArray *)floatArrayWithCount:(unsigned)_count
{
  MGMutableFloatArray *theobj;

  theobj = [[MGMutableFloatArray alloc] initWithCount:_count];
  return [theobj autorelease];
}

+ (MGMutableFloatArray *)floatArrayUsingData:(MGNSMutableData *)thedata
{
  MGMutableFloatArray *theobj;
  theobj = [[MGMutableFloatArray alloc] initWithDataObj:thedata];
  return [theobj autorelease];
}

+ (MGMutableFloatArray *)floatArray
{
  MGMutableFloatArray *theobj;
  theobj = [[MGMutableFloatArray alloc] initWithCount:0];
  return [theobj autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
  MGMutableFloatArray *newArray = [MGMutableFloatArray allocWithZone:zone];

  newArray->theArray = [theArray mutableCopyWithZone:zone];
  newArray->fltarray = [newArray->theArray mutableBytes];
  newArray->count = count;
  newArray->realsize = realsize;

  return newArray;
}

- (MGMutableFloatArray *)init
{
  theArray = [MGNSMutableData allocWithZone:[self zone]];
  fltarray = NULL;
  count = 0;
  return self;
}

- (MGMutableFloatArray *)initWithCount:(unsigned)theCount
{
  count = theCount;
  theArray = [[[MGNSMutableData	dataWithLength:(count * sizeof(float))] retain] setType:'f'];
  fltarray = [theArray mutableBytes];
  return self;
}

- (MGMutableFloatArray *)initWithDataObj:(MGNSMutableData *)thedata
{
  count = [thedata length]/sizeof(float);
  theArray = [thedata retain];
  fltarray = [theArray mutableBytes];
  return self;

}

- (MGMutableFloatArray *)setRefToData:(MGNSMutableData *)thedata
{
  if (theArray != NULL)
    [theArray release];
  count = [thedata length]/sizeof(float);
  theArray = [thedata retain];
  fltarray = [theArray mutableBytes];
  return self;
}

//Added this because GDB is broken in DR2 and won't print float values correctly
- (NSString *)stringValueForElement:(int)pos
{
  if (pos < count)
    return [NSString stringWithFormat:@"%f", fltarray[pos]];
  else
    return @"";
}


- (float)elementAt:(unsigned)pos
{
  if (pos < count)
    return(fltarray[pos]);
  else {
    [NSException raise:@"NSRangeException" format:@"MGNSMutableArray: Attempt to access non-existent element number %d.", (int)pos];
    return 0;
  }
}

- (void)insertValueAt:(unsigned)pos value:(float)val
{
	if (pos < count) {
		[theArray increaseLengthBy:sizeof(float)];
		fltarray = [theArray mutableBytes];
		memmove(&fltarray[pos+1],&fltarray[pos], 
						(count-pos)*sizeof(float));
		count += 1;
		fltarray[pos] = val;
	}
	else
          [NSException raise:NSRangeException format:@"MGNSMutableArray: Attempt to access non-existent element number %d.", (int)pos];
}

- (void)setValueAt:(unsigned)pos to:(float)val
{
  if (pos < count)
    {
    fltarray = [theArray mutableBytes];
    fltarray[pos] = val;
    }
  else
    [NSException raise:NSRangeException format:@"MGNSMutableArray: Attempt to access non-existent element number %d.", (int)pos];
}


- (void)appendValue:(float)val
{
  [theArray increaseLengthBy:sizeof(float)];
  fltarray = [theArray mutableBytes];
  fltarray[count++] = val;
}


- (void)deleteValueAt:(unsigned)position
{
  unsigned int i;
  unsigned int length;
  
  if (position >= count)
    [NSException raise:NSRangeException format:@"MGNSMutableArray: Attempt to access non-existent element number %d.", (int)position];
  fltarray = (float *)[theArray mutableBytes];
  for (i = position; i < count; i++)
    fltarray[i] = fltarray[i+1];
  count -= 1;
  length = count * sizeof(float);
  [theArray setLength:length];
 
}


- (float *)floatArray
{
	return fltarray;
}

- (MGNSMutableData *)theFloatData
{
	return theArray;
}

- (unsigned)count
{
	return count;	
}

- (void)increaseCountBy:(unsigned)amount
{
	[theArray increaseLengthBy:sizeof(float)*amount];
}

- (void)dealloc
{
	[theArray release];
	[super dealloc];
}

- (void)removeNegatives
{
  unsigned i;

  for (i = 0; i < count; i++)
    if (fltarray[i] < 0) fltarray[i] = 0;
}

- (void)writeToTextFile:(NSString *)pathname
{
  NSMutableString *textOut=[NSMutableString stringWithCapacity:255];
  unsigned i;
  float temp;

  for (i=0; i < count; i++) {
    temp = [self elementAt:i];
    [textOut appendFormat:@"%f\n", temp];
  }

  [textOut writeToFile:pathname atomically:NO];

}


@end
