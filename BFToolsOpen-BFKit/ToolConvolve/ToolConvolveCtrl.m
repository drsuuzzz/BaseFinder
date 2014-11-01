 /* "$Id: ToolConvolveCtrl.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
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

#import "ToolConvolveCtrl.h"
#import "ToolConvolve.h"

#define M_form 0
#define SIG_form 1

/*****
* Nov 8, 1998  Jessica Severin
* Split into spearate files for PDO
*
* July 19, 1994 Mike Koehrsen
* Split ToolConvolve class into ToolConvolve and ToolConvolveCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*/

@implementation ToolConvolveCtrl

- init
{	
  ToolConvolve     *procStruct;
  NSDictionary     *defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"10", @"M",
    @"2", @"sigma",
    @"0", @"ConvType",
    nil];

  [super init];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];

  procStruct = (ToolConvolve *)dataProcessor;

  procStruct->m = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"M"] cString]);
  procStruct->sigma = (float)atof([[[NSUserDefaults standardUserDefaults] objectForKey:@"sigma"] cString]);
  procStruct->convType = (int)atoi([[[NSUserDefaults standardUserDefaults] objectForKey:@"ConvType"] cString]);
  return self;
}

- (void)getParams
{
  ToolConvolve *procStruct = (ToolConvolve *)dataProcessor;	
  char 	M[255], SIGMA[255], tempStr[255];

  procStruct->sigma = [[convolutionformID cellAtIndex:SIG_form] floatValue];
  procStruct->m = [[convolutionformID cellAtIndex:M_form] intValue];
  procStruct->convType = [convolutionType selectedRow];

  sprintf(M, "%d", procStruct->m);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:M]
                                            forKey:@"M"];

  sprintf(SIGMA, "%f", procStruct->sigma);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:SIGMA]
                                            forKey:@"sigma"];

  sprintf(tempStr, "%d", procStruct->convType);
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:tempStr]
                                            forKey:@"ConvType"];

  [super getParams];
}

- (void)displayParams
{
  ToolConvolve *procStruct = (ToolConvolve *)dataProcessor;	

  [[convolutionformID cellAtIndex:M_form] setIntValue:procStruct->m];
  [[convolutionformID cellAtIndex:SIG_form] setFloatValue:procStruct->sigma];
  [convolutionType selectCellAtRow:procStruct->convType column:0];

  [super displayParams];
}

@end
