/* "$Id: NewScript.m,v 1.8 2007/01/26 04:10:50 smvasa Exp $" */
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

#import "NewScript.h"
#import <GeneKit/AsciiArchiver.h>
#import "ScriptScheduler.h"
#import <objc/List.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/*****	
* May 2, 1997 Jessica Severin
* Simplified caching again. Now all caching is done here in NewScript.  The tool only has the
* data pointers during the -apply method, after which the pointers are cleared.  All cached tool data
* is now kept in NSMutableDictionaries here in NewScript.  New system also allow for separate
* cache flags for data and bases.  Replaced -implementsCache in GenericTool with -shouldCache.
*
* April 21, 1997 Jessica Severin
* Redid data management between scripts and tools.  There were excessive memory leaks
* in these operations.  The new system make the Script responsible for keeping track
* of the retaincount of the data for all the tools.  This makes sense because all data accesses
* eventually come through the script, and not through the tool of the script.  Now tools that
* cache data are left with a copy of their processed data which is freed in GenericTool (but created here).
* The GenericTool methods -setDataList, -clearCache, -setBaseList now check if they cache, and
* do the appropriate release if they do cache.  Other than this caching condition, there is one active
* set of data which is just passed in and out of the tools.  This reduces excessive copies, and makes
* it easier to keep track of memory leaks
*****/

@interface NewScript (LocalNewScript)
- (void)clearCacheWithTestAtIndex:(int)toolIndex;
@end

@implementation NewScript

+ scriptWithContentsOfFile:(NSString*)scriptPath
{
  NewScript       *newScript;
  AsciiArchiver   *archiver;
  char tagBuf[MAXTAGLEN];
  NSString        *tempScriptName;

  archiver = [[[AsciiArchiver alloc] initWithContentsOfFile:scriptPath] autorelease];
  if(archiver == NULL) return nil;

  [archiver getNextTag:tagBuf];

  NS_DURING
    if ((newScript = [archiver readObject])!=nil) {
      tempScriptName = [scriptPath lastPathComponent];
      if([tempScriptName length] == 0)
        [newScript setScriptName:scriptPath];
      else
        [newScript setScriptName:tempScriptName];
    }
    [newScript connectAllToolsToScript];

  NS_HANDLER
    tempScriptName = [scriptPath lastPathComponent];
    if([tempScriptName length] == 0) tempScriptName = scriptPath;
    NSLog(@"exception during -openScript %@: %@\n", tempScriptName, localException);
    newScript = NULL;
  NS_ENDHANDLER

  return newScript;
}

- init
{
  [super init];

  debugMode  = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
  currentExecuteIndex = -1;
  desiredExecuteIndex = -1;
  currentEditIndex = -1;
  autoexecute = YES;
  autosave = NO;
  isActive = NO;
  threadIsExecuting = NO;
  showEditAlert = YES;
  currentCacheWhileThreading = nil;
  useCurrentCacheWhileThreading = NO;
  tools = [[NSMutableArray alloc] initWithCapacity:16];
  unprocessedLists = [[NSMutableArray alloc] init];
  scriptName = [[NSMutableString alloc]  initWithCapacity:64];
  [scriptName setString:@"User modified script"];
  cache = [[NSMutableDictionary dictionary] retain];
  statusMessage = nil;
  statusPercent = 0.0;
  needsToSave = NO;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(switchDebugMode::)
                                               name:@"BFDebugModeChange"
                                             object:nil];
  return self;
}

- (void)dealloc
{
  [unprocessedLists removeAllObjects];
  [unprocessedLists release];
  [cache removeAllObjects];
  [cache release];
  [tools removeAllObjects];
  [tools release];
  [super dealloc];
}

- (void)clearCacheButCurrentExecuted
{
  int i;

  for (i=0; i<[self count]; i++) {
    if(i != currentExecuteIndex) {
      [cache removeObjectForKey:[NSNumber numberWithInt:i]];
    }
  }
}

- (void)switchDebugMode:(NSNotification*)aNotification;
{
  debugMode  = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
}

- (void)setScriptName:(NSString*)name
{
  [scriptName setString:name];
}

- (NSString*)scriptName;
{
  return [[scriptName copy] autorelease];
}

- (NSString*)description
{
  NSMutableString   *tempString;
  int    i;

  tempString = [NSMutableString stringWithString:[super description]];
  [tempString appendFormat:@"scriptName='%@'\n", scriptName];

  [tempString appendFormat:@"rawData[%d]=\n", [unprocessedLists count]];
  for(i=0; i<[unprocessedLists count]; i++) {
    [tempString appendFormat:@"  %@\n", [[unprocessedLists objectAtIndex:i] description]];
  }

  [tempString appendFormat:@"tools[%d]=\n", [tools count]];
  for(i=0; i<[tools count]; i++) {
    [tempString appendFormat:@"  %@\n", [[tools objectAtIndex:i] description]];
  }
  
  return tempString;
}

/*****
*
* Editing section
*
*****/

- (void)alertThatCantEdit
{
#ifdef _APPKITDEFINES_H
  int   panelResult;
  
  NSBeep();
  if(showEditAlert) {
    panelResult = NSRunAlertPanel(@"Cannot edit script",
                                  @"Cannot edit because script is processing data in background",
                                  @"show again", @"don't show again", NULL);
    if(panelResult == NSAlertAlternateReturn) showEditAlert=NO;
  }
#endif
}

- (BOOL)appendTool:(GenericTool*)newTool
{
  //Appends new tool after the current tool, moving all subsequent tools up
  //new tool becomes the current
  int        i, count, toolIndex;
  int	     ucount = [unprocessedLists count];

  if(currentEditIndex<(ucount-1) || currentEditIndex>=[self count]) return NO;
  if(threadIsExecuting) { [self alertThatCantEdit]; return NO; }

  [newTool setScript:self];
  toolIndex = currentEditIndex-ucount+1;
  if(currentEditIndex == [self count] -1) {
    //appending after last position in script
    //NSLog(@"NewScript append to end");
    [tools addObject:newTool];
  } else {
    //NSLog(@"NewScript append after currentEditIndex (at index=%d)", toolIndex);
    [tools insertObject:newTool atIndex:(unsigned int)toolIndex];
    count = [tools count];
    for (i=toolIndex;i<count;i++) {
      [cache removeObjectForKey:[NSNumber numberWithInt:i+ucount]];
      //if not cached does nothing(I hope)
    }
  }

  if(autoexecute) {
    [self setDesiredExecuteIndex:currentEditIndex+1];
    //[self execToIndex:currentEditIndex+1];
    //[self executeInThread];
    if(currentExecuteIndex > currentEditIndex) currentExecuteIndex++;
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:self];
  }
  [self setCurrentEditIndex:currentEditIndex+1];
  [scriptName setString:@"User modified script"];
  needsToSave = YES;
  return YES;
}

- (BOOL)insertTool:(GenericTool*)newTool
{
  //inserts new tool before the current tool, moving all subsequent tools up
  //new tool becomes the current
  int   i, count, toolIndex;
  int	ucount = [unprocessedLists count];

  if(currentEditIndex<ucount || currentEditIndex>=[self count]) return NO;
  if(threadIsExecuting) { [self alertThatCantEdit]; return NO; }

  [newTool setScript:self];
  if(currentCacheWhileThreading == nil)
    currentCacheWhileThreading = [[self currentCache] copy];
  [self clearCacheWithTestAtIndex:currentExecuteIndex];

  toolIndex = currentEditIndex-ucount;
  //NSLog(@"NewScript inserting before current (at index=%d)", toolIndex);
  [tools insertObject:newTool atIndex:(unsigned int)toolIndex];
  count = [tools count];
  for (i=toolIndex;i<count;i++) {
    [cache removeObjectForKey:[NSNumber numberWithInt:i+ucount]];
  }

  if(autoexecute) {
    [self setDesiredExecuteIndex:currentEditIndex];
    //[self execToIndex:currentEditIndex];
    //[self executeInThread];
    if(currentExecuteIndex >= currentEditIndex) currentExecuteIndex++;  
	//so script display is correct while processing
    [[ScriptScheduler sharedScriptScheduler] addForgroundJob:self];
  }

  [self setCurrentEditIndex:currentEditIndex];
  [scriptName setString:@"User modified script"];
  needsToSave = YES;
  return YES;
}

- (BOOL)replaceToolAtIndex:(int)index withTool:(GenericTool*)newTool
{
  int   i, count, toolIndex;
  int	ucount = [unprocessedLists count];
	BOOL	saveCache=NO;
 
  if(index<ucount || index>=([tools count]+ucount)) return NO;
  if(threadIsExecuting) { [self alertThatCantEdit]; return NO; }

  [newTool setScript:self];
  if(currentCacheWhileThreading == nil)
    currentCacheWhileThreading = [[self currentCache] copy];
  [self clearCacheWithTestAtIndex:currentExecuteIndex];
  
	if ([[self toolAt:index] isInteractive] && [[self toolAt:index] shouldCache]) 
		if ([[[self toolAt:index] toolName] isEqualToString:[newTool toolName]])
			saveCache = YES;
	
  toolIndex = index-ucount;
  [tools replaceObjectAtIndex:(unsigned int)toolIndex withObject:newTool];
  count = [tools count];
  for (i=toolIndex;i<count;i++) {
		if (saveCache && (toolIndex == i)) //keep the cache for the interactive tool
		{}
		else  
			[cache removeObjectForKey:[NSNumber numberWithInt:i+ucount]];
  }
  if(index <= currentEditIndex) {
    if(autoexecute) {
      [self setDesiredExecuteIndex:index];
      //[self execToIndex:index];
      //[self executeInThread];
      [[ScriptScheduler sharedScriptScheduler] addForgroundJob:self];
    }
    [self setCurrentEditIndex:index];
  }
  [scriptName setString:@"User modified script"];
  needsToSave = YES;
  return YES;
}

- (BOOL)removeToolAtIndex:(int)index;
{
  int   i, count, toolIndex;
  int	ucount = [unprocessedLists count];

  if(index<ucount || index>=([tools count]+ucount)) return NO;
  if(threadIsExecuting) { [self alertThatCantEdit]; return NO; }

  if(currentCacheWhileThreading == nil)
    currentCacheWhileThreading = [[self currentCache] copy];
  [self clearCacheWithTestAtIndex:currentExecuteIndex];

  toolIndex = index-ucount;
  count = [tools count];
  for (i=toolIndex;i<count;i++) {
    [cache removeObjectForKey:[NSNumber numberWithInt:i+ucount]];
  }
  [tools removeObjectAtIndex:(unsigned int)toolIndex];
  if(index <= currentEditIndex) {
    if(autoexecute) {
      [self setDesiredExecuteIndex:index-1];
      //[self execToIndex:index-1];
      //[self executeInThread];
      if(currentExecuteIndex == currentEditIndex) currentExecuteIndex= -1;
      [[ScriptScheduler sharedScriptScheduler] addForgroundJob:self];
    }
    [self setCurrentEditIndex:index-1];
  }
  [scriptName setString:@"User modified script"];
  needsToSave = YES;
  return YES;
}

/******
*
* Access and executing
*
******/

- (GenericTool*)toolAt:(int)index
{
  int	ucount = [unprocessedLists count];

  if((index >= ucount) && (index < [self count]))
    return [tools objectAtIndex:(index-ucount)];
  else
    return nil;
}

- (GenericTool*)currentTool
{
  int	ucount = [unprocessedLists count];

  if((currentEditIndex >= ucount) && (currentEditIndex < [self count]))
    return [tools objectAtIndex:(currentEditIndex-ucount)];
  else
    return nil;
}

// truncate so current tool is at end
- (void)truncate
{
  int	i, c=[self count], ucount = [unprocessedLists count];

  if (currentExecuteIndex<ucount-1) {
    for (i=ucount-1;i>currentExecuteIndex;i--)
      [self removeUnprocessedList:ucount-1];
    [tools removeAllObjects];
    [cache removeAllObjects];
  } else {	
    for (i=currentExecuteIndex+1;i<c;i++)
      //1-31-96: BUG, memory leak was occurring here that would cause program
      //to crash with repeated changing of the script.
      //[[tools removeLastObject] free];  //tools is a List.
      [tools removeLastObject];
  }
  [scriptName setString:@"User modified script"];
  needsToSave = YES;
}

- (void)clearCacheWithTestAtIndex:(int)toolIndex
{
  //clears the current steps data & bases if the following are true
  // 1) tool should not cache
  // 2) tool is not last tool in script (old not used anymore)
  GenericTool   *thisTool = [self toolAt:toolIndex];

  if(thisTool == NULL) return;

  if(![thisTool shouldCache]) {
    [cache removeObjectForKey:[NSNumber numberWithInt:toolIndex]];
  }
}

- (int)cachedIndexBefore:(int)index
{
  int   i, uCount = [unprocessedLists count];

  for (i=index;i>=uCount;i--) {
    if ([cache objectForKey:[NSNumber numberWithInt:i]]!=nil) {
      return i;
    }
  }
  return (uCount-1);
}

- (void)execToIndex:(int)index;
{
  //could be executed from within another thread
  int                  i, uCount = [unprocessedLists count];
  int                  startPos;
  GenericTool          *thisTool;
  Trace                *tempTrace=nil;
  Sequence             *tempBases=nil, *tempAlnBases=nil;
  AlignedPeaks         *tempPeaks=nil;
  EventLadder          *tempLadder=nil;
  NewScriptCacheEntry  *cacheEntry;
  NSZone               *rootZone = [cache zone];

  if(currentCacheWhileThreading == nil) {
    cacheEntry = [self currentCache];
    currentCacheWhileThreading = [cacheEntry copyWithZone:[cacheEntry zone]];
  }
  useCurrentCacheWhileThreading = YES;
  if(index<currentExecuteIndex) {
    //execing backwards, so current temp cache is no longer valid
    [self clearCacheWithTestAtIndex:currentExecuteIndex];
  }

  startPos = [self cachedIndexBefore:index];
  if((index<uCount) || (startPos == index)) {
    // Some form of cached data exists
		if (![[self toolAt:startPos] isInteractive]) {
			currentExecuteIndex = index;
			useCurrentCacheWhileThreading = NO;
			return;
		}
  }

  if(startPos < uCount) {
    if (debugMode) NSLog(@"extract from unprocessedList");
    cacheEntry = [unprocessedLists objectAtIndex:(uCount-1)];
    tempTrace = [[cacheEntry trace] copy];
    tempBases = [[cacheEntry sequence] copy];
    tempLadder = nil;
    tempPeaks = nil;
    tempAlnBases = nil;
  } else {
    if ([cache objectForKey:[NSNumber numberWithInt:startPos]]!=nil) {
      thisTool = [self toolAt:startPos];
      if (debugMode) NSLog(@"extract cache %@", [thisTool description]);
      if([thisTool shouldCache]) {
        cacheEntry = [cache objectForKey:[NSNumber numberWithInt:startPos]];
        tempTrace = [[cacheEntry trace] copy];
        tempBases = [[cacheEntry sequence] copy];
        tempAlnBases = [[cacheEntry alnSequence] copy];
        tempPeaks = [[cacheEntry peakList] copy];
        tempLadder = [[cacheEntry ladder] copy];
				if ([thisTool isInteractive])//we will be replacing the cache
					[cache removeObjectForKey:[NSNumber numberWithInt:startPos]];
        //leave entry in cache
      } else {
        cacheEntry = [cache objectForKey:[NSNumber numberWithInt:startPos]];
        tempTrace = [[cacheEntry trace] retain];
        tempBases = [[cacheEntry sequence] retain];
        tempAlnBases = [[cacheEntry alnSequence] retain];
        tempPeaks = [[cacheEntry peakList] retain];
        tempLadder = [[cacheEntry ladder] retain];
        [cache removeObjectForKey:[NSNumber numberWithInt:startPos]];
      }
    } else
      if (debugMode) NSLog(@"error extracting entry from cache");
  }
  if ((startPos == index) && [[self toolAt:startPos] isInteractive]) 
		startPos--;
  for (i=startPos+1; i<=index; i++) {
    thisTool=[self toolAt:i];
    [thisTool setDataList:tempTrace];
    [thisTool setBaseList:tempBases];
    [thisTool setLadder:tempLadder];
    [thisTool setAlnBaseList:tempAlnBases];
    [thisTool setPeakList:tempPeaks];

    if(debugMode) fprintf(stderr,"APPLYING %s\n", [[thisTool description] cString]);
    if((tempTrace != nil) && ([tempTrace length] > 0))
       [thisTool apply];  //trace might be nil if tool throws it out

    if(tempTrace  != nil) [tempTrace release];
    if(tempBases  != nil) [tempBases release];
    if(tempLadder != nil) [tempLadder release];
    if(tempAlnBases != nil) [tempAlnBases release];
    if(tempPeaks != nil) [tempPeaks release];
    tempTrace = [[thisTool dataList] retain];
    tempBases = [[thisTool baseList] retain];
    tempLadder = [[thisTool ladder] retain];
    tempAlnBases = [[thisTool alnBaseList] retain];
    tempPeaks = [[thisTool peakList] retain];
    [thisTool clearPointers];

    if((i==index || [thisTool shouldCache])) {
      cacheEntry = [[NewScriptCacheEntry allocWithZone:rootZone] init];
      //trace, bases, & ladder are all inited to nil, so if the following conditions
      //fail the cacheEntry will have nil entries
      if(tempTrace != nil)
        [cacheEntry setTrace:[[tempTrace copyWithZone:rootZone] autorelease]];
      if(tempBases != nil)
        [cacheEntry setSequence:[[tempBases copyWithZone:rootZone] autorelease]];
      if(tempLadder != nil)
        [cacheEntry setLadder:[[tempLadder copyWithZone:rootZone] autorelease]];
      if(tempAlnBases != nil)
        [cacheEntry setAlnSequence:[[tempAlnBases copyWithZone:rootZone] autorelease]];
      if(tempPeaks != nil)
        [cacheEntry setPeakList:[[tempPeaks copyWithZone:rootZone] autorelease]];
      [cacheEntry setCacheName:[thisTool toolName]];
      [cache setObject:cacheEntry forKey:[NSNumber numberWithInt:i]];
      [cacheEntry release];
    }
  }
  currentExecuteIndex = index;
  useCurrentCacheWhileThreading = NO;

  if(tempTrace  != nil) [tempTrace release];
  if(tempBases  != nil) [tempBases release];
  if(tempLadder != nil) [tempLadder release];
  if(tempAlnBases != nil) [tempAlnBases release];
  if(tempPeaks != nil) [tempPeaks release];

  if(autosave) {
    [self setStatusMessage:@"Autosaving"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BFScriptAutosave" object:self];
    needsToSave = NO;
  }
  [self setStatusMessage:nil];
}

- (void)setAutoexecute:(BOOL)state;
{
  autoexecute = state;
  /*
  if(autoexecute) {
    [self setDesiredExecuteIndex:currentExecuteIndex];
    [self execToIndex:currentExecuteIndex];
  }
  */
}

- (BOOL)autoexecute { return autoexecute; }

- (void)setAutosave:(BOOL)state
{
  autosave = state;
}

- (BOOL)autosave { return autosave; }

- (void)setNeedsToSave:(BOOL)state;
{
  needsToSave = state;
}

- (BOOL)needsToSave { return needsToSave; }


- (NSString*)nameAtIndex:(int)index
{
  int   ucount = [unprocessedLists count];

  if (index<ucount) {
    return [[unprocessedLists objectAtIndex:index] cacheName];
  } else if (index < [self count]) {
    return [[tools objectAtIndex:(index-ucount)] toolName];
  } else {
    return NULL;
  }
}		

- (unsigned)count
{
  unsigned  total;

  total = [tools count];
  total += [unprocessedLists count];

  return total;
}

- (BOOL)setCurrentDataList:(Trace *)dataList
                  BaseList:(Sequence *)baseList 
                    ladder:(EventLadder*)aLadder 
               alnBaseList:(Sequence *)alnBases
                  PeakList:(AlignedPeaks *)aPeakList
{
  NewScriptCacheEntry  *cacheEntry;

  if([self toolAt:currentExecuteIndex]==nil) return NO;

  cacheEntry = [NewScriptCacheEntry new];
  [cacheEntry setTrace:dataList];
  [cacheEntry setSequence:baseList];
  [cacheEntry setLadder:aLadder];
  [cacheEntry setAlnSequence:alnBases];
  [cacheEntry setPeakList:aPeakList];
  [cacheEntry setCacheName:@"External data"];
  [cache setObject:cacheEntry forKey:[NSNumber numberWithInt:currentExecuteIndex]];
  [cacheEntry release];

  return YES;
}

- (void)addUnprocessedList:(Trace *)dataList BaseList:(Sequence *)baseList name:(NSString*)theName
{
  NewScriptCacheEntry   *cacheEntry;

  cacheEntry = [[NewScriptCacheEntry alloc] init];
  [cacheEntry setTrace:dataList];
  [cacheEntry setSequence:baseList];

  if (theName) {
    [cacheEntry setCacheName:theName];
  } else {
    [cacheEntry setCacheName:@"Raw data"];
  }

  [unprocessedLists addObject:cacheEntry];
  [cacheEntry release];
  currentEditIndex++;
  currentExecuteIndex++;
}

- (BOOL)removeUnprocessedList:(int)index
{
  if (index >= [unprocessedLists count] || index < 0)
    return NO;
		
  [unprocessedLists removeObjectAtIndex:index];

  if (currentEditIndex >= index)
    currentEditIndex--;

  return YES;	
}

- (int)currentEditIndex { return currentEditIndex; }
- (int)currentExecuteIndex { return currentExecuteIndex; }
- (int)desiredExecuteIndex { return desiredExecuteIndex; }

- (void)setCurrentEditIndex:(int)newValue
{
  if(newValue >= [self count]) return;
  currentEditIndex = newValue;
}
- (void)setCurrentExecuteIndex:(int)newValue
{
  if(newValue >= [self count]) return;
  if(newValue<currentExecuteIndex) [self clearCacheWithTestAtIndex:currentExecuteIndex];
  currentExecuteIndex = newValue;
}
- (void)setDesiredExecuteIndex:(int)newValue
{
  if(newValue >= [self count]) return;
  desiredExecuteIndex = newValue;
}

- (void)setIndexesToEnd
{
  int    pos = [self count]-1;
  [self setDesiredExecuteIndex:pos];
  [self setCurrentEditIndex:pos];
}

- (BOOL)isActive { return isActive; }

- (void)setIsActive:(BOOL)state
{
  isActive = state;
}

- (Trace*)rawData
{
  if ([unprocessedLists count]==0)
    return nil;
  else {
    return [[unprocessedLists objectAtIndex:0] trace];
  }
}

- (Sequence*)rawBases
{
  if ([unprocessedLists count]==0)
    return nil;
  else {
    return [[unprocessedLists objectAtIndex:0] sequence];
  }
}

- (NewScriptCacheEntry*)currentCache
{
  int    uCount = [unprocessedLists count];

  if(useCurrentCacheWhileThreading) {
    return currentCacheWhileThreading;
  }
  else if(currentCacheWhileThreading != nil) {
    [currentCacheWhileThreading autorelease];
    currentCacheWhileThreading = nil;
  };

  if (currentExecuteIndex >= uCount) {
    return [cache objectForKey:[NSNumber numberWithInt:currentExecuteIndex]];
  }

  if(currentExecuteIndex < 0) return nil;

  //current cache is actually from an unprocessed list
  return [unprocessedLists objectAtIndex:currentExecuteIndex];
}

- (Sequence*)currentBases
{
  NewScriptCacheEntry    *currentCache = [self currentCache];

  if(currentCache == nil) return nil;
  return [currentCache sequence];
}

- (Sequence*)currentAlnBases
{
  NewScriptCacheEntry   *currentCache = [self currentCache];
  
  if (currentCache == nil) return nil;
  return [currentCache alnSequence];
}

-(AlignedPeaks*)currentPeakList
{
  NewScriptCacheEntry   *currentCache = [self currentCache];
  
  if (currentCache == nil) return nil;
  return [currentCache peakList];
}

- (Trace*)currentData
{
  NewScriptCacheEntry    *currentCache = [self currentCache];

  if(currentCache == nil) return nil;
  return [currentCache trace];
}

- (EventLadder*)currentLadder
{
  NewScriptCacheEntry    *currentCache = [self currentCache];

  if(currentCache == nil) return nil;
  return [currentCache ladder];
}

- (void)connectAllToolsToScript
{
  //should be fixed more automatically, but can't track down
  int  i;

  for(i=0; i<[tools count]; i++) {
    [[tools objectAtIndex:i] setScript:self];
  }
}

- (id)copyWithZone:(NSZone *)zone
{
  int          toolCount, i;
  GenericTool  *dupTool;
  NewScript    *dupSelf;

  dupSelf = [[[self class] allocWithZone:zone] init];

  toolCount = [tools count];
  for (i=0;i<toolCount;i++) {
    dupTool = [[tools objectAtIndex:i] copy];
    [dupTool clearPointers];
    [dupTool setScript:dupSelf];
    [dupSelf->tools addObject:dupTool];
  }
  dupSelf->currentEditIndex = -1;
  dupSelf->currentExecuteIndex = -1;
  dupSelf->desiredExecuteIndex = -1;
  [dupSelf->scriptName setString:scriptName];
	
  return dupSelf;
}

- (void)writeAscii:archiver
{
  id    *toolPtr;
  int   i;

  [archiver writeString:(char*)[scriptName cString] tag:"scriptName"];

  toolPtr = (id*)calloc([tools count], sizeof(id));
  for(i=0; i<[tools count]; i++) {
    toolPtr[i] = [tools objectAtIndex:i];
  }
  //[archiver writeObject:tools tag:"tools"];
  [archiver writeArray:toolPtr size:[tools count] type:"@" tag:"toolsArray"];
  free(toolPtr);

  return [super writeAscii:archiver];
}

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  int   cnt, i;
  id    *toolPtr, newTool;
  List  *tempTools;
  char  tempBuffer[256];

  if (!strcmp(tag,"scriptName")) {
    [archiver readString:tempBuffer maxLength:255];
    [scriptName release];
    scriptName = [[NSMutableString alloc] initWithCString:tempBuffer];
  } else
  if (!strcmp(tag,"tools")) {
    //pre-openstep scripts archived the tools as a List object
    tempTools = [archiver readObject];
    cnt = [tempTools count];
    if(tools != nil) [tools release];
    tools = [[NSMutableArray alloc] initWithCapacity:cnt];
    for(i=0; i<cnt; i++) {
      newTool = [tempTools objectAt:i];
      [newTool setScript:self];
      [tools addObject:newTool];
    }
  } else if (!strcmp(tag,"toolsArray")) {
    //openstep version archives tools as a simple array of objects
    //and then converts to internal type (NSMutableArray)
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      [self release];
      return nil;
    }
    toolPtr = (id*)calloc(cnt, sizeof(id));
    [archiver readArray:toolPtr];
    if(tools != nil) [tools release];
    tools = [[NSMutableArray alloc] initWithCapacity:cnt];
    for(i=0; i<cnt; i++) {
      newTool = toolPtr[i];
      [newTool setScript:self];
      [tools addObject:newTool];
    }
    free(toolPtr);
  } else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

/****
*
* Threaded Execution section
*   *still need to do cleanup when thread exits
*****/

- (BOOL)threadIsExecuting;
{
  return threadIsExecuting;
}

- (void)lockScriptForThreading
{
  threadIsExecuting = YES;
}

- (void)executeInThread
{
  //this method will be called from a top level execution thread
  //the 'target' object should also be running in this same thread
  NSConnection    *threadConnection;
  NSPort          *port1;
  NSPort          *port2;
  NSArray         *portArray;

  if(self == nil) return;
  //if([self currentExecuteIndex] ==  [self desiredExecuteIndex]) return;
  if([self desiredExecuteIndex] < 0) return;

  threadIsExecuting = YES;

  port1 = [NSPort port];
  port2 = [NSPort port];
  threadConnection = [[NSConnection alloc] initWithReceivePort:port1
                                                      sendPort:port2];
  [threadConnection setRootObject:self];
  portArray = [NSArray arrayWithObjects:port2, port1, nil]; //Ports switched here

  [NSThread detachNewThreadSelector:@selector(runExecuteLoop:)
                           toTarget:self
                         withObject:portArray];
}

- (void)notifyThatThreadDone
{
  //this method is called over an NSConnection because this
  //notification might evenutally lead to an appkit call
  //which cannot by executed from the thread
  desiredExecuteIndex = currentExecuteIndex;  
  [[NSNotificationCenter defaultCenter]
          postNotificationName:@"BFScriptThreadFinished"
                        object:self];
}

/*****
*
*  code that is actually run in the separate thread
*
******/
- (void)runExecuteLoop:(NSArray*)portArray
{
  //called by detachNewThreadSelector:
  //this method will be executing in a separate thread (no-appkit)
  NSAutoreleasePool     *pool =[[NSAutoreleasePool alloc] init];
  NSConnection          *serverConnection;
  int                   index;

  serverConnection = [NSConnection connectionWithReceivePort:[portArray objectAtIndex:0]
                                                    sendPort:[portArray objectAtIndex:1]];

  threadIsExecuting = YES;
  index = [self desiredExecuteIndex];
  [self execToIndex:index];
  threadIsExecuting = NO;

  if([self isActive]) {
    [(id)[serverConnection rootProxy] notifyThatThreadDone];
  }

  [pool release];
  threadIsExecuting = NO;
  [NSThread exit];
}

/******
*
* status methods (may be called from within other threads)
*
*******/

- (NSString*)statusMessage
{
  return statusMessage;
}

- (float)statusPercent
{
  return statusPercent;
}

- (void)setStatusMessage:(NSString*)aMessage
{
  if(statusMessage != nil) [statusMessage release];
  statusMessage = [aMessage retain];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BFScriptStatusChanged" object:self];
}

- (void)setStatusPercent:(float)percent
{
  statusPercent = percent;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BFScriptStatusChanged" object:self];
}

@end

@implementation NewScriptCacheEntry

- init
{
  [super init];
  traceData = nil;
  sequenceData = nil;
  alnSequenceData = nil;
  peakListData = nil;
  ladder = nil;
  cacheName = [[NSString string] retain];
  return self;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"%@, %@", [super description], cacheName];
}

- (Trace*)trace { return traceData; }
- (Sequence*)sequence { return sequenceData; }
- (Sequence*)alnSequence { return alnSequenceData; }
- (AlignedPeaks *)peakList { return peakListData; }
- (EventLadder*)ladder { return ladder; }
- (NSString*)cacheName { return cacheName; }

- (void)setTrace:(Trace*)aTrace
{
  if(traceData != nil) [traceData release];
  traceData = [aTrace retain];
}

- (void)setSequence:(Sequence*)aSeq
{
  if(sequenceData != nil) [sequenceData release];
  sequenceData = [aSeq retain];
}

- (void)setAlnSequence:(Sequence*)bSeq
{
  if(alnSequenceData != nil) [alnSequenceData release];
  alnSequenceData = [bSeq retain];
}

- (void)setPeakList:(AlignedPeaks *)pList
{
  if (peakListData != nil) [peakListData release];
  peakListData = [pList retain];
}

- (void)setLadder:(EventLadder*)aLadder
{
  if(ladder != nil) [ladder release];
  ladder = [aLadder retain];
}

- (void)setCacheName:(NSString*)description;
{
  //used primarily for debugging, when getting a description of the cache
  [cacheName release];
  cacheName = [description copy];
}

- (void)dealloc
{
  if(traceData != nil) [traceData release];
  if(sequenceData != nil) [sequenceData release];
  if(alnSequenceData != nil) [alnSequenceData release];
  if(peakListData != nil) [peakListData release];
  if(ladder != nil) [ladder release];
  if(cacheName != nil) [cacheName release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
  NewScriptCacheEntry    *dupSelf;

  dupSelf = [[[self class] allocWithZone:zone] init];

  if(traceData != nil)
    dupSelf->traceData = [traceData copyWithZone:zone];
  if(sequenceData != nil)
    dupSelf->sequenceData =  [sequenceData copyWithZone:zone];
  if(alnSequenceData != nil)
    dupSelf->alnSequenceData = [alnSequenceData copyWithZone:zone];
  if(peakListData != nil)
    dupSelf->peakListData = [peakListData copyWithZone:zone];
  if(ladder != nil)
    dupSelf->ladder = [ladder copyWithZone:zone];
  dupSelf->cacheName =  [cacheName copyWithZone:zone];

  return dupSelf;
}

@end
