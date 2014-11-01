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

/* TraceFileAdapter.m created by jessica on Fri 21-Nov-1997 */

#import "TraceFileAdapter.h"
#import <GeneKit/NumericalRoutines.h>
#import <limits.h>
#include "readABI.h"
#include "scf.h"

typedef struct {
  int       headerSize;
  int       numLanes;
  int       numChannels;
  BOOL      dataIsLittleEndian;
  BOOL      rawDataIsScaled;
} LANESHeader;


@interface TraceFileAdapter (TraceFileAdapterLocalMethods)
- (UWBFPrivateSCFHeader)UWPrivateHeaderFromSCFRepresentation:(NSData*)fileData;
@end

@implementation TraceFileAdapter

+ (TraceFileAdapter *)adapter
{
  return [[[self alloc] init] autorelease];
}


- init
{
  [super init];
  debugmode = NO;
  return self;
}

- (void)setDebugmode:(BOOL)state;
{
  debugmode = state;
}
/***
DAT section - tab delimited text - for import/export to ascii, spreadsheets, etc
***/
- (Trace *)traceFromDATFile:(NSString *)path
{
  NSData *data = [NSData dataWithContentsOfFile:path];

  if (data == NULL) return NULL;

  return [self traceFromTabedAsciiData:data :0];
 
}

- (Trace*)traceFromTabedAsciiData:(NSData *)data :(int)beginNum
{
  int     storageNum, num_chan;
  float   tempFloat, max=0;
  int     row=0;
  Trace   *dataList;
  char    *bytes, *nextToken;

  num_chan = [self count_columns:data];
  dataList = [Trace traceWithCapacity:1024 channels:num_chan];

  bytes = (char*)[data bytes];
  storageNum = beginNum;
  nextToken = strtok(bytes," \t\n\r");

  if(beginNum == 0) [dataList increaseLengthBy:1];	//filling an empty Trace
  while (nextToken != NULL) {
    tempFloat = atof(nextToken);
    max = max > tempFloat ?  max : tempFloat;
    [dataList setSample:tempFloat atIndex:row channel:storageNum];
    storageNum = (storageNum+1) % num_chan;
    if (storageNum == 0) {
      storageNum = beginNum;
      row++;
      if(beginNum == 0) [dataList increaseLengthBy:1];
    }
    nextToken = strtok(NULL, " \t\n\r");
  }
  return dataList;
}

- (int)count_columns:(NSData*)data
{
  long   position;
  int    count=0;
  char   *bytes, thechar;

  bytes = (char*)[data bytes];
  position = 0;
  thechar = bytes[position];

  while ( (thechar != '\n') && (thechar != EOF)){
    if ((thechar == ' ') || (thechar == '\t')) {
      while ((thechar == ' ') || (thechar == '\t')) {
        position++;
        if(position>=[data length]) thechar=EOF;
        else thechar = bytes[position];
      }
    }
    else {
      if ((thechar != '\n') && (thechar != EOF))
        count += 1;
      while ((thechar != ' ') && (thechar != '\t') && (thechar != '\n') && (thechar != EOF)) {
        position++;
        if(position>=[data length]) thechar=EOF;
        else thechar = bytes[position];
      }
    }
  }
  return count;
}


/*****
*
* SCF file section
*   The .scf format is used by Washington University's TED program (sequence quality checker).
*   It is a BigEndian format. Also used by STADEN package
*
*****/
- (TraceDataWrapper*)wrapperFromSCFFile:(NSString*)path
{
  NSData   *tempData;
  Trace    *rawTrace;
  
  TraceDataWrapper *wrapper=[TraceDataWrapper wrapper];
  tempData = [NSData dataWithContentsOfFile:path];
  [wrapper setProcessedTrace:[self traceFromSCFRepresentation:tempData]];
  [wrapper setSequence:[self sequenceFromSCFRepresentation:tempData]];
  rawTrace = [self altTraceFromSCFRepresentation:tempData];
  if(rawTrace != nil)
    [wrapper setRawTrace:rawTrace];
  return wrapper;
}


- (Trace*)traceFromSCFFile:(NSString*)path
{
  NSData   *tempData;

  tempData = [NSData dataWithContentsOfFile:path];
  return [self traceFromSCFRepresentation:tempData];
}

- (Trace*)altTraceFromSCFFile:(NSString*)path
{
  NSData   *tempData;

  tempData = [NSData dataWithContentsOfFile:path];
  return [self altTraceFromSCFRepresentation:tempData];
}

- (Sequence*)sequenceFromSCFFile:(NSString*)path
{
  NSData   *tempData;

  tempData = [NSData dataWithContentsOfFile:path];
  return [self sequenceFromSCFRepresentation:tempData];
}

- (SCFHeader)SCFHeaderFromData:(NSData*)fileData
{
  SCFHeader         header;

  if(fileData == NULL) return header;

  [fileData getBytes:&header length:sizeof(header)];
  if(header.magic_number != NSSwapHostIntToBig(SCF_MAGIC)) {
    NSLog(@"SCF read error:magic wrong");
    return header;
  }

  header.samples = NSSwapBigIntToHost(header.samples);
  header.samples_offset = NSSwapBigIntToHost(header.samples_offset);	
  header.bases = NSSwapBigIntToHost(header.bases);
  header.bases_left_clip = NSSwapBigIntToHost(header.bases_left_clip);
  header.bases_right_clip = NSSwapBigIntToHost(header.bases_right_clip);
  header.bases_offset = NSSwapBigIntToHost(header.bases_offset);
  header.comments_size = NSSwapBigIntToHost(header.comments_size);
  header.comments_offset = NSSwapBigIntToHost(header.comments_offset);
  header.sample_size = NSSwapBigIntToHost(header.sample_size);
  header.code_set = NSSwapBigIntToHost(header.code_set);
  header.private_size = NSSwapBigIntToHost(header.private_size);
  header.private_offset = NSSwapBigIntToHost(header.private_offset);

  if (debugmode) {
    NSLog(@"SCFHeader");
    NSLog(@"  samples = %d", (int)header.samples);
    NSLog(@"  samples_offset = %d", (int)header.samples_offset);
    NSLog(@"  bases = %d", (int)header.bases);
    NSLog(@"  bases_left_clip = %d", (int)header.bases_left_clip);
    NSLog(@"  bases_right_clip = %d", (int)header.bases_right_clip);
    NSLog(@"  bases_offset = %d", (int)header.bases_offset);
    NSLog(@"  comments_size = %d", (int)header.comments_size);
    NSLog(@"  comments_offset = %d", (int)header.comments_offset);
    NSLog(@"  sample_size = %d", (int)header.sample_size);
    NSLog(@"  code_set = %d", (int)header.code_set);
    NSLog(@"  private_size = %d", (int)header.private_size);
    NSLog(@"  private_offset = %d", (int)header.private_offset);
  }
  return header;
}

- (Trace*)traceFromSCFRepresentation:(NSData*)fileData
{
  int               i, channel, numChannels=4;
  Trace             *thisTrace;
  unsigned short    tempShort;
  unsigned char     tempByte;
  float             tempFloat;
  SCFHeader         header;
  SCFSamples1       dataSample1;
  SCFSamples2       dataSample2;
  unsigned int      filePos;

  if(fileData == NULL) return nil;
  header = [self SCFHeaderFromData:fileData];

  thisTrace = [Trace traceWithLength:(header.samples) channels:numChannels];
  filePos = header.samples_offset;

  for (i=0;i<header.samples;i++) {
    if(header.sample_size == 1) {
      [fileData getBytes:&dataSample1 range:NSMakeRange(filePos, sizeof(SCFSamples1))];
      filePos += sizeof(SCFSamples1);
      for (channel=0;channel<numChannels;channel++) {
        tempByte=0;
        switch(channel) {
          case 0:	tempByte=dataSample1.sample_C; break;
          case 1:	tempByte=dataSample1.sample_A; break;
          case 2:	tempByte=dataSample1.sample_G; break;
          case 3:	tempByte=dataSample1.sample_T; break;
        }
        tempFloat = (float)tempByte;
        [thisTrace setSample:tempFloat atIndex:i channel:channel];
      }
    }
    else if(header.sample_size == 2) {
      [fileData getBytes:&dataSample2 range:NSMakeRange(filePos, sizeof(SCFSamples2))];
      filePos += sizeof(SCFSamples2);
      for (channel=0;channel<numChannels;channel++) {
        tempShort=0;
        switch(channel) {
          case 0:	tempShort=dataSample2.sample_C; break;
          case 1:	tempShort=dataSample2.sample_A; break;
          case 2:	tempShort=dataSample2.sample_G; break;
          case 3:	tempShort=dataSample2.sample_T; break;
        }
        tempFloat = (float)(NSSwapBigShortToHost(tempShort));
        [thisTrace setSample:tempFloat atIndex:i channel:channel];
      }
    }
  }
  [thisTrace setDefaultProcLabels];

  return thisTrace;
}

- (NSData*)privateDataFromSCFRepresentation:(NSData*)fileData
{
  SCFHeader      header;
  NSRange        tempRange;
  NSData         *returnData=nil;

  if(fileData == NULL) return nil;
  header = [self SCFHeaderFromData:fileData];
  if(header.private_size == 0) return nil;

  tempRange = NSMakeRange(header.private_offset, header.private_size);
  NS_DURING
    returnData = [fileData subdataWithRange:tempRange];
  NS_HANDLER
    returnData = nil;
  NS_ENDHANDLER
  return returnData;
}

- (Trace*)altTraceFromSCFRepresentation:(NSData*)fileData
{
  //UW extension to SCF, uses private section of SCF2.0 to hold
  //raw traces and ASCII script
  NSData                  *privateData;
  UWBFPrivateSCFHeader    header;
  int                     i, channel;
  Trace                   *thisTrace;
  float                   tempFloat;
  unsigned short          tempShort, *rawPtr;
  char                    uwMagic[4];

  privateData = [self privateDataFromSCFRepresentation:fileData];
  if(privateData == NULL) return nil;

  memcpy(uwMagic, [privateData bytes], 4);
  if(strncmp(uwMagic, "UWBF", 4) != 0) return nil;  //magic number does not match

  [privateData getBytes:&header
                 length:sizeof(header)];

  header.raw_samples = NSSwapBigIntToHost(header.raw_samples);
  header.raw_channel_count = NSSwapBigIntToHost(header.raw_channel_count);
  header.raw_samples_offset = NSSwapBigIntToHost(header.raw_samples_offset);	

  thisTrace = [Trace traceWithLength:(header.raw_samples)
                            channels:header.raw_channel_count];
  rawPtr = (unsigned short*)([privateData bytes] + header.raw_samples_offset);

  for (channel=0; channel<header.raw_channel_count; channel++) {
    for (i=0; i<header.raw_samples; i++) {
      tempShort = (unsigned short)(NSSwapBigShortToHost(*(rawPtr++)));
      tempFloat = (float)(tempShort);
      [thisTrace setSample:tempFloat atIndex:i channel:channel];
    }
  }
  [thisTrace setDefaultRawLabels];

  return thisTrace;
}

- (NSData*)scriptRepFromSCFRepresentation:(NSData*)fileData
{
  //UW extension to SCF, uses private section of SCF2.0 to hold
  //raw traces and ASCII script
  NSData                  *privateData, *thisScript;
  UWBFPrivateSCFHeader    header;
  char                    uwMagic[4];
  NSRange                 tempRange;

  privateData = [self privateDataFromSCFRepresentation:fileData];
  if(privateData == NULL) return nil;

  memcpy(uwMagic, [privateData bytes], 4);
  if(strncmp(uwMagic, "UWBF", 4) != 0) return nil;  //magic number does not match

  [privateData getBytes:&header  length:sizeof(header)];

  header.script_size = NSSwapBigIntToHost(header.script_size);
  header.script_offset = NSSwapBigIntToHost(header.script_offset);

  tempRange = NSMakeRange(header.script_offset, header.script_size);
  NS_DURING
    thisScript = [privateData subdataWithRange:tempRange];
  NS_HANDLER
    thisScript = nil;
  NS_ENDHANDLER

  return thisScript;
}

- (NSData*)commentFromSCFRepresentation:(NSData*)fileData;
{
  SCFHeader         header;
  NSRange           tempRange;
  NSData            *returnData=nil;

  if(fileData == NULL) return nil;
  header = [self SCFHeaderFromData:fileData];

  if(header.comments_size == 0) return nil;

  tempRange = NSMakeRange(header.comments_offset, header.comments_size);
  NS_DURING
    returnData = [fileData subdataWithRange:tempRange];
  NS_HANDLER
    returnData = nil;
  NS_ENDHANDLER
  return returnData;
}

- (Sequence*)sequenceFromSCFRepresentation:(NSData*)fileData
{
  int               i;
  Sequence          *thisSequence;
  SCFHeader         header;
  SCFBase           tempSCFBase;
  Base              *nextBase;
  unsigned int      filePos;

  if(fileData == NULL) return nil;
  header = [self SCFHeaderFromData:fileData];

  if(header.bases <= 0) return nil;

  thisSequence = [Sequence newSequence];
  filePos = header.bases_offset;

  for (i = 0; i < header.bases; i++) {
    [fileData getBytes:&tempSCFBase range:NSMakeRange(filePos, sizeof(tempSCFBase))];
    filePos += sizeof(tempSCFBase);
    nextBase = [Base baseWithCall:tempSCFBase.base
                            confA:tempSCFBase.prob_A
                            confC:tempSCFBase.prob_C
                            confG:tempSCFBase.prob_G
                            confT:tempSCFBase.prob_T];
    [nextBase setLocation:NSSwapBigIntToHost(tempSCFBase.peak_index)];
    [thisSequence addBase:nextBase];
  }
  return thisSequence;
}

- (BOOL)writeSCFFile:(NSString*)path
               trace:(Trace*)aTrace
            sequence:(Sequence*)aSequence
             rescale:(BOOL)shouldRescale;
{
  NSData   *tempData;

  tempData = [self SCFRepresentationFromTrace:aTrace sequence:aSequence rescale:shouldRescale];
  if(tempData == nil) return NO;
  return [tempData writeToFile:path atomically:YES];

}

- (NSData*)privateDataFromTrace:(Trace*)aTrace
                         script:(NSData*)aScript
{
  UWBFPrivateSCFHeader    header;
  NSMutableData           *privateData, *traceData;
  unsigned short          *dataPtr, tempShort;
  float                   tempFloat;
  int                     i, channel;

  if(aTrace == nil || aScript == nil) return nil;

  memset(&header, '\0', sizeof(header));
  // if trace data does not fall in range of unsigned short then can't create private data (return nil)
  privateData = [NSMutableData data];
  strncpy(header.magic_number, "UWBF", 4);

  /*** write trace data ***/
  header.raw_samples = [aTrace length];
  header.raw_channel_count = [aTrace numChannels];
  header.raw_samples_offset = sizeof(header);

  traceData = [NSMutableData dataWithLength:([aTrace length]*[aTrace numChannels]*sizeof(short))];
  dataPtr = [traceData mutableBytes];

  for (channel=0;channel<header.raw_channel_count;channel++) {
    for (i=0;i<header.raw_samples;i++) {
      tempFloat = [aTrace sampleAtIndex:i channel:channel];

      if(tempFloat < 0.0) return nil;
      if(tempFloat > USHRT_MAX) return nil;

      tempShort = (unsigned short)(tempFloat);
      tempShort = (unsigned short)NSSwapHostShortToBig((unsigned short)tempShort);

      *(dataPtr++) = tempShort;
    }
  }

  header.script_size = [aScript length];
  header.script_offset = sizeof(header) + [traceData length];

  header.raw_samples = NSSwapHostIntToBig(header.raw_samples);
  header.raw_channel_count = NSSwapHostIntToBig(header.raw_channel_count);
  header.raw_samples_offset = NSSwapHostIntToBig(header.raw_samples_offset);	
  header.script_size = NSSwapHostIntToBig(header.script_size);
  header.script_offset = NSSwapHostIntToBig(header.script_offset);

  [privateData appendBytes:&header length:sizeof(header)];
  [privateData appendData:traceData];
  [privateData appendData:aScript];

  return privateData;
}

- (NSData*)SCFRepresentationFromTrace:(Trace*)aTrace
                             sequence:(Sequence*)aSequence
                              rescale:(BOOL)shouldRescale
                             altTrace:(Trace*)rawTrace
                               script:(NSData*)aScript
                              comment:(NSString*)comment;
{
  int               count, i, channel, offset=sizeof(SCFHeader), numChannels;
  float             *dataPtr, tempFloat;
  unsigned short    tempShort;
  SCFHeader         header;
  SCFSamples2       dataSample;
  SCFBase           tempSCFBase;
  Base              *nextBase;
  //int             confidence;
  NSData            *commentData, *privateData;
  NSMutableData     *fileData;

  if(aTrace==nil) return nil;

  numChannels=[aTrace numChannels];
  fileData = [NSMutableData data];

  privateData = [self privateDataFromTrace:rawTrace  script:aScript];

  /**** create comment stream, so its size can be entered into the header ****/
  comment = [comment stringByAppendingFormat:@"BFPrimerOffset=%d\n", [aTrace deleteOffset]];
  commentData = [comment dataUsingEncoding:NSASCIIStringEncoding
                      allowLossyConversion:YES];


  /*** write header ***/
  memset(&header, '\0', sizeof(header));
  header.magic_number = (unsigned int)NSSwapHostIntToBig(SCF_MAGIC);

  header.samples = (unsigned int)NSSwapHostIntToBig([aTrace length]);
  header.samples_offset = (unsigned int)NSSwapHostIntToBig(offset);
  offset += sizeof(SCFSamples2) * [aTrace length];

  if(aSequence != nil)
    header.bases = (unsigned int)NSSwapHostIntToBig([aSequence seqLength]);
  else header.bases = 0;
  header.bases_left_clip = 0;
  header.bases_right_clip = 0;
  header.bases_offset = (unsigned int)NSSwapHostIntToBig(offset);
  offset += sizeof(SCFBase) * [aSequence seqLength];

  header.comments_size = (unsigned int)NSSwapHostIntToBig([commentData length]);
  header.comments_offset = (unsigned int)NSSwapHostIntToBig(offset);
  offset += [commentData length];

  if(privateData != nil) {
    header.private_size = (unsigned int)NSSwapHostIntToBig([privateData length]);
    header.private_offset = (unsigned int)NSSwapHostIntToBig(offset);
  }
  
  strncpy(header.version, "2.00", 4);
  header.sample_size = (unsigned int)NSSwapHostIntToBig(2);
  header.code_set = (unsigned int)NSSwapHostIntToBig(CSET_ABI);

  if (debugmode) NSLog(@"SCFHeader size = %d", (int)sizeof(header));
  if (debugmode) NSLog(@"SCFSamples2 size = %d", (int)sizeof(SCFSamples2));
  [fileData appendBytes:&header length:sizeof(header)];

  /*** write processed data ***/
#define SCF_SCALE  USHRT_MAX
  {
    float             scale[numChannels];

    if(shouldRescale) {
      // first, calc scale factors -- scales data to range
      // 0..SCF_SCALE
      count = [aTrace length];
      dataPtr = (float*)malloc(count*sizeof(float));
      for (channel=0;channel<numChannels;channel++) {
        for(i=0; i<count; i++)
          dataPtr[i] = [aTrace sampleAtIndex:i channel:channel];
        scale[channel] = (float)SCF_SCALE;
        if (maxVal(dataPtr,count) > 0.0)
          scale[channel] = (float)SCF_SCALE / maxVal(dataPtr,count);
        if (debugmode) NSLog(@"scale factor (%d) = %f", channel, scale[channel]);
      }
      free(dataPtr);
    }
    else {
      for (channel=0;channel<numChannels;channel++)
        scale[channel] = 1.0;
    }

    count = [aTrace length];
    if (debugmode) NSLog(@"saving %d sample points", count);
    for (i=0;i<count;i++) {
      for (channel=0;channel<numChannels;channel++) {
        tempFloat = [aTrace sampleAtIndex:i channel:channel] * scale[channel];
        if(!shouldRescale) {
          if(tempFloat < 0.0) tempFloat = 0.0;
          if(tempFloat > USHRT_MAX) tempFloat = USHRT_MAX;
        }
        tempShort = (unsigned short)floor(tempFloat+0.5);
        tempShort = (unsigned short)NSSwapHostShortToBig((unsigned short)tempShort);
        switch(channel) {
          case 0:	dataSample.sample_C=tempShort; break;
          case 1:	dataSample.sample_A=tempShort; break;
          case 2:	dataSample.sample_G=tempShort; break;
          case 3:	dataSample.sample_T=tempShort; break;
        }
      }
      [fileData appendBytes:&dataSample length:sizeof(SCFSamples2)];
    }
  }

  /**** write base calls ****/
  if(aSequence != NULL) {
    count = [aSequence seqLength];
    if (debugmode) NSLog(@"saving %d bases", count);
    for (i = 0; i < count; i++) {
      nextBase = (Base *)[aSequence baseAt:i];
      tempSCFBase.peak_index = (unsigned int)NSSwapHostIntToBig((unsigned int)[nextBase location]);
      tempSCFBase.base = [nextBase base];
      tempSCFBase.prob_A = [nextBase confA];
      tempSCFBase.prob_C = [nextBase confC];
      tempSCFBase.prob_G = [nextBase confG];
      tempSCFBase.prob_T = [nextBase confT];
      [fileData appendBytes:&tempSCFBase length:sizeof(tempSCFBase)];
    }
  }

  /**** write commentStream ****/
  [fileData appendData:commentData];

  /**** append private data ****/
  [fileData appendData:privateData];
  
  return fileData;
}

- (NSData*)SCFRepresentationFromTrace:(Trace*)aTrace
                             sequence:(Sequence*)aSequence
                              rescale:(BOOL)shouldRescale;
{
  //original pre-rawData-script-method. Keep this interface for compatibility
  NSData     *fileData;
  NSString   *comment;

  /**** create comment stream, so its size can be entered into the header ****/
  comment = [NSString stringWithCString:"TPSW=BaseFinder, Version=3,0\nBCSW=BaseFinder, Version=3.0\n"];

  fileData = [self SCFRepresentationFromTrace:aTrace
                                     sequence:aSequence
                                      rescale:shouldRescale
                                     altTrace:nil
                                       script:nil
                                      comment:comment];
  return fileData;
}

- (MGMutableFloatArray*)SCFScalesFromTrace:(Trace*)aTrace
{
  MGMutableFloatArray   *scales;
  float                 value, max, temp;
  int                   count, i, channel;

  if(aTrace == nil) return nil;
  if([aTrace numChannels] == 0) return [MGMutableFloatArray floatArrayWithCount:0];

  scales = [MGMutableFloatArray floatArrayWithCount:[aTrace numChannels]];
  count = [aTrace length];
  if(count == 0) {
    for(i=0; i<[scales count]; i++) [scales setValueAt:i  to:1.0];
    return scales;
  }

  // first, calc scale factors -- scales data to range
  // 0..USHRT_MAX
  
  for (channel=0; channel<[aTrace numChannels]; channel++) {
    max = [aTrace sampleAtIndex:0 channel:channel];
    for(i=1; i<count; i++) {
      temp = [aTrace sampleAtIndex:i channel:channel];
      if(temp > max) max=temp;
    }
    value = (float)USHRT_MAX;
    if (max > 0.0)
      value = (float)USHRT_MAX / max;
    [scales setValueAt:channel  to:value];
    if(debugmode) NSLog(@"scf scale factor (%d) = %f", channel, value);
  }

  return scales;
}

/*****
*
* ABI file section (no saving)
*
*****/
- (Trace*)rawTraceFromABIFile:(NSString*)path
{	
  int         numChannels=4;
  Trace       *rawTrace, *processedTrace;
  Sequence    *aSequence;

  processedTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  rawTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  aSequence = [Sequence newSequence];
  readABISeq((char*)[path fileSystemRepresentation], processedTrace, rawTrace, aSequence);

  if(debugmode) {
    NSLog(@" raw length=%d", [rawTrace length]);
    if(processedTrace != NULL)
      NSLog(@" proc length=%d", [processedTrace length]);
  }
  return rawTrace;
}

- (TraceDataWrapper*)wrapperFromABIFile:(NSString*)path;
{	
  int         numChannels=4;
  Trace       *rawTrace, *processedTrace;
  Sequence    *aSequence;
  TraceDataWrapper *wrapper;

  processedTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  rawTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  aSequence = [Sequence newSequence];
  readABISeq((char*)[path fileSystemRepresentation], processedTrace, rawTrace, aSequence);

  if(debugmode) {
    NSLog(@" raw length=%d", [rawTrace length]);
    if(processedTrace != NULL)
      NSLog(@" proc length=%d", [processedTrace length]);
  }
  wrapper = [TraceDataWrapper wrapperWithRawTrace:rawTrace 	
                                   processedTrace:processedTrace
                                         sequence:aSequence];

  return wrapper;
}

- (Trace*)processedTraceFromABIFile:(NSString*)path
{	
  int         numChannels=4;
  Trace       *rawTrace, *processedTrace;
  Sequence    *aSequence;

  processedTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  rawTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  aSequence = [Sequence newSequence];
  readABISeq((char*)[path fileSystemRepresentation], processedTrace, rawTrace, aSequence);

  if(debugmode) {
    NSLog(@" raw length=%d", [rawTrace length]);
    if(processedTrace != NULL)
      NSLog(@" proc length=%d", [processedTrace length]);
  }

  return processedTrace;
}



- (Sequence*)sequenceFromABIFile:(NSString*)path
{	
  int         numChannels=4;
  Trace       *rawTrace, *processedTrace;
  Sequence    *aSequence;

  processedTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  rawTrace = [Trace traceWithCapacity:1024 channels:numChannels];
  aSequence = [Sequence newSequence];
  readABISeq((char*)[path fileSystemRepresentation], processedTrace, rawTrace, aSequence);

  if(debugmode) {
    NSLog(@" raw length=%d", [rawTrace length]);
    if(processedTrace != NULL)
      NSLog(@" proc length=%d", [processedTrace length]);
  }
  return aSequence;
}


/*****
*
* LANE file section
*
******/
- (TraceDataWrapper*)wrapperFromLANEFile:(NSString*)path
{

  return [TraceDataWrapper wrapperWithRawTrace:
    [self startingTraceFromLANEFile:path]
                                   processedTrace:
    [self finalTraceFromLANEFile:path]
                                         sequence:
    [self finalSequenceFromLANEFile:path]];
  
}

- (LANESHeader)parseLANESHeader:(NSData*)headerData
{
  BOOL		done=NO;
  char		lineBuffer[256], *tempPtr, *token, *dataPtr;
  int		x, state;
  LANESHeader   header;

  dataPtr = (char*)[headerData bytes];
  
  header.numLanes = 1;
  header.numChannels = 4;
  header.dataIsLittleEndian=NO;
  header.rawDataIsScaled = NO;

  tempPtr = dataPtr;
  while(!done) {
    x=0;
    while((*tempPtr)!='\n') {
      lineBuffer[x++] = *tempPtr;
      tempPtr++;
    }
    lineBuffer[x]='\0';
    tempPtr++;

    //NSLog(@"parse:'%s'",lineBuffer);
    if(strcmp(lineBuffer,"end")==0) done=YES;
    else {
      token = strtok(lineBuffer,": \t\n[]");
      state=0;
      while(token!=NULL) {
        switch(state) {
          case 0:
            if(strcmp(token,"numLanes")==0) state=1;
            if(strcmp(token,"numChannels")==0) state=2;
            if(strcmp(token,"byteOrder")==0) state=4;
            if(strcmp(token,"rawDataIsScaled")==0) state=5;
            break;
          case 1:	/* numLanes */
            header.numLanes = atoi(token);
            if (debugmode) NSLog(@" numLanes=%d",header.numLanes);
            state=-1;
            break;
          case 2:	/* numChannels */
            header.numChannels = atoi(token);
            if (debugmode) NSLog(@" numChannels=%d",header.numChannels);
            state=-1;
            break;
          case 4:	/* byteOrder */
            if(strcmp(token,"bigEndian")==0) header.dataIsLittleEndian=NO;
            else header.dataIsLittleEndian=YES;
            if (debugmode) NSLog(@" data is '%s'",token);
            state=-1;
            break;
          case 5:	/* rawDataIsScaled */
            if(strcmp(token,"yes")==0) header.rawDataIsScaled=YES;
            else header.rawDataIsScaled=NO;
            if (debugmode) NSLog(@" rawDataIsScaled = '%s'",token);
            state=-1;
            break;
          default:
            break;
        }
        token = strtok(NULL,": \t\n[]");
      }
    }
  }
  header.headerSize = (int)tempPtr - (int)(dataPtr);
  if (debugmode) NSLog(@"headerSize=%d",header.headerSize);
  return header;
}

- (Trace*)readLaneData:(NSData*)fileData
           lanesHeader:(LANESHeader)header
             withScale:(BOOL)usesScale
{
  Trace            *dataList;
  void	           *data, *loc;
  int              i, j, count, numPerChannel, numChannels;
  unsigned short   tempShort;
  signed short     tempSignedShort;
  float            tempFloat;
  short            scale=1;

  if(fileData == nil) return nil;

  count = [fileData length]/sizeof(short);
  numChannels = header.numChannels;
  numPerChannel = count/(numChannels);
  dataList = [Trace traceWithLength:numPerChannel 	channels:numChannels];

  if(usesScale) {
    scale = *(short*)[fileData bytes];
    if (header.dataIsLittleEndian) scale = NSSwapLittleShortToHost(scale);
    else scale = NSSwapBigShortToHost(scale);
    if (debugmode) NSLog(@"scale factor = %d",scale);
    data = (void*)[fileData bytes] + sizeof(short);
  } else {
    data = (void*)[fileData bytes];
  }
  loc = data;
  for (i = 0; i < numChannels; i++) {
    for (j = 0; j < numPerChannel; j++) {
      tempShort = *((unsigned short *)loc);
      ((unsigned short *)loc)++;
      if(header.dataIsLittleEndian)
        tempShort = (unsigned short)NSSwapLittleShortToHost(tempShort);
      else
        tempShort = (unsigned short)NSSwapBigShortToHost(tempShort);

      if(usesScale) {
        tempSignedShort = (signed short) tempShort;
        tempFloat = ((float)tempSignedShort)/(float)scale;
      } else
        tempFloat = (float)tempShort;
      [dataList setSample:tempFloat atIndex:(unsigned)j channel:(unsigned)i];
    }
  }
  return dataList;
}

- (Sequence*)readLaneSequenceAtPath:(NSString*)pathName
{
  Sequence         *baseList=nil;
  Base             *thisBase;
  FILE             *fp;
  int              location;
  char             base;
  float            confidence;

  fp = fopen([pathName fileSystemRepresentation],"r");

  if (fp) {
    baseList = [Sequence newSequence];
    while(fscanf(fp,"%d %c %f",&(location),&(base),&(confidence))==3) {
      //confidence stored in file as float in 0.0-1.0 range (old format)
      confidence = confidence*255;
      if(confidence>255.0) confidence=255;
      thisBase = [Base baseWithCall:base confidence:confidence];
      [thisBase setLocation:(unsigned int)location];
      [baseList addBase:thisBase];
    }
    fclose(fp);
  } else
    baseList = nil;
  return baseList;
}

- (Trace*)startingTraceFromLANEFile:(NSString*)path
{
  //single lane version of the .lanes file format
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  Trace            *dataList;
  LANESHeader      header;

  /*** Read info file ***/
  headerPath = [path stringByAppendingPathComponent:@"LaneInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];
  if (headerData == nil) {
    if (debugmode) NSLog(@"initFromFile: couldn't open %s.", [path cString]);
    return NULL;
  }
  header = [self parseLANESHeader:headerData];
  header.numLanes = 1;  //just in case

  //2. raw data
  pathName = [path stringByAppendingPathComponent:@"rawTrace"];
  dataList = [self readLaneData:[NSData dataWithContentsOfFile:pathName]
                    lanesHeader:(LANESHeader)header
                      withScale:(header.rawDataIsScaled)];
  [dataList setDefaultRawLabels];
  return dataList;
}

- (Trace*)finalTraceFromLANEFile:(NSString*)path
{
  //single lane version of the .lanes file format
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  Trace            *dataList;
  LANESHeader      header;

  /*** Read info file ***/
  headerPath = [path stringByAppendingPathComponent:@"LaneInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];
  if (headerData == nil) {
    if (debugmode) NSLog(@"initFromFile: couldn't open %s.", [path cString]);
    return NULL;
  }
  header = [self parseLANESHeader:headerData];
  header.numLanes = 1;  //just in case

  //3. load procTrace and procTrace.bsl, if present
  pathName = [path stringByAppendingPathComponent:@"procTrace"];
  dataList = [self readLaneData:[NSData dataWithContentsOfFile:pathName]
                    lanesHeader:(LANESHeader)header
                      withScale:YES];
  [dataList setDefaultProcLabels];
  return dataList;
}

- (Sequence*)startingSequenceFromLANEFile:(NSString*)path
{
  //single lane version of the .lanes file format
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  Sequence         *baseList=nil;
  LANESHeader      header;

  /*** Read info file ***/
  headerPath = [path stringByAppendingPathComponent:@"LaneInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];
  if (headerData == nil) {
    if (debugmode) NSLog(@"initFromFile: couldn't open %s.", [path cString]);
    return NULL;
  }
  header = [self parseLANESHeader:headerData];
  header.numLanes = 1;  //just in case

  //3. load rawTrace.bsl, if present
  pathName = [path stringByAppendingPathComponent:@"rawTrace.bsl"];
  baseList = [self readLaneSequenceAtPath:pathName];
  return baseList;
}

- (Sequence*)finalSequenceFromLANEFile:(NSString*)path
{
  //single lane version of the .lanes file format
  NSString         *headerPath, *pathName;
  NSData           *headerData;
  Sequence         *baseList=nil;
  LANESHeader      header;

  /*** Read info file ***/
  headerPath = [path stringByAppendingPathComponent:@"LaneInfo"];
  headerData = [NSData dataWithContentsOfFile:headerPath];
  if (headerData == nil) {
    if (debugmode) NSLog(@"initFromFile: couldn't open %s.", [path cString]);
    return NULL;
  }
  header = [self parseLANESHeader:headerData];
  header.numLanes = 1;  //just in case

  //3. load procTrace.bsl, if present
  pathName = [path stringByAppendingPathComponent:@"procTrace.bsl"];
  baseList = [self readLaneSequenceAtPath:pathName];
  return baseList;
}

/*****
*
* Sequence output section
*
*****/

- (NSData*)SEQRepresentationFrom:(Sequence*)aSequence
{	
  //The .seq format is used by the GCG assembly and databasing software.
  int              count, i;
  NSMutableString  *seqData;
  NSString         *label;

  if(aSequence == nil) return nil;

  seqData = (NSMutableString*)[NSMutableString string];
  count = [aSequence seqLength];
  [seqData appendFormat:@"\n..%d\n\n",count];
  [seqData appendFormat:@"%8d ", 0];

  //  M13-102mod.Txt  Length: 6981  May 18, 1995 11:52  Type: N  Check: 1889  ..
  label = [aSequence label];
  [seqData appendFormat:@"%@  Length: %d  %@  Type: N  ..\n", label, [aSequence seqLength],
    [NSCalendarDate calendarDate]];

  for (i = 0; i < count; i++) {
    if ((i % 10 == 0) && (i%50 != 0))
      [seqData appendFormat:@" "];
    if ((i%50 == 0) && (i != 0))
      [seqData appendFormat:@"\n\n%8d ",i];
    [seqData appendFormat:@"%c", [[aSequence baseAt:i] base]];
  }
  [seqData appendFormat:@"\n"];
  return [seqData dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES];
}

- (NSData*)FASTARepresentationFrom:(Sequence*)aSequence
{
  //The .fasta format is used by the Phrap assembly and databasing software.
  int 		   count, i;
  NSString         *label;
  char             *tempLabel;
  NSMutableString  *seqData;

  if(aSequence == nil) return nil;
  
  //replace spaces in label with '_'
  label = [[aSequence label] lastPathComponent];
  if (!label)
      label = [NSString stringWithString:@"Sequence"];
  tempLabel = (char*)malloc(strlen([label cString])+4);
  strcpy(tempLabel, [label cString]);
  for(i=0; i<strlen(tempLabel); i++) {
    if(isspace((int)tempLabel[i]))
      tempLabel[i] = '_';
  }
  label = [NSString stringWithCString:tempLabel];
  free(tempLabel);

  seqData = (NSMutableString*)[NSMutableString string];
  count = [aSequence seqLength];
  [seqData appendFormat:@">%@\n",label];
  for (i = 0; i < count; i++) {
    [seqData appendFormat:@"%c", [[aSequence baseAt:i] base]];
  }
  [seqData appendFormat:@"\n"];

  return [seqData dataUsingEncoding:NSASCIIStringEncoding
               allowLossyConversion:YES];
}

- (NSData*)FASTARepresentationFromArray:(NSArray*)multipleSequences
{
  int            i;
  Sequence       *aSequence;
  NSMutableData  *fastaData;

  fastaData = [NSMutableData data];
  for(i=0; i<[multipleSequences count]; i++) {
    aSequence = [multipleSequences objectAtIndex:i];
    [fastaData appendData:[self FASTARepresentationFrom:aSequence]];
  }
  return fastaData;
}

- (BOOL)writeSEQFile:(NSString*)path
            sequence:(Sequence*)aSequence
{
  NSData   *tempData;

  tempData = [self SEQRepresentationFrom:aSequence];
  if(tempData == nil) return NO;
  return [tempData writeToFile:path atomically:YES];
}

- (BOOL)writeFASTAFile:(NSString*)path
              sequence:(Sequence*)aSequence
{
  NSData   *tempData;

  tempData = [self FASTARepresentationFrom:aSequence];
  if(tempData == nil) return NO;
  return [tempData writeToFile:path atomically:YES];
}

- (BOOL)writeFASTAFile:(NSString*)path
         sequenceArray:(NSArray*)multipleSequences
{
  NSData   *tempData;

  tempData = [self FASTARepresentationFromArray:multipleSequences];
  if(tempData == nil) return NO;
  return [tempData writeToFile:path atomically:YES];
}


@end
