/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#define OSX
#import "AsciiArchiver.h"
#include <string.h>

#if !defined(GNUSTEP_BASE_LIBRARY) && !defined(MACOSX)


#import <objc/List.h>
/****
*
* List
*
****/
@implementation List (AAMethods)

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  int cnt;

  if (!strcmp(tag,"dataPtr")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      [self free];
      return nil;
    }
    [self setAvailableCapacity:cnt];
    [archiver readArray:dataPtr];
    numElements = cnt;
  } else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeArray:dataPtr size:[self count] type:"@" tag:"dataPtr"];

  return [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  [self init];
  return [super beginDearchiving:archiver];
}
@end


/****
*
* Storage
*
****/

@implementation Storage (AAMethods)

- (id)handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"elementSize")) {
    [archiver readData:&elementSize];
  }
  if (!strcmp(tag,"numElements")) {
    [archiver readData:&numElements];
    maxElements = numElements;
  }
  if (!strcmp(tag,"description")) {
    description = [archiver readData];		//archiver allocates memory for description string
  }
  if (!strcmp(tag,"dataPtr")) {
    dataPtr = [archiver readData];		//archiver allocates memory for the data
  }
  else return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  char			myType[32];

  sprintf(myType, "[%d%s]", numElements, description);
  printf("storage writeAscii type='%s'\n",myType);
  [archiver writeData:&elementSize type:"I" tag:"elementSize"];
  [archiver writeData:&numElements type:"I" tag:"numElements"];
  [archiver writeData:(char*)description type:"*" tag:"description"];
  [archiver writeData:dataPtr type:myType tag:"dataPtr"];
  return [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver;
{
  [self init];
  return [super beginDearchiving:archiver];
}

@end
#endif /*ifndef GNUSTEP_BASE_LIBRARY */


/****
*
* NSArray
*
****/
@implementation NSArray (AAMethods)

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  int      cnt;
  id       *arrayPtr;

  if (!strcmp(tag,"arrayObjects")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      [self release];
      return nil;
    }
    arrayPtr = (id*)calloc(cnt, sizeof(id));
    [archiver readArray:arrayPtr];
    [self initWithObjects:arrayPtr count:cnt];
    free(arrayPtr);
  } else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{	
  id    *arrayPtr;
  int   i;

  arrayPtr = (id*)calloc([self count], sizeof(id));
  for(i=0; i<[self count]; i++) {
    arrayPtr[i] = [self objectAtIndex:i];
  }
  [archiver writeArray:arrayPtr size:[self count] type:"@" tag:"arrayObjects"];
  free(arrayPtr);
  return [super writeAscii:archiver];
}

@end
