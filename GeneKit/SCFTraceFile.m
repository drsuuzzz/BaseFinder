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

/* SCFTraceFile.m created by jessica on Fri 21-Nov-1997 */

#import "SCFTraceFile.h"
#import <GeneKit/NumericalRoutines.h>
#import <limits.h>
#import "scf.h"


@implementation SCFTraceFile

+ (id)scf;
{
  return [[[self alloc] init] autorelease];
}

+ (id)scfWithContentsOfFile:(NSString*)path
{
  return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

- init
{
  [super init];
  debugmode = NO;
  shouldRescale = NO;
  pathname = [[NSString string] retain];
  scfData = nil;
  primaryTrace = nil;
  primarySequence = nil;
  comment = nil;
  alternateTrace = nil;
  scriptData = nil;
  taggedInfo = nil;
  return self;
}

- (void)dealloc
{
  [pathname release];
  if(scfData != nil) [scfData release];
  if(primaryTrace != nil) [primaryTrace release];
  if(primarySequence != nil) [primarySequence release];
  if(comment != nil) [comment release];
  if(alternateTrace != nil) [alternateTrace release];
  if(scriptData != nil) [scriptData release];
  if(taggedInfo != nil) [taggedInfo release];
  [super dealloc];
}

- (id)initWithContentsOfFile:(NSString *)path
{
  [self init];
  [pathname release];
  pathname = [path retain];
  scfData = [[NSData dataWithContentsOfFile:path] retain];
  return self;
}

- (id)initFromSCFRepresentation:(NSData*)data
{
  [self init];
  scfData = [data retain];
  return self;
}

- (void)loadEverything
{
  //since this object is designed for speed, the individual sections aren't loaded
  //until they are needed.  This will load everything

  if(![self primaryTrace] && debugmode) printf("missing primary trace\n");
  if(![self sequence] && debugmode) printf("missing sequence\n");
  if(![self comment] && debugmode) printf("missing comment\n");

  if(![self alternateTrace] && debugmode) printf("missing alternate trace\n");
  if(![self scriptRepresentation] && debugmode) printf("missing scriptRepresentation\n");
  if(![self taggedInfo] && debugmode) printf("missing taggedInfo\n");
}

/*****
*
* Core routines
*
*****/
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

	if (header.samples == 0)
		[NSException raise:@"File system error" 
								format:@"SCF File Error: There are no sample points!  Is this a Beckman file? Use ESD"];
	
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

- (NSData*)privateData
{
  SCFHeader      header;
  NSRange        tempRange;
  NSData         *returnData=nil;

  if(scfData == NULL) return nil;
  header = [self SCFHeaderFromData:scfData];
  if(header.private_size == 0) return nil;

  tempRange = NSMakeRange(header.private_offset, header.private_size);
  NS_DURING
    returnData = [scfData subdataWithRange:tempRange];
  NS_HANDLER
    returnData = nil;
  NS_ENDHANDLER
  return returnData;
}

/*****
*
* primary read section
*
*****/
- (TraceDataWrapper*)wrapper
{
  TraceDataWrapper *wrapper=[TraceDataWrapper wrapper];
  Trace   *rawTrace;
  
  [wrapper setProcessedTrace:[self primaryTrace]];
  [wrapper setSequence:[self sequence]];
  rawTrace = [self alternateTrace];
  if(rawTrace != nil)
    [wrapper setRawTrace:rawTrace];
  return wrapper;
}

- (Trace*)primaryTrace
{
  int               i, channel, numChannels=4;
  unsigned short    tempShort;
  unsigned char     tempByte;
  float             tempFloat;
  SCFHeader         header;
  SCFSamples1       dataSample1;
  SCFSamples2       dataSample2;
  unsigned int      filePos;

  if(primaryTrace != nil) return primaryTrace;
  if(scfData == NULL) return nil;
  
  header = [self SCFHeaderFromData:scfData];

  primaryTrace = [[Trace traceWithLength:(header.samples) channels:numChannels] retain];
  filePos = header.samples_offset;

  for (i=0;i<header.samples;i++) {
    if(header.sample_size == 1) {
      [scfData getBytes:&dataSample1 range:NSMakeRange(filePos, sizeof(SCFSamples1))];
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
        [primaryTrace setSample:tempFloat atIndex:i channel:channel];
      }
    }
    else if(header.sample_size == 2) {
      [scfData getBytes:&dataSample2 range:NSMakeRange(filePos, sizeof(SCFSamples2))];
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
        [primaryTrace setSample:tempFloat atIndex:i channel:channel];
      }
    }
  }
  [primaryTrace setDefaultProcLabels];

  return primaryTrace;
}

- (Sequence*)sequence
{
  int               i;
  SCFHeader         header;
  SCFBase           tempSCFBase;
  Base              *nextBase;
  unsigned int      filePos;

  if(primarySequence != nil) return primarySequence;
  if(scfData == NULL) return nil;
  
  header = [self SCFHeaderFromData:scfData];

  if(header.bases <= 0) return nil;

  primarySequence = [[Sequence newSequence] retain];
  filePos = header.bases_offset;

  for (i = 0; i < header.bases; i++) {
    [scfData getBytes:&tempSCFBase range:NSMakeRange(filePos, sizeof(tempSCFBase))];
    filePos += sizeof(tempSCFBase);
    nextBase = [Base baseWithCall:tempSCFBase.base
                            confA:tempSCFBase.prob_A
                            confC:tempSCFBase.prob_C
                            confG:tempSCFBase.prob_G
                            confT:tempSCFBase.prob_T];
    [nextBase setLocation:NSSwapBigIntToHost(tempSCFBase.peak_index)];
    [primarySequence addBase:nextBase];
  }
  return primarySequence;
}

- (NSString*)comment;
{
  SCFHeader         header;
  NSRange           tempRange;
  NSData            *commentData=nil;

  if(comment != nil) return comment;
  if(scfData == NULL) return nil;
  
  header = [self SCFHeaderFromData:scfData];
  if((header.comments_size==0)||(header.comments_offset==0)) return nil;

  tempRange = NSMakeRange(header.comments_offset, header.comments_size);
  NS_DURING
    commentData = [scfData subdataWithRange:tempRange];
  NS_HANDLER
    commentData = nil;
  NS_ENDHANDLER
  
  if(commentData != nil)
    comment = [[NSString alloc] initWithData:commentData  encoding:NSASCIIStringEncoding];
  
  return comment;
}

/*****
*
* UW smith group extended section
*
*****/
- (Trace*)alternateTrace
{
  //UW extension to SCF, uses private section of SCF2.0 to hold
  //raw traces and ASCII script
  NSData                  *privateData;
  UWBFPrivateSCFHeader    header;
  int                     i, channel;
  float                   tempFloat;
  unsigned short          tempShort, *rawPtr;
  char                    uwMagic[4];

  if(alternateTrace != nil) return alternateTrace;
  
  privateData = [self privateData];
  if(privateData == NULL) return nil;

  memcpy(uwMagic, [privateData bytes], 4);
  if(strncmp(uwMagic, "UWBF", 4) != 0) return nil;  //magic number does not match

  [privateData getBytes:&header
                 length:sizeof(header)];

  header.raw_samples = NSSwapBigIntToHost(header.raw_samples);
  header.raw_channel_count = NSSwapBigIntToHost(header.raw_channel_count);
  header.raw_samples_offset = NSSwapBigIntToHost(header.raw_samples_offset);	

  if((header.raw_samples==0) || (header.raw_samples_offset==0))
    return nil;  //no alternate trace in file
  
  alternateTrace = [[Trace traceWithLength:(header.raw_samples)
                                  channels:header.raw_channel_count] retain];
  rawPtr = (unsigned short*)([privateData bytes] + header.raw_samples_offset);

  for (channel=0; channel<header.raw_channel_count; channel++) {
    for (i=0; i<header.raw_samples; i++) {
      tempShort = (unsigned short)(NSSwapBigShortToHost(*(rawPtr++)));
      tempFloat = (float)(tempShort);
      [alternateTrace setSample:tempFloat atIndex:i channel:channel];
    }
  }
  [alternateTrace setDefaultRawLabels];

  return alternateTrace;
}

- (NSData*)scriptRepresentation
{
  //UW extension to SCF, uses private section of SCF2.0 to hold
  //raw traces and ASCII script
  NSData                  *privateData;
  UWBFPrivateSCFHeader    header;
  char                    uwMagic[4];
  NSRange                 tempRange;

  if(scriptData != nil) return scriptData;
  
  privateData = [self privateData];
  if(privateData == NULL) return nil;

  memcpy(uwMagic, [privateData bytes], 4);
  if(strncmp(uwMagic, "UWBF", 4) != 0) return nil;  //magic number does not match

  [privateData getBytes:&header  length:sizeof(header)];

  header.script_size = NSSwapBigIntToHost(header.script_size);
  header.script_offset = NSSwapBigIntToHost(header.script_offset);

  if((header.script_size==0)||(header.script_offset==0))
    return nil;  //no scriptRep in file
  
  tempRange = NSMakeRange(header.script_offset, header.script_size);
  NS_DURING
    scriptData = [[privateData subdataWithRange:tempRange] retain];
  NS_HANDLER
    scriptData = nil;
  NS_ENDHANDLER

  return scriptData;
}

- (NSMutableDictionary*)taggedInfo
{
  //UW extension to SCF, uses private section of SCF2.0 to hold
  //raw traces and ASCII script
  NSData                  *privateData, *taggedInfoData=nil;
  UWBFPrivateSCFHeader    header;
  char                    uwMagic[4];
  NSRange                 tempRange;
  NSString                *taggedInfoString;

  if(taggedInfo != nil) return taggedInfo;
  
  privateData = [self privateData];
  if(privateData == NULL) return nil;

  memcpy(uwMagic, [privateData bytes], 4);
  if(strncmp(uwMagic, "UWBF", 4) != 0) return nil;  //magic number does not match

  [privateData getBytes:&header  length:sizeof(header)];

  header.taggedInfo_size = NSSwapBigIntToHost(header.taggedInfo_size);
  header.taggedInfo_offset = NSSwapBigIntToHost(header.taggedInfo_offset);

  if((header.taggedInfo_size==0)||(header.taggedInfo_offset==0))
    return nil;  //no tagged info in file

  tempRange = NSMakeRange(header.taggedInfo_offset, header.taggedInfo_size);
  NS_DURING
    taggedInfoData = [privateData subdataWithRange:tempRange];
  NS_HANDLER
    return nil;
  NS_ENDHANDLER
  
  if(taggedInfoData != nil) {
    taggedInfoString = [[NSString alloc] initWithData:taggedInfoData  encoding:NSASCIIStringEncoding];
    taggedInfo = [taggedInfoString propertyList];
    if([taggedInfo isKindOfClass:[NSDictionary class]]) {
      //convert to mutable form and retained
      taggedInfo = [taggedInfo mutableCopy];
    }
    else {
      NSLog(@"error regenerating taggedInfo PropertyList");
      taggedInfo = [[NSMutableDictionary dictionary] retain];
    }
    [taggedInfoString release];
  }
  
  if(debugmode) NSLog(@"taggedInfo=%@", [taggedInfo description]);
  return taggedInfo;
}

/*****
*
*  creation and writing og SCF files
*
*****/
- (NSData*)generatePrivateData
{
  UWBFPrivateSCFHeader    header;
  NSMutableData           *privateData=nil, *traceData=nil;
  NSData                  *taggedInfoData=nil;
  unsigned short          *dataPtr, tempShort;
  float                   tempFloat;
  int                     i, channel;
  int                     currentOffset = sizeof(header);

  if((alternateTrace==nil)&&(scriptData==nil)&&(taggedInfo==nil))
    return nil;  //no private data if all these are missing
  
  memset(&header, '\0', sizeof(header));
  // if trace data does not fall in range of unsigned short then
  // can't create private data (return nil)
  privateData = [NSMutableData data];
  strncpy(header.magic_number, "UWBF", 4);

  /*** write trace data ***/
  if(alternateTrace != nil) {
    header.raw_samples = [alternateTrace length];
    header.raw_channel_count = [alternateTrace numChannels];
    header.raw_samples_offset = currentOffset;

    traceData = [NSMutableData dataWithLength:([alternateTrace length]*
                                               [alternateTrace numChannels]*
                                               sizeof(short))];
    dataPtr = [traceData mutableBytes];

    for (channel=0;channel<header.raw_channel_count;channel++) {
      for (i=0;i<header.raw_samples;i++) {
        tempFloat = [alternateTrace sampleAtIndex:i channel:channel];

        if(tempFloat < 0.0) return nil;
        if(tempFloat > USHRT_MAX) return nil;

        tempShort = (unsigned short)(tempFloat);
        tempShort = (unsigned short)NSSwapHostShortToBig((unsigned short)tempShort);

        *(dataPtr++) = tempShort;
      }
    }
    currentOffset += [traceData length];
  }

  /*** set up script rep data header ***/
  if(scriptData != nil) {
    header.script_size = [scriptData length];
    header.script_offset = currentOffset;
    currentOffset += header.script_size;
  }

  /*** setup the taggedInfoData ***
   * the taggedInfo starts as an NSMutableDictionary from traceData
   * description: converts NSDictionary to NSString property list
   * dataUsingEncoding: converts NSString to ascii data representation
   ***/
  if(taggedInfo!=nil) {
    taggedInfoData = [[taggedInfo description] dataUsingEncoding:NSASCIIStringEncoding];
    header.taggedInfo_size = [taggedInfoData length];
    header.taggedInfo_offset = currentOffset;
    currentOffset += header.taggedInfo_size;
  }

 /*** convert UWBFPrivateSCFHeader to bigendian ***/
  header.raw_samples = NSSwapHostIntToBig(header.raw_samples);
  header.raw_channel_count = NSSwapHostIntToBig(header.raw_channel_count);
  header.raw_samples_offset = NSSwapHostIntToBig(header.raw_samples_offset);	
  header.script_size = NSSwapHostIntToBig(header.script_size);
  header.script_offset = NSSwapHostIntToBig(header.script_offset);
  header.taggedInfo_size = NSSwapHostIntToBig(header.taggedInfo_size);
  header.taggedInfo_offset = NSSwapHostIntToBig(header.taggedInfo_offset);

  /*** create the privateData ***/
  [privateData appendBytes:&header length:sizeof(header)];
  if(traceData != nil) [privateData appendData:traceData];
  if(scriptData != nil) [privateData appendData:scriptData];
  if(taggedInfoData != nil) [privateData appendData:taggedInfoData];

  return privateData;
}

- (BOOL)writeToFile:(NSString*)path atomically:(BOOL)flag
{
  NSData   *tempData;

  tempData = [self SCFFileRepresentation];
  if(tempData == nil) return NO;
  return [tempData writeToFile:path atomically:flag];
}

- (NSData*)SCFFileRepresentation
{
  int               count, i, channel, offset=sizeof(SCFHeader), numChannels;
  float             tempFloat;
  unsigned short    tempShort;
  SCFHeader         header;
  SCFSamples2       dataSample;
  SCFBase           tempSCFBase;
  Base              *nextBase;
  //int             confidence;
  NSData            *commentData, *privateData;

  [self loadEverything];
  if(primaryTrace==nil) return nil;

  numChannels=[primaryTrace numChannels];
  scfData = [[NSMutableData data] retain];

  privateData = [self generatePrivateData];

  /**** create comment stream, so its size can be entered into the header ****/
  if(comment == nil)
    comment = [[NSString stringWithCString:"TPSW=BaseFinder, Version=3,0\nBCSW=BaseFinder, Version=3.0\n"] retain];
  //comment = [comment stringByAppendingFormat:@"BFPrimerOffset=%d\n", [primaryTrace deleteOffset]];
  commentData = [comment dataUsingEncoding:NSASCIIStringEncoding
                      allowLossyConversion:YES];


  /*** write header ***/
  memset(&header, '\0', sizeof(header));
  header.magic_number = (unsigned int)NSSwapHostIntToBig(SCF_MAGIC);

  header.samples = (unsigned int)NSSwapHostIntToBig([primaryTrace length]);
  header.samples_offset = (unsigned int)NSSwapHostIntToBig(offset);
  offset += sizeof(SCFSamples2) * [primaryTrace length];

  if(primarySequence != nil)
    header.bases = (unsigned int)NSSwapHostIntToBig([primarySequence seqLength]);
  else header.bases = 0;
  header.bases_left_clip = 0;
  header.bases_right_clip = 0;
  header.bases_offset = (unsigned int)NSSwapHostIntToBig(offset);
  offset += sizeof(SCFBase) * [primarySequence seqLength];

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
  [scfData appendBytes:&header length:sizeof(header)];

  /*** write processed data ***/
  {
    float             scale[numChannels];

    if(shouldRescale) {
      MGMutableFloatArray  *myscales = [self SCFScalesFromTrace:primaryTrace];
      if(debugmode) NSLog(@"using SCFScalesFromTrace for scales");
      for (channel=0;channel<numChannels;channel++)
        scale[channel] = [myscales elementAt:channel];
    }
    else {
      for (channel=0;channel<numChannels;channel++)
        scale[channel] = 1.0;
    }

    count = [primaryTrace length];
    if (debugmode) NSLog(@"saving %d sample points", count);
    for (i=0;i<count;i++) {
      for (channel=0;channel<numChannels;channel++) {
        tempFloat = [primaryTrace sampleAtIndex:i channel:channel] * scale[channel];
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
      [scfData appendBytes:&dataSample length:sizeof(SCFSamples2)];
    }
  }

  /**** write base calls ****/
  if(primarySequence != NULL) {
    count = [primarySequence seqLength];
    if (debugmode) NSLog(@"saving %d bases", count);
    memset(&tempSCFBase, '\0', sizeof(tempSCFBase));
    for (i = 0; i < count; i++) {
      nextBase = (Base *)[primarySequence baseAt:i];
      tempSCFBase.peak_index = (unsigned int)NSSwapHostIntToBig((unsigned int)[nextBase location]);
      tempSCFBase.base = [nextBase base];
      tempSCFBase.prob_A = [nextBase confA];
      tempSCFBase.prob_C = [nextBase confC];
      tempSCFBase.prob_G = [nextBase confG];
      tempSCFBase.prob_T = [nextBase confT];
      [scfData appendBytes:&tempSCFBase length:sizeof(tempSCFBase)];
    }
  }

  /**** write commentStream ****/
  [scfData appendData:commentData];

  /**** append private data ****/
  [scfData appendData:privateData];
  
  return scfData;
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
    value /= 64.0;  //needed to reduce dynamic range for consed
    [scales setValueAt:channel  to:value];
    if(debugmode) NSLog(@"scf scale factor (%d) = %f", channel, value);
  }

  return scales;
}

/*****
*
* setting components
*
*****/

- (void)setPrimaryTrace:(Trace*)aTrace
{
  if(primaryTrace != nil) [primaryTrace release];
  primaryTrace = [aTrace retain];
}

- (void)setSequence:(Sequence*)aSequence;
{
  if(primarySequence != nil) [primarySequence release];
  primarySequence = [aSequence retain];
}

- (void)setComment:(NSString*)aComment;
{
  if(comment != nil) [comment release];
  comment = [aComment retain];
}

- (void)setAlternateTrace:(Trace*)aTrace;
{
  if(alternateTrace != nil) [alternateTrace release];
  alternateTrace = [aTrace retain];
}

- (void)setScriptRepresentation:(NSData*)aScript;
{
  if(scriptData != nil) [scriptData release];
  scriptData = [aScript retain];
}

- (void)setTaggedInfo:(NSMutableDictionary*)aDict;
{
  if(taggedInfo != nil) [taggedInfo release];
  taggedInfo = [aDict retain];
}

- (void)setDebugmode:(BOOL)state;
{
  debugmode = state;
}

- (void)setShouldRescale:(BOOL)state;
{
  shouldRescale = state;
}

/******
*
* convienience methods to externally convert alternate trace to USHRT range
*
******/

- (BOOL)traceHasFloats:(Trace*)dataList
{
  int    i, chan, pointCount;
  float  fval;

  pointCount = [dataList length];

  for(chan=0; chan<[dataList numChannels]; chan++) {
    for(i=0; i<pointCount; i++) {
      fval = [dataList sampleAtIndex:i channel:chan];
      if(fval != (float)floor(fval)) return YES;
    }
  }
  return NO;
}

- (void)rescaleTraceToUSHRT:(Trace*)dataList
{
  //a convenience method to convert an 'alternateTrace' which is not in the
  //range of unsigned short
  int        i, chan, pointCount, numChannels=[dataList numChannels];
  float      scaleFactor;
  float      min=0.0, max=0.0, val;

  if(debugmode) printf("Rescale data to full range of unsigned 16bit int\n");

  pointCount = [dataList length];
  if((numChannels == 0) || (pointCount == 0)) return;

  max = min = [dataList sampleAtIndex:0 channel:0];

  for(chan=0;chan<numChannels;chan++) {
    for(i=0; i<pointCount; i++) {
      val = [dataList sampleAtIndex:i channel:chan];
      if(val < min) min=val;
      if(val > max) max=val;
    }
  }

  if(debugmode) printf("chan %d: min=%f  max=%f\n", chan, min, max);
  scaleFactor = (float)USHRT_MAX / (float)(max - min);

  for(chan=0;chan<numChannels;chan++) {
    for(i=0; i<pointCount; i++) {
      val = ([dataList sampleAtIndex:i channel:chan] - min)  * scaleFactor;
      [dataList setSample:val atIndex:i channel:chan];
    }
  }
}


@end
