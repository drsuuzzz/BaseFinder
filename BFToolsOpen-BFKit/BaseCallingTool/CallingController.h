/* "$Id: CallingController.h,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
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

#import <Foundation/Foundation.h>
#import "SpacingObj.h"
#import "SizeObj.h"
#import "WidthObj.h"
#define MIN_SPACING_THRESH	1
#define MAX_SPACING_THRESH	2.9
#define SET_SPACING	2.1
#define CONTROLLER_ADDED_OWNER_ID 1

@interface CallingController:NSObject
{
  NSMutableArray   *calculationStructures;
  id 		   paramObj;
  float  	   finalout, callquit, throwout;
  int 		   highorder, maxit;
  id		   distributor;
  float 	   beginwidthtol, endwidthtol, spacingtol;
}

- init;
- (void)setParamObj:(id)obj;
- (Sequence *)calculateBaseList:(Trace *)dataStorage;
- (Sequence *)dumpBases:(Trace *)dataStorage;
- (void)cleanupBaseList:(Sequence *)baseList :(Trace *)dataStorage;
- (void)prepareBaseList:(Sequence *)baseList :(Trace *)dataStorage;
- (void)fillwidthGaps:(Sequence*)baseList :(Trace*)dataStorage;
- (void)fillGaps:(Sequence *)baseList :(Trace *)dataStorage;
- (void)removeExtraBases:(Sequence *)baseList :(Trace *)dataStorage;
- (Sequence*)indexCall:(Trace *)dataStorage :(int)channel;
@end
