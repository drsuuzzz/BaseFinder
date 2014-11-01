/* "$Id: StatusController.m,v 1.2 2006/08/04 20:31:58 svasa Exp $" */
/***********************************************************

Copyright (c) 1994-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/********
StatusController.m is a general purpose object to graphically display
process status. 
********/

#import "StatusController.h"
#import "BoxView.h"
#import <AppKit/NSApplication.h>
#import <stdlib.h>

static StatusController  *theStatusController=NULL;

@implementation StatusController

+ (StatusController*)connect
{
  /** ensures that only one StatusContoller is created per application **/	
  if (NSApp == nil) return nil;
  if(!theStatusController) {
    theStatusController = [super alloc];
    [NSBundle loadNibNamed:@"StatusController.nib" owner:theStatusController];
    [theStatusController init];
  }
  return theStatusController;
}

- init
{
  isconnected = NO;
  type = 0;
  [messageText retain];
  [statusBoxView retain];
  
 // [messageText removeFromSuperview];
//  [statusBoxView removeFromSuperview];
  [masterMessage setStringValue:[NSString string]];

  /* The code below is to properly syncronize in NT.
    In NT the status panel also has the menu added to the top of it.
    This causes the window to be bigger than the window stored in the .nib
    without the following sync, the window will grow taller with each launch
    of basefinder
    */
//  [statusPanel setFrameUsingName:@"StatusPanel"];
 // [statusPanel display];
//  PSWait();   /* sync app with window server */
//  [statusPanel setFrameAutosaveName:@"StatusPanel"];
//  [statusPanel display];

  return self;
};

- (void)dealloc
{
  theStatusController=NULL;
  [messageText release];
  [statusBoxView release];
  [super dealloc];
}

- (void)setSuperMessage:(NSString*)message;
{
  [masterMessage setStringValue:message];
  [masterMessage display];
#ifndef MACOSX
  PSWait();   /* sync app with window server */
  #endif
}

- (BOOL)processConnect:sender :(char *)processName :(float)initPcent
{
  if (isconnected == YES)
    {
    
    }

  currentProcess = sender;
  [processNameText setStringValue:[NSString stringWithCString:processName]];
  [altStatus setStringValue:@"% Complete:"];
  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:messageText] != NSNotFound)
    [messageText removeFromSuperview];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:statusBoxView] == NSNotFound)
    [[statusPanel contentView] addSubview:statusBoxView];

  [statusBoxView setPercent:initPcent];
  isconnected = YES;
  type = STATUS;
  [statusPanel display];
  [statusPanel orderFront:self];
    #ifndef MACOSX
  PSWait();   /* sync app with window server */
    #endif
  return YES;
}

- (BOOL)messageConnect:sender :(char *)processName :(char *)initMessage
{
  if (isconnected == YES)
    {
    }

  currentProcess = sender;
  [processNameText setStringValue:[NSString stringWithCString:processName]];
  [altStatus setStringValue:@"Message:"];
  [messageText setStringValue:[NSString stringWithCString:initMessage]];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:statusBoxView] != NSNotFound)
    [statusBoxView removeFromSuperview];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:messageText] == NSNotFound)
    [[statusPanel contentView] addSubview:messageText];

  isconnected = YES;
  type = MESSAGE;
  [statusPanel display];
 [statusPanel orderFront:self];
  return YES;
}

- (BOOL)processConnect:sender :(char *)processName
{
  if (isconnected == YES)
    {
    
    }
  currentProcess = sender;
  [processNameText setStringValue:[NSString stringWithCString:processName]];
  [altStatus setStringValue:[NSString string]];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:statusBoxView] != NSNotFound)
    [statusBoxView removeFromSuperview];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:messageText] != NSNotFound)
    [messageText removeFromSuperview];

  isconnected = YES;
  type = PROCESS;
  [statusPanel display];
  [statusPanel orderFront:self];
  return YES;
}

- (BOOL)updatePercent:sender :(float)percent
{
  if ((currentProcess != sender) || (type!=STATUS))
    return NO;
  [statusBoxView setPercent:percent];
  [statusBoxView display];
  [statusPanel orderFront:self];
  return YES;
}

- (BOOL)updateMessage:sender :(char*)message
{
  if ((currentProcess != sender) || (type!=MESSAGE))
    return NO;
  [messageText setStringValue:[NSString stringWithCString:message]];
  [messageText display];
  [statusPanel orderFront:self];
  return YES;
}

- (void)hideStatus
{
    [statusPanel orderOut:self];
}

- (void)center
{
  [statusPanel center];
}

- (BOOL)done:sender
{
  if(!isconnected) //|| (currentProcess != sender)
    return NO;
  switch(type) {
    case STATUS:
//      [statusBoxView setPercent:100.0];
//      [statusBoxView display];
      [statusBoxView setPercent:0.0];
      [statusBoxView display];
      break;
    default:
      break;
  }
  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:statusBoxView] != NSNotFound)
    [statusBoxView removeFromSuperview];

  if([[[statusPanel contentView] subviews] indexOfObjectIdenticalTo:messageText] != NSNotFound)
    [messageText removeFromSuperview];

  [processNameText setStringValue:@"No Processing"];
  [altStatus setStringValue:[NSString string]];
  isconnected = NO;
  currentProcess = nil;
  type = 0;
  [self hideStatus];
  return YES;
}

@end
