/* "$Id: ToolManualDeletion.h,v 1.2 2007/01/31 19:36:11 smvasa Exp $" */
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

#import <BaseFinderKit/GenericTool.h>


@interface ToolManualDeletion:GenericTool
{
  @public
  char  firstLoc[32], lastLoc[32];		//char descriptors of positions
  BOOL  leaveSpace;
	int		delChannels[8];
}

- apply;
- (int)convertDescript:(char*)input;

- (void)deleteBases:(int)firstPoint :(int)lastPoint;
- (void)shiftBasesAfterDelete:(int)firstPoint :(int)lastPoint;
- (int)getDelChans:(int)channel;
- (void)setDelChans:(int)val at:(int)index;


- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

@end 
