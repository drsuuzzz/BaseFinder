/* "$Id: GelData.m,v 1.2 2006/08/04 20:31:32 svasa Exp $" */
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


#import "GelData.h"

@implementation GelData

- initWithType:(gelDataType)aType
   numChannels:(int)channelCount
     numFrames:(int)frameCount
         width:(int)aWidth;
{
  [super init];
  gelWidth=aWidth;
  numChannels=channelCount;
  numFrames=frameCount;
  dataType = aType;
  
  dataModified = NO;
  //sourceIdent = uniqueSourceIdent();
  sourceIdent = 1;

  attachments = [[NSMutableDictionary dictionary] retain];
  switch (dataType) {
    case GelDataIntType :
      gelData = [[NSMutableData dataWithLength:(gelWidth * numChannels * numFrames * sizeof(int))] retain];
      break;
    case GelDataFloatType:
      gelData = [[NSMutableData dataWithLength:(gelWidth * numChannels * numFrames * sizeof(float))] retain];
      break;
  }
  return self;
}

- (void)dealloc
{
  if(gelData!=NULL) [gelData release];
  if(attachments!=NULL) [attachments release];
  [super dealloc];	
}

- (int)numberOfChannels { return numChannels; }
- (int)numberOfFrames { return numFrames; }
- (int)width { return gelWidth; }
- (gelDataType)dataType { return dataType; }


- (float)floatValueAtChannel:(int)channel  frame:(int)frame  pos:(int)x
{
  float  floatValue=0.0, *floatPtr;
  int    intValue=0, *intPtr;

  switch (dataType) {
    case GelDataIntType :
      intPtr = (int*)[gelData mutableBytes];
      intPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      intValue = *intPtr;
      floatValue = (float)intValue;
      break;
    case GelDataFloatType:
      floatPtr = (float*)[gelData mutableBytes];
      floatPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      floatValue = *floatPtr;
      break;
  }
  return floatValue;
}

- (int)intValueAtChannel:(int)channel  frame:(int)frame  pos:(int)x;
{
  float  floatValue=0.0, *floatPtr;
  int    intValue=0, *intPtr;

  switch (dataType) {
    case GelDataIntType :
      intPtr = (int*)[gelData mutableBytes];
      intPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      intValue = *intPtr;
      break;
    case GelDataFloatType:
      floatPtr = (float*)[gelData mutableBytes];
      floatPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      floatValue = *floatPtr;
      intValue = (int)floatValue;
      break;
  }
  return intValue;
}


- (void)setFloatValue:(float)value  channel:(int)channel  frame:(int)frame  pos:(int)x;
{
  float  *floatPtr;
  int    intValue=0, *intPtr;

  switch (dataType) {
    case GelDataIntType :
      intPtr = (int*)[gelData mutableBytes];
      intPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      intValue = (int)value;
      *intPtr = intValue;
      break;
    case GelDataFloatType:
      floatPtr = (float*)[gelData mutableBytes];
      floatPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      *floatPtr = value;
      break;
  }
}

- (void)setIntValue:(int)value  channel:(int)channel  frame:(int)frame  pos:(int)x
{
  float  floatValue=0.0, *floatPtr;
  int    *intPtr;

  switch (dataType) {
    case GelDataIntType :
      intPtr = (int*)[gelData mutableBytes];
      intPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      *intPtr = value;
      break;
    case GelDataFloatType:
      floatPtr = (float*)[gelData mutableBytes];
      floatPtr += channel*(numFrames*gelWidth) + frame*(gelWidth) + x;
      floatValue = (float)value;
      *floatPtr = floatValue;
      break;
  }
}

- (int)sourceIdent { return sourceIdent; }

- (NSMutableDictionary*)attachments { return attachments; }

@end

