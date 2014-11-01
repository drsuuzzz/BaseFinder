/* "$Id: ToolFFTCtrl.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolFFTCtrl.h"
#import "ToolFFT.h"
#define LOW_FORM 0
#define HIGH_FORM 1


/*****
* Spet 10, 1998 Jessica Severin
* Finally converted to OpenStep and new BaseFinder tool APIs
*
* July 19, 1994 Mike Koehrsen
* Split ToolFFT class into ToolFFT and ToolFFTCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolFFTCtrl

- init
{
  ToolFFT *procStruct = (ToolFFT *)dataProcessor;
  NSDictionary     *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"100.0", @"FFT_HIGHF",
    @"5.0", @"FFT_LOWF",
    @"0.10", @"FFTchop",
    nil];
  

  [super init];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  procStruct-> highCutoff = [[NSUserDefaults standardUserDefaults] floatForKey:@"FFT_HIGHF"];
  procStruct->lowCutoff = [[NSUserDefaults standardUserDefaults] floatForKey:@"FFT_LOWF"];
  procStruct->chopVal = [[NSUserDefaults standardUserDefaults] floatForKey:@"FFTchop"];

  return self;
}

- (void)getParams
{
  ToolFFT *procStruct = (ToolFFT *)dataProcessor;

  procStruct->highCutoff = [[cutoffFormID cellAtIndex:HIGH_FORM] floatValue];
  if(procStruct->highCutoff<1.0) procStruct->highCutoff=1.0;
  procStruct->lowCutoff = [[cutoffFormID cellAtIndex:LOW_FORM] floatValue];
  if(procStruct->lowCutoff<1.0) procStruct->lowCutoff=1.0;

  procStruct->chopVal = [chopValID floatValue]/100.0;
  if(procStruct->chopVal<0) procStruct->chopVal=0.0;
  if(procStruct->chopVal>1.0) procStruct->chopVal=1.0;
  [chopValID setFloatValue:procStruct->chopVal*100.0];

  [[NSUserDefaults standardUserDefaults] setFloat:procStruct->highCutoff forKey:@"HIGHF"];
  [[NSUserDefaults standardUserDefaults] setFloat:procStruct->lowCutoff forKey:@"LOWF"];
  [[NSUserDefaults standardUserDefaults] setFloat:procStruct->chopVal forKey:@"FFTchop"];

  [super getParams];
}

- (void)displayParams
{
  ToolFFT *procStruct = (ToolFFT *)dataProcessor;
  [[cutoffFormID cellAtIndex:HIGH_FORM] setFloatValue:procStruct->highCutoff];
  [[cutoffFormID cellAtIndex:LOW_FORM] setFloatValue:procStruct->lowCutoff];
  [chopValID setFloatValue:procStruct->chopVal*100.0];
		
  [super displayParams];
}

@end
