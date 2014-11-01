/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import <GeneKit/MGNSMutableData.h>


@interface MGMutableFloatArray:NSObject
{
	MGNSMutableData *theArray;
	float *fltarray;
	//Realsize is included in case at some point functionality would be added
	//for rapid insertion by creating an array larger than is actually needed.
	//For now, however, realsize=count
	unsigned count, realsize;

        //For array traversal in category FLTArrayTraverseExt - since
        //instance variables can't be used in a category.
        unsigned curPos;
        BOOL reachedEnd;

}

+ (MGMutableFloatArray *)floatArrayWithCount:(unsigned)_count;
+ (MGMutableFloatArray *)floatArray;
+ (MGMutableFloatArray *)floatArrayUsingData:(MGNSMutableData *)thedata;

- (MGMutableFloatArray *)init;
- (MGMutableFloatArray *)initWithDataObj:(MGNSMutableData *)thedata;
- (MGMutableFloatArray *)initWithCount:(unsigned)theCount;

- (MGMutableFloatArray *)setRefToData:(MGNSMutableData *)thedata;
- (float)elementAt:(unsigned)pos;
- (void)setValueAt:(unsigned)pos to:(float)val;
- (void)insertValueAt:(unsigned)pos value:(float)val;
- (void)appendValue:(float)val;
- (void)deleteValueAt:(unsigned)position;
- (float *)floatArray;
- (MGNSMutableData *)theFloatData;
- (void)increaseCountBy:(unsigned)amount;
- (unsigned)count;
- (void)removeNegatives;
- (void)writeToTextFile:(NSString *)pathname;
- (NSString *)stringValueForElement:(int)pos;

@end
