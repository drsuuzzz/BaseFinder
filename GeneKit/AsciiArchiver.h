/* "$Id: AsciiArchiver.h,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

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
#import <objc/Object.h>

#define MAXTAGLEN 64
#define MAXDESCLEN 128

// These two macros should cover about 80% of AsciiArchiver uses:
//#define AAWRITE(IDENT,TYPE); 	[archiver writeData:&IDENT type:#TYPE tag:#IDENT];
//#define AACONDREAD(IDENT)	if (!strcmp(tag,#IDENT)) [archiver readData:&IDENT]
//#define AADEFAULT { [super handleTag:tag fromArchiver:archiver]; }

enum asciiArchiverExceptions {
    AA_classUnknown,
    AA_syntaxError
};
enum asciiArchiverInitModes {
    AA_readOnly,
    AA_writeOnly
};

@interface AsciiArchiver:NSObject

{
  NSMutableString   *aaData;
  char              *readDataPtr;
  NSString          *fileName;
  int               mode;

  id knownObjects; // those that have been written or read so far

  // The following are used only when mode==NX_WRITEONLY
  int nestingLevel;
  BOOL dirty;
  BOOL initFromFilename;

  // The following are used only when mode==NX_READONLY
  char currentDesc[MAXDESCLEN];
  BOOL expectingTag;
}

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithAsciiData:(NSString*)data;
- (id)initForWriting;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;

- (NSString*)asciiRepresentation;

- writeData:(void *)data type:(const char *)descriptor tag:(const char *)tag;
- writeObject:object tag:(const char *)tag;
- writeArray:(void *)data size:(int)count type:(const char *)descriptor tag:(const char *)tag;
- writeString:(char *)string tag:(const char *)tag;
- writeNSString:(NSString *)string tag:(const char *)tag;
- skipItem;
- getNextTag:(char *)tagBuf;

// readData:, readArray:, and readString: require that buf already be allocated; 
// readObject and readData allocate buffers themselves
- (NSString *)readNSString;
- readData:(void *)buf;
- readArray:(void *)buf;
- readString:(char *)buf maxLength:(int)len;
- readObject;
- readObjectWithTag:(const char *)tag;
- (void *)readData;
- (BOOL)findTag:(const char *)tag;


// This can be used if the caller wants to allocate the array buffer
- (int)arraySize;

// These are "private"--they shouldn't normally be called from outside AsciiArchiver
- readArray:(void *)buf elementType:(const char *)descriptor count:(int)cnt;
- readData:(void *)buf type:(const char *)descriptor;

@end

@protocol AsciiArchiving
- (id)handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;
- (void)beginDearchiving:archiver;
@end

// Put this in here to make sure it's visible:

@interface NSObject (AAMethods) // Methods required by AsciiArchiver
- (id)handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;
- (void)beginDearchiving:archiver;
@end

@interface NSObject (AAMethods) // Methods required by AsciiArchiver
- (id)handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;
- (void)beginDearchiving:archiver;
@end

