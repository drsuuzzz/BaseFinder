/* "$Id: LanesFile.m,v 1.16 2007/05/24 20:21:57 smvasa Exp $" */
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

#import "LanesFile.h"
#import <GeneKit/Trace.h>
#import <GeneKit/EventLadder.h>
#import <GeneKit/Gaussian.h>
#import <GeneKit/NumericalRoutines.h>
#import <GeneKit/AsciiArchiver.h>
#import <GeneKit/SCFTraceFile.h>
#import <GeneKit/readABI.h>
#import "ABIProcessTool.h"
#include <string.h>
#include <sys/types.h>
#include <limits.h>
#ifndef BASEFINDER_CMD_LINE
#import <AppKit/NSPanel.h>
#endif


@protocol ExternalSequenceEditorMethods
- (void)setFileName:(NSString*)aName;
@end

@interface LanesFile (PrivateLanesFile)
- (BOOL)checkNewPath:(NSString *)path;
- (BOOL)saveLane;
- initFromABIFile:(const char *)fullName;
- initFromLANESFile:(NSString *)fullName;
- initFromLANE_File:(NSString*)fullName;
- (int)parseLANESHeader:(char*)dataPtr;
- (BOOL)loadLane:(int)lane;
- (BOOL)addScript:(NewScript*)script;
- (BOOL)createFileHeader:(NSString*)path;
- initFromSCFFile:(NSString*)pathname;
- initFromESDFile:(NSString*)fullName;
- initFromDATFile:(NSString *)fullName;
- initFromShapeFile:(NSString *)fullName;
- (int)countColumns:(NSScanner*)data;
- (Trace*)traceFromTabedAsciiData:(NSData *)data :(int)beginNum;
- (Trace*)readLaneDataAtPath:(NSString*)pathName
                   withScale:(BOOL)usesScale
                 numChannels:(int)numberOfChannels;
- (Sequence*)readLaneSequenceAtPath:(NSString*)pathName;
- (NewScript*)readLaneScriptAtPath:(NSString*)pathName;
- (EventLadder*)readLadderAtPath:(NSString*)pathName;
- (AlignedPeaks*)readPeakListAtPath:(NSString*)pathName;
- (void)setFileName:(NSString*)aName;

@end


@implementation LanesFile

- init
{
  // Lanes will be added; set default values for empty bundle
  debugMode  = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
  numLanes = 0;
  activeLane = -1;
  dataIsLittleEndian = NO;
  rawDataIsScaled = NO;
  currentIndex = 0;
  bundleDir = [[NSMutableString string] retain];
  fileName = nil;
  loadedType = defaultSaveType = SCF;
  lanesScripts = [[NSMutableArray arrayWithCapacity:8] retain];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(autosave:)
                                               name:@"BFScriptAutosave"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(switchDebugMode::)
                                               name:@"BFDebugModeChange"
                                             object:nil];
	needsSaveAs = NO;
  return self;
}

- (void)dealloc
{
  if (debugMode) NSLog(@"%@ dealloc", self);
  [lanesScripts removeAllObjects];
  [lanesScripts release];
  [super dealloc];
}

- (NSString*)description
{
  NSMutableString   *tempString;

  tempString = [NSMutableString stringWithString:[super description]];
  [tempString appendFormat:@"  path='%@'", fileName];
  [tempString appendFormat:@"  numLanes=%d  activeLane=%d", numLanes, activeLane];
  return tempString;
}

- (void)switchDebugMode:(NSNotification*)aNotification;
{
  debugMode  = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
}

- (BOOL)switchToLane:(int)lane
{
  if((lane<1) || (lane>[lanesScripts count])) return NO;

  activeLane = lane;
  if ([[lanesScripts objectAtIndex:(lane-1)] isMemberOfClass:[NSObject class]])
    [self loadLane:lane];

  [[lanesScripts objectAtIndex:(lane-1)] setAutoexecute:YES];
  return YES;
}

- (NewScript*)activeScript
{
  if ([[lanesScripts objectAtIndex:(activeLane-1)] isMemberOfClass:[NSObject class]]) {
    return NULL;
  }
  return [lanesScripts objectAtIndex:(activeLane-1)];
}

- (int)numLanes;
{
  return [lanesScripts count];
}
- (int)activeLane
{
  return activeLane;
}

- (BOOL)applyScript:(NewScript*)script
{
  NewScript  *newScript, *oldScript;
  //int        pos;

  if((activeLane<1) || (activeLane>[lanesScripts count])) return NO;

  newScript = [script copy];
  oldScript = [self activeScript];

  [newScript addUnprocessedList:[[[oldScript rawData] copy] autorelease] BaseList:nil name:NULL];
  [newScript setNeedsToSave:YES];

  //[oldScript release]; //replaceObjectAtIndex sends own release

  [lanesScripts replaceObjectAtIndex:(activeLane-1) withObject:newScript];
  [newScript release];
  //pos = [newScript count]-1;
  //NSLog(@"execTo pos=%d", pos);
  //[newScript execToIndex:pos];

  return YES;
}

- (BOOL)addScript:(NewScript*)script
// With associated data: used for adding data from other file formats
{
  /*
  if(numChannels && (numChannels!=[[script currentData] numChannels]))
    return NO; // Can't mix channel counts
  else
    numChannels=[[script currentData] numChannels];
  */
  [lanesScripts addObject:script];
  if ([lanesScripts count] == 1)
    activeLane = 1;

  return YES;
}

- (NSString*)fileName;
{
  return fileName;
}

- (void)setFileName:(NSString*)aName
{
	if (fileName != nil)
		[fileName release];
	fileName = [aName retain];
}

- (NSComparisonResult)compareName:(LanesFile *)otherObject
{
  return [[[self fileName] lastPathComponent] compare:[[otherObject fileName] lastPathComponent]];
}

-(BOOL)needsSaveAs
{
	return needsSaveAs;
}

/*****
*
*  Initialization from (lane, lanes)
*
******/

- initWithContentsOfFile:(NSString *)fullName
{
  NSString    *type;
  NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

  [self init];

  type = [[fullName pathExtension] lowercaseString];
  if (debugMode) NSLog(@"LanesFile initFromFile of type '%@'", type);

  if ([type isEqualToString:@"abi"] || [type isEqualToString:@"abd"] || [type isEqualToString:@"ab1"] || [type isEqualToString:@"fsa"])
    [self initFromABIFile:[fullName cString]];
  else if ([type isEqualToString:@"dat"] || [type isEqualToString:@"txt"])
    [self initFromDATFile:fullName];
  else if ([type isEqualToString:@"scf"])
    [self initFromSCFFile:fullName];
  else if ([type isEqualToString:@"lane"])
    [self initFromLANE_File:fullName];
  else if ([type isEqualToString:@"lanes"] || [type isEqualToString:@"lanes~"]) {
   if (debugMode) NSLog(@"lanes file");
    [self initFromLANESFile:fullName];
		}
	else if ([type isEqualToString:@"esd"])
		[self initFromESDFile:fullName];
  else if ([type isEqualToString:@"shape"])
    [self initFromShapeFile:fullName];

  if(fileName != nil) [fileName release];
  fileName = [fullName copy];

  [pool release];
  return self;
}

- initFromABIFile:(const char *)fullName
{	
  Trace       *rawList, *processedList;
  Sequence    *bases;
  NewScript   *script;

  numChannels = 4;
  processedList = [[Trace alloc] initWithCapacity:1024 channels:numChannels];
  rawList = [[Trace alloc] initWithCapacity:1024 channels:numChannels];
  bases = [Sequence newSequence];
  readABISeq((char*)fullName, processedList, rawList, bases);

  script = [[NewScript alloc] init];
  [script setAutoexecute:NO];
  
  if ([processedList length]>0) {
    [script addUnprocessedList:processedList BaseList:nil name:@"Raw ABI Data"];

    
/*    ABIProcessTool   *abiTool = [[ABIProcessTool alloc] init];

    [processedList setDefaultProcLabels];
    [[processedList taggedInfo] setObject:[NSString stringWithCString:fullName] forKey:@"originalFilePath"];
    [[processedList taggedInfo] setObject:@"abi"  forKey:@"originalFileType"];  

    [script appendTool:abiTool];
    [script setCurrentEditIndex:[script count]-1];
    [script setCurrentExecuteIndex:[script count]-1];
    [script setCurrentDataList:processedList 
                      BaseList:(([bases seqLength] > 0) ? bases: nil) 
                        ladder:nil 
                   alnBaseList:nil 
                      PeakList:nil];*/
    //if ([bases seqLength] > 0) [bases release];
    [rawList release];
    rawList = nil;
  } else {
    [script addUnprocessedList:rawList BaseList:nil name:@"Raw ABI Data"];
    [rawList setDefaultRawLabels];
    [[rawList taggedInfo] setObject:[NSString stringWithCString:fullName] forKey:@"originalFilePath"];
    [[rawList taggedInfo] setObject:@"abi"  forKey:@"originalFileType"];  
        
    [processedList release];
   // [bases release];         //will crash because of autorelease pool because newSequence is autorelease.
    processedList = nil;
  }
  [script setNeedsToSave:NO];

  [self addScript:script];
  [script release];

  if (debugMode) {
    if (rawList != nil) NSLog(@" raw length=%d", [rawList length]);
    if(processedList != NULL) NSLog(@" proc length=%d", [processedList length]);
  }
	defaultSaveType = DAT;
	needsSaveAs = YES;
  return self;
}

- ORIGinitFromABIFile:(const char *)fullName
{	
  Trace       *rawList, *processedList;
  Sequence    *baseStorage;
  NewScript   *script;

  numChannels = 4;
  processedList = [[Trace alloc] initWithCapacity:1024 channels:numChannels];
  rawList = [[Trace alloc] initWithCapacity:1024 channels:numChannels];
  baseStorage = [Sequence newSequence];
  readABISeq((char*)fullName, processedList, rawList, baseStorage);

  script = [[NewScript alloc] init];
  [script addUnprocessedList:rawList BaseList:nil name:@"Raw ABI Data"];
  [rawList setDefaultRawLabels];

  [self addScript:script];
  [script release];

  if ([processedList length]>0) {
    script = [[NewScript alloc] init];
    [script addUnprocessedList:processedList BaseList:baseStorage name:@"Processed ABI Data"];
    [processedList setDefaultProcLabels];
    [self addScript:script];
  } else {
    NSLog(@"ABI processed List is empty");
    [processedList release];
    processedList = NULL;
    [baseStorage release];
  }

  if (debugMode) NSLog(@" raw length=%d", [rawList length]);
  if(processedList != NULL)
    if (debugMode) NSLog(@" proc length=%d", [processedList length]);

  /*
  for (i=0; i <numChannels; i++) {
    if(processedList != NULL) [[processedList objectAt:i] autoCalcParams];
    [[rawList objectAt:i] autoCalcParams];
  }
  */
	return self;
}


/*
 * ESD Format
 *
 */

- initFromESDFile:(NSString*)fullName
{
	ESDRecord curRecord, *records;
	NSData            *data;
	int numRecords, i;
  Trace             *rawList;
  NewScript         *script;
	

	data = [NSData dataWithContentsOfFile:fullName];
  if(data == NULL)	
		[NSException raise:@"File system error"
								format:@"Could not read this ESD file"];
	numRecords = [data length] / sizeof(ESDRecord);
	if (numRecords < 1)
		[NSException raise:@"File system error" 
								format:@"File length of zero in ESD file %@", 
			[fullName lastPathComponent]];
	fprintf(stderr, "Reading %d records from ESD file\n", numRecords);
	
	rawList = [[Trace alloc] initWithLength:numRecords channels:4];
	records = (ESDRecord *)[data bytes];
	for (i = 0; i < numRecords; i++) {
		curRecord = records[i];
		[rawList setSample:(float)NSSwapLittleShortToHost(curRecord.data8) 
								atIndex:i
								channel:0];
		[rawList setSample:(float)NSSwapLittleShortToHost((int)curRecord.data6) 
								atIndex:i
								channel:1];
		[rawList setSample:(float)NSSwapLittleShortToHost((int)curRecord.data4) 
								atIndex:i
								channel:2];
		[rawList setSample:(float)NSSwapLittleShortToHost((int)curRecord.data2) 
								atIndex:i
								channel:3];
	}
	numChannels = 4;
  [[rawList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
  [[rawList taggedInfo] setObject:@"esd"  forKey:@"originalFileType"];  
		
	script = [[NewScript alloc] init];
  [script addUnprocessedList:rawList BaseList:nil name:@"ESD Data"];
  [self addScript:script];
  [script release];
  loadedType = ESD; defaultSaveType = LANE;
	needsSaveAs = YES;
  return self;
}

- initFromLANE_File:(NSString*)fullName
{
  //single lane version of the .lanes file format
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  NewScript        *tempScript;
  char             *header;
  BOOL             foundScript=NO, foundProcTrace=NO;
  Trace            *dataList;
  Sequence         *baseList=nil;

  [bundleDir setString:fullName];

  /*** Read info file ***/
  headerPath = [fullName stringByAppendingPathComponent:@"LaneInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];

  if (headerData == nil) {
    if (debugMode) NSLog(@"initFromFile: couldn't open %s.", [fullName cString]);
    return NULL;
  }

  header = (char*)[headerData bytes];
  [self parseLANESHeader:header];
  numLanes = 1;  //just in case
  activeLane = 1;

  //1. load script.scr, if present
  pathName = [fullName stringByAppendingPathComponent:@"script"];
  tempScript = [self readLaneScriptAtPath:pathName];
  if(tempScript != nil) foundScript=YES;
  else tempScript = [[NewScript alloc] init];

  //2. raw data
  pathName = [fullName stringByAppendingPathComponent:@"rawTrace"];
  if(rawDataIsScaled)
    dataList = [self readLaneDataAtPath:pathName withScale:YES numChannels:numChannels];
  else
    dataList = [self readLaneDataAtPath:pathName withScale:NO numChannels:numChannels];

  [dataList setDefaultRawLabels];
  [[dataList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
  [[dataList taggedInfo] setObject:@"lane"   forKey:@"originalFileType"];  
  [tempScript addUnprocessedList:dataList BaseList:nil name:NULL];


  //3. load procTrace and procTrace.bsl, if present
  pathName = [fullName stringByAppendingPathComponent:@"procTrace"];
  dataList = [self readLaneDataAtPath:pathName withScale:YES numChannels:currentNumChannels];
  if (dataList != nil) {
    foundProcTrace = YES;
    pathName = [fullName stringByAppendingPathComponent:@"procTrace.bsl"];
    baseList = [self readLaneSequenceAtPath:pathName];
  }
  if(baseList) [dataList setDefaultProcLabels];
  else [dataList setDefaultRawLabels];
  [[dataList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
  [[dataList taggedInfo] setObject:@"lane"   forKey:@"originalFileType"];  

  if(currentDataOffset > 0) [dataList setDeleteOffset:currentDataOffset];

  if(foundScript && foundProcTrace) {
    if((currentIndex >= 0)  && (currentIndex<[tempScript count])) {
      [tempScript setCurrentEditIndex:currentIndex];
      [tempScript setCurrentExecuteIndex:currentIndex];
    } else {
      //assume in older format where stored at the end
      [tempScript setCurrentEditIndex:[tempScript count]-1];
      [tempScript setCurrentExecuteIndex:[tempScript count]-1];
    }
    [tempScript setCurrentDataList:dataList BaseList:baseList ladder:nil alnBaseList:nil PeakList:nil];
  } else {
    [tempScript setCurrentEditIndex:0];
    [tempScript setCurrentExecuteIndex:0];
  }
  [self addScript:tempScript];

  loadedType = defaultSaveType = LANE;
  return self;
}

- initFromLANESFile:(NSString *)fullName
{
  NSString   *headerPath;
  NSData     *headerData;
  char       *header;
  int        i;

  [bundleDir setString:fullName];

  /*** Read info file ***/
  headerPath = [fullName stringByAppendingPathComponent:@"LaneInfo"]; 
  headerData = [NSData dataWithContentsOfFile:headerPath];

  if (headerData) {
    header = (char*)[headerData bytes];
    [self parseLANESHeader:header];
    lanesScripts = [[NSMutableArray array] retain];
    for(i=0; i<numLanes; i++) {
      [lanesScripts addObject:[NSObject new]]; //use plain NSObjects as place holders
    }
    activeLane = -1;
  } else {
    if (debugMode) NSLog(@"initFromFile: couldn't open %s.", [fullName cString]);
    return NULL;
  }
  
  /*** does not load in a lane though ***/
  loadedType = defaultSaveType = LANES;
  return self;
}

- initFromShapeFile:(NSString *)fullName
{
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  NewScript        *tempScript;
  char             *header;
  BOOL             foundScript=NO, foundProcTrace=NO;
  Trace            *dataList;
  Sequence         *baseList=nil, *alnBases=nil;
  EventLadder      *ladder=nil;
  AlignedPeaks     *peakList=nil;
  NSData           *data;
  
  
  //  [bundleDir setString:fullName];
  
  /*** Read info file ***/
  headerPath = [fullName stringByAppendingPathComponent:@"SHAPEInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];
  
  if (headerData == nil) {
    if (debugMode) NSLog(@"initFromFile: couldn't open %s.", [fullName cString]);
    return NULL;
  }
  
  header = (char*)[headerData bytes];
  [self parseLANESHeader:header];
  numLanes = 1;  //just in case
  activeLane = 1;
  if (debugMode) NSLog(@"initFromFile: done with header...");

  //1. load script.scr, if present
  pathName = [fullName stringByAppendingPathComponent:@"script"];
  tempScript = [self readLaneScriptAtPath:pathName];
  if(tempScript != nil) foundScript=YES;
  else tempScript = [[NewScript alloc] init];
  if (debugMode) NSLog(@"initFromFile: Loading script...");
  
  //2. raw data
  pathName = [fullName stringByAppendingPathComponent:@"rawTrace"];
  data = [NSData dataWithContentsOfFile:pathName];
  dataList = [self traceFromTabedAsciiData:data :0];  
  [dataList setDefaultRawLabels];
  [[dataList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
  [[dataList taggedInfo] setObject:@"shape"   forKey:@"originalFileType"];  
  [tempScript addUnprocessedList:dataList BaseList:nil name:NULL];
  if (debugMode) NSLog(@"initFromFile: raw data...");

  //3. load procTrace and procTrace.bsl, if present
  pathName = [fullName stringByAppendingPathComponent:@"procTrace"];
  data = [NSData dataWithContentsOfFile:pathName];
  dataList = [self traceFromTabedAsciiData:data :0];
  if (dataList != nil) {
    foundProcTrace = YES;
    pathName = [fullName stringByAppendingPathComponent:@"procTrace.bsl"];
    baseList = [self readLaneSequenceAtPath:pathName];
    if (debugMode) NSLog(@"initFromFile: Loading base list...");
  }
  if(baseList) [dataList setDefaultProcLabels];
  else [dataList setDefaultRawLabels];
  [[dataList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
  [[dataList taggedInfo] setObject:@"shape"   forKey:@"originalFileType"];  
  
  if(currentDataOffset > 0) [dataList setDeleteOffset:currentDataOffset];
  
  //4. load ladder, aligned bases, and peak list
  pathName = [fullName stringByAppendingPathComponent:@"procTrace.ldr"];
  ladder = [self readLadderAtPath:pathName];
  if (debugMode) NSLog(@"initFromFile: Loading ladder...");

  pathName = [fullName stringByAppendingPathComponent:@"procTrace.aln"];
  alnBases = [self readLaneSequenceAtPath:pathName];
  if (debugMode) NSLog(@"initFromFile: Loading aligned base list...");

  pathName = [fullName stringByAppendingPathComponent:@"procTrace.pkl"];
  peakList = [self readPeakListAtPath:pathName];
  if (debugMode) NSLog(@"initFromFile: Loading peak list...");

  if(foundScript && foundProcTrace) {
    if((currentIndex >= 0)  && (currentIndex<[tempScript count])) {
      [tempScript setCurrentEditIndex:currentIndex];
      [tempScript setCurrentExecuteIndex:currentIndex];
    } else {
      //assume in older format where stored at the end
      [tempScript setCurrentEditIndex:[tempScript count]-1];
      [tempScript setCurrentExecuteIndex:[tempScript count]-1];
    }
    [tempScript setCurrentDataList:dataList BaseList:baseList ladder:ladder alnBaseList:alnBases PeakList:peakList];
  } 
  else {
    [tempScript setCurrentEditIndex:0];
    [tempScript setCurrentExecuteIndex:0];
  }
  [self addScript:tempScript];
  
  loadedType = defaultSaveType = SHAPE;
  return self;  
}

- (int)parseLANESHeader:(char*)dataPtr
{
  BOOL		done=NO;
  char		lineBuffer[256], *tempPtr, *token;
  int		x, state, headerSize;

  numLanes = 1;
  numChannels = 4;
  dataIsLittleEndian=NO;
  rawDataIsScaled = NO;
  currentDataOffset = 0;
  currentIndex = -1;
  currentNumChannels = 4;

  tempPtr = dataPtr;
  while(!done) {
    x=0;
    while((*tempPtr)!='\n') {
      lineBuffer[x++] = *tempPtr;
      tempPtr++;
    }
    lineBuffer[x]='\0';
    tempPtr++;

    //NSLog(@"parse:'%s'",lineBuffer);
    if(strcmp(lineBuffer,"end")==0) done=YES;
    else {
      token = strtok(lineBuffer,": \t\n[]");
      state=0;
      while(token!=NULL) {
        switch(state) {
          case 0:
            if(strcmp(token,"numLanes")==0) state=1;
            if(strcmp(token,"numChannels")==0) state=2;
            if(strcmp(token,"byteOrder")==0) state=4;
            if(strcmp(token,"rawDataIsScaled")==0) state=5;
            if(strcmp(token,"currentDataOffset")==0) state=6;
            if(strcmp(token,"currentIndex")==0) state=7;
            if(strcmp(token,"currentNumChannels")==0) state=8;
            break;
          case 1:	/* numLanes */
            numLanes = atoi(token);
            if (debugMode) NSLog(@" numLanes=%d",numLanes);
            state=-1;
            break;
          case 2:	/* numChannels */
            numChannels = atoi(token);
            if (debugMode) NSLog(@" numChannels=%d",numChannels);
            state=-1;
            break;
          case 4:	/* byteOrder */
            if(strcmp(token,"bigEndian")==0) dataIsLittleEndian=NO;
            else dataIsLittleEndian=YES;
            if (debugMode) NSLog(@" data is '%s'",token);
            state=-1;
            break;
          case 5:	/* rawDataIsScaled */
            if(strcmp(token,"yes")==0) rawDataIsScaled=YES;
            else rawDataIsScaled=NO;
            if (debugMode) NSLog(@" rawDataIsScaled = '%s'",token);
            state=-1;
            break;
          case 6:	/* currentDataOffset */
            currentDataOffset = atoi(token);
            if (debugMode) NSLog(@" currentDataOffset = '%s'",token);
            state=-1;
            break;
          case 7:	/* currentIndex */
            currentIndex = atoi(token);
            if (debugMode) NSLog(@" currentIndex = '%s'",token);
            state=-1;
            break;
          case 8:	/* currentNumChannels */
            currentNumChannels = atoi(token);
            if (debugMode) NSLog(@" currentNumChannels = '%s'",token);
            state=-1;
            break;
          default:
            break;
        }
        token = strtok(NULL,": \t\n[]");
      }
    }
  }
  headerSize = (int)tempPtr - (int)(dataPtr);
  if (debugMode) NSLog(@"headerSize=%d",headerSize);
  return headerSize;
}

- (NewScript*)readLaneScriptAtPath:(NSString*)pathName
{
  NSFileManager    *filemanager = [NSFileManager defaultManager];
  NewScript        *tempScript=nil;
  AsciiArchiver    *archiver;

  if ([filemanager fileExistsAtPath:pathName]) {
    archiver = [[AsciiArchiver alloc] initWithContentsOfFile:pathName];

    NS_DURING
      tempScript = [archiver readObjectWithTag:"script"];  //returns a NewScript objectID
    NS_HANDLER
      if(([[localException name] isEqualToString:@"AA_classUnknown"]) ||
         ([[localException name] isEqualToString:@"AA_syntaxError"])) {
#if !defined(BASEFINDER_CMD_LINE)
        NSRunAlertPanel(@"Error loading script", @"%@", @"OK", nil, nil, localException);
#endif
        NSLog(@"Error loading script %@", localException);
      }
      else {
        NSLog(@"exception raised by archiver, but unknown kind.");
        [localException raise];		//exception unknown, pass up a level
      }
    NS_ENDHANDLER
    //NSLog(@"after exception handle section");
    if(archiver) [archiver release];
  }
  return tempScript;
}

- (Trace*)readLaneDataAtPath:(NSString*)pathName
                   withScale:(BOOL)usesScale
                 numChannels:(int)numberOfChannels
{
  Trace            *dataList;
  NSData           *fileData;
  void	           *data;
	unsigned short	 *loc;
  int              i, j, count, numPerChannel;
  unsigned short   tempShort;
  signed short     tempSignedShort;
  float            tempFloat;
  short            scale=1;

  
  fileData = [NSData dataWithContentsOfFile:pathName];
  if(fileData == nil) return nil;
  
  count = [fileData length]/sizeof(short);
  if(usesScale) numPerChannel = (count-1)/(numberOfChannels);
  else numPerChannel = (count)/(numberOfChannels);
  dataList = [Trace traceWithLength:numPerChannel channels:numberOfChannels];

  if(usesScale) {
    scale = *(short*)[fileData bytes];
    if (dataIsLittleEndian) scale = NSSwapLittleShortToHost(scale);
    else scale = NSSwapBigShortToHost(scale);
    if (debugMode) NSLog(@"scale factor = %d",scale);
    data = (void*)[fileData bytes] + sizeof(short);
  } else {
    data = (void*)[fileData bytes];
  }
  loc = (unsigned short *)data;
  for (i = 0; i < numberOfChannels; i++) {
    for (j = 0; j < numPerChannel; j++) {
      tempShort = *(loc);
      loc++;
      if(dataIsLittleEndian)
        tempShort = (unsigned short)NSSwapLittleShortToHost(tempShort);
      else
        tempShort = (unsigned short)NSSwapBigShortToHost(tempShort);

      if(usesScale) {
        tempSignedShort = (signed short) tempShort;
        tempFloat = ((float)tempSignedShort)/(float)scale;
      } else
        tempFloat = (float)tempShort;
      [dataList setSample:tempFloat atIndex:(unsigned)j channel:(unsigned)i];
    }
  }
  return dataList;
}

- (Sequence*)readLaneSequenceAtPath:(NSString*)pathName
{
  Sequence         *baseList=nil;
  Base             *thisBase;
  FILE             *fp;
  int              location, back, offset;
  char             base;
  float            confidence;

  fp = fopen([pathName fileSystemRepresentation],"r");

  if (fp) {
		baseList = [Sequence newSequence];
		if (fscanf(fp, "%d %d",&back,&offset) == 2) {
			[baseList setOffset:offset];
			[baseList setbackForwards:((back==1) ? YES : NO)];
		}
		else
			rewind(fp);
    while(fscanf(fp,"%d %c %f",&(location),&(base),&(confidence))==3) {
      //confidence stored in file as float in 0.0-1.0 range (old format)
      thisBase = [[Base alloc] init];
			[thisBase setBase:base];
			[thisBase setLocation:location];
      confidence = confidence*255;
      if(confidence>255.0) confidence=255;
			[thisBase setConf:confidence];
      [baseList addBase:thisBase];
      [thisBase release];
    }
    fclose(fp);
  } else
    baseList = nil;
  return baseList;
}

- (EventLadder*)readLadderAtPath:(NSString*)pathName
{
  EventLadder      *ladder=nil;
  Gaussian         *thisPeak;
  float            width, center, scale;
  int              channel;
  FILE             *fp;
  
  fp = fopen([pathName fileSystemRepresentation],"r");
   if (fp) {
     ladder = [[EventLadder alloc] init];
     while(fscanf(fp,"%d %f %f %f",&(channel),&width,&(center),&scale)==4) {
       thisPeak = [Gaussian GaussianWithWidth:width 
                                        scale:scale 
                                       center:center];
       [thisPeak setChannel:channel];
       [ladder addEntry:thisPeak];
     }
     fclose(fp);
   }
   else
     ladder = nil;
  
  return ladder;
}

- (AlignedPeaks*)readPeakListAtPath:(NSString*)pathName
{
  AlignedPeaks     *peakList=nil;
  Peak             *thisPeak;
  FILE             *fp;
  int              pos1, pos2, pos3, pos4;
  
  fp = fopen([pathName fileSystemRepresentation],"r");
  
  if (fp) {
    peakList = [[AlignedPeaks alloc] init];
    while(fscanf(fp,"%d %d %d %d ",&(pos1),&(pos2),&(pos3),&(pos4))==4) {
      //confidence stored in file as float in 0.0-1.0 range (old format)
      thisPeak = [[Peak alloc] init];
      [thisPeak addPosition:pos1];
      [thisPeak addPosition:pos2];
      [thisPeak addPosition:pos3];
      [thisPeak addPosition:pos4];
      [peakList addAlnPeak:thisPeak];
      [thisPeak release];
    }
    fclose(fp);
  } 
  else
    peakList = nil;
  return peakList;
}

- (BOOL)loadLane:(int)lane
{
  NSString         *pathName;
  BOOL             foundScript=NO, foundProcTrace=NO;
  Trace            *dataList;
  Sequence         *baseList=nil;
  NewScript        *tempScript;

  if(lane > [lanesScripts count]) return NO;

  if([bundleDir length]==0) return NO;

  activeLane = lane;

  //1. load script.scr, if present
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/script.scr",lane];
  tempScript = [self readLaneScriptAtPath:pathName];
  if(tempScript != nil) {
    [lanesScripts replaceObjectAtIndex:(lane-1) withObject:tempScript];
    foundScript = YES;
  } else {
    [lanesScripts replaceObjectAtIndex:(lane-1) withObject:[[[NewScript alloc] init] autorelease]];
  }

    
  //2. load rawTrace and add to script as unprocessedList
  if (debugMode) NSLog(@"load lane '%s'",[pathName cString]);
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/rawTrace",lane];
  dataList = [self readLaneDataAtPath:pathName withScale:NO numChannels:numChannels];

  // If this bundle originated as an ABI file, there will be a "raw" base list
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/rawTrace.bsl",lane];
  baseList = [self readLaneSequenceAtPath:pathName];
  if(baseList) [dataList setDefaultProcLabels];
  else [dataList setDefaultRawLabels];
  [[dataList taggedInfo] setObject:fileName  forKey:@"originalFilePath"];
  [[dataList taggedInfo] setObject:@"lanes"   forKey:@"originalFileType"];  

  [[self activeScript] addUnprocessedList:dataList BaseList:baseList name:NULL];


  //3. load procTrace and procTrace.bsl, if present
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/procTrace",lane];
  dataList = [self readLaneDataAtPath:pathName withScale:YES numChannels:currentNumChannels];
  if (dataList != nil) {
    foundProcTrace = YES;
    pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/procTrace.bsl",lane];
    baseList = [self readLaneSequenceAtPath:pathName];
  }
  if(baseList) [dataList setDefaultProcLabels];
  else [dataList setDefaultRawLabels];

  [[self activeScript] setCurrentEditIndex:[[self activeScript] count]-1];
  [[self activeScript] setCurrentExecuteIndex:[[self activeScript] count]-1];
  if (foundScript) {
    if (foundProcTrace)
      [[self activeScript] setCurrentDataList:dataList BaseList:baseList ladder:nil alnBaseList:nil PeakList:nil];
  } else {
    if (foundProcTrace)
      [[self activeScript] addUnprocessedList:dataList BaseList:baseList name:NULL];
  }

  return YES;
}


/*****
*
* Writing Data Section (lane, lanes, seq, fasta)
*
******/

- (void)autosave:(NSNotification*)aNotification
{
  NSString          *autosaveFormat;
  BFlaneFileTypes   origDefaultSaveType = defaultSaveType;

  if([self activeScript] != [aNotification object]) return;

  autosaveFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"AutosaveFormat"];
  if(debugMode) { fprintf(stderr, "autosave '%s' format\n", [autosaveFormat cString]); fflush(stderr);}
  [self setDefaultSaveFormat:autosaveFormat];
  [self saveCurrentToDefaultFormat];

  defaultSaveType = origDefaultSaveType;
  //[[thisLanesFile activeScript] clearCacheButCurrentExecuted];
}

- (void)setDefaultSaveFormat:(NSString*)aType
{
  int       index;
  NSArray   *availableTypes = [NSArray arrayWithObjects:@"LANE", @"LANES", @"SCF", @"SEQ",
    @"FASTA", @"DAT", @"TXT", @"SHAPE",nil];

  index = [availableTypes indexOfObject:[aType uppercaseString]];
  switch(index) {
    case 0: defaultSaveType=LANE; break;
    case 1: defaultSaveType=LANES; break;
    case 2: defaultSaveType=SCF; break;
    case 3: defaultSaveType=SEQ; break;
    case 4: defaultSaveType=FASTA; break;
    case 5: defaultSaveType=DAT; break;
	  case 6: defaultSaveType=TXT; break;
    case 7: defaultSaveType=SHAPE; break;
    case NSNotFound:
    default:
      defaultSaveType = loadedType;
			if (defaultSaveType == ESD)
				defaultSaveType = LANE;
      break;
  }
}

- (BOOL)saveCurrentToDefaultFormat
{
  NSString   *newPath;

  newPath = [fileName stringByDeletingPathExtension];
  switch (defaultSaveType) {
    case LANE:
      newPath = [newPath stringByAppendingPathExtension:@"lane"];
      [self saveCurrentToLANE:newPath];
      break;
    case SCF:
      newPath = [newPath stringByAppendingPathExtension:@"scf"];
      return [self saveCurrentToSCF:newPath];
      break;
    case SEQ:
      newPath = [newPath stringByAppendingPathExtension:@"seq"];
      [self saveCurrentSequenceToSEQ:newPath];
      break;
    case FASTA:
      newPath = [newPath stringByAppendingPathExtension:@"fasta"];
      [self saveCurrentSequenceToFASTA:newPath];
      break;
    case DAT:
      newPath = [newPath stringByAppendingPathExtension:@"dat"];
      [self saveCurrentToDAT:newPath];
      break;
		case TXT:
			newPath = [newPath stringByAppendingPathExtension:@"txt"];
			[self saveCurrentToDAT:newPath];
      break;
    case SHAPE:
      newPath = [newPath stringByAppendingPathExtension:@"shape"];
      [self saveCurrentToSHAPE:newPath];
      break;
    default:
      return NO;
  }
  return YES;
}

- (BOOL)checkNewPath:(NSString *)path
{
  NSString      *tempPath;
  NSDictionary  *attributesDict;
  NSFileManager *filemanager = [NSFileManager defaultManager];

  if([filemanager fileExistsAtPath:path]) {
    // blow away path~, if it exists
    tempPath = [path stringByAppendingString:@"~"];
    [filemanager removeFileAtPath:tempPath handler:nil];

    // move path to path~
    if(![filemanager movePath:path toPath:tempPath handler:nil]) {
      [NSException raise:BFFileSystemException
                  format:@"Could not backup and remove existing file %@.", [path lastPathComponent]];
      //NSRunAlertPanel(@"BaseFinder", @"Could not backup and remove existing bundle. Aborting save.", @"", nil, nil);
      return NO;
    }
  }

  // create the path
  attributesDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777]
                                               forKey:@"NSPosixPermissions"];
  [filemanager createDirectoryAtPath:path
                          attributes:attributesDict];
  tempPath = [path stringByAppendingPathComponent:@"LaneInfo"];
  [self createFileHeader:tempPath];

  return YES;
}

- (BOOL)createFileHeader:(NSString *)path
{
  NSMutableString *dataString;

  dataString = [NSMutableString string];
  [dataString appendFormat:@"numLanes: %d\n", [self numLanes]];
  [dataString appendFormat:@"numChannels: %d\n", numChannels];
  [dataString appendString:@"bytesPerSample: 2\n"];
  if (dataIsLittleEndian)
    [dataString appendString:@"byteOrder: littleEndian\n"];
  else
    [dataString appendString:@"byteOrder: bigEndian\n"];
  if(([self numLanes] == 1) && [[self activeScript] currentData] != nil) {
    [dataString appendFormat:@"currentDataOffset: %d\n", [[[self activeScript] currentData] deleteOffset]];
    [dataString appendFormat:@"currentIndex: %d\n", [[self activeScript] currentExecuteIndex]];
    [dataString appendFormat:@"currentNumChannels: %d\n", [[[self activeScript] currentData] numChannels]];
  }
  [dataString appendString:@"end\n"];

  return [dataString writeToFile:path atomically:YES];
}

- (BOOL)writeSequence:(Sequence*)thisSequence
               toFile:(NSString*)path
{
  FILE             *fp;
  Base             *myBase;
  unsigned int     count, i;

  fp = fopen([path fileSystemRepresentation],"w");
  if(fp == NULL) return NO;

  count = [thisSequence seqLength];
	fprintf(fp,"%d %d\n",([thisSequence getbackForwards] ? 1 : 0),[thisSequence getOffset]);
  for (i=0;i<count;i++) {
    myBase = (Base *)[thisSequence baseAt:i];
    fprintf(fp,"%d %c %f\n",[myBase location], [myBase base], (float)[myBase floatConfidence]);
  }
  fclose(fp);
  return YES;
}

- (BOOL)writeLaneTrace:(Trace*)thisTrace
                toFile:(NSString*)path
             withScale:(BOOL)usesScale
{
  NSString         *bundlePath;
  float            data, *dataPtr, min=0.0, max=0.0, tempFloat, floatScale;
  unsigned short   tempShort;
  unsigned int     channel, count, i, numberOfChannels = [thisTrace numChannels];
  short            scale=1, tmp;
  BOOL             isDir, internallyRescaled=NO;
  NSMutableData    *fileData;
  NSFileManager    *filemanager = [NSFileManager defaultManager];

  if (activeLane < 0)
    return NO;

  // make sure directory exists
  bundlePath = [path stringByDeletingLastPathComponent];
  if(!([filemanager fileExistsAtPath:bundlePath isDirectory:&isDir] && isDir))
    return NO;

  count = [thisTrace length];
  fileData = [[NSMutableData alloc] initWithCapacity:(numberOfChannels*count*sizeof(short))];

  if(count>0 && numberOfChannels>0) min = max = [thisTrace sampleAtIndex:0 channel:0];
  for (channel=0;channel<numberOfChannels;channel++) {
    for(i=0; i<count; i++) {
      tempFloat = fabs([thisTrace sampleAtIndex:i channel:channel]);
      if(tempFloat > max) max=tempFloat;
      if(tempFloat < min) min=tempFloat;
    }
  }
  if(max > SHRT_MAX) {
    //Trace data is larger than 16bit signed integers.  Scale down to 16bit range
    if(debugMode) NSLog(@"Writing .lane Trace larger than 16bit int");
    floatScale = SHRT_MAX/max;
    internallyRescaled = YES;
    thisTrace = [thisTrace copy];
    for (channel=0;channel<numberOfChannels;channel++) {
      for(i=0; i<count; i++) {
        tempFloat = [thisTrace sampleAtIndex:i channel:channel];
        tempFloat = tempFloat * floatScale;
        [thisTrace setSample:tempFloat atIndex:i channel:channel];
      }
    }
  }

  if(usesScale) {
    // first, calc a scale factor and write it--scales data to range
    // 0..SHRT_MAX
    scale = SHRT_MAX; tmp=0;
    dataPtr = (float*)malloc(count*sizeof(float));
    for (channel=0;channel<numberOfChannels;channel++) {
      for(i=0; i<count; i++)
        dataPtr[i] = [thisTrace sampleAtIndex:i channel:channel];
      if (maxVal(dataPtr,count) > 1.0) {
        tmp = (short)((float)SHRT_MAX / maxVal(dataPtr,count));
        scale = tmp < scale ? tmp : scale;
      }
    }
    free(dataPtr);
    if (debugMode) NSLog(@"scale factor = %d",scale);
    if (dataIsLittleEndian)
      tmp = NSSwapHostShortToLittle(scale);
    else
      tmp = NSSwapHostShortToBig(scale);
    [fileData appendBytes:&tmp length:sizeof(short)];
  }

  for (channel=0;channel<numberOfChannels;channel++) {
    for (i=0;i<count;i++) {
      data = [thisTrace sampleAtIndex:i channel:channel];
      if(usesScale) {
        if (dataIsLittleEndian)
          tempShort = (unsigned short)NSSwapHostShortToLittle((short)(scale*data));
        else
          tempShort = (unsigned short)NSSwapHostShortToBig((short)(scale*data));
      }
      else {
        if (dataIsLittleEndian)
          tempShort = (unsigned short)NSSwapHostShortToLittle((unsigned short)data);
        else
          tempShort = (unsigned short)NSSwapHostShortToBig((unsigned short)data);
      }
      [fileData appendBytes:&tempShort length:sizeof(short)];
    }
  }
  
  if(![fileData writeToFile:path atomically:YES]) {
    [fileData release];
    [NSException raise:@"File system error"
                format:@"Unable to save %@.  File system error: Permission denied",
      [bundlePath lastPathComponent]];
  }
  
  [fileData autorelease];
  if(internallyRescaled) [thisTrace release];
  
  return YES;
}

- (BOOL)writeLadder:(EventLadder*)thisLadder
             toFile:(NSString*)path
{
  FILE             *fp;
  Gaussian         *myPeak;
  unsigned int     count, i;
  
  fp = fopen([path fileSystemRepresentation],"w");
  if(fp == NULL) return NO;
  
  count = [thisLadder count];
  for (i=0;i<count;i++) {
    myPeak = [thisLadder objectAtIndex:i];
    fprintf(fp,"%d %f %f %f\n",[myPeak channel],[myPeak width], [myPeak center], [myPeak scale]);
  }
  fclose(fp);
  
  return YES;  
}

- (BOOL)writePeakList:(AlignedPeaks *)thisPeakList toFile:(NSString *)path
{
  FILE             *fp;
  unsigned int     count, i, j;
  
  fp = fopen([path fileSystemRepresentation],"w");
  if (fp == NULL) return NO;
  
  count = [thisPeakList length];
  for (i = 0; i < count; i++) {
    for (j = 0; j < 4; j++) {
      fprintf(fp,"%d ", [thisPeakList valueAt:i :j]);
    }
    fprintf(fp,"\n");
  }
  fclose(fp);
  return YES;
}

- (BOOL)saveLane
{
  NSString         *pathName, *bundlePath;
  id               archiver;
  FILE             *fp;
  float            data, *dataPtr;
  unsigned short   tempShort;
  //struct base    *myBase;
  Base             *myBase;
  unsigned int     channel, count, i;
  short            scale, tmp;
  BOOL             isDir;
  NSMutableData    *fileData;
  NSFileManager    *filemanager = [NSFileManager defaultManager];

  if (activeLane < 0)
    return NO;

  bundlePath = [bundleDir copy];
  // make sure lane directory exists
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d",activeLane];
  if(!([filemanager fileExistsAtPath:pathName isDirectory:&isDir] && isDir))
    [filemanager createDirectoryAtPath:pathName attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777] forKey:@"NSPosixPermissions"]];

  // if rawTrace file is absent, save raw data
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/rawTrace",activeLane];
  if (![filemanager fileExistsAtPath:pathName]) {
    count = [[[self activeScript] rawData] length];
    fileData = [[NSMutableData alloc] initWithCapacity:(numChannels*count*sizeof(short))];
    for (channel=0;channel<numChannels;channel++) {
      for (i=0;i<count;i++) {
        data = [[[self activeScript] rawData] sampleAtIndex:i channel:channel];
        if (dataIsLittleEndian)
          tempShort = (unsigned short)NSSwapHostShortToLittle((unsigned short)data);
        else
          tempShort = (unsigned short)NSSwapHostShortToBig((unsigned short)data);
        [fileData appendBytes:&tempShort length:sizeof(short)];
      }
    }
    if(![fileData writeToFile:pathName atomically:YES]) {
      [fileData release];
      [NSException raise:@"File system error"
                  format:@"Unable to save %@.  File system error: Permission denied",
        [bundlePath lastPathComponent]];
    }
    [fileData autorelease];
  }

  // if there is a baseList associated with the raw data, save it also
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/rawTrace.bsl",activeLane];
  if ([[self activeScript] rawBases] != nil && ![filemanager fileExistsAtPath:pathName]) {
    fp = fopen([pathName fileSystemRepresentation],"w");
    if(fp == NULL) {
        [NSException raise:@"File system error"
                    format:@"Unable to save %@.  File system error: Permission denied",
          [bundlePath lastPathComponent]];
    }
    count = [[[self activeScript] rawBases] seqLength];
    for (i=0;i<count;i++) {
      myBase = (Base *)[[[self activeScript] rawBases] baseAt:i];
      fprintf(fp,"%d %c %f\n",[myBase location], [myBase base], (float)[myBase floatConfidence]);
      /**
        myBase = (struct base *)[[[self activeScript] rawBases] elementAt:i];
        fprintf(fp,"%d %c %f\n",myBase->location,myBase->base,myBase->confidence);
        fprintf(fp,"%d ",myBase->location);
        switch(myBase->channel) {
          case A_BASE: fprintf(fp,"A "); break;
          case C_BASE: fprintf(fp,"C "); break;
          case G_BASE: fprintf(fp,"G "); break;
          case T_BASE: fprintf(fp,"T "); break;
        }
        fprintf(fp,"%f\n",myBase->confidence);
      **/
    }
    fclose(fp);
  }


  // if script length is one, it consists of only the raw trace
  if ([[self activeScript] count] <= 1)
    return YES;

  // save script:
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/script.scr",activeLane];
  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:[self activeScript] tag:"script"];
  [archiver writeToFile:pathName  atomically:YES];
  if(archiver) [archiver release];

  // save processed data to procData
  pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/procTrace",activeLane];
  count = [[[self activeScript] currentData] length];
  fileData = [[NSMutableData alloc] initWithCapacity:(numChannels*count*sizeof(short))];

  // first, calc a scale factor and write it--scales data to range
  // 0..SHRT_MAX
  scale = SHRT_MAX; tmp=0;
  dataPtr = (float*)malloc(count*sizeof(float));
  for (channel=0;channel<numChannels;channel++) {
    for(i=0; i<count; i++)
      dataPtr[i] = [[[self activeScript] currentData] sampleAtIndex:i channel:channel];
    if (maxVal(dataPtr,count) > 1.0) {
      tmp = (short)((float)SHRT_MAX / maxVal(dataPtr,count));
      scale = tmp < scale ? tmp : scale;
    }
  }
  free(dataPtr);
  if (debugMode) NSLog(@"scale factor = %d",scale);
  if (dataIsLittleEndian)
    tmp = NSSwapHostShortToLittle(scale);
  else
    tmp = NSSwapHostShortToBig(scale);
  [fileData appendBytes:&tmp length:sizeof(short)];

  for (channel=0;channel<numChannels;channel++) {
    for (i=0;i<count;i++) {
      data = [[[self activeScript] currentData] sampleAtIndex:i channel:channel];
      if (dataIsLittleEndian)
        tempShort = NSSwapHostShortToLittle((short)(scale * data));
      else
        tempShort = NSSwapHostShortToBig((short)(scale * data));
      [fileData appendBytes:&tempShort length:sizeof(short)];
    }
  }
  if(![fileData writeToFile:pathName atomically:YES]) {
    [fileData release];
    [NSException raise:@"File system error"
                format:@"Unable to save %@.  File system error: Permission denied",
      [bundlePath lastPathComponent]];
  }
  [fileData autorelease];

  // save base list to procTrace.bsl
  if ([[self activeScript] currentBases] != nil) {
    pathName = [bundleDir stringByAppendingFormat:@"/Lane%1d/procTrace.bsl",activeLane];
    fp = fopen([pathName fileSystemRepresentation],"w");
    if(fp == NULL) {
      [NSException raise:@"File system error"
                  format:@"Unable to save %@.  File system error: Permission denied",
        [bundlePath lastPathComponent]];
    }

    count = [[[self activeScript] currentBases] seqLength];
    for (i=0;i<count;i++) {
      myBase = (Base *)[[[self activeScript] currentBases] baseAt:i];
      fprintf(fp,"%d %c %f\n",[myBase location], [myBase base], (float)[myBase floatConfidence]);
      /***
        myBase = (struct base *)[[[self activeScript] finalBases] elementAt:i];
        fprintf(fp,"%d %c %f\n",myBase->location,myBase->base,myBase->confidence);
        fprintf(fp,"%d ",myBase->location);
        switch(myBase->channel) {
          case A_BASE: fprintf(fp,"A "); break;
          case C_BASE: fprintf(fp,"C "); break;
          case G_BASE: fprintf(fp,"G "); break;
          case T_BASE: fprintf(fp,"T "); break;
          case UNKNOWN_BASE: fprintf(fp,"N "); break;
        }
        fprintf(fp,"%f\n",myBase->confidence);
      ***/
    }
    fclose(fp);
  }

  return YES;
}

- (BOOL)save:sender
{
  int i;
  int initLane = activeLane;

  /**** to create .lanes~ copy
  if([bundleDir length]==0) || ![self checkNewPath:path])
  return self;
  ****/
  if([bundleDir length]==0)
    return NO;

  for (i=1;i<=[lanesScripts count];i++) {
    if ([[lanesScripts objectAtIndex:(i-1)] isMemberOfClass:[NewScript class]]) {
      [self switchToLane:i];
      [self saveLane];
    }
  }

  [self switchToLane:initLane];

  return YES;
}

- (BOOL)saveCurrentToLANE:(NSString*)pathname;
{
  NSString        *tempPath;
  NSFileManager   *manager = [NSFileManager defaultManager];
  AsciiArchiver   *archiver;
  NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0777], @"NSPosixPermissions", nil];
  
  if([manager fileExistsAtPath:pathname]) {
    tempPath = [pathname stringByAppendingString:@"~"];
    if([manager fileExistsAtPath:tempPath]) {
      //delete old .lanes~ file
      [manager removeFileAtPath:tempPath handler:nil];
    }
    [manager movePath:pathname toPath:tempPath handler:nil];
  }

  if(![manager createDirectoryAtPath:pathname attributes:attributes]) return NO;

  tempPath = [pathname stringByAppendingPathComponent:@"LaneInfo"];
  if(![self createFileHeader:tempPath]) {
    //NSRunAlertPanel(@"Saving Error", @"Could not create .lane header file.", @"", nil, nil);
    return NO;
  }

  // write raw trace
  tempPath = [pathname stringByAppendingPathComponent:@"rawTrace"];
  if(![self writeLaneTrace:[[self activeScript] rawData] toFile:tempPath withScale:NO]) return NO;

  // write raw bases
  if ([[self activeScript] rawBases] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"rawTrace.bsl"];
    if(![self writeSequence:[[self activeScript] rawBases] toFile:tempPath]) return NO;
  }

  [[self activeScript] setNeedsToSave:NO];
	needsSaveAs = NO;
	defaultSaveType = LANE;
	[self setFileName:pathname];
		
	// if script length is one, it consists of only the raw trace

	if ([[self activeScript] count] <= 1) return YES;

  // save script:
  tempPath = [pathname stringByAppendingPathComponent:@"script"];
  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:[self activeScript] tag:"script"];
  [archiver writeToFile:tempPath atomically:YES];
  if(archiver) [archiver release];

  // write proc trace
  tempPath = [pathname stringByAppendingPathComponent:@"procTrace"];
  if(![self writeLaneTrace:[[self activeScript] currentData] toFile:tempPath withScale:YES]) return NO;

  // write proc bases
  if ([[self activeScript] currentBases] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"procTrace.bsl"];
    if(![self writeSequence:[[self activeScript] currentBases] toFile:tempPath]) return NO;
  }

  return YES;
}

- (BOOL)saveCurrentToSHAPE:(NSString*)pathname;
{
  NSString        *tempPath;
  NSFileManager   *manager = [NSFileManager defaultManager];
  AsciiArchiver   *archiver;
  FILE            *fp;
  int             i, j, count, channels;
  NSDictionary    *attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0777], @"NSPosixPermissions", nil];
  
  if([manager fileExistsAtPath:pathname]) {
    tempPath = [pathname stringByAppendingString:@"~"];
    if([manager fileExistsAtPath:tempPath]) {
      //delete old .shape~ file
      [manager removeFileAtPath:tempPath handler:nil];
    }
    [manager movePath:pathname toPath:tempPath handler:nil];
  }
  
  if(![manager createDirectoryAtPath:pathname attributes:attributes]) return NO;
  
  tempPath = [pathname stringByAppendingPathComponent:@"SHAPEInfo"];
  if(![self createFileHeader:tempPath]) {
    //NSRunAlertPanel(@"Saving Error", @"Could not create .shape header file.", @"", nil, nil);
    return NO;
  }
	
	//write raw trace
	tempPath = [pathname stringByAppendingPathComponent:@"rawTrace"];
	fp = fopen([tempPath fileSystemRepresentation],"w");
	if(fp == NULL) {
    [NSException raise:@"File system error"
                format:@"Unable to open %@.  File system error: Permission denied", [tempPath lastPathComponent]];
  }
  count = [[[self activeScript] rawData] length];
  channels = [[[self activeScript] rawData] numChannels];
  for (i = 0; i < count; i++) {
    for (j = 0; j < (channels-1); j++)
      fprintf(fp, "%f	", [[[self activeScript] rawData] sampleAtIndex:i channel:j]);
    fprintf(fp, "%f\n", [[[self activeScript] rawData] sampleAtIndex:i channel:(channels-1)]);
  }
  fclose(fp);
  
  [[self activeScript] setNeedsToSave:NO];
	needsSaveAs = NO;
	defaultSaveType = SHAPE;
	[self setFileName:pathname];
		
	// if script length is one, it consists of only the raw trace
  
	if ([[self activeScript] count] <= 1) return YES;
  
  // save script:
  tempPath = [pathname stringByAppendingPathComponent:@"script"];
  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:[self activeScript] tag:"script"];
  [archiver writeToFile:tempPath atomically:YES];
  if(archiver) [archiver release];
  
  // write proc trace
  tempPath = [pathname stringByAppendingPathComponent:@"procTrace"];
  fp = fopen([tempPath fileSystemRepresentation], "w");
  if(fp == NULL) {
    [NSException raise:@"File system error"
                format:@"Unable to open %@.  File system error: Permission denied",
      [tempPath lastPathComponent]];
  }
  count = [[[self activeScript] currentData] length];
  channels = [[[self activeScript] currentData] numChannels];
  
  for (i = 0; i < count; i++) {
    for (j = 0; j < (channels-1); j++)
      fprintf(fp, "%f	", [[[self activeScript] currentData] sampleAtIndex:i channel:j]);
    fprintf(fp, "%f\n", [[[self activeScript] currentData] sampleAtIndex:i channel:(channels-1)]);
  }
  fclose(fp);
  
  // write proc bases
  if ([[self activeScript] currentBases] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"procTrace.bsl"];
    if(![self writeSequence:[[self activeScript] currentBases] toFile:tempPath]) return NO;
  }
  //write aligned bases
  if ([[self activeScript] currentAlnBases] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"procTrace.aln"];
    if (![self writeSequence:[[self activeScript] currentAlnBases] toFile:tempPath]) return NO;
  }
    //write ladder
  if ([[self activeScript] currentLadder] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"procTrace.ldr"];
    if (![self writeLadder:[[self activeScript] currentLadder] toFile:tempPath]) return NO;
  }
    //write peak list
  if ([[self activeScript] currentPeakList] != nil) {
    tempPath = [pathname stringByAppendingPathComponent:@"procTrace.pkl"];
    if (![self writePeakList:[[self activeScript] currentPeakList] toFile:tempPath]) return NO;
  }
    
  return YES;
}

- (BOOL)saveLanesTo:(NSString*)path
{
  int    i;
  int    initLane = activeLane;

  // This forces a load from original file since not
  // all lanes may have been loaded
  for (i=1;i<=[lanesScripts count];i++)
    [self switchToLane:i];
		
  if([bundleDir isEqualToString:path] && ![self checkNewPath:path])
    return YES;
		
  [bundleDir setString:path];           // switch to new bundleDir name to save out
  for (i=1;i<=[lanesScripts count];i++) {
    if ([[lanesScripts objectAtIndex:(i-1)] isMemberOfClass:[NewScript class]]) {
      [self switchToLane:i];
      [self saveLane];
    }
  }
  [self switchToLane:initLane];
  return YES;
}

- (BOOL)saveSequenceToDir:(NSString *)path;
{
  //creates a directory of .seq files of the called sequences of all lanes.
  //The .seq format is used by the GCG assembly and databasing software.
  int      x;
  int      initLane = activeLane;
  NSFileManager *filemanager = [NSFileManager defaultManager];
  NSString      *tempFile, *newName;


  [filemanager createDirectoryAtPath:path
                          attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777]
                                                                 forKey:@"NSPosixPermissions"]];
	
  tempFile = [[path lastPathComponent] stringByDeletingPathExtension];

  if (debugMode) NSLog(@"saving seqd to  path=%@\n  baseFileName='%@'", path, tempFile);

  for (x=1;x<=[lanesScripts count];x++) {
    [self switchToLane:x];
    //newName = [tempFile stringByAppendingFormat:@"_L%1d.seq",x];
    newName = [tempFile stringByAppendingFormat:@"%2d.seq",x];
    [self saveCurrentSequenceToSEQ:[path stringByAppendingPathComponent:newName]];
  }

  [self switchToLane:initLane];
  return YES;
}

- (BOOL)saveCurrentSequenceToSEQ:(NSString *)pathname
{	
  //The .seq format is used by the GCG assembly and databasing software.
  int        count, i;
  Sequence   *bases;
  //char     *baseName;
  FILE       *fp;

  bases = [[self activeScript] currentBases];
  if(bases) {
    fp = fopen([pathname fileSystemRepresentation], "w");
    if(fp == NULL) {
        [NSException raise:@"File system error"
                    format:@"Unable to save %@.  File system error: Permission denied",
          [pathname lastPathComponent]];
    }
    count = [bases seqLength];
    fprintf(fp, "\n..%d\n\n",count);
    fprintf(fp, "%8d ", 0);
#ifdef OLDCODE
    baseName = strrchr(pathname, '/');
    if(baseName == NULL) baseName=pathname;
    else baseName++;
    fprintf(fp, "%s",);
 //   M13-102mod.Txt  Length: 6981  May 18, 1995 11:52  Type: N  Check: 1889  ..
#endif
    for (i = 0; i < count; i++) {
      if ((i % 10 == 0) && (i%50 != 0))
        fprintf(fp, " ");
      if ((i%50 == 0) && (i != 0))
        fprintf(fp, "\n\n%8d ",i);
      fprintf(fp, "%c", [[bases baseAt:i] base]);
    }
    fprintf(fp, "\n");
    fclose(fp);
  }
  return YES; 
}

- (BOOL)saveCurrentSequenceToFASTA:(NSString*)pathname
{
  //The .fasta format is used by the Phrap assembly and databasing software.
  int 		count, i;
  Sequence   *bases;
  NSString   *seqName;
  char    *tempFile, *buffer;
  FILE 		*fp;

  //if([[NSFileManager defaultManager] fileExistsAtPath:pathname])
  
  bases = [[self activeScript] currentBases];

  //replace spaces with '_'
  seqName = [pathname lastPathComponent];

  buffer = (char*)malloc(strlen([seqName cString])+4);
  strcpy(buffer, [seqName cString]);
  tempFile = strrchr(buffer, '/');
  if(tempFile == NULL) tempFile = buffer;
  else tempFile++;
  for(i=0; i<strlen(tempFile); i++) {
    if(isspace(tempFile[i]))
      tempFile[i] = '_';
  }

  if(bases) {
    fp = fopen([pathname fileSystemRepresentation], "w");
    if(fp == NULL) {
        [NSException raise:@"File system error"
                    format:@"Unable to save %@.  File system error: Permission denied",
          [pathname lastPathComponent]];
    }
    count = [bases seqLength];
    fprintf(fp, ">%s\n",tempFile);
    for (i = 0; i < count; i++) {
      fprintf(fp, "%c", [[bases baseAt:i] base]);
    }
    fprintf(fp, "\n");
    fclose(fp);
  }
  free(buffer);
  return YES;
}




/******
*
* SCF file read/write section (a bigendian file type)
*
*******/

- initFromSCFFile:(NSString*)pathname
{
  //The .scf format is used by Washington University's TED program (sequence quality checker).
  //It is a BigEndian format.
  Trace             *primaryTrace, *altTrace;
  Sequence          *bases=nil;
  NewScript         *script=nil;
  NSData            *fileData;
  SCFTraceFile      *traceAdapter;
  NSData            *scriptData;
  NSString          *scriptString;
  AsciiArchiver     *archiver;
  NSMutableDictionary  *taggedInfo;

  currentDataOffset=0;
  currentIndex=-1;

  fileData = [NSData dataWithContentsOfFile:pathname];
  if(fileData == NULL) return NULL;

  traceAdapter = [[SCFTraceFile alloc] initFromSCFRepresentation:fileData];
  
  primaryTrace = [traceAdapter primaryTrace];
  bases = [traceAdapter sequence];
  altTrace = [traceAdapter alternateTrace];
  taggedInfo = [traceAdapter taggedInfo];
  if(taggedInfo!=nil) [[primaryTrace taggedInfo] addEntriesFromDictionary:taggedInfo];

  if(altTrace != nil) {
    //UW extended SCF, has script and raw data in SCF file
    if(taggedInfo!=nil) [[altTrace taggedInfo] addEntriesFromDictionary:taggedInfo];
    scriptData = [traceAdapter scriptRepresentation];
    scriptString = [[NSString alloc] initWithData:scriptData
                                         encoding:NSASCIIStringEncoding];
    archiver = [[AsciiArchiver alloc] initWithAsciiData:scriptString];

    NS_DURING
      script = [archiver readObjectWithTag:"script"];
    NS_HANDLER
#if !defined(BASEFINDER_CMD_LINE)
      NSRunAlertPanel(@"Error Panel", @"Error reading script from file '%@'.\n%@", @"OK", nil, nil,
                      [pathname lastPathComponent], localException);
#endif
      NSLog(@"exception during readScript from %@: %@\n", pathname, localException);
      script = nil;   //just in case archiver didn't, to flag that script load failed
    NS_ENDHANDLER

    if(script != nil) {
      [altTrace setDefaultRawLabels];
      [script addUnprocessedList:altTrace  BaseList:nil  name:@"Raw Data"];

      if([archiver findTag:"currentDataOffset"])
        [archiver readData:&currentDataOffset];
      if([archiver findTag:"currentIndex"])
        [archiver readData:&currentIndex];
      if([archiver findTag:"processedNumChannels"]) {
        int  numChan, i;
        [archiver readData:&numChan];
        for(i=[primaryTrace numChannels]-1; i>=numChan; i--)
          [primaryTrace removeChannel:i];
      }
      
      if([archiver findTag:"scfScales"]) {
        int    cnt, pos, channel;
        float  *scales, value;
        cnt = [archiver arraySize];
        if(cnt > 0 && (cnt == [primaryTrace numChannels])) {
          if(debugMode) { fprintf(stderr, "rescaling primary scf trace\n"); fflush(stderr); }
          scales = (float*)calloc(cnt, sizeof(float));
          [archiver readArray:scales];
          for(channel=0; channel<cnt; channel++) {
            for(pos=0; pos<[primaryTrace length]; pos++) {
              value = [primaryTrace sampleAtIndex:pos  channel:channel];
              value /= scales[channel];
              [primaryTrace setSample:value atIndex:pos channel:channel];
            }
          }
          free(scales);
        } else {
          fprintf(stderr, "scf scale channel mismatch, can't rescale!\n");
          fflush(stderr);
        }
      }

      [primaryTrace setDefaultProcLabels];
      if(currentDataOffset > 0) [primaryTrace setDeleteOffset:currentDataOffset];
     
      if(currentIndex > 0 ) {
        if((currentIndex >= 0)  && (currentIndex<[script count])) {
          [script setCurrentEditIndex:currentIndex];
          [script setCurrentExecuteIndex:currentIndex];
        } else {
          //assume in older format where stored at the end
          [script setCurrentEditIndex:[script count]-1];
          [script setCurrentExecuteIndex:[script count]-1];
        }
        [script setCurrentDataList:primaryTrace BaseList:bases ladder:nil alnBaseList:nil PeakList:nil];
      } else {
        currentIndex = 0;
        [script setCurrentEditIndex:0];
        [script setCurrentExecuteIndex:0];
      }
      
      [self addScript:script];
    }
    else {  //script==nil ie failed to read script
      //primaryTrace is autoreleased by AsciiArchiver, so don't need to release it here.
      primaryTrace = altTrace;  //make the raw data the only data (ie it becomes the unprocessed)
    }
    [scriptString release];
    [archiver release];
 }

  if(script == nil) {
    //either script failed to read from file, or not present
    script = [[NewScript alloc] init];

    if(bases != nil)
      [primaryTrace setDefaultProcLabels];
    else
      [primaryTrace setDefaultRawLabels];
    [script addUnprocessedList:primaryTrace  BaseList:bases  name:@"SCF Data"];
    [self addScript:script];
    [script release];
  }

  loadedType = defaultSaveType = SCF;
  [traceAdapter release];
  return self;
}

- (BOOL)saveLanestoSCF:(NSString*)path
{
  //creates a directory of .scf files of the processed and called data.
  //The .scf format is used by Washington University's TED program (sequence quality checker).
  int 		x;
  NSString      *tempFile, *newPath, *newName;
  int 		initLane = activeLane;
  NSFileManager *filemanager = [NSFileManager defaultManager];

  [filemanager createDirectoryAtPath:path
                          attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777] forKey:@"NSPosixPermissions"]];
	
  tempFile = [[path lastPathComponent] stringByDeletingPathExtension];

  if (debugMode) NSLog(@"path=%s",[path fileSystemRepresentation]);
  if (debugMode) NSLog(@"fileName='%s'",[tempFile cString]);

  for (x=1;x<=[lanesScripts count];x++) {
    [self switchToLane:x];
    //newName = [tempFile stringByAppendingFormat:@"_L%1d.seq",x];
    if(x<10) newName = [tempFile stringByAppendingFormat:@"_0%d.scf",x];
    else newName = [tempFile stringByAppendingFormat:@"_%d.scf",x];
    newPath = [path stringByAppendingPathComponent:newName];
    [self saveCurrentToSCF:newPath];
  }

  [self switchToLane:initLane];
  return YES;
}

- (BOOL)saveCurrentToSCF:(NSString*)pathname
{
  //The .scf format is used by Washington University's TED program (sequence quality checker).
  //It is a BigEndian format.
  Sequence          *bases;
  Trace             *data, *rawTrace;
  NSData            *fileData, *scriptData;
  NSString          *scriptString;
  SCFTraceFile      *traceAdapter;
  AsciiArchiver     *archiver;
  MGMutableFloatArray  *scfScales;
  int                  chan, pos;
  float                *scales, tempValue;
  BOOL                 saveWithScript=YES;

  bases = [[self activeScript] currentBases];
  data = [[[[self activeScript] currentData] copy] autorelease];
  rawTrace = [[[[self activeScript] rawData] copy] autorelease];

  traceAdapter = [SCFTraceFile scf];

  //check for floats in raw data
#if !defined(BASEFINDER_CMD_LINE)
  if([traceAdapter traceHasFloats:rawTrace]) {
    int  result = NSRunAlertPanel(@"SCF save error", @"File %@ has floating point numbers in its raw data.  Our extended SCF format does not allow non-integers for raw data", @"Rescale raw data to integers", @"Cancel", nil,
                             [[self fileName] lastPathComponent]);
    switch(result) {
      case NSAlertDefaultReturn:  //Rescale
        [traceAdapter rescaleTraceToUSHRT:rawTrace];
        break;
      case NSAlertAlternateReturn:  //cancel
        return NO;
      case NSAlertOtherReturn:
      case NSAlertErrorReturn:
        break;
    }
  }
#else
  if([traceAdapter traceHasFloats:rawTrace])
    [traceAdapter rescaleTraceToUSHRT:rawTrace];
#endif

  // if script length is one, it consists of only the raw trace
  if ([[self activeScript] count] <= 1) {
    [[rawTrace taggedInfo] setObject:pathname  forKey:@"lastFilePath"];
    [traceAdapter setPrimaryTrace:rawTrace];
    [traceAdapter setSequence:bases];
    [traceAdapter setShouldRescale:NO];
    [traceAdapter setTaggedInfo:[rawTrace taggedInfo]];

    fileData = [traceAdapter SCFFileRepresentation];
  }
  else {
    currentDataOffset = [[[self activeScript] currentData] deleteOffset];
    currentIndex = [[self activeScript] currentExecuteIndex];

    scfScales = [traceAdapter SCFScalesFromTrace:data];
    scales = [scfScales floatArray];
    for(chan=0; chan<[data numChannels]; chan++) {
      for(pos=0; pos<[data length]; pos++) {
        tempValue = [data sampleAtIndex:pos channel:chan] * scales[chan];
        [data setSample:tempValue atIndex:pos channel:chan];
      }
    }

    archiver = [[AsciiArchiver alloc] initForWriting];
    [archiver writeData:&currentDataOffset  type:"i"  tag:"currentDataOffset"];
    [archiver writeData:&currentIndex  type:"i"  tag:"currentIndex"];
    [archiver writeObject:[self activeScript]  tag:"script"];
    chan = [data numChannels];
    [archiver writeData:&chan  type:"i"  tag:"processedNumChannels"];
    [archiver writeArray:[scfScales floatArray]  size:[scfScales count]  type:"f"  tag:"scfScales"];

    scriptString = [archiver asciiRepresentation];
    //if(debugMode) NSLog(@"scf ascii script rep\n%@", scriptString);
    scriptData = [scriptString dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES];

    if([[data taggedInfo] objectForKey:@"originalFilePath"] == nil) {
      NSLog(@"missing originalFilePath, using new save name");
      [[data taggedInfo] setObject:pathname  forKey:@"originalFilePath"];
      [[data taggedInfo] setObject:@"scf"    forKey:@"originalFileType"];
    }
    [[data taggedInfo] setObject:pathname  forKey:@"lastFilePath"];
      
    [traceAdapter setPrimaryTrace:data];
    [traceAdapter setSequence:bases];
    [traceAdapter setShouldRescale:NO];
    if(saveWithScript) {
      [traceAdapter setAlternateTrace:rawTrace];
      [traceAdapter setScriptRepresentation:scriptData];
    }
    [traceAdapter setTaggedInfo:[data taggedInfo]];
    fileData = [traceAdapter SCFFileRepresentation];

    [archiver release];
  }

  if(![fileData writeToFile:pathname atomically:YES]) {
    [NSException raise:@"File system error"
                format:@"Unable to save %@.  File system error: Permission denied",
      [pathname lastPathComponent]];
    return NO;
  }
  [[self activeScript] setNeedsToSave:NO];
	[self setFileName:pathname];
	defaultSaveType = SCF;
	needsSaveAs = NO;
  return YES;
}


/******
*
* Tabbed ascii data section
*
*******/

- (int)countColumns:(NSScanner*)data
{
  int    count=0;
	NSCharacterSet	*endline;
	NSString	*tempstring;
	NSScanner	*chars=nil;

	//skip header
	[data scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
	//scan in first line
	endline = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
	if ([data scanUpToCharactersFromSet:endline intoString:&tempstring])
		chars = [NSScanner scannerWithString:tempstring];
	if (chars != nil)
	{
		//count columns
		while (![chars isAtEnd])
		{
			if ([chars scanFloat:nil])
				count++;
			else  //prevent endless loop if row mixed with characters
			{
				[chars scanUpToCharactersFromSet:endline intoString:nil];
				count=0;
			}
		}
	}
	//reset scan location
	[data setScanLocation:0];
  return count;
}

- (Trace*)traceFromTabedAsciiData:(NSData *)data :(int)beginNum
{
  int     storageNum, num_chan;
  float   tempFloat;
  int     row=0;
  Trace   *dataList;
  NSString  *injection=@"Injection";
	NSString	*separation=@"Separation";
	NSString	*index=@"CURRENT";
	NSString  *filedata;
	NSScanner	*datascanner;
	NSCharacterSet	*endline;
	BOOL		beckmanformat=NO, readdata=NO;

	endline = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
	filedata = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  datascanner = [NSScanner scannerWithString:filedata];
	//check for beckman headers
	if ([datascanner scanUpToString:injection intoString:nil] && ![datascanner isAtEnd])
	{
		if ([datascanner scanUpToString:separation intoString:nil] && ![datascanner isAtEnd])
			{
				beckmanformat = YES;
				num_chan = 4;
				[datascanner scanUpToString:index intoString:nil];  //scan to get past digits in header
			}
	}
	if ([datascanner isAtEnd]) //reset scan to beginning of file
		[datascanner setScanLocation:0];
	//count columns
	if (!beckmanformat)
		num_chan = [self countColumns:datascanner];
	dataList = [[Trace alloc] initWithCapacity:1024 channels:num_chan];
  if (num_chan == 0) return dataList;
	//skip past header
	[datascanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
  if(beginNum == 0) [dataList increaseLengthBy:1];	//filling an empty Trace
	while (![datascanner isAtEnd])
		{
			if (beckmanformat) 
			{
				readdata = [datascanner scanInt:nil];   //index
				readdata = [datascanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];  //CAP
			}
			for (storageNum=0; storageNum<num_chan; storageNum++)
			{
				readdata = [datascanner scanFloat:&tempFloat];
				if(readdata)
					[dataList setSample:tempFloat atIndex:row channel:storageNum];
			}
			if (beckmanformat)	//skip rest of data on line
			{
				[datascanner scanUpToCharactersFromSet:endline intoString:nil];
			}
			if (!readdata)  //trying to prevent endless loop
				[datascanner scanUpToCharactersFromSet:endline intoString:nil];
			else
				if (![datascanner isAtEnd])
				{
					row++;
					if(beginNum == 0) [dataList increaseLengthBy:1];
				}
		}
	[filedata release];
  return dataList;
}

- initFromDATFile:(NSString *)fullName;
{
  /*** for .dat files ***/
  NSData            *data;
  Trace             *rawList;
  NewScript         *script;
	NSString					*type;

  data = [NSData dataWithContentsOfFile:fullName];
	type = [[fullName pathExtension] lowercaseString];
	
  if(data == NULL) return NULL;

  rawList = [self traceFromTabedAsciiData:data :0];
  numChannels = [rawList numChannels];
	if ([type isEqualToString:@"dat"])
	{
		[[rawList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
		[[rawList taggedInfo] setObject:@"dat"  forKey:@"originalFileType"];  
	}
	else
	{
		[[rawList taggedInfo] setObject:fullName  forKey:@"originalFilePath"];
		[[rawList taggedInfo] setObject:@"txt"  forKey:@"originalFileType"];
	}
  
  script = [[NewScript alloc] init];
  [script addUnprocessedList:rawList BaseList:nil name:@"Tabbed ASCII Data"];
  [self addScript:script];
  [script release];
	if ([type isEqualToString:@"dat"])
		loadedType = defaultSaveType = DAT;
	else
		loadedType = defaultSaveType = TXT;
		
  return self;
}

- initFromTabedData:(NSData *)data
{
  /*** for pasteboard formated NXTabularTextPboardType as NSData ***/
  Trace       *rawList;
  NewScript   *script;

  rawList = [self traceFromTabedAsciiData:data :0];
  numChannels = [rawList numChannels];

  script = [[NewScript alloc] init];
  [script addUnprocessedList:rawList BaseList:nil name:@"Tabbed ASCII Data"];
  [self addScript:script];
  [script release];
  return self;
}

#ifdef OLDCODE
- (BOOL)addAnotherDataFile:(const char *)fullName
{
  // to be fixed at a latter date
  int      columns, begin_loc;
  int      i;
  NSData   *data;

  data = [NSData dataWithContentsOfFile:[NSString stringWithCString:fullName]];
  if(data == nil) return NO;

  begin_loc = [self numberChannels];
  columns = [self countColumns:data];
  for (i = 0; i < columns; ++i) 	
    [[self pointStorageID] addChannel];
  [self loadFromTabedAsciiData:data :begin_loc];

  [self shouldRedraw];

  return YES;
}
#endif

- (void)saveCurrentToDAT:(NSString *)pathname
{
  unsigned int i,j, count, channels;
  FILE *fp;
  Trace             *data;
	NSString					*type;

  data = [[self activeScript] currentData];
	type = [[pathname pathExtension] lowercaseString];

  fp = fopen([pathname fileSystemRepresentation], "w");
  if(fp == NULL) {
    [NSException raise:@"File system error"
                format:@"Unable to open %@.  File system error: Permission denied",
      [pathname lastPathComponent]];
  }

  count = [data length];
  channels = [data numChannels];

  for (i = 0; i < count; i++) {
    for (j = 0; j < (channels-1); j++)
      fprintf(fp, "%f	", [data sampleAtIndex:i channel:j]);
    fprintf(fp, "%f\n", [data sampleAtIndex:i channel:(channels-1)]);
  }
  fclose(fp);
  [[self activeScript] setNeedsToSave:NO];
	//read last chars and determine if txt or dat
	if ([type isEqualToString:@"dat"])
		defaultSaveType = DAT;
	else
		defaultSaveType = TXT;
	needsSaveAs = NO;
  [self setFileName:pathname];

}


/******
*
* Old File types read/write section (moved from SequenceEditor)
*
*******/


#ifdef OLDCODE
- (void)saveBinary:(NSString*)pathname
{
  int i, j, count, channels;
  FILE *fp;
  float		tempFloat;

  fp = fopen([pathname fileSystemRepresentation], "wb");
  if(fp == NULL) {
    [NSException raise:@"File system error"
                format:@"Unable to open %@.  File system error: Permission denied",
      [pathname lastPathComponent]];
  }

  count = [self numberPoints];
  channels = [self numberChannels];

  for (j = 0; j < channels; j++) {
    for(i=0; i<count; i++) {
      tempFloat = [[self pointStorageID] sampleAtIndex:i channel:j];
      fwrite(&tempFloat, sizeof(float), 1, fp);
    }
  }
  fclose(fp);
}

- initFromSNDFile:(const char *)fullName
{
  id				updateBox;
  id				rawList;
  char			myname[32];
  id sound;
  short *sndData;
  long count;
  int i;
  float temp;

  sound = [Sound alloc];
  [sound initFromSoundfile:fullName];
  sndData = (short *)[sound data];
  count = [sound sampleCount];
  if ([sound dataFormat] != SND_FORMAT_LINEAR_16) {
    NSLog(@"WRONG SOUND FORMAT");
    return 0;
  }
  updateBox = [StatusController connect];
  sprintf(myname, "Loading Data from SND file");
  [updateBox processConnect:self :myname];

  rawList = [[SeqList alloc] initCount:1];
  [rawList addObject:[[ArrayStorage alloc] initCount:0
                                         elementSize:sizeof(float) description:"f"]];


  for (i = 0; i < count; i++) {
    temp = ((float) sndData[i])/ ((float)SHRT_MAX);
    [[rawList objectAt:0] addElement:&temp];
  }

  [updateBox done:self];

  [[self currentScript] addUnprocessedList:rawList BaseList:nil name:NULL];
  [[self pointStorageID] setDefaultRawLabels];
  [self setDefaultColors];
  [self initializeArrays];
  [myMasterView setColorWells];
  [self setFileName:(char*)fullName];
  [self show:self];
  [sound release];
  return self;
}


- initFromCCDFile:(const char *)fullName
{
  //.ccd files are raw array writed of motorola signed shorts
  id 							channelCountObj;
  id							updateBox;
  char						myname[32];
  signed short 		*data, *loc, dataItem;
  float 					flt_temp;
  long 						count=0, numperchannel;
  int 						i,j, numlanes=1, lane=1, num_chnls = 4;
  FILE 						*fp;
  id							tempArray;
  id							rawList, script;
  BOOL						status;

  channelCountObj = NXGetNamedObject("LaneCountInstance",NSApp);
  status = [channelCountObj showAndWaitCount:&numlanes :&lane];
  if (debugMode) NSLog(@"status = %d",(int)status);
  if(status == NO) return NULL;

  updateBox = [StatusController connect];
  sprintf(myname, "Loading Data from CCD file");
  [updateBox processConnect:self :myname];

  fp = fopen(fullName, "rb");
  while (getc(fp) != EOF) {};
  count = ftell(fp)/sizeof(short);
  rewind(fp);
  numperchannel = count/(num_chnls * numlanes);
  if (debugMode) NSLog(@"numLanes=%d  width=%d",numlanes, numperchannel);

  if(laneFileObj != NULL) [laneFileObj release];
  laneFileObj = [[LanesFile alloc] init];

  data = calloc(num_chnls * numperchannel, sizeof(unsigned short));
  for(lane = 0; lane<numlanes; lane++) {
    rawList = [[SeqList alloc] initCount:num_chnls];
    for (i = 0; i < num_chnls; ++i) {
      tempArray = [[ArrayStorage alloc] initCount:0 elementSize:sizeof(float)
                                      description:"f"];
      [rawList addObject:tempArray];
    }

    fread(data, sizeof(unsigned short), num_chnls*numperchannel, fp);
    loc = data;
    for (i = 0; i < num_chnls; i++) {
      for (j = 0; j < numperchannel; j++) {
        dataItem = *(loc++);
        dataItem = (signed short) NSSwapBigShortToHost(dataItem);
        flt_temp = (float)dataItem;
        //swap always casts to unsigned so must recast back to signed
        //you must separate these casts onto different lines, it didn't
        // work when combining onto a single line
        flt_temp = (float) dataItem;
        [[rawList objectAt:i] addElement:&flt_temp];
      }
    }

    [rawList setDefaultRawLabels];
    script = [[NewScript alloc] init];
    [script addUnprocessedList:rawList BaseList:nil name:NULL];
    [laneFileObj addScript:script];
    [script release];
  }
  free(data);

  [self setDefaultColors];
  //[self initializeArrays];

  [updateBox done:self];

  [myMasterView setColorWells];
  [self setFileName:(char*)fullName];
  [numLanesID setIntValue:[laneFileObj numLanes]];
  [self show:self];
  return self;
}
#endif

@end
