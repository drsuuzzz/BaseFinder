/* "$Id: ArrayStorage.h,v 1.4 2006/08/04 20:31:32 svasa Exp $" */

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



#import <GeneKit/Storage.h>
#import <float.h>
#import <Foundation/NSCoder.h>

typedef struct {
  int	start, end;	        // inclusive points in original index space
  unsigned char	*dataPoints;	// malloced array of the deleted data
} DeletedSeg;

@class NSColor;

//11/2/00 MG trying to remove dependence on old Storage class, by moving to an NSData.

@interface ArrayStorage:Storage
{
  float 	minY, maxY;
  float		xScale, yScale;
  float 	axisY;
  char		name[32];
  int		disable;		// for displaying the points
  NSColor 	*color;
  NSColor 	*gray;
  id		deletedSegments;	// a Storage objects of DeletedSeg structs
  int		deleteOffset;
}

-initCount:(unsigned int)count
             elementSize:(unsigned int)sizeInBytes
             description:(const char *)string;

- (void *)returnDataPtr;
- (unsigned int) elementSize;
- (float)min;
- (float)max;
- setMin:(float)min andMax:(float)max;
- setXScale:(float)scale_x YScale:(float)scale_y;
- getXScale:(float *)scale_x YScale:(float *)scale_y;
- setAxis:(float)axis;
- (float)getAxis;
- (char*)getLabel;
- setLabel:(char*)str;
- (int)enable;
- setEnable:(int)state;
- (NSColor *)color;
- (NSColor *)gray;
- (void)setColor:(NSColor *)thisColor;
- setGray:(NSColor *)thisGray;
- autoCalcParams;
- normalizebyArea;
- normalizebyRange;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (int)deleteOffset;
//- delete:(int)first :(int)last;   		//the cause of the indexing problem
- deleteData:(int)first :(int)last;
- clearData:(int)first :(int)last;
- dumpHistogram;
- shiftDataBy:(int)dist;
- copy;
- normalizeAllChannels:(float)scale;

@end
