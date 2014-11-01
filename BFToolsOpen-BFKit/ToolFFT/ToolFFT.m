/* "$Id: ToolFFT.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolFFT.h"
#import <GeneKit/NumericalRoutines.h>
#import <GeneKit/FFT.h>


/*****
* Spet 10, 1998 Jessica Severin
* Finally converted to OpenStep and new BaseFinder tool APIs
*
* July 19, 1994 Mike Koehrsen
* Split ToolFFT class into ToolFFT and ToolFFTCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolFFT

- (BOOL)shouldCache { return YES; }

- (NSString *)toolName
{
  return @"Filter-FFT";
}

- apply
{	
  int     chan, i, numChannels;
  float   *tempArray;

  [self setStatusPercent:0.0]; //don't use, just make sure it's cleared
  [self setStatusMessage:@"FFT filtering"];

  normalizeWithCommonScale(dataList);
  numChannels = [dataList numChannels];
  printf("FFT: %d channels\n",numChannels);
  tempArray = (float*)malloc(sizeof(float)*([dataList length]+2));
  for(chan=0;chan<numChannels;chan++) {
    if(selChannels[chan]) {
      [self setStatusPercent:((float)(chan)/(float)numChannels)*100.0];
      for(i=0; i<[dataList length]; i++) {
        tempArray[i] = [dataList sampleAtIndex:i channel:chan];
      }

      fftFilter(tempArray, [dataList length], (float)lowCutoff, (float)highCutoff, 0);
      chopNormalize(tempArray, [dataList length], chopVal);

      for(i=0; i<[dataList length]; i++) {
        [dataList setSample:tempArray[i] atIndex:i channel:chan];
      }
      [self setStatusPercent:((float)(chan+1)/(float)numChannels)*100.0];
    }
  }
  normalizeWithCommonScale(dataList);

  [self setStatusMessage:nil];  //clears status display
  [self setStatusPercent:0.0];
  return [super apply];
}

/*****
*
* NSCopying and archiving section
*
*****/

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

  [aDecoder decodeValuesOfObjCTypes:"fff",&highCutoff,&lowCutoff,&chopVal];	

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];

  [aCoder encodeValuesOfObjCTypes:"fff",&highCutoff,&lowCutoff,&chopVal];
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if(!strcmp(tag,"highCutoff")) [archiver readData:&highCutoff];
  else if(!strcmp(tag,"lowCutoff")) [archiver readData:&lowCutoff];
  else if(!strcmp(tag,"chopVal")) [archiver readData:&chopVal];
  else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&highCutoff type:"f" tag:"highCutoff"];
  [archiver writeData:&lowCutoff type:"f" tag:"lowCutoff"];
  [archiver writeData:&chopVal type:"f" tag:"chopVal"];
  return [super writeAscii:archiver];
}

- (id)copyWithZone:(NSZone *)zone
{
  ToolFFT     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  dupSelf->highCutoff = highCutoff;
  dupSelf->lowCutoff = lowCutoff;
  dupSelf->chopVal = chopVal;
  return dupSelf;
}

@end
