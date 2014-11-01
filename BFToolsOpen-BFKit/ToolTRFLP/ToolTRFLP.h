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
NIH Cystic Fibrosis

******************************************************************/

#import <BaseFinderKit/GenericTool.h>
#import <GeneKit/EventLadder.h>
#import <GeneKit/Gaussian.h>
#import <GeneKit/Sequence.h>

@interface ToolTRFLP:GenericTool
{
  NSString  *myOutFile;
  Sequence  *markerBases;
  EventLadder    *peakAreas;
  double       *X; //list of base positions matching standard
  double       *Y; //list of position of base versus time
  int       numPairs;
  NSString  *standard;
  float     threshold[2];
	int				pstate;
}

- (NSString *)getOutFile;
- (void) saveOutFile:(NSString*)outFile;
- (void) setTheData:(NSString*)marker :(float *)thresh :(int)primerState;
- (NSString *) getTheData:(float*)thresh :(int*)primerState;

- apply;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (void)beginDearchiving:archiver;
- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

@end
