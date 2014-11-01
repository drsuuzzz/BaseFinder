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

/* TrackingInfo.h created by jessica on Wed 10-Sep-1997 */

#import <Foundation/Foundation.h>

@class NDDSSample;

@interface NDDSData : NSObject
{
  NSString             *identifier;
  NSString             *dataType;
  NSString             *processingState;
  NSDate               *timeStamp;
  BOOL                 shouldArchive;
  
  NSMutableArray       *sampleArray;
  NSMutableArray       *childDataArray, *parentDataArray;
}

- (NSString*)identifier;
- (NSString*)dataType;  //might be redundant, but leave in for now
- (NSString*)processingState;
- (NSDate*)timeStamp;
- (BOOL)shouldArchive;

- (void)setIdentifier:(NSString*)aString;
- (void)setDataType:(NSString*)aString;
- (void)setProcessingState:(NSString*)state;
- (void)timeStampNow;
- (void)setShouldArchive:(BOOL)state;

- (void)associateWithSample:(NDDSSample*)aSample;
- (NSArray*)associatedSamples;
- (BOOL)isSampleCollection;   //overridden by subclasses like Gels and Plates

//Following routines are used for redundancy or in situations where the processing can
//not imeadiately associated generated data with an NDDSSample
- (void)addChildData:(NDDSData*)someData;
- (void)addParentData:(NDDSData*)someData;
- (NSArray*)childData;
- (NSArray*)parentData;
@end
