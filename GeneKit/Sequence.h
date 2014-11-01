/* "$Id: Sequence.h,v 1.8 2007/05/24 20:22:57 smvasa Exp $" */
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

//By Morgan Giddings
//Version 0.5
#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <GeneKit/Base.h>

@interface Sequence:NSObject <NSCoding, NSCopying>
{
  NSMutableArray  *theSeq;  //NSArray of Bases or subclass
  Class           BaseClass;
  NSString        *label;
	int							offset;
	BOOL						backForwards;
}

+ (Sequence *)newWithCStringSeq:(char *)seq;
+ (Sequence *)newWithString:(NSString *)string;
+ (Sequence *)newWithString:(NSString *)string class:(Class)class;
+ (Sequence *)newSequence;
+ (Sequence *)sequenceWithString:(NSString *)string;  //autorelease version
- init;
-initWithContentsOfFile:(NSString*)fname;

//Object oriented base accessor methods
- (id <BaseProtocol>)baseAt:(unsigned)baseno; //Not typed to a specific ID for subclasses
- (void)addBase:(id <BaseProtocol>)base;
- (void)insertBase:(id <BaseProtocol>)base At:(unsigned)baseno;
- (void)removeBaseAt:(unsigned)index;
- (unsigned)positionOfBase:(id <BaseProtocol>)base;
- (int)indexOfBaseAssociatedWithPeak:(id)peak;

//Character oriented base accessor methods
- (char)charBaseAt:(unsigned)baseno;
- (void)addCharBase:(char)base;
- (void)insertCharBase:(char)base At:(unsigned)baseno;


//Whole sequence accessor methods
- (void)getCStringSeqRep:(char *)theCBuf;
- (NSString *) seqString;
- (void)setClass:(Class)class;
- setSeqFromCString:(char *)theBases;


//Sequence operations
- (void)reverseSequence:sender;
- (void)complementSequence:sender;
- (Sequence*)reverseComplement;
- (Sequence*)unpaddedSequence;
- (void)partialSequenceFrom:(int)from to:(int)to;
- (void)maskSequence:(char *)theCs NT1:(char)nt1 NT2:(char)nt2;
-(int) alignOverlapRNA:(char *)seq2 :(int)len2 :(char) nt1 :(char) nt2 :(char *)align1 :(char *)align2 :(int *)lenAlign;

- (unsigned)seqLength;
- (unsigned)count;
- (void)dealloc;
- (void) setOffset:(int)newset;
- (int) getOffset;
- (void) setbackForwards:(BOOL)flag;
- (BOOL) getbackForwards;

//Labeling the sequence
- (void)setLabel:(NSString*)aString;
- (NSString*)label;

//Sorting Sequence
- (void)sortByLocation;

//Oligo Searching
- (NSMutableArray*)locationsOfOligo:(Sequence*)oligo;


@end
