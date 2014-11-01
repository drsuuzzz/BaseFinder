#import "BasecallCutoff.h"
/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/*****
* March 1996 Jessica Severin
* Created tool from modified ToolManualDeletion.
*/

@implementation BasecallCutoff

- init
{
  baseCutoff = 0;
  deleteData = NO;
  return [super init];
}

- apply
{		
  Base    *tempBase;
  int     pointCount;

  if(baseList==NULL || [baseList seqLength]==0) return[super apply];	

  if([self debugmode]) printf("baseCallCutoff %d\n",baseCutoff);

  // delete data at baseCallCutoff point
  if(deleteData && ([baseList seqLength] > baseCutoff)) {
    tempBase = (Base *)[baseList baseAt:baseCutoff];
    pointCount = [dataList length]-[tempBase location];
    [dataList removeSamples:pointCount atIndex:[tempBase location]];
  }

  // delete the bases from baseList
  while([baseList seqLength] > baseCutoff) {
    [baseList removeBaseAt:[baseList seqLength]-1];
  }	

  return [super apply];
}


- (NSString *)toolName
{
  return @"Basecall Cutoff-1.1";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"baseCutoff")) {
    [archiver readData:&baseCutoff];
  } else if (!strcmp(tag,"deleteData")) {
    [archiver readData:&deleteData];
  }
  else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&baseCutoff type:"i" tag:"baseCutoff"];
  [archiver writeData:&deleteData type:"i" tag:"deleteData"];
  //printf("sizeof BOOL = %d\n", sizeof(deleteData));
  [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  BasecallCutoff     *dupSelf;

  dupSelf = [super copyWithZone:zone];

  dupSelf->baseCutoff = baseCutoff;
  dupSelf->deleteData = deleteData;
  return dupSelf;
}

@end


@implementation BasecallCutoffCtrl

- init
{
  [super init];
  return self;
}

- (void)getParams
{
  BasecallCutoff_t *procStruct = (BasecallCutoff_t *)dataProcessor;

  [super getParams];
  procStruct->baseCutoff = [cutoffID intValue];
  procStruct->deleteData = [dataWithBasesID state];

  [self displayParams];
}

- (void)displayParams
{
  BasecallCutoff_t *procStruct = (BasecallCutoff_t *)dataProcessor;

  [super displayParams];
  [cutoffID setIntValue:procStruct->baseCutoff];
  [dataWithBasesID setState:procStruct->deleteData];
}

@end
