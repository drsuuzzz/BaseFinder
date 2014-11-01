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

/* NDDSData.m created by jessica on Wed 10-Sep-1997 */

#import "NDDSData.h"
#import "NDDSSample.h"

@implementation NDDSData

- init
{
  [super init];
  identifier = nil;
  dataType = nil;
  processingState = [[NSString stringWithCString:"none"] retain];
  timeStamp = [[NSDate date] retain];
  shouldArchive = NO;

  sampleArray = [[NSMutableArray array] retain];
  childDataArray = [[NSMutableArray array] retain];
  parentDataArray = [[NSMutableArray array] retain];
  return self;
}

- (void)dealloc
{
  if(identifier != nil) [identifier release];
  if(dataType != nil) [dataType release];
  if(processingState != nil) [processingState release];
  if(timeStamp != nil) [timeStamp release];
  if(sampleArray != nil) [sampleArray release];
  if(childDataArray != nil) [childDataArray release];
  if(parentDataArray != nil) [parentDataArray release];
  [super dealloc];
}

- (BOOL)isEqual:(id)anObject
{
  //equal if class, identifier, and dataType are equal
  BOOL   value=YES;
  
  if(![anObject isKindOfClass:[self class]]) value=NO;
  if(identifier!=nil && [anObject identifier]!=nil &&
     ![identifier isEqualToString:[anObject identifier]]) value=NO;
  if(dataType!=nil && [anObject dataType]!=nil &&
     ![dataType isEqualToString:[anObject dataType]]) value=NO;
  return value;
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];
  
  [tempString appendFormat:@", identifier=%@", identifier];
  [tempString appendFormat:@", dataType=%@", dataType];
  [tempString appendFormat:@", sampleArrayCount=%@", [sampleArray count]];
  return tempString;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:identifier];
  [coder encodeObject:dataType];
  [coder encodeObject:processingState];
  [coder encodeObject:timeStamp];
  [coder encodeValueOfObjCType:@encode(BOOL) at:&shouldArchive];

  //[coder encodeValueOfObjCType:@encode(NSString) at:&identifier];
  //[coder encodeValueOfObjCType:@encode(NSString) at:&dataType];
  //[coder encodeValueOfObjCType:@encode(NSString) at:&processingState];
  //[coder encodeValueOfObjCType:@encode(NSDate) at:&timeStamp];

  [coder encodeRootObject:sampleArray];
  [coder encodeRootObject:childDataArray];
  [coder encodeRootObject:parentDataArray];
  return;
}

- (id)initWithCoder:(NSCoder *)coder
{
  identifier = [[coder decodeObject] retain];
  dataType = [[coder decodeObject] retain];
  processingState = [[coder decodeObject] retain];
  timeStamp = [[coder decodeObject] retain];
  [coder decodeValueOfObjCType:@encode(BOOL) at:&shouldArchive];

  sampleArray = [[coder decodeObject] retain];
  childDataArray = [[coder decodeObject] retain];
  parentDataArray = [[coder decodeObject] retain];

  return self;
}

/****
*
* return values
*
****/
- (NSString*)identifier { return identifier; }

- (NSString*)dataType { return dataType; }

- (NSString*)processingState { return processingState; }

- (NSDate*)timeStamp { return timeStamp; }

- (BOOL)shouldArchive { return shouldArchive; }


/****
*
* Setting values
*
****/
- (void)setIdentifier:(NSString*)aString
{
  if(identifier != nil) [identifier release];
  identifier = [aString copy];
}

- (void)setDataType:(NSString*)aString
{
  if(dataType != nil) [dataType release];
  dataType = [aString copy];
}

- (void)setProcessingState:(NSString*)state;
{
  if(processingState != nil) [processingState release];
  processingState = [state copy];
}

- (void)timeStampNow;
{
  if(timeStamp != nil) [timeStamp release];
  timeStamp = [NSDate date];
}

- (void)setShouldArchive:(BOOL)state
{
  shouldArchive = state;
}

/****
*
* relationships among trackingInfo
*
****/

- (void)associateWithSample:(NDDSSample*)aSample
{
  if([sampleArray indexOfObject:aSample] == NSNotFound)
    [sampleArray addObject:aSample];
}

- (NSArray*)associatedSamples
{
  return [[sampleArray copy] autorelease];
}

- (BOOL)isSampleCollection
{
  //overridden by subclasses like Gels and Plates where there is not a one-to-one
  //relationship between this Data object and an NDDSSample.
  //uesed for infoTracking before the sampleArray has any objects in it.
  return NO;
}

- (void)addChildData:(NDDSData*)someData;
{
  //used for redundancy or in situations where the processing can not imeadiately
  //associated generated data with an NDDSSample
  if([someData isKindOfClass:[NDDSData class]])
    [childDataArray addObject:someData];
}

- (void)addParentData:(NDDSData*)someData;
{
  if([someData isKindOfClass:[NDDSData class]])
    [parentDataArray addObject:someData];
}

- (NSArray*)childData
{
  return childDataArray;
}

- (NSArray*)parentData
{
  return parentDataArray;
}


@end
