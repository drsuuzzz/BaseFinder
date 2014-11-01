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

/* TraceFileAdapter.h created by jessica on Fri 21-Nov-1997 */

#import <Foundation/Foundation.h>
#import <GeneKit/Trace.h>
#import <GeneKit/Sequence.h>
#import <GeneKit/TraceDataWrapper.h>
#import <GeneKit/MGMutableFloatArray.h>

@interface TraceFileAdapter : NSObject
{
  BOOL debugmode;
}

+ (TraceFileAdapter *)adapter;
- (void)setDebugmode:(BOOL)state;

//ABI file section (no saving)
- (Trace*)rawTraceFromABIFile:(NSString*)path;
- (Trace*)processedTraceFromABIFile:(NSString*)path;
- (Sequence*)sequenceFromABIFile:(NSString*)path;
- (TraceDataWrapper*)wrapperFromABIFile:(NSString*)path;

//DAT file section
- (Trace *)traceFromDATFile:(NSString *)path;
- (int)count_columns:(NSData*)data;
- (Trace*)traceFromTabedAsciiData:(NSData *)data :(int)beginNum;


//SCF file section
- (NSData*)privateDataFromSCFRepresentation:(NSData*)fileData;

- (Trace*)traceFromSCFFile:(NSString*)path;
- (Trace*)altTraceFromSCFFile:(NSString*)path;
- (Sequence*)sequenceFromSCFFile:(NSString*)path;
- (TraceDataWrapper*)wrapperFromSCFFile:(NSString*)path;

- (Trace*)traceFromSCFRepresentation:(NSData*)data;
- (Trace*)altTraceFromSCFRepresentation:(NSData*)data;
- (Sequence*)sequenceFromSCFRepresentation:(NSData*)data;
- (NSData*)scriptRepFromSCFRepresentation:(NSData*)fileData;
- (NSData*)commentFromSCFRepresentation:(NSData*)fileData;

- (BOOL)writeSCFFile:(NSString*)path
               trace:(Trace*)aTrace
            sequence:(Sequence*)aSequence
             rescale:(BOOL)shouldRescale;
- (NSData*)SCFRepresentationFromTrace:(Trace*)aTrace
                             sequence:(Sequence*)aSequence
                              rescale:(BOOL)shouldRescale;
- (NSData*)SCFRepresentationFromTrace:(Trace*)aTrace
                             sequence:(Sequence*)aSequence
                              rescale:(BOOL)shouldRescale
                             altTrace:(Trace*)rawTrace
                               script:(NSData*)aScript
                              comment:(NSString*)comment;
- (MGMutableFloatArray*)SCFScalesFromTrace:(Trace*)aTrace;   //if 'shouldRescale' these are the scales used


//LANE file section
- (Trace*)startingTraceFromLANEFile:(NSString*)path;
- (Trace*)finalTraceFromLANEFile:(NSString*)path;
- (Sequence*)startingSequenceFromLANEFile:(NSString*)path;
- (Sequence*)finalSequenceFromLANEFile:(NSString*)path;
- (TraceDataWrapper*)wrapperFromLANEFile:(NSString*)path;


//Sequence output section
- (NSData*)SEQRepresentationFrom:(Sequence*)aSequence;
- (NSData*)FASTARepresentationFrom:(Sequence*)aSequence;
- (NSData*)FASTARepresentationFromArray:(NSArray*)multipleSequences;
- (BOOL)writeSEQFile:(NSString*)path
            sequence:(Sequence*)aSequence;
- (BOOL)writeFASTAFile:(NSString*)path
              sequence:(Sequence*)aSequence;
- (BOOL)writeFASTAFile:(NSString*)path
         sequenceArray:(NSArray*)multipleSequences;
@end
