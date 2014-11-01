/* "$Id: Trace.m,v 1.2 2006/08/04 20:32:15 svasa Exp $" */
/***********************************************************

Copyright (c) 1991-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "Trace.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSValue.h>

@implementation Trace

+ traceWithCapacity:(unsigned int)capacity channels:(unsigned int)channels
{
  return [[[self alloc] initWithCapacity:capacity channels:channels] 	autorelease];
}

+ traceWithLength:(unsigned int)length channels:(unsigned int)channels
{
  return [[[self alloc] initWithLength:length channels:channels] 	autorelease];
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@", numChan=%d", [arrayData count]];
  [tempString appendFormat:@", length=%d", _length];
  return tempString;
}

- init
{
  //should not really call this method but just in case
  [self initWithCapacity:0 channels:0];
  return self;
}

- (void)dealloc
{
  [labelsArray release];
  [arrayData release];
  [attachment autorelease];
  [taggedInfo autorelease];
  [super dealloc];
}

/* - (void)release
{
  fprintf(stderr, "%s, release sent, count=%d\n",
          [[NSString stringWithFormat:@"%@", self] cString], [self retainCount]);
  [super release];
} */

- initWithCapacity:(unsigned int)capacity channels:(unsigned int)channels
{
  int		i;

  [super init];
  arrayData = [[NSMutableArray alloc] initWithCapacity:channels];
  labelsArray = [[NSMutableArray alloc] initWithCapacity:channels];
  for(i=0; i<channels; i++) {
      [arrayData addObject:[[MGNSMutableData dataWithCapacity:capacity*sizeof(float)] setType:'f']];
    [labelsArray addObject:[NSString string]];
  }
  deleteOffset = 0;
  attachment = NULL;
  taggedInfo = [[NSMutableDictionary dictionary] retain];
  return self;
}

- initWithLength:(unsigned int)length channels:(unsigned int)channels;
{
  int		i;

  [super init];
  arrayData = [[NSMutableArray alloc] initWithCapacity:channels];
  labelsArray = [[NSMutableArray alloc] initWithCapacity:channels];
  for(i=0; i<channels; i++) {
    [arrayData addObject:[[MGNSMutableData dataWithLength:length*sizeof(float)] setType:'f']];
    [labelsArray addObject:[NSString string]];
  }
  deleteOffset = 0;
  attachment = NULL;
  taggedInfo = [[NSMutableDictionary dictionary] retain];
  _length = length;
  return self;
}

/*****
* NSCopying section
******/
/****
- copy
{
  return [self copyWithZone:NSDefaultMallocZone()];
}
****/
- (id)copyWithZone:(NSZone *)zone
{
  Trace               *dupSelf;
  unsigned         i, length, numChannels;
  MGNSMutableData    *thisData;

  dupSelf = [[Trace allocWithZone:zone] init];

  numChannels = [self numChannels];
  length = [self length];

  if(dupSelf->labelsArray != nil) [dupSelf->labelsArray release];
  if(dupSelf->arrayData != nil) [dupSelf->arrayData release];

  dupSelf->labelsArray = [labelsArray mutableCopyWithZone:zone];
  dupSelf->arrayData = [[NSMutableArray allocWithZone:zone] initWithCapacity:numChannels];
  for(i=0; i<numChannels; i++) {
    thisData = [arrayData objectAtIndex:i];
    [dupSelf->arrayData addObject:[[thisData mutableCopyWithZone:zone] autorelease]];
  }
  dupSelf->_length = _length;

  dupSelf->attachment = [attachment retain];		//when everything is NSObject
  dupSelf->deleteOffset = deleteOffset;
  dupSelf->taggedInfo = [taggedInfo mutableCopyWithZone:zone];
  return dupSelf;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    //just call self copyWithZone since that appears to do a mutable copy anyway
    //(Maybe for sake of speed that routine should eventually be modified to
    //return a non-mutable copy by just retaining)
    return [self copyWithZone:zone];
}

- replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy])
        return self;
    else
        return [super replacementObjectForPortCoder:encoder];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:arrayData];
    [coder encodeObject:labelsArray];
    [coder encodeValueOfObjCType:@encode(int) at:&deleteOffset];
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&_length];
}

- (id)initWithCoder:(NSCoder *)coder
{
    arrayData = [[coder decodeObject] retain];
    labelsArray = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(int) at:&deleteOffset];
    [coder decodeValueOfObjCType:@encode(unsigned int) at:&_length];

    return self;
}


- (unsigned int)numChannels
{
  return [arrayData count];
}

- (unsigned int)length
{
    return _length;
    //The code below was causing a crash if called after the trace was
    //Initialized with zero channels to start with
    //    MGNSMutableData *temp = [arrayData objectAtIndex:0];
    //    return [temp length]/sizeof(float);
}

- (int)deleteOffset;
{
  return deleteOffset;
}

- (void)setDeleteOffset:(unsigned int)offset;
{
  //for external initialization of processed data
  deleteOffset = offset;
}



/*******
*
* adjusting capacity
*
********/
- (void)addChannel
{
  int     length = [self length];

  [labelsArray addObject:[NSString string]];
  [arrayData addObject:[[MGNSMutableData dataWithLength:length*sizeof(float)] setType:'f']];
}

- (void)addChannelWithData:(MGNSMutableData *)data label:(NSString *)label
{
    [labelsArray addObject:[label autorelease]];
    [data setLength:(_length * sizeof(float))];
    [arrayData addObject:[data autorelease]];
}

- (void)removeChannel:(unsigned int)channel
{
  if(channel >= [arrayData count]) return;
  [arrayData removeObjectAtIndex:channel];
  [labelsArray removeObjectAtIndex:channel];
}

- (void)setLength:(unsigned int)length
{
  unsigned int    tempLength = [self length];
  int    j;

  if(length == tempLength) return;
  for(j=0; j<[arrayData count]; j++) {
    //NSLog(@"old length = %d", [[arrayData objectAtIndex:j] length]);
    tempLength = (unsigned int)(length*sizeof(float));
    [[arrayData objectAtIndex:j] setLength:tempLength];
    //NSLog(@"new length = %d", [[arrayData objectAtIndex:j] length]);
  }
  _length = length;
}

- (void)increaseLengthBy:(unsigned int)extraLength
{
  int		j;

  for(j=0; j<[arrayData count]; j++) {
    [[arrayData objectAtIndex:j] increaseLengthBy:extraLength*sizeof(float)];
  }
  _length += extraLength;
}

- (void)insertSamples:(unsigned int)num atIndex:(unsigned int)index
{
  //inserts samples at 'index' shifting index up
  //interpolates from index-1 to index
  int     i, j, length, count;
  float	  left, right, value, *dataPtr;
  void    *channelPtr, *startPoint, *endPoint;

  if(index > [self length]) return;
  if(num==0) return;

  for(j=0; j<[arrayData count]; j++) {
    dataPtr = (float*)[[arrayData objectAtIndex:j] mutableBytes];
    if(index==0) left=dataPtr[0];
    else left=dataPtr[index-1];
    if(index==[self length]) right=dataPtr[index-1];
    else right=dataPtr[index];

    [[arrayData objectAtIndex:j] increaseLengthBy:num*sizeof(float)];
    length = [[arrayData objectAtIndex:j] length];
    channelPtr = [[arrayData objectAtIndex:j] mutableBytes];
    startPoint = channelPtr + index*sizeof(float);
    endPoint = startPoint + num*sizeof(float);
    count = length-((index-num)*sizeof(float));
    memmove(endPoint, startPoint, count);
    for(i=0; i<num; i++) {
      value = ((right-left)/(num+1) * (i+1)) + left;
      *((float*)(channelPtr + (index+i)*sizeof(float))) = value;
    }
  }
  _length += num;
}

- (void)removeSamples:(unsigned int)num atIndex:(unsigned int)index
{
  int      i, j, length;
  float    *dataPtr;

  if(num==0) return;
  
  for(j=0; j<[arrayData count]; j++) {
    length = [[arrayData objectAtIndex:j] length] / sizeof(float);
    dataPtr = (float*)[[arrayData objectAtIndex:j] mutableBytes];
    if (index >= length)
      [NSException raise:@"NSRangeException" format:@"index greater than Length in obj Trace method removeSamples:"];
    if ((num+index) > length)
      num = length - index;
    for(i=index; i<=(int)(length-num); i++) {
      if(i> (length-num-10)) {
        //NSLog(@"pos=%d  old=%f  new=%f", i, dataPtr[i], dataPtr[i+num]);
      }
      if(i+num >= length) dataPtr[i]=0.0;
      else dataPtr[i] = dataPtr[i+num];
    }

    length = (unsigned int)((length - num) * sizeof(float));
    [[arrayData objectAtIndex:j] setLength:length];
  }
  if(index == 0) deleteOffset+=num;
  _length -= num;
}

- (void)deleteFromPosToEnd:(unsigned)position
{
  if (position >= _length)
    [NSException raise:@"NSRangeException" format:@"position greater than Length in obj Trace method deleteFromPosToEnd:"];
  [self removeSamples:(_length - position) atIndex:position];
}

- (void)insertSamples:(unsigned int)num atIndex:(unsigned int)index channel:(unsigned int)channel;
{
  //in/del for specific channels used for shifting channels relative to one another
  //for now this will do interpolation but extra data off end will be removed
  int       i, length;
  float	    left, right, value, *dataPtr;

  if(channel >= [arrayData count]) return;
  
  dataPtr = (float*)[[arrayData objectAtIndex:channel] mutableBytes];
  length = [[arrayData objectAtIndex:channel] length];  //num bytes
  length /= sizeof(float);

  if(index >= length) return;
  if(num==0) return;
  if(num+index > length) return;

  if(index==0) left=dataPtr[0];
  else left=dataPtr[index-1];
  if(index==length) right=dataPtr[index-1];
  else right=dataPtr[index];

  for(i=(length-1-num); i>=(int)(index); i--) {
    dataPtr[i+num] = dataPtr[i];
  }

  for(i=0; i<num; i++) {
    value = ((right-left)/(float)(num+1) * (float)(i+1)) + left;
    dataPtr[index+i] = value;
  }
}


- (void)removeSamples:(unsigned int)num atIndex:(unsigned int)index channel:(unsigned int)channel
{
  //in/del for specific channels used for shifting channels relative to one another
  //remove will pad end of that channel with last data point
  int     i, length, count;
  void    *channelPtr, *startPoint, *endPoint;
  float	  last;

  if(num==0) return;
  length = [[arrayData objectAtIndex:channel] length];
  channelPtr = [[arrayData objectAtIndex:channel] mutableBytes];
  last = *((float*)(channelPtr + length - sizeof(float)));
  startPoint = channelPtr + (index+num)*sizeof(float);
  endPoint = startPoint - num*sizeof(float);
  count = length-((index+num)*sizeof(float));
  memmove(endPoint, startPoint, count);

  channelPtr = channelPtr + length - ((num+1)*sizeof(float));
  for(i=0; i<num; i++) {
    *((float*)(channelPtr + i*sizeof(float)))=last;
  }
}


/******
*
* distributed object safe methods for access and modify (without copying object)
*
*******/

- (float)sampleAtIndex:(unsigned int)index channel:(unsigned int)channel
{
  float   *channelPtr;

  if(channel>[arrayData count]) return 0.0;
  if(index>[self length]) return 0.0;
  channelPtr = (float*)[[arrayData objectAtIndex:channel] mutableBytes];
  return channelPtr[index];
}

- (void)setSample:(float)data atIndex:(unsigned int)index channel:(unsigned int)channel;
{
  float   *channelPtr;
  if(channel>[arrayData count]) return;
  if(index>[self length]) return;
  channelPtr = (float*)[[arrayData objectAtIndex:channel] mutableBytes];
  channelPtr[index] = data;
}

/*******
*
* non distributedObject safe methods (ie potential of byte-order problems)
* (before using these methods check [traceObject isProxy], if NO, then safe to use this)
*
*******/
- (float*)sampleArrayAtChannel:(unsigned int)channel
{
  return (float*)[[arrayData objectAtIndex:channel] mutableBytes];
}

//The following should be DO safe.
- (MGNSMutableData *)sampleDataAtChannel:(unsigned int)channel
{
    return [arrayData objectAtIndex:channel];
}

/*******
*
* Attachment section: an object associated with this trace data that can store
*   additional information (BF will attach a SequenceEditor)
*
********/
- (void)setAttachment:(id)anObj
{
  [attachment autorelease];
  attachment = [anObj retain]; 
}

- (id)attachment
{
  return attachment;
}

- (NSMutableDictionary*)taggedInfo;
{
  return taggedInfo;
}

/******
*
* Label section: NSString labels associated with each channel of this Trace
*
*******/

- (void)setDefaultRawLabels
{
  unsigned int   i;
  NSString       *tempString;

  for(i=0; i<[labelsArray count]; i++) {
    switch (i) {
      case 0: tempString = @"540 nM"; break;
      case 1: tempString = @"560 nM"; break;
      case 2: tempString = @"580 nM"; break;
      case 3: tempString = @"610 nM"; break;
      default: tempString = @""; break;
    }
    [labelsArray replaceObjectAtIndex:i withObject:tempString];
  }
}

- (void)setDefaultProcLabels
{
  unsigned int   i;
  NSString       *tempString;

  for(i=0; i<[labelsArray count]; i++) {
    switch (i) {
      case 0: tempString = @"Channel C"; break;
      case 1: tempString = @"Channel A"; break;
      case 2: tempString = @"Channel G"; break;
      case 3: tempString = @"Channel T"; break;
      default: tempString = @""; break;
    }
    [labelsArray replaceObjectAtIndex:i withObject:tempString];
  }
}

- (NSString*)labelForChannel:(unsigned int)channel
{
  if(channel < [labelsArray count])
    return [labelsArray objectAtIndex:channel];
  else
    return @"";
}

- (void)setLabel:(NSString*)label forChannel:(unsigned int)channel
{
  if(channel < [labelsArray count]) {
    [labelsArray replaceObjectAtIndex:channel withObject:label];
  }
}

@end
