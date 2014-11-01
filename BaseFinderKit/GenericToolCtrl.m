/* "$Id: GenericToolCtrl.m,v 1.3 2006/08/04 17:23:55 svasa Exp $" */
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

#import "GenericToolCtrl.h"
#import <GeneKit/AsciiArchiver.h>
#if defined(GNU_RUNTIME)
#else
#import <objc/objc-runtime.h>
#endif
#import <GeneKit/Trace.h>
#import "NewScript.h"


/*****	
* Oct 28, 1998 Jessica Severin
* Finished spliting by making into separate files. Needed for PDO.
*
* July 19, 1994 Mike Koehrsen
* Split GenericTool class into GenericTool and GenericToolCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
* Also eliminated currentSeqEdit ivar in favor of global GSeqEdit.
*****/

@interface GenericTool (PrivateGenericTool)
- (float)numSelChannels;
- (void)setNumSelChannels:(float)value;
- (int)selChannels:(int)index;
- (void)setSelChannels:(int)value at:(int)index;
@end

@implementation GenericToolCtrl

- (void)dealloc
{
  if (dataProcessor != nil) [dataProcessor release];
  [super dealloc];
}


+ newTool:myToolMaster
{
  NSString   *nibPath;
  NSString   *name;
  NSRange    tempRange;
  struct ctrlDefs { @defs(GenericToolCtrl) } *newDefs;
  GenericToolCtrl  *newSelf;

  tempRange = [[[self class] description] rangeOfString:CTRLSUF];
  name = [[[self class] description] substringToIndex:tempRange.location];

  nibPath = [[NSBundle bundleForClass:self] pathForResource:name
                                                     ofType:@"nib"];
  if(nibPath == nil)
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"])
      printf("error finding nib -- %s\n",[name cString]);
		
  newSelf = [self alloc];
  newDefs = (struct ctrlDefs *)newSelf;

  newDefs->toolMaster = myToolMaster;
  //newDefs->dataProcessor = [[objc_lookUpClass([scratch cString]) alloc] init];
  newDefs->dataProcessor = [[NSClassFromString(name) alloc] init];

  if([NSBundle loadNibFile:nibPath
         externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:newSelf, @"NSOwner", nil]
                  withZone:[newSelf zone]]==NO)
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"])
      printf("Nib load failed--%s\n",[nibPath cString]);

  [newSelf init];
  [newSelf->inspectorView retain];
  [newDefs->dataProcessor setController:newSelf];
  return [newSelf autorelease];
}

- (void)appWillInit
{			
}

- (void)setDataProcessor:(GenericTool*)processor
{
  [dataProcessor autorelease];
  dataProcessor = [processor retain]; 
}

- (GenericTool*)dataProcessor { return dataProcessor; }

- (NSBox*)inspectorView
{
  BOOL debugmode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
  
  if (inspectorView==nil) {
    NSString  *nibPath;
    NSString  *scratch;
    NSRange   tempRange;

    tempRange = [[[self class] description] rangeOfString:CTRLSUF];
    scratch = [[[self class] description] substringToIndex:tempRange.location];

    nibPath = [[NSBundle bundleForClass:[self class]] pathForResource:scratch
                                                               ofType:@"nib"];
    if(nibPath == nil)
      if(debugmode) printf("error finding nib -- %s\n",[scratch cString]);

    if(debugmode) printf("nibPath = '%s'\n",[nibPath cString]);

    if([NSBundle loadNibFile:nibPath
           externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil]
                    withZone:[self zone]]==NO)
      if(debugmode) printf("loadNibFile failed--%s\n",[nibPath cString]);
    [inspectorView retain];
  }
  return inspectorView;
}

- (void)registerValue:sender
{
  [self getParams]; 
}

- (void)getParams
{
  int     row,col, index, value;
  float   count=0.0;

  if (channelSelID == nil)
    return;

  for(row=0;row<2;row++) {
    for(col=0;col<4;col++) {
      index = row*4 + col;
      value = [[channelSelID cellAtRow:row column:col] intValue];
      [dataProcessor setSelChannels:value at:index];
      if(value) count +=  1.0;
    }
  }
  [dataProcessor setNumSelChannels:count];
}


- (void)displayParams
{
  int numChannels = [toolMaster numberChannels], index;

  if (channelSelID == nil)
    return;

  for(index=0;index<8;index++) {
    if(index<numChannels) {
      [[channelSelID cellAtRow:index/4 column:index%4] setEnabled:YES];
      [[channelSelID cellAtRow:index/4 column:index%4] setIntValue:[dataProcessor selChannels:index]];
    }
    else {
      [[channelSelID cellAtRow:index/4 column:index%4] setIntValue:[dataProcessor selChannels:index]];
      [[channelSelID cellAtRow:index/4 column:index%4] setEnabled:NO];
    }
  }
}

//this routine will be called when new trace file is loaded.  Tools can use to clear data and release memory carried over from another script.
- (void)resetParams
{
  
}

- (void)resetSelChannels // enable all channels present in seqEdit
{
  int numChannels = [toolMaster numberChannels], i;

  for (i=0;i<8;i++)
    if (i<numChannels) [dataProcessor setSelChannels:1 at:i];
    else [dataProcessor setSelChannels:0 at:i];
  [dataProcessor setNumSelChannels:(float)numChannels]; 
}

- (void)show
{
  [toolMaster showTool:self]; 
}

// These do nothing by default, but can be overridden
- (void)inspectorDidDisplay
{

}

- (BOOL)inspectorWillUndisplay
{
  return YES;
}


@end
