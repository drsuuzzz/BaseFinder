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
/* LadderPeak.m created by giddings on Wed 22-Apr-1998 */

#import "LadderPeak.h"

@implementation LadderPeak

- init
{
  channel = 0;
  return self;
}
- (int)channel
{
  return channel;
}

//Subclass should override but these has to be here or comparePosition:
//won't compile.
- (float)position
{
  return 0;
}

- (float)area
{
  return 0;
}

////////////////////

- (void)setChannel:(int)chan
{
  channel = chan;
}

- (NSComparisonResult)comparePosition:(id <LadderPeak>)obj
{
        if ([self position] < [obj position])
                return NSOrderedAscending;
        else if ([self position] > [obj position])
                return NSOrderedDescending;
        else
                return NSOrderedSame;
}

- (NSComparisonResult)compareSize:(id <LadderPeak>)obj
{
  if ([self area] < [obj area])
    return NSOrderedAscending;
  else if ([self area] > [obj area])
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}


- (id)copyWithZone:(NSZone *)zone
{
  LadderPeak   *dupSelf;

  dupSelf = [[[self class] alloc] init];

  dupSelf->channel = channel;

  return dupSelf;
 
}

@end
