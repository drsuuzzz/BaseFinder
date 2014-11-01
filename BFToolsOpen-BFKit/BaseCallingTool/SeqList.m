/* "$Id: SeqList.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */
/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "SeqList.h"

/*
#define C_COLOR	[NSColor blueColor]
#define A_COLOR [NSColor greenColor]
#define G_COLOR [NSColor blackColor]
#define T_COLOR [NSColor redColor]
*/

@implementation SeqList

- (id)copyList
{	
  int count, i;
  SeqList *newList;

  count = numElements;
  newList = [[SeqList alloc] initCount:count];
  for (i = 0; i < count; i++)
    [newList addObject:[[self objectAt:i] copy]];

  return newList;
}

- (void)freeList
{
  int count,i;

  count = numElements;
  for (i = 0; i < count; i++)
    [[self objectAt:i] release];
  [self free];
}

- (void)setLabels:(char **)labels
{
  int	i;

  for (i=0;i < 4 && i < [self count];i++) {
    [(ArrayStorage*)[self objectAt:i] setLabel:labels[i]];
  }
}

- (void)setDefaultRawLabels
{
  char *defaultLabels[] =
  {	"540 nM",
    "560 nM",
    "580 nM",
    "610 nM",
    NULL	};
		
  [self setLabels:defaultLabels];
}

- (void)setDefaultProcLabels
{
  char *defaultLabels[] =
  {	"Channel C",
    "Channel A",
    "Channel G",
    "Channel T",
    NULL	};
		
  [self setLabels:defaultLabels];
}

/*
- (void)setColorsGrays:(NSColor *[][2])colorsGrays
{
  int i;

  for(i=0;colorsGrays[i] && i < [self count];i++) {
    [[self objectAt:i] setColor:colorsGrays[i][0]];
    [[self objectAt:i] setGray:colorsGrays[i][1]];
  }
}

- (void)setDefaultColors
{
  NSColor * defaultColorsGrays[][2] =
  {{ C_COLOR, [NSColor blackColor] },
    { A_COLOR, [NSColor darkGrayColor] },
    { G_COLOR, [NSColor grayColor] },
    { T_COLOR, [NSColor lightGrayColor] },
    { 0 , 0 }
  };

  [self setColorsGrays:defaultColorsGrays];
}
*/

@end
