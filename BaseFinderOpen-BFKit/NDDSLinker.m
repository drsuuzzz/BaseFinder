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

#import "NDDSLinker.h"

@protocol NDDSServerProtocol
- (NSString*)serverVersion;
- (id)allocTool:(NSString*)toolClass;
- (NSArray*)availableTools;
@end


@implementation NDDSLinker

- init
{
  [super init];
  [NSBundle loadNibNamed:@"NDDSLinker.nib" owner:self];
  toolMatrix = [toolScrollView documentView];
  return self;
}

- (void)runModal
{
  [NSApp runModalForWindow:linkerPanel];
}

- (void)updateAvailableTools:sender
{
  NSConnection  *theConnection;
  id            NDDSserver, tempCell;
  NSArray       *availableTools;
  int           i,count;
  
  hostMachine = [machineName stringValue];

  theConnection = [NSConnection connectionWithRegisteredName:@"NDDSToolServer" host:hostMachine];
  NDDSserver = [[theConnection rootProxy] retain];

  [serverVersion setStringValue:[NDDSserver serverVersion]];
  availableTools = [NDDSserver availableTools];
  if (debugmode) NSLog(@"availableTools=%@", availableTools);

  //set up matrix
  [[toolMatrix prototype] setHighlightsBy:NSPushInCellMask];
  //[[toolMatrix prototype] setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
  if([availableTools count] > [toolMatrix numberOfRows]) {
    count = [availableTools count] - [toolMatrix numberOfRows];
    for(i=0; i<count; i++) [toolMatrix addRow];
  }
  if([availableTools count] < [toolMatrix numberOfRows]) {
    count = [toolMatrix numberOfRows] - [availableTools count];
    for(i=0; i<count; i++) [toolMatrix removeRow:0];
  }
  for(i=0; i<[availableTools count]; i++) {
    //NSButtonCell
    tempCell = [toolMatrix cellAtRow:i column:0];
    [tempCell setTitle:[availableTools objectAtIndex:i]];
    //[tempCell setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
    [tempCell setHighlightsBy:NSPushInCellMask]; 
  }
  [toolMatrix sizeToCells];
  [toolMatrix setNeedsDisplay:YES];
  [toolScrollView display];
}

- (void)link:sender
{
  //send message to delegate with selected tools and machine
  //NSMutableArray     *selectedTools;

  //[delegate createNDDSLinks:selectedTools onMachine:hostMachine];
  [NSApp stopModal];
  [linkerPanel orderOut:self];
}

- (NSArray*)selectedTools;
{
  return NULL;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  //should check from correct window
  [NSApp stopModal];
}

@end
