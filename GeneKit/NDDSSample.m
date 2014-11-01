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
/* NDDSSample.m created by jessica on Fri 03-Oct-1997 */

#import "NDDSSample.h"
#import "NDDSData.h"

@implementation NDDSSample

- init
{
  [super init];
  label = [[NSString stringWithCString:"none"] retain];
  parentSample = nil;
  childSamples = [[NSMutableArray array] retain];
  associatedData = [[NSMutableDictionary dictionary] retain];
  return self;
}

- (void)dealloc
{
  if(label != nil) [label release];
  if(parentSample != nil) [parentSample release];
  if(childSamples != nil) [childSamples release];
  if(associatedData != nil) [associatedData release];
  [super dealloc];
}

- (BOOL)isEqual:(id)anObject
{
  //equal if class, identifier, and dataType are equal
  if(anObject == self) return YES;
  if(![anObject isKindOfClass:[NDDSSample class]]) return NO;
  if([label isEqualToString:[anObject label]]) return YES;
  return NO;
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@", label=%@", label];
  return tempString;
}

/*****
*
* Common info, and relationships between samples
*
*****/

- (NSString*)label
{
  return label;
}

- (void)setLabel:(NSString*)aString
{
  if(label != nil) [label release];
  label = [aString copy];
}

- (NDDSSample*)parentSample
{
  return parentSample;
}

- (void)setParentSample:(NDDSSample*)newParentSample;
{
  if(parentSample == newParentSample) return;
  if(parentSample != nil) [parentSample release];
  parentSample = [newParentSample retain];
  [newParentSample addChildSample:self];
}

- (NSArray*)childSamples;
{
  return childSamples;
}

- (void)addChildSample:(NDDSSample*)aSample
{
  if([childSamples indexOfObject:aSample] == NSNotFound) {
    [childSamples addObject:aSample];
    [aSample setParentSample:self];    
  }
}

/*****
*
* Section for associating data (NDDSData objects) with this sample
*
******/

- (void)associateWithData:(NDDSData*)data key:(NSString*)key
{
  if(![data isKindOfClass:[NDDSData class]]) return;
  [associatedData setObject:data forKey:key];
  [data associateWithSample:self];
}

- (NSArray*)allAssociatedData
{
  return [associatedData allValues];
}

- (NDDSData*)dataForKey:(NSString*)key
{
  NDDSData   *data;

  data = [associatedData objectForKey:key];
  if(![data isKindOfClass:[NDDSData class]]) data=nil;
  return data;
}

@end
