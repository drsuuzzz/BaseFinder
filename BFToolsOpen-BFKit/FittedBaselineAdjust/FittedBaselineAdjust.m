 
/* "$Id: FittedBaselineAdjust.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "FittedBaselineAdjust.h"

/******
* April 26, 1994 Jessica: Fixed bug: this tool would work fine on intel machines
* but would hang indefinately on motorla machines.  The algorithm would hang durring
* the iteration stage and keep adding the same new point forever.  The problem came from
* the fact that in findBaselineMinima, I was checking the interpolation inclusive of the
* end point, and there was a precision difference between the interpolated y at the end
* and the actual y at the end, but only on the motorola machine.  So the algorithm would
* keep adding a new point at the end position and keep finding that it was still negative.
* I suspect the motorola complier differentiates between floats and double, but the intel 
* compiler only uses doubles (so there wasn't this precision error on the intel code).  
* The bug was fixed by recoding the algorithms so that each segment was checked up to
* but not inclusive of the next inflection point.
******/
/*****
* July 19, 1994 Mike Koehrsen
* Split FittedBaselineAdjust class into FittedBaselineAdjust and FittedBaselineAdjustCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation FittedBaselineAdjust

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@"    windowWidth=%d", windowWidth];
  return tempString;
}


typedef struct {
  int     pos;
  float   value;
} basePoint_t;


BOOL findBaselineMinima2(float* data, int startX, float startY, 
				int endX, float endY, int *minX, float *minY)
{
  BOOL    newPoint = NO;
  int     i, minPos=0;
  float   minValue=0.0, baseline, value;

  for(i=startX; i<endX; i++) {
    baseline = (float)(i-startX)*((endY-startY)/(endX-startX)) + startY;
    value = data[i] - baseline;
    if(value < minValue) {	//find smallest point that is less than 0.0
      newPoint = YES;
      minValue = value;
      minPos = i;
    }
  }
  *minX = minPos;
  *minY = minValue;
  return newPoint;
}

- (NSArray*)createFittedBaseline:(Trace*)traceData
                forChannel:(int)channel
             withIntervals:(int)numIntervals
{
  NSMutableArray   *baseline;
  int              i, j, x, numPoints;
  basePoint_t      tempPoint;
  float            *dataArray;
  int              startX, endX, newX;
  float            startY, endY, newY;

  if(traceData == nil) return nil;

  //printf("start createFittedBaseline\n");
  numPoints = [traceData length];
  //printf("numPoints=%d\n",numPoints);
  if([traceData isProxy]) {
    dataArray = (float *)calloc(numPoints, sizeof(float));
    for(i=0; i<numPoints; i++)
      dataArray[i] = [traceData sampleAtIndex:i channel:channel];
  } else
    dataArray = [traceData sampleArrayAtChannel:channel];
  
  baseline = [NSMutableArray array];

  /*** first minima as initial point ***/
  newX = 0;
  newY = dataArray[0];
  for(x=1; x<numPoints; x++) {
    if(dataArray[x] < newY) {
      newX = x;
      newY=dataArray[x];
    }
    else break;
  }
  //printf("first minima x:%d  y:%f\n",newX,newY);
  tempPoint.pos = 0;
  tempPoint.value = newY;
  [baseline addObject:[NSValue value:&tempPoint withObjCType:@encode(basePoint_t)]];

  /*** break the data into interval windows and find min position in each ***/
  for(x=0; x<numIntervals; x++) {
    startX = (numPoints*x)/numIntervals;
    endX = (numPoints*(x+1))/numIntervals - 1;
    if(startX<0) startX=0;
    if(endX>numPoints) endX=numPoints;
    tempPoint.pos = startX;
    tempPoint.value = dataArray[startX];
    for(j=startX;j<endX;j++) {
      if(tempPoint.value > dataArray[j]) {
        tempPoint.pos = j;
        tempPoint.value = dataArray[j];
      }
    }
    [baseline addObject:[NSValue value:&tempPoint withObjCType:@encode(basePoint_t)]];
  }
  //printf("after interval windows\n");

  /*** last minima as final point ***/
  newX = numPoints-1;		
  newY = dataArray[newX];
  for(x=numPoints-2; x>=0; x--) {
    if(dataArray[x] < newY) {
      newX = x;
      newY=dataArray[x];
    }
    else break;
  }
  //printf("last minima x:%d  y:%f\n",newX,newY);
  tempPoint.pos = numPoints;
		// all algorithms work upto but not including next point that is why this is numpoints
		// and not numPoints-1
  tempPoint.value = newY;
  [baseline addObject:[NSValue value:&tempPoint withObjCType:@encode(basePoint_t)]];

  /****
     printf("baseline before iterations\n");
     for(x=0; x<[baseline count]; x++) {
       tpoint = (basePoint_t*) [baseline elementAt:x];
       printf("pos=%d   value=%f\n",tempPoint.pos, tempPoint.value);
     }
     *****/

  /*** now iterate on this list until no data points fall below baseline ***/
  x=0;
  while(x<([baseline count]-1)) {
    [[baseline objectAtIndex:x] getValue:&tempPoint];
    //tempPoint = (basePoint_t*)[baseline elementAt:x];
    startX = tempPoint.pos;
    startY = tempPoint.value;
    [[baseline objectAtIndex:(x+1)] getValue:&tempPoint];
    //tempPoint = (basePoint_t*)[baseline elementAt:(x+1)];
    endX = tempPoint.pos;
    endY = tempPoint.value;	
    //printf("x:%d  start:%d, %f   end:%d, %f\n",x,startX,startY,endX,endY);	
    if(findBaselineMinima2(dataArray, startX, startY, endX, endY, &newX, &newY)) {
      tempPoint.pos = newX;
      tempPoint.value = dataArray[newX];
      [baseline insertObject:[NSValue value:&tempPoint withObjCType:@encode(basePoint_t)]
                              atIndex:(x+1)];
      //[baseline insertElement:&tempPoint at:(x+1)];
      //printf(" adding new point %d  %f, listSize=%d\n",newX, newY, [baseline count]);
      //if([baseline count] > 500) {
      //  [NSException raise:NSRangeException format:@"baseLine generated >500 inflections"];
      //};
    }
    else x++;
  }
  //printf("done creating baseline\n");
  if([traceData isProxy]) free(dataArray);
  return baseline;
}


- (void)adjustData:(Trace*)traceData forChannel:(int)channel withBaseline:(NSArray*)baseline
{
  int           length,x;
  int           sampleSegment, x1, x2;
  float         y1, y2;
  float         dataValue, baseVal;
  basePoint_t   tempPoint;

  length = [traceData length];

  sampleSegment=1;
  [[baseline objectAtIndex:0] getValue:&tempPoint];
  x1 = tempPoint.pos;
  y1 = tempPoint.value;
  [[baseline objectAtIndex:1] getValue:&tempPoint];
  x2 = tempPoint.pos;
  y2 = tempPoint.value;
  for(x=0;x<length;x++) {
    if(x>=x2) {	
      /* shift to next segment of baseline */
      sampleSegment++;
      x1 = x2;
      y1 = y2;
      [[baseline objectAtIndex:sampleSegment] getValue:&tempPoint];
      //tpoint = (basePoint_t*)[baseline elementAt:sampleSegment];
      x2 = tempPoint.pos;
      y2 = tempPoint.value;
    }
    /* linear interpolation */
    if(x1==x2) /* point identical so no need to interpolate (just in case) */
      baseVal=y1;	
    else
      baseVal = ((x-x1)*(y2-y1)/(x2-x1)) + y1;
    dataValue = [traceData sampleAtIndex:x channel:channel];
    [traceData setSample:(dataValue - baseVal) atIndex:x channel:channel];
    //dataArray[x] = dataArray[x] - baseVal;
  }

  /*** check for any negative points (where algoithm failed) ***/
  for(x=0; x<length; x++) {
    dataValue = [traceData sampleAtIndex:x channel:channel];
    if(dataValue<0.0)
      fprintf(stderr, " neg at %d, %f\n",x,dataValue);
  }
}


/****
* Code from old baseline tool
****/
#ifdef OLDCODE

typedef struct {
  int     x;
  float   y;
} minPoint;

- createBaseline:(int)channel
{
  id			dataObject;
  int			count, j, x, thePoint;
  int			start, end;
  float		*dataArray;
  minPoint minVal;

  dataObject = [dataList objectAt:channel];
  count = [dataObject count];
  dataArray = (float*)[dataObject returnDataPtr];
  fittedBaseline = (minPoint*)malloc((samplePoints+1)*sizeof(minPoint));
  for(x=0;x<samplePoints;x++) {
    thePoint = (count*x)/samplePoints;
    start = thePoint;
    end	= thePoint+(count/samplePoints)+1;
    if(start<0) start=0;
    if(end>count) end=count;
    minVal.y = dataArray[start];
    minVal.x = start;
    for(j=start;j<end;j++) {
      if(minVal.y > dataArray[j]) {
        minVal.x = j;
        minVal.y = dataArray[j];
      }
    }
    fittedBaseline[x].x = minVal.x;
    fittedBaseline[x].y = minVal.y;
  }
  /* duplicate last minvalue at the endpoint of the data, guarantees a line till the end of
     the data
     */
  fittedBaseline[x].x = count;
  fittedBaseline[x].y = minVal.y;
  return self;
}

#endif

- printBaseline:(NSArray*)baseline :(int)channel
{
  int           x;
  basePoint_t   tempPoint;

  printf("baseline for channel:%d\n",channel);
  for(x=0; x<[baseline count]; x++) {
    [[baseline objectAtIndex:x] getValue:&tempPoint];
    //tpoint = (basePoint_t*) [baseline elementAt:x];
    printf("pos=%d   value=%f\n",tempPoint.pos, tempPoint.value);
  }
  return self;
}

- (Trace*)turnBaselineIntoTrace:(NSArray*)baseline
{
  Trace*        newTrace;
  float         dataValue;
  int           numPoints, x;
  basePoint_t   tempPoint;

  /* newTrace starts out initialized to all 0.  When the baseline
     * is subtracted from a flat data set you get a negative
     * baseline, so just change the sign of this adjusted data.
     */
  [[baseline lastObject] getValue:&tempPoint];
  //tpoint = (basePoint_t*) [baseline elementAt:[baseline count]-1];
  numPoints = tempPoint.pos+1;
  newTrace = [[Trace alloc] initWithLength:(unsigned)numPoints channels:1];

  [self adjustData:newTrace forChannel:0 withBaseline:baseline];
  //[self adjustData:newTrace withBaseline:baseline];
  for(x=0; x<numPoints; x++) {
    dataValue = [newTrace sampleAtIndex:x channel:0];
    [newTrace setSample:-dataValue atIndex:x channel:0];
  }
  return [newTrace autorelease];
}


- apply
{	
  int       channel;
  Trace     *traceData;
  NSArray   *baseline;

  [self setStatusMessage:@"Adjusting Baseline"];
  traceData = [self dataList];
  for(channel=0;channel<8;channel++) {
    if(selChannels[channel]) {
      baseline =  [self createFittedBaseline:traceData
                                  forChannel:channel
                               withIntervals:([traceData length]/windowWidth)];
      //baseline = [self createFittedBaseline:[traceData objectAt:channel]
      //                                     :([[traceData objectAt:channel] count]/windowWidth)];

      /*** then remove this baseline ***/
      [self adjustData:traceData forChannel:channel withBaseline:baseline];
      //[self adjustData:[traceData objectAt:channel] withBaseline:baseline];
    }
  }
  [self setStatusMessage:nil];
  return [super apply];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType:"i" at:&windowWidth];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType:"i" at:&windowWidth];
}

- (NSString *)toolName
{
  return @"Fitted Baseline Adjust";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"windowWidth"))
    [archiver readData:&windowWidth];
  else
    return [super handleTag:tag fromArchiver:archiver];
		
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&windowWidth type:"i" tag:"windowWidth"];

  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  FittedBaselineAdjust     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  dupSelf->windowWidth = windowWidth;

  return dupSelf;
}

@end
