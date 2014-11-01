/* "$Id: GenericTool.h,v 1.5 2007/06/04 21:36:10 smvasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, Lloyd Smith and Mike Koehrsen

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
#import <GeneKit/Trace.h>
#import <GeneKit/Sequence.h>
#import <GeneKit/EventLadder.h>
#import <GeneKit/AsciiArchiver.h>
#import <GeneKit/Peak.h>

@class NewScript;

@interface GenericTool:NSObject <NSCopying>
{
  Trace          *dataList;
  Sequence       *baseList;
  Sequence       *alnBaseList;
  AlignedPeaks   *peakList;
  EventLadder    *ladder;
  
  id             controller;
  NewScript      *script;
  
  float          numSelChannels;
  int            selChannels[8];
}

- (id)apply;
- (NSString*)toolName;

- (BOOL)isSelectedChannel:(int)channel;
- (BOOL)shouldCache;
- (BOOL)modifiesData;
- (BOOL)isOnlyAnInterface;
- (BOOL)isInteractive;
- (void)setController:(id)ctrl;
- (void)setScript:(NewScript*)aScript;
- (void)setDataList:(Trace*)theList;
- (void)setBaseList:(Sequence*)theList;
- (void)setAlnBaseList:(Sequence*)theList;
- (void)setPeakList:(AlignedPeaks*)theList;
- (void)setLadder:(EventLadder*)theLadder;
- (Trace*)dataList;
- (Sequence*)baseList;
- (Sequence*)alnBaseList;
- (AlignedPeaks*)peakList;
- (EventLadder*)ladder;
- (void)clearPointers;

- (void)setNumSelChannels:(float)value;
- (void)setSelChannels:(int)value at:(int)index;

- (id)handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

//status methods forwarded to controlling script
- (void)setStatusMessage:(NSString*)aMessage;
- (void)setStatusPercent:(float)percent;

- (BOOL)debugmode;
@end
