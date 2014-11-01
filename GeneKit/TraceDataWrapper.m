/* TraceDataWrapper.m created by giddings on Wed 04-Mar-1998 */
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

#import "TraceDataWrapper.h"

@implementation TraceDataWrapper
+ (TraceDataWrapper *)wrapperWithRawTrace:(Trace *)raw
                           processedTrace:(Trace *)processed
                                 sequence:(Sequence *)seq
{
  TraceDataWrapper *wrap = [[self alloc] init];
  [wrap setRawTrace:raw];
  [wrap setProcessedTrace:processed];
  [wrap setSequence:seq];
  return [wrap autorelease];
}

+ (TraceDataWrapper *)wrapper
{
  return [[[self alloc] init] autorelease];
}

- init
{
  rawTrace = NULL;
  processedTrace = NULL;
  sequence = NULL;
  [super init];
  return self;
}

- (void)setRawTrace:(Trace *)raw
{
  if (rawTrace != NULL)
    [rawTrace release];
  rawTrace = [raw retain];
}

- (void)setProcessedTrace:(Trace *)processed
{
  if (processedTrace != NULL)
    [processedTrace release];
  processedTrace = [processed retain];

}

- (void)setSequence:(Sequence *)seq
{
  if (sequence != NULL)
    [sequence release];
  sequence = [seq retain];
}

- (Trace *)rawTrace
{
  return rawTrace;
}

- (Trace *)processedTrace
{
  return processedTrace;
}

- (Sequence *)sequence
{
  return sequence;
}

- (void)dealloc
{
  if (sequence != NULL)
    [sequence release];
  if (processedTrace != NULL)
    [processedTrace release];
  if (rawTrace != NULL)
    [rawTrace release];
  [super dealloc];
}

@end
