/* "$Id: NewScript.h,v 1.7 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1997-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith

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
#import <BaseFinderKit/ResourceTool.h>
#import <GeneKit/Peak.h>
//ResourceTool.h includes GenericTool, Trace, Sequence, EventLadder, and AsciiArchiver

//MCG 10/5/98 - NewGenericTool declares a part of this same interface in it's own header
//files to avoid dependencies on the locations of the basefinder code.  This means that if
//the following interface is changed, corresponding changes need to be made to NewGenericTool 

@interface NewScriptCacheEntry:NSObject <NSCopying>
{
  Trace       *traceData;
  Sequence    *sequenceData;
  Sequence    *alnSequenceData;
  AlignedPeaks *peakListData;
  EventLadder *ladder;
  NSString    *cacheName;
}
- (Trace*)trace;
- (Sequence*)sequence;
- (Sequence *)alnSequence;
- (AlignedPeaks *)peakList;
- (EventLadder*)ladder;
- (NSString*)cacheName;
- (void)setTrace:(Trace*)aTrace;
- (void)setSequence:(Sequence*)aSeq;
- (void)setAlnSequence:(Sequence *)bSeq;
- (void)setPeakList:(AlignedPeaks *)pList;
- (void)setLadder:(EventLadder*)aLadder;
- (void)setCacheName:(NSString*)description;
@end

@interface NewScript:NSObject <NSCopying>
{
  NSMutableArray        *tools;
  NSMutableArray        *unprocessedLists;
  NSMutableString       *scriptName;
  NSMutableDictionary   *cache;
  NewScriptCacheEntry   *currentCacheWhileThreading;

  NSString    *statusMessage;
  float       statusPercent;

  int	currentEditIndex; /* index of last-applied tool */
  int   currentExecuteIndex, desiredExecuteIndex;
  BOOL  autoexecute, autosave;
  BOOL  isActive;
  BOOL  threadIsExecuting;
  BOOL  showEditAlert;
  BOOL  useCurrentCacheWhileThreading;
  BOOL  needsToSave;
  BOOL  debugMode;
}

+ scriptWithContentsOfFile:(NSString*)scriptPath;

- init;
- (void)clearCacheButCurrentExecuted;

- (void)switchDebugMode:(NSNotification*)aNotification;

- (void)setScriptName:(NSString*)name;
- (NSString*)scriptName;

- (BOOL)appendTool:(GenericTool*)tool;
- (BOOL)insertTool:(GenericTool*)newTool;
- (BOOL)replaceToolAtIndex:(int)index withTool:(GenericTool*)newTool;
- (BOOL)removeToolAtIndex:(int)index;

- (GenericTool*)toolAt:(int)index;
- (GenericTool*)currentTool;

- (void)truncate;

- (void)execToIndex:(int)index;
- (void)setAutoexecute:(BOOL)state;
- (BOOL)autoexecute;
- (void)setAutosave:(BOOL)state;
- (BOOL)autosave;
- (void)setNeedsToSave:(BOOL)state;
- (BOOL)needsToSave;

- (NSString*)nameAtIndex:(int)index;

- (unsigned)count;
- (BOOL)removeUnprocessedList:(int)index;
- (void)addUnprocessedList:(Trace*)dataList BaseList:(Sequence *)baseList name:(NSString*)theName;
- (BOOL)setCurrentDataList:(Trace*)dataList 
                  BaseList:(Sequence *)baseList 
                    ladder:(EventLadder*)aLadder
               alnBaseList:(Sequence *)alnBases
                  PeakList:(AlignedPeaks *)aPeakList;

- (int)currentEditIndex;
- (int)currentExecuteIndex;
- (int)desiredExecuteIndex;  //for threaded/remote execution
- (void)setCurrentEditIndex:(int)newValue;
- (void)setCurrentExecuteIndex:(int)newValue;
- (void)setDesiredExecuteIndex:(int)newValue;
- (void)setIndexesToEnd;
- (BOOL)isActive;
- (void)setIsActive:(BOOL)state;

- (Trace*)rawData;
- (Sequence*)rawBases; // a little weird--this is for bundles that originated as ABI files

- (NewScriptCacheEntry*)currentCache;
- (Sequence*)currentBases;
- (Trace*)currentData;
- (EventLadder*)currentLadder;
- (AlignedPeaks*)currentPeakList;
- (Sequence*)currentAlnBases;

- (void)connectAllToolsToScript;
- (void)writeAscii:archiver;
- (id)handleTag:(char *)tag fromArchiver:archiver;

// multithreaded section
- (void)executeInThread;
- (void)notifyThatThreadDone;
- (void)runExecuteLoop:(NSArray*)portArray;
- (BOOL)threadIsExecuting;
- (void)lockScriptForThreading;

//status methods (posts notification 'BFScriptStatusChanged' when messages changed)
- (NSString*)statusMessage;
- (float)statusPercent;
- (void)setStatusMessage:(NSString*)aMessage;
- (void)setStatusPercent:(float)percent;

@end

