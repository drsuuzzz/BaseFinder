/* "$Id: LanesFile.h,v 1.6 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith

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

#import <Foundation/Foundation.h>
#import <BaseFinderKit/NewScript.h>

#define BFFileSystemException @"File system error"

// NOTE--lanes are numbered 1..numLanes, but scripts are numbered 0..(numLanes-1)

typedef enum {
  LANE, LANES, SCF, SEQ, FASTA, DAT, SAMEASLOADED, ESD, TXT, SHAPE
} BFlaneFileTypes;

typedef struct {
	unsigned short int	data0;
	unsigned short int	data1;
		unsigned short int	data2;
		unsigned short int	data3;
		unsigned short int	data4;
		unsigned short int	data5;
		unsigned short int	data6;
		unsigned short int	data7;
		unsigned short int	data8;
		unsigned short int	data9;
} ESDRecord;

@interface LanesFile:NSObject
{
  int    numLanes, activeLane, numChannels, currentDataOffset, currentIndex;
  int    currentNumChannels;
  BOOL   dataIsLittleEndian;
  BOOL   rawDataIsScaled;
  BOOL   debugMode;
	BOOL	needsSaveAs; //When we load a type we can't save, we mark this so that we know to save as the first time
  NSMutableString    *bundleDir;
  NSString           *fileName;
  BFlaneFileTypes    defaultSaveType, loadedType;

  NSMutableArray  *lanesScripts;
    // dynamically allocated array of size numLanes
    // This is an array instead of a list because I'm using
    // a NULL pointer to indicate an unloaded lane
    // (Lists automatically close gaps)

}

- initWithContentsOfFile:(NSString *)fullName;
- initFromTabedData:(NSData *)data;

- (void)switchDebugMode:(NSNotification*)aNotification;

- (NSString*)fileName;
- (NSComparisonResult)compareName:(LanesFile *)otherObject;

- (void)dealloc;

- (void)autosave:(NSNotification*)aNotification;
- (void)setDefaultSaveFormat:(NSString*)aType;
- (BOOL)saveCurrentToDefaultFormat;

- (int)numLanes;
- (BOOL)switchToLane:(int)lane;
- (int)activeLane;

- (BOOL)applyScript:(NewScript*)script;
- (NewScript*)activeScript;
-(BOOL)needsSaveAs;

- (BOOL)save:sender;
- (BOOL)saveLanesTo:(NSString*)path;
- (BOOL)saveSequenceToDir:(NSString*)path;
- (BOOL)saveCurrentSequenceToSEQ:(NSString*)pathname;
- (BOOL)saveCurrentSequenceToFASTA:(NSString*)pathname;
- (BOOL)saveLanestoSCF:(NSString*)path;
- (BOOL)saveCurrentToSCF:(NSString*)pathname;
- (BOOL)saveCurrentToLANE:(NSString*)pathname;
- (void)saveCurrentToDAT:(NSString *)pathname;
- (BOOL)saveCurrentToSHAPE:(NSString *)pathname;

@end
