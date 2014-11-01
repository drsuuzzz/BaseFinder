/* "$Id: GenericTool.m,v 1.4 2006/10/06 16:44:52 smvasa Exp $" */
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

#import "GenericTool.h"
#ifdef GNUSTEP_BASE_LIBRARY
#import <extensions/objc-runtime.h>
#else
#import <objc/objc-runtime.h>
#endif
#import "NewScript.h"

/*****	
* Oct 18, 1998 Jessica Severin
* Split into separate source files for PDO
*
* July 19, 1994 Mike Koehrsen
* Split GenericTool class into GenericTool and GenericToolCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
*****/


@implementation GenericTool

- (float)numSelChannels
{
  return numSelChannels;
}
- (void)setNumSelChannels:(float)value
{
  numSelChannels = value;
}
- (int)selChannels:(int)index
{
  return selChannels[index];
}
- (void)setSelChannels:(int)value at:(int)index
{
  selChannels[index]=value;
}

- (id)init
{
  dataList = NULL;
  baseList = NULL;
  alnBaseList = NULL;
  peakList = NULL;
  ladder = NULL;
  script = NULL;
  return [super init];
}

- (void)dealloc
{
  [self clearPointers];
  if(script != nil) [script release];
  [super dealloc];
}

- (id)apply // Must be overridden
{
	return self;
}

- (NSString*)toolName;
{
  return [self description];
}

- (BOOL)isSelectedChannel:(int)channel
{
	return selChannels[channel];
}

- (BOOL)shouldCache
{
  return NO; // override as needed
}

- (BOOL)modifiesData
{
	return YES; // Will be overridden for base-calling tool, typically
}

- (BOOL)isOnlyAnInterface
{
  // Will be overridden by tools that are not designed to be
  // added to scripts, ie they do not have an -apply method
  return NO;
}

- (BOOL)isInteractive
{
	return NO;
}

- (void)setController:(id)ctrl
{
    controller = ctrl;
}

- (void)setScript:(NewScript*)aScript;
{
  if(script != nil) [script release];
  script = [aScript retain];
}

- (void)setDataList:(Trace*)theList
{
  if(dataList  != nil) [dataList release];
  dataList = [theList retain];
}

- (Trace*)dataList
{
  //NSLog(@"self=%@  data=%@ retainCount=%d", self, dataList, [dataList retainCount]);
  return dataList;
}

- (Sequence*)baseList
{
  return baseList;
}

- (void)setBaseList:(Sequence*)theList
{
  if(baseList  != nil) [baseList release];
  if([theList isKindOfClass:[Sequence class]]) {
    baseList = [theList retain];
  } else
    baseList = NULL;
}

- (Sequence*)alnBaseList
{
  return alnBaseList;
}

- (void)setAlnBaseList:(Sequence*)theList
{
  if(alnBaseList  != nil) [alnBaseList release];
  if([theList isKindOfClass:[Sequence class]]) {
    alnBaseList = [theList retain];
  } else
    alnBaseList = NULL;
}

-(AlignedPeaks *)peakList
{
  return peakList;
}

- (void)setPeakList:(AlignedPeaks*)theList
{
  if(peakList  != nil) [peakList release];
  if(theList != nil) {
    peakList = [theList retain];
  } else
    peakList = NULL;
}

- (void)setLadder:(EventLadder*)theLadder
{
  if(ladder != nil) [ladder release];
  if([theLadder isKindOfClass:[EventLadder class]]) {
    ladder = [theLadder retain];
  } else
    ladder = NULL;
}

- (EventLadder*)ladder
{
  return ladder;
}


- (void)clearPointers
{
  if(dataList  != nil) [dataList release];
  if(baseList  != nil) [baseList release];
  if(alnBaseList != nil) [alnBaseList release];
  if(peakList != nil) [peakList release];
  if(ladder != nil) [ladder release];
  dataList = NULL;
  baseList = NULL;
  alnBaseList = NULL;
  peakList = NULL;
  ladder = NULL;
}

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  int i;

  if (!strcmp(tag,"selChannels")) {
    [archiver readArray:selChannels];
    numSelChannels = 0;
    for (i=0;i<8;i++)
      if (selChannels[i])
        numSelChannels += 1;
  } else
    return [super handleTag:tag fromArchiver:archiver];
  
  return self;
}

- (void)writeAscii:archiver
{
	[archiver writeArray:selChannels size:8 type:"i" tag:"selChannels"];
	
	return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- copy
{
  return [self copyWithZone:NSDefaultMallocZone()];
}

/* original copy */
- (id)copyWithZone:(NSZone *)zone
{
  //copying a generictool does not copy the data with it
  GenericTool     *dupSelf;
  int             i;

  dupSelf = [[self class] allocWithZone:zone];
  [dupSelf init];
  dupSelf->dataList = NULL;
  dupSelf->baseList = NULL;
  dupSelf->alnBaseList = NULL;
  dupSelf->peakList = NULL;
  dupSelf->ladder = NULL;
  dupSelf->controller = controller;
  dupSelf->numSelChannels = numSelChannels;
  for(i=0; i<8; i++) dupSelf->selChannels[i] = selChannels[i];

  return dupSelf;
}


/* new but broken *
- (id)copyWithZone:(NSZone *)zone
{
  //copying a generictool does not copy the data with it
  GenericTool     *dupSelf = NSCopyObject(self, 0, zone);

  dupSelf->dataList = NULL;
  dupSelf->baseList = NULL;
  dupSelf->ladder = NULL;
  return dupSelf;
}
*/

/*****
* status methods forwarded to controlling script
*****/
- (void)setStatusMessage:(NSString*)aMessage
{
  [script setStatusMessage:aMessage];
}

- (void)setStatusPercent:(float)percent
{
  [script setStatusPercent:percent];
}

- (BOOL)debugmode;
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
}

@end

