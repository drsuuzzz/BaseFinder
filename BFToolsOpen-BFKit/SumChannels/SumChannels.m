
/* "$Id: SumChannels.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */

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

#import "SumChannels.h"

/******
* Feb 10, 1998 Jessica: Created first version of tool to help in developing
* algorithm for lane tracking.
******/

@implementation SumChannels

- init
{
  replaceChannels = NO;
  return self;
}

- (NSString *)toolName
{
  return @"Sum Channels";
}

- apply
{	
  int       channel, x, length, numChannels;
  float     tempSum;
  Trace     *traceData;

  traceData = [self dataList];
  length = [traceData length];
  numChannels = [traceData numChannels];
  [traceData addChannel];

  for(x=0; x<length; x++) {
    tempSum=0.0;
    for(channel=0; channel<numChannels; channel++) {
      if(selChannels[channel]) {
        tempSum += [traceData sampleAtIndex:x channel:channel];
      }
    }
    [traceData setSample:tempSum atIndex:x channel:numChannels];
  }

  if(replaceChannels)
    for(channel=0; channel<numChannels; channel++) {
      [traceData removeChannel:0];
    }

  return [super apply];
}

/*****
*
* NSCopying and archiving section
*
******/

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];
  [aDecoder decodeValueOfObjCType:"i" at:&replaceChannels];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];
  [aCoder encodeValueOfObjCType:"i" at:&replaceChannels];
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"replaceChannels"))
    [archiver readData:&replaceChannels];
  else
    return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&replaceChannels type:"i" tag:"replaceChannels"];
  [super writeAscii:archiver];
}

- (id)copyWithZone:(NSZone *)zone
{
  SumChannels     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  dupSelf->replaceChannels = replaceChannels;
  return dupSelf;
}

@end

@implementation SumChannelsCtrl

- (void)getParams
{
  SumChannels  *myProc = dataProcessor;

  myProc->replaceChannels = [replaceChannelsButton state];
  [super getParams];
}

- (void)displayParams
{
  SumChannels  *myProc = dataProcessor;

  [replaceChannelsButton setState:myProc->replaceChannels];
  [super displayParams];
}

@end
