/***********************************************************

Copyright (c) 1997-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/* SCFTraceFile.h created by jessica on Fri 21-Nov-1997 */

/* The .scf format is used by Washington University's TED program (sequence quality checker).
 * It is a BigEndian format. Also used by STADEN package
 */
#import <Foundation/Foundation.h>
#import <GeneKit/Trace.h>
#import <GeneKit/Sequence.h>
#import <GeneKit/TraceDataWrapper.h>
#import <GeneKit/MGMutableFloatArray.h>

@interface SCFTraceFile : NSObject
{
  NSString              *pathname;
  NSMutableData         *scfData;
  BOOL                  debugmode, shouldRescale;

  Trace                 *primaryTrace, *alternateTrace;
  Sequence              *primarySequence;
  NSString              *comment;
  NSData                *scriptData;
  NSMutableDictionary   *taggedInfo;
}

+ (id)scf;
+ (id)scfWithContentsOfFile:(NSString*)path;

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initFromSCFRepresentation:(NSData*)data;

- (NSData*)SCFFileRepresentation;
- (BOOL)writeToFile:(NSString*)path atomically:(BOOL)flag;

//available in all scf files
- (TraceDataWrapper*)wrapper;
- (Trace*)primaryTrace;
- (Sequence*)sequence;
- (NSString*)comment;

  //UW Smith group extensions to use private data section for addition info
//like raw data, script, ...
- (NSData*)privateData;                //give the entire private data section in its raw form
- (Trace*)alternateTrace;
- (NSData*)scriptRepresentation;       //an AsciiArchiver archive of script and related variables
- (NSMutableDictionary*)taggedInfo;    //a property list of additional info

- (void)setPrimaryTrace:(Trace*)aTrace;
- (void)setSequence:(Sequence*)aSequence;
- (void)setComment:(NSString*)aComment;
- (void)setAlternateTrace:(Trace*)aTrace;
- (void)setScriptRepresentation:(NSData*)aScript;
- (void)setTaggedInfo:(NSMutableDictionary*)aDict;

- (void)setDebugmode:(BOOL)state;
- (void)setShouldRescale:(BOOL)state;
- (MGMutableFloatArray*)SCFScalesFromTrace:(Trace*)aTrace;   //if 'shouldRescale' these are the scales used

- (BOOL)traceHasFloats:(Trace*)dataList;
- (void)rescaleTraceToUSHRT:(Trace*)dataList;

@end
