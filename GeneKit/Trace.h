/* "$Id: Trace.h,v 1.4 2006/08/04 20:32:15 svasa Exp $" */
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

#import <Foundation/Foundation.h>
#import <GeneKit/MGNSMutableData.h>

@interface Trace:NSObject <NSCopying,NSMutableCopying,NSCoding>
{
  NSMutableArray    *arrayData, *labelsArray;
  id                attachment;
  unsigned int      deleteOffset;
  unsigned int      _length;
  NSMutableDictionary  *taggedInfo;
}


+ traceWithCapacity:(unsigned int)capacity channels:(unsigned int)channels;
+ traceWithLength:(unsigned int)length channels:(unsigned int)channels;

- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;

- init;
  //these adapted from NSData
- initWithCapacity:(unsigned int)capacity channels:(unsigned int)channels;
- initWithLength:(unsigned int)length channels:(unsigned int)channels;

  //querying size of object
- (unsigned int)numChannels;
- (unsigned int)length;
- (int)deleteOffset;
- (void)setDeleteOffset:(unsigned int)offset;

  //adjusting capacity (nullifies any existing data pointers?)
- (void)addChannel;
- (void)addChannelWithData:(MGNSMutableData *)data label:(NSString *)label;
- (void)removeChannel:(unsigned int)channel;
- (void)setLength:(unsigned int)length;
- (void)increaseLengthBy:(unsigned int)extraLength;
- (void)insertSamples:(unsigned int)num atIndex:(unsigned int)index;
- (void)removeSamples:(unsigned int)num atIndex:(unsigned int)index;
- (void)deleteFromPosToEnd:(unsigned)position;
- (void)insertSamples:(unsigned int)num atIndex:(unsigned int)index channel:(unsigned int)channel;
- (void)removeSamples:(unsigned int)num atIndex:(unsigned int)index channel:(unsigned int)channel;
  //in/del for specific channels used for shifting channels relative to one another
  //remove will pad end of that channel with zeros (or last data point)
  //insert will pad the end of the OTHER channels with zeros or the last data point

  //distributed object safe methods for access and modify (without copying object)
- (float)sampleAtIndex:(unsigned int)index channel:(unsigned int)channel;  
- (void)setSample:(float)data atIndex:(unsigned int)index channel:(unsigned int)channel;

  //accessing and modifying data, returned data can be modified
  //returned data pointers may persist temporarily?
- (float*)sampleArrayAtChannel:(unsigned int)channel;	   //returns array[length] of floats
- (MGNSMutableData *)sampleDataAtChannel:(unsigned int)channel;
    //returns an NSMutableData which contains an array of floats

  //any other methods for 'attached' data
  //eg: SequenceEditor, color, offsets, min/max, shifting ....
- (void)setAttachment:(id)anObj;
- (id)attachment;
- (NSMutableDictionary*)taggedInfo;

  // Label Section
- (void)setDefaultRawLabels;
- (void)setDefaultProcLabels;
- (NSString*)labelForChannel:(unsigned int)channel;
- (void)setLabel:(NSString*)label forChannel:(unsigned int)channel;

/*****
* OTHER Methods from ArrayStorage and SeqList that are currently used
* (doesn't mean they should be here, but if they are put here
*  it will be an easier transition)
******/
//- setDefaultRawLabels;
//- setDefaultProcLabels;
//- normalizeAllChannels:(float)scale;
//- copy;
//- autoCalcParams;

// old ArrayStorage methods that still might be in use
//- (float)min;
//- (float)max;
//- setMin:(float)min andMax:(float)max;
//- (char*)getLabel;
//- setLabel:(char*)str;
//- delete:(int)first :(int)last;
//- deleteData:(int)first :(int)last;
//- clearData:(int)first :(int)last;
//- shiftDataBy:(int)dist;

// old SeqList methods that might still be in use
//- (id)copyList;
//- freeList;
//- setLabels:(char **)labels;
//- setDefaultRawLabels;
//- setDefaultProcLabels;


@end
