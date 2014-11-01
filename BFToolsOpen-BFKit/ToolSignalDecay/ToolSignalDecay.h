
/* "$Id: ToolSignalDecay.h,v 1.4 2007/04/11 02:06:34 smvasa Exp $" */
/***********************************************************

Copyright (c) 2006 Suzy Vasa 

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
NIH Center for AIDS research

******************************************************************/

#import <BaseFinderKit/GenericTool.h>


@interface ToolSignalDecay:GenericTool
{
  int			scale;
	int			rangeFrom;
	int			rangeTo;
	double	coeff[3];
}

- init;
- apply;
- (NSString *)toolName;
- (BOOL)shouldCache;

- (void)setValues:(double *)inCoeff :(int)size;
-(void)getValues:(double *)decays :(int *)size  :(int *)from :(int *)to;
- (void)setRange:(int)from :(int)to;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

@end
