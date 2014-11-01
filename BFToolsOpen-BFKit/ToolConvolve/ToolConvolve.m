 /* "$Id: ToolConvolve.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolConvolve.h"
#import <GeneKit/NumericalObject.h>

/*****
* Nov 8, 1998  Jessica Severin
* Split into spearate files for PDO
*
* July 19, 1994 Mike Koehrsen
* Split ToolConvolve class into ToolConvolve and ToolConvolveCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/


@implementation ToolConvolve

- apply
{
  int                channel, i, numChannels, numPoints;
  float              c=0.0, *dataArray=NULL;
  NumericalObject    *numObj = [NumericalObject new];

  [self setStatusPercent:0.0]; //don't use, just make sure it's cleared
  [self setStatusMessage:@"Convolution filtering"];
  
  [numObj normalizeWithCommonScale:dataList];
  numChannels = [dataList numChannels];
  numPoints = [dataList length];

  if([dataList isProxy])
    dataArray = (float *)calloc(numPoints, sizeof(float));
    
  for(channel=0; channel<numChannels; channel++) {
    if(selChannels[channel]) {
      if([dataList isProxy]) {
        for(i=0; i<numPoints; i++)
          dataArray[i] = [dataList sampleAtIndex:i channel:channel];
      } else
        dataArray = [dataList sampleArrayAtChannel:channel];
      switch(convType) {
        case 0: 	/* standard convolve */
          c = c + 1.0;
          [numObj convolve:dataArray
                 numPoints:numPoints
                          :sigma
                          :(float)m];
          break;
        case 1: 	/* zero area convolution */
          [numObj Zconvolve:dataArray
                  numPoints:numPoints
                           :sigma
                           :(float)m
                           :(c/numSelChannels)
                           :1.0/numSelChannels
                           :nil  //updateBox
                           :self];
          c = c + 1.0;
          break;
      }
      if([dataList isProxy])
        for(i=0; i<numPoints; i++)
          [dataList setSample:dataArray[i] atIndex:i channel:channel];
    }
  }
  [numObj normalizeWithCommonScale:dataList];
  if([dataList isProxy]) free(dataArray);

  [numObj release];
  [self setStatusMessage:nil];  //clears status display
  return [super apply];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

  [aDecoder decodeValuesOfObjCTypes:"ifi",&m,&sigma,&convType];

  return self;

}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];

  [aCoder encodeValuesOfObjCTypes:"ifi",&m,&sigma,&convType];
}

- (NSString *)toolName
{
  return @"Filter-Convolution";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"m"))
    [archiver readData:&m];
  else if (!strcmp(tag,"sigma"))
    [archiver readData:&sigma];
  else if (!strcmp(tag,"convType"))
    [archiver readData:&convType];
  else
    return [super handleTag:tag fromArchiver:archiver];
		
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&m type:"i" tag:"m"];
  [archiver writeData:&sigma type:"f" tag:"sigma"];
  [archiver writeData:&convType type:"i" tag:"convType"];

  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolConvolve     *dupSelf;

  dupSelf = [super copyWithZone:zone];

  dupSelf->m = m;
  dupSelf->sigma = sigma;
  dupSelf->convType = convType;

  return dupSelf;
}

@end
