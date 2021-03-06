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

/* NDDSPath.m created by jessica on Fri 03-Oct-1997 */

#import "NDDSPath.h"

@implementation NDDSPath

- init
{
  [super init];
  pathname = [[NSString string] retain];
  return self;
}

- (void)dealloc
{
  if(pathname != nil) [pathname release];
  [super dealloc];
}

- (NSString*)pathname
{
  return pathname;
}

- (void)setPathname:(NSString*)aPath
{
  if(pathname != nil) [pathname release];
  pathname = [aPath copy];
}

- (BOOL)isEqual:(id)anObject
{
  //equal if class, identifier, and dataType are equal
  BOOL   value=YES;

  if(![super isEqual:anObject]) value=NO;
  if(![pathname isEqualToString:[anObject pathname]]) value=NO;
  return value;
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@", path=%@", pathname];
  return tempString;
}

@end
