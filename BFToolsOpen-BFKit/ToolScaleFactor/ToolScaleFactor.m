/***********************************************************

Copyright (c) 2005 Suzy Vasa 

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

#import "ToolScaleFactor.h"
#import <GeneKit/NumericalObject.h>

@implementation ToolScaleFactor

- apply
{
  int                channel, i, numChannels, numPoints;
  float              *dataArray=NULL;
	Trace							 *channelData;

  [self setStatusPercent:0.0]; //don't use, just make sure it's cleared
  [self setStatusMessage:@"Scaling"];
	
  channelData = [self dataList];
  numChannels = [channelData numChannels];
  numPoints = [channelData length];

  dataArray = (float *)calloc(numPoints, sizeof(float));
	
  for(channel=0; channel<numChannels; channel++) 
	{
		for(i=0; i<numPoints; i++)
				dataArray[i] = [channelData sampleAtIndex:i channel:channel] * sfactor[channel];
		for(i=0; i<numPoints; i++)
				[channelData setSample:dataArray[i] atIndex:i channel:channel];
  }
  
  free(dataArray);

  [self setStatusMessage:nil];  //clears status display
  return [super apply];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

  [aDecoder decodeArrayOfObjCType:"f" count:8 at:sfactor];
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];

  [aCoder encodeArrayOfObjCType:"f" count:8 at:sfactor];
  
}

- (NSString *)toolName
{
  return @"Scale Factor";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"sfactor")) 
    [archiver readData:sfactor];
  else
    return [super handleTag:tag fromArchiver:archiver];
		
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeArray:sfactor size:8 type:"f" tag:"sfactor"];

  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolScaleFactor     *dupSelf;
	int i;

  dupSelf = [super copyWithZone:zone];

	for (i=0; i < 8; i++)
	{
		dupSelf->sfactor[i] = sfactor[i];
	}
  return dupSelf;
}

@end
