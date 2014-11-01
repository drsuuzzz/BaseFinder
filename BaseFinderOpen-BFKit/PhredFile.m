/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "PhredFile.h"


@implementation PhredFile

- init
{
  [super init];
  verbose = NO;
  phredInfo=[[NSMutableDictionary dictionary] retain];
  return self;
}

- (id)initWithContentsOfFile:(NSString *)path;
{
  NSString           *fileContents;
  NSScanner          *scanner;
  NSCharacterSet     *whiteSpace;
  NSString           *tempString, *base;
  int                phredValue, position;
  BOOL               rtnValue;
  NSDictionary       *phredCall;
  NSMutableArray     *phredDNA;

  [self init];

  fileContents = [NSString stringWithContentsOfFile:path];
  whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  
  scanner = [NSScanner scannerWithString:fileContents];

  /*** Get DNA basecall info ***/
  if(![scanner scanUpToString:@"BEGIN_DNA"  intoString:&tempString]) {
    [self autorelease];
    return nil;
  }
  if(![scanner scanString:@"BEGIN_DNA"  intoString:NULL]) {
    [self autorelease];
    return nil;
  }

  phredDNA = [NSMutableArray array];
  do {
    rtnValue = [scanner scanUpToCharactersFromSet:whiteSpace intoString:&base];
    rtnValue = rtnValue & [scanner scanInt:&phredValue];
    rtnValue = rtnValue & [scanner scanInt:&position];
    printf("base=%s   phred=%d   pos=%d\n", [base cString], phredValue, position);

    phredCall = [NSDictionary dictionaryWithObjectsAndKeys:
      [base uppercaseString], @"baseCall",
      [NSNumber numberWithInt:position], @"position",
      [NSNumber numberWithInt:phredValue], @"phredScore",
      nil];
    [phredDNA addObject:phredCall];
  } while(rtnValue && ![scanner scanString:@"END_DNA" intoString:NULL] && ![scanner isAtEnd]);

  [phredInfo setObject:phredDNA  forKey:@"phredBaseCall"];

  /*
  if(![scanner scanString:@"END_DNA"  intoString:&tempString]) {
    printf("couldn't find 'END_DNA' tag in phred file %s\n", [phred_file cString]);
    return -1;
  }
   */

  return self;
}

- (void)setVerbose:(BOOL)value
{
  verbose = value;
}

- (NSMutableDictionary*)phredInfo
{
  return phredInfo;
}

/******
*
* calculating phred scores stats
*
******/

- (int)numBPwithPhredScore:(int)phredScore inFile:(NSString*)phred_file
{
  NSAutoreleasePool  *pool = [[NSAutoreleasePool alloc] init];
  NSString           *fileContents = [NSString stringWithContentsOfFile:phred_file];
  NSScanner          *scanner;
  NSCharacterSet     *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSString           *tempString;
  int                count=0, phredValue, position;
  BOOL               rtnValue;

  scanner = [NSScanner scannerWithString:fileContents];
  if(![scanner scanUpToString:@"BEGIN_DNA"  intoString:&tempString]) return -1;
  if(![scanner scanString:@"BEGIN_DNA"  intoString:NULL]) return -1;

  do {
    rtnValue = [scanner scanUpToCharactersFromSet:whiteSpace intoString:&tempString];
    rtnValue = rtnValue & [scanner scanInt:&phredValue];
    rtnValue = rtnValue & [scanner scanInt:&position];
    //printf("base=%s   phred=%d   pos=%d\n", [tempString cString], phredValue, position);
    if(phredValue >= phredScore) count++;
  } while(rtnValue && ![scanner scanString:@"END_DNA" intoString:NULL] && ![scanner isAtEnd]);


  /*
  if(![scanner scanString:@"END_DNA"  intoString:&tempString]) {
    printf("couldn't find 'END_DNA' tag in phred file %s\n", [phred_file cString]);
    return -1;
  }
   */

  if(verbose) printf("%s counted %d >= %d\n", [phred_file cString], count, phredScore);
  [pool release];
  return count;
}


@end
