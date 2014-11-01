/* "$Id: ScriptScheduler.m,v 1.2 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith

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

/* ScriptScheduler.m created by jessica on Thu 02-Apr-1998 */

#import "ScriptScheduler.h"
#import "NewScript.h"

ScriptScheduler    *_theOnlyScriptScheduler = nil;

@interface ScriptScheduler (ScriptSchulerLocalMethods)
- (void)checkActiveJobs;
- (void)jobFinished:(NSNotification *)aNotification;
- (BOOL)jobAlreadyQueued:(NewScript*)aScript;
@end

@implementation ScriptScheduler

- (void)checkActiveJobs
{
  NewScript   *aScript;
  int         i=0;

  while(i<[activeJobs count]) {
    if(![[activeJobs objectAtIndex:i] threadIsExecuting]) {
      //a lost job, disconnect it
      [activeJobs removeObjectAtIndex:i];
      fprintf(stderr,"lost job!!!\n");
    }
    else
      i++;
  }

  if([activeJobs count] > 0) return;    //some jobs are already running
  if([waitingJobs count] == 0) return;  //nothing left to queue

  aScript = [[waitingJobs objectAtIndex:0] retain];
  [waitingJobs removeObjectAtIndex:0];
  [activeJobs addObject:aScript];
  [aScript release];
  [aScript executeInThread];
}

- (void)jobFinished:(NSNotification *)aNotification
{
  NewScript   *aScript = [aNotification object];
  int         index;

  index = [activeJobs indexOfObjectIdenticalTo:aScript];
  if(index == NSNotFound)
    fprintf(stderr, "ScriptScheduler internal error: finished job not queued\n");
  else {
    [activeJobs removeObjectAtIndex:index];
  }
  [self checkActiveJobs];
}

- (BOOL)jobAlreadyQueued:(NewScript*)aScript;
{
  if(([activeJobs indexOfObjectIdenticalTo:aScript] == NSNotFound) &&
     ([waitingJobs indexOfObjectIdenticalTo:aScript] == NSNotFound))
    return NO;
  else
    return YES;
}

- init
{
  [super init];
  activeJobs = [[NSMutableArray array] retain];
  waitingJobs = [[NSMutableArray array] retain];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(jobFinished:)
                                               name:@"BFScriptThreadFinished"
                                             object:nil];
  [NSTimer scheduledTimerWithTimeInterval:15.0
                                   target:self
                                 selector:@selector(checkActiveJobs)
                                 userInfo:nil
                                  repeats:YES];
  return self;
}


/*****
*
* Public API methods
*
*****/

+ (ScriptScheduler*)sharedScriptScheduler
{
  if(_theOnlyScriptScheduler != nil) return _theOnlyScriptScheduler;

  _theOnlyScriptScheduler = [[ScriptScheduler alloc] init];
  return _theOnlyScriptScheduler;
}

- (BOOL)addForgroundJob:(NewScript*)aScript
{
  if(![[NSUserDefaults standardUserDefaults] boolForKey:@"useForgroundThreading"]) {
    [activeJobs addObject:aScript];
    [aScript execToIndex:[aScript desiredExecuteIndex]];
    [[NSNotificationCenter defaultCenter]
            postNotificationName:@"BFScriptThreadFinished"
                          object:aScript];
    return YES;
  }
  
  if([self jobAlreadyQueued:aScript]) return NO;
  [activeJobs addObject:aScript];
  [aScript lockScriptForThreading];
  [aScript executeInThread];
  return YES;
}

- (BOOL)addBackgroundJob:(NewScript*)aScript
{
  if([self jobAlreadyQueued:aScript]) return NO;
  [waitingJobs addObject:aScript];
  [aScript lockScriptForThreading];
  [self checkActiveJobs];
  return YES;
}

@end
