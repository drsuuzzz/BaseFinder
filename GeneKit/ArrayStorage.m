/* "$Id: ArrayStorage.m,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

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

#import "ArrayStorage.h"
#import "NumericalRoutines.h"
#import <Foundation/NSString.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#if ! defined PDO && ! defined GNUSTEP_BASE_LIBRARY
#import <AppKit/NSColor.h>
#endif

@implementation ArrayStorage

-initCount:(unsigned)count 
		elementSize:(unsigned)sizeInBytes
		description:(const char *)string
{
  [super initCount:count elementSize:sizeInBytes description:string];
#if ! defined PDO && ! defined GNUSTEP_BASE_LIBRARY
  color=[NSColor blackColor];
#endif
  deletedSegments = [[Storage alloc] initCount:0
                                   elementSize:sizeof(DeletedSeg)
                                   description:"{ii*}"];
  [ArrayStorage setVersion:3];
  deleteOffset = 0;
  return self;
}

-(void *) returnDataPtr 
{
	return dataPtr;
}

- (unsigned int) elementSize
{
	return elementSize;
}

-(float)min
{
	return minY;
}

-(float)max
{
	return maxY;
}

- setMin:(float)min andMax:(float)max
{
	minY = min;
	maxY = max;
	return self;
}

- setXScale:(float)scale_x YScale:(float)scale_y
{
	xScale = scale_x;
	yScale = scale_y;
	return self;
}

- getXScale:(float *)scale_x YScale:(float *)scale_y
{
	*scale_x = xScale;
	*scale_y = yScale;
	return self;
}

- setAxis:(float)axis
{
	axisY = axis;
	return self;
}

- (float)getAxis
{
	return axisY;
}

- (char*)getLabel
{
	return name;
}

- setLabel:(char*)str
{
	strcpy(name,str);
	return self;
}

- (int)enable
{
	return !disable;
}

- setEnable:(int)state
{
	disable = !state;
	return self;
}

- (NSColor *)color
{
	return color;
}

- (NSColor *)gray
{
	return gray;
}

- (void)setColor:(NSColor *)thisColor
{
	color=thisColor;
}

- setGray:(NSColor *)thisGray
{
	gray=thisGray;
	return self;
}

- autoCalcParams
{	
	minY = minVal([self returnDataPtr],[self count]);
	maxY = maxVal([self returnDataPtr],[self count]);
	return self;
}

- normalizebyArea
{
	normalizeToArea(1,[self returnDataPtr],[self count]);
	[self autoCalcParams];
	return self;
}

- normalizebyRange 
{

	normalizeToRange(0, 1, [self returnDataPtr], [self count]);
	[self autoCalcParams];
	return self;
}

- normalizeAllChannels:(float)scale
{
	normalizeBy(scale, (float)0, [self returnDataPtr], [self count]);
	[self autoCalcParams];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	char		*tempChar;
	int			amountShifted=0; // Used to be instance variable-retained for compatibility
	
	//[super encodeWithCoder:aCoder];
	tempChar = name;
	/* no need to write out the delegate because it is set on loading */
	[aCoder encodeValuesOfObjCTypes:"fffff", &minY, &maxY, &xScale, &yScale, &axisY];
	[aCoder encodeValuesOfObjCTypes:"*i",&tempChar,&disable];
	[aCoder encodeObject:color];
	[aCoder encodeValuesOfObjCTypes:"i",&amountShifted];
	[aCoder encodeObject:gray]; 
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  char		*tempChar;
  int		version;
  int		amountShifted;

  version = [aDecoder versionForClassName:@"ArrayStorage"];
  [ArrayStorage setVersion:3];
  //[super initWithCoder:aDecoder];
  [aDecoder decodeValuesOfObjCTypes:"fffff", &minY, &maxY, &xScale, &yScale, &axisY];
  [aDecoder decodeValuesOfObjCTypes:"*i",&tempChar,&disable];
  strcpy(name,tempChar);
  color=[[aDecoder decodeObject] retain];
  if(version>=2) [aDecoder decodeValuesOfObjCTypes:"i",&amountShifted];
  if(version>=3) gray=[[aDecoder decodeObject] retain];

  return self;
}

- (int)deleteOffset;
{
	return deleteOffset;
}

- delete:(int)first :(int)last
{
	if((first==0) || (last==numElements-1)) {
		[self deleteData:first :last];
	}
	else [self clearData:first :last];
	return self;
}

- deleteData:(int)first :(int)last
{	
	/* Remove all elements from "first" to "last", inclusive */
	unsigned char *moverfrom, *moverto;
	int i,j;
	
	if ((first >= last) || (last >= numElements) || (first < 0))
		return self;

	moverto = dataPtr + (first) * elementSize;
	moverfrom = dataPtr + (last + 1) * elementSize;	
	for (i = 0; i < (numElements-last + 1); i ++) {
		for (j = 0; j < elementSize; j ++) 
			*moverto++ = *moverfrom++;
	}		
	numElements = numElements - (last - first + 1);
	
	if(first == 0) {
		deleteOffset += (last - first +1);
	}
	//printf(" delete data %d to %d. offset=%d\n",first,last,deleteOffset);
	return self;
}

- deleteDataWithBackstore:(int)first :(int)last
{
	/* Remove all elements from "first" to "last", inclusive */

	int 							i,j;
	unsigned char			*tmpPtr, *thisData;
	DeletedSeg				*segPtr;
	
	if ((first >= last) || (last >= numElements))
		return self;
	segPtr = (DeletedSeg*) malloc(sizeof(DeletedSeg));
	segPtr->dataPoints = (unsigned char*)calloc((last-first), elementSize);
	tmpPtr = segPtr->dataPoints;
	thisData = dataPtr + (first) * elementSize;
	for (i = 0; i < (last-first+1); i ++) {
		for (j = 0; j < elementSize; j ++) 
			*tmpPtr++ = *thisData++;
	}
	segPtr->start = first;
	segPtr->end = last;
	[deletedSegments addElement:segPtr];
	[self deleteData:first :last];
	return self;
}

- clearData:(int)first :(int)last
{	
	/* zero out all elements from "first" to "last", inclusive */
	unsigned char 	*tmpPtr;
	int i,j;
	
	printf("clear from %d to %d.  NumElements = %d\n",first,last,(int)numElements);
	if ((first >= last) || (last >= numElements))
		return self;

	tmpPtr = dataPtr + (first) * elementSize;
	for (i = 0; i <= (last-first); i ++) {
		for (j = 0; j < elementSize; j ++) 
			*tmpPtr++ = (unsigned char)0;
	}	
	return self;
}


- dumpHistogram {
	dumpHistogram([self returnDataPtr],[self count]);
	return self;
}	

- shiftDataBy:(int)dist
{
	void		*startPoint=NULL, *endPoint=NULL;
	
	if(dist==0) return self;
	if(dist>0) {
		startPoint = dataPtr;
		endPoint = dataPtr + abs(dist)*elementSize;
	}
	if(dist<0) {
		startPoint = dataPtr + abs(dist)*elementSize;
		endPoint = dataPtr;	
	}
	memmove(endPoint, startPoint, (numElements-abs(dist))*elementSize);
	if(dist>0) memset(dataPtr, 0, dist*elementSize);
	if(dist<0) 
		memset(dataPtr+(numElements-abs(dist))*elementSize, 0,
			 abs(dist)*elementSize);
	return self;
}


- copy
{
	typedef struct {
		@defs(ArrayStorage)
	} ArrayStorage_t;

	id		copyID;
	ArrayStorage_t *procStruct;

	
	copyID = [super copy];
	procStruct = (ArrayStorage_t*)copyID;
	
	[copyID setMin:minY andMax:maxY];
	[copyID setXScale:xScale YScale:yScale];
	[copyID setAxis:axisY];
	[copyID setLabel:name];
	[copyID setEnable:(!disable)];
	[copyID setColor:color];
	[copyID setGray:gray];
	procStruct->deleteOffset = deleteOffset;
	return copyID;
}

@end
