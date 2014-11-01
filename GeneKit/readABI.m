/* "$Id: readABI.m,v 1.7 2006/10/24 18:15:52 smvasa Exp $" */
/* Many thanks to LaDenia Hillier and Clark Tibbetts for deciphering the ABI file format */

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

#import <stdio.h>
#import <objc/objc.h>
#import <stdlib.h>
//#import <objc/List.h>
#import <GeneKit/Trace.h>
#import <GeneKit/Sequence.h>
#define IndexEntryLength 28
#define INDEX_LOCATOR	26
#import <GeneKit/NumericalRoutines.h>
#import <Foundation/NSByteOrder.h>
//extern BOOL debugmode;
#define ABI_OWNER 2

/* Index entries */
//#define DATA_ENTRY	(long)'DATA'
//#define BASE_ENTRY	(long)'PBAS'
//#define BASEPOS_ENTRY	(long)'PLOC'
//#define SPACE_ENTRY	(long)'SPAC'
//#define SIGNAL_ENTRY	(long)'S/N%'
//#define FWO_ENTRY	(long)'FWO_'

#define DATA_ENTRY	(((long) 'D' << 24) + ((long) 'A' << 16) + ((long) 'T' << 8) + ((long) 'A'))
#define BASE_ENTRY	(((long) 'P' << 24) + ((long) 'B' << 16) + ((long) 'A' << 8) + ((long) 'S'))
#define BASEPOS_ENTRY	(((long) 'P' << 24) + ((long) 'L' << 16) + ((long) 'O' << 8) + ((long) 'C'))
#define SPACE_ENTRY	(((long) 'S' << 24) + ((long) 'P' << 16) + ((long) 'A' << 8) + ((long) 'C'))
#define SIGNAL_ENTRY	(((long) 'S' << 24) + ((long) '/' << 16) + ((long) 'N' << 8) + ((long) '%'))
#define FWO_ENTRY	(((long) 'F' << 24) + ((long) 'W' << 16) + ((long) 'O' << 8) + ((long) '_'))

long indexEntryValue(FILE *fp, long index, long label, long count, int word)
{
  long *loc;
  long currentLabel, currentCount;
  long returnVal;
  int record_count=0;

  loc = (long *)index;
  do {
    fseek(fp, index + record_count * IndexEntryLength, 0);
    if (fread(&currentLabel, sizeof(long), 1, fp)==0)
      return 0;
    currentLabel =  NSSwapBigLongToHost(currentLabel);
    if (fread(&currentCount, sizeof(long), 1, fp)==0)
      return 0;
    currentCount = NSSwapBigLongToHost(currentCount);
    record_count += 1;
    }
  while (!((currentLabel == label) && (currentCount == count)));

  record_count -= 1;
  fseek(fp, index + record_count * IndexEntryLength +
        word*sizeof(long), SEEK_SET);
  if (fread(&returnVal, sizeof(long), 1, fp) == 0)
    return 0;
  returnVal = NSSwapBigLongToHost(returnVal);

  return(returnVal);
}





void readABISeq(char *fname, id procTrace, id rawTrace, id baseList)
{
  FILE	*fp;
  long 	indexLOC;
  long 	baseLOC;
  long  baseposLOC;
  long 	dataCLOC=0;
  long 	dataALOC=0;
  long	dataGLOC=0;
  long	dataTLOC=0;
  long 	rawCLOC=0;
  long 	rawALOC=0;
  long	rawGLOC=0;
  long	rawTLOC=0;
  long  raw105LOC = 0;
  long 	numRawPoints, numProcPoints, numBases;
  long	traceOrder;
  short *tempdata;
  float tempval;
  int   i;
  //aBase thebase;
  Base  *thebase;
  short location;
	//unsigned int endian;

	//endian = NSHostByteOrder(); // NS_LittleEndian or NS_BigEndian
  fp = fopen(fname, "rb");
  //MG added this 2/10/97 after several crashes
  if (fp == NULL) {
      //exception here??!!
      //if (debugmode) fprintf(stderr, "FILE NOT FOUND!");
      return;
  }
  fseek(fp, INDEX_LOCATOR, 0);
  if (fread(&indexLOC, sizeof(long), 1, fp)==0) return;
  indexLOC = NSSwapBigLongToHost(indexLOC);
  numProcPoints = indexEntryValue(fp, indexLOC, DATA_ENTRY, 9, 3);
  numRawPoints = indexEntryValue(fp, indexLOC,DATA_ENTRY, 1, 3);
  numBases = indexEntryValue(fp, indexLOC, BASE_ENTRY, 1, 3);
  if (numRawPoints>numProcPoints) // I think this is always TRUE, but just in case...
    tempdata = calloc(numRawPoints, sizeof(short));
  else
    tempdata = calloc(numProcPoints, sizeof(short));
  traceOrder = indexEntryValue(fp, indexLOC, FWO_ENTRY, 1, 5);
  if (numRawPoints == 0) return;
  [rawTrace setLength:numRawPoints];
  if (numProcPoints > 0)
    [procTrace setLength:numProcPoints];

  if (traceOrder == 0) traceOrder = 0x43414754;
  for (i = 0; i < 4; i++) {
    switch((char)((traceOrder >> ((3-i) * 8)) & 255)) {
      case 'A':
        rawALOC = indexEntryValue(fp, indexLOC, DATA_ENTRY,1 + i, 5);
        dataALOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 9 + i, 5);
        break;
      case 'C':
        rawCLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 1 + i, 5);
        dataCLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 9 + i, 5);
        break;
      case 'G':
        rawGLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 1 + i, 5);
        dataGLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 9 + i, 5);
        break;
      case 'T':
        rawTLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 1 + i, 5);
        dataTLOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 9 + i, 5);
        break;
    }
  }
  
  raw105LOC = indexEntryValue(fp, indexLOC, DATA_ENTRY, 105, 5);
  
  /* Read in raw A data */
  if (rawALOC != 0) {
    fseek(fp, rawALOC, SEEK_SET);
    fread(tempdata, sizeof(short), numRawPoints, fp);
    for (i = 0; i < numRawPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);  //only accepts unsigned values, but ABI DATA are signed 16-bit integers.
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [rawTrace setSample:tempval atIndex:i channel:1];
    }    
  }
  //if (debugmode) fprintf(stderr,"read raw A channel\n");

  /* Read in raw C data */
  if (rawCLOC != 0) {
    fseek(fp, rawCLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numRawPoints, fp);
    for (i = 0; i < numRawPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [rawTrace setSample:tempval atIndex:i channel:0];
    }
  }
  //if (debugmode) fprintf(stderr,"read raw C channel\n");

  /* Read in raw G data */
  if (rawGLOC != 0) {
    fseek(fp, rawGLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numRawPoints, fp);
    for (i = 0; i < numRawPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [rawTrace setSample:tempval atIndex:i channel:2];
    }
  }
  //if (debugmode) fprintf(stderr,"read raw G channel\n");

  /* Read in raw T data */
  if (rawTLOC != 0) {
    fseek(fp, rawTLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numRawPoints, fp);
    for (i = 0; i < numRawPoints; i++) {
     // tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [rawTrace setSample:tempval atIndex:i channel:3];
    }    
  }
  //if (debugmode) fprintf(stderr,"read raw T data\n");
  
  /* Read in 5th channel data */
  if (raw105LOC != 0) {
    fseek(fp, raw105LOC, SEEK_SET);
    fread(tempdata, sizeof(short), numRawPoints, fp);
    [rawTrace addChannel];
    for (i = 0; i < numRawPoints; i++) {
     // tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [rawTrace setSample:tempval atIndex:i channel:4];
    }
  }
  
  /* Read in processed A data */
  if (dataALOC != 0) {
    fseek(fp, dataALOC, SEEK_SET);
    fread(tempdata, sizeof(short), numProcPoints, fp);
    for (i = 0; i < numProcPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [procTrace setSample:tempval atIndex:i channel:1];
    }    
  }  //if (debugmode) fprintf(stderr,"read processed A data\n");

  /* Read in processed C data */
  if (dataCLOC != 0) {
    fseek(fp, dataCLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numProcPoints, fp);
    for (i = 0; i < numProcPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [procTrace setSample:tempval atIndex:i channel:0];
    }
  }
  
  //if (debugmode) fprintf(stderr,"read processed C data\n");

  /* Read in processed G data */
  if (dataGLOC != 0) {
    fseek(fp, dataGLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numProcPoints, fp);
    for (i = 0; i < numProcPoints; i++) {
      //tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [procTrace setSample:tempval atIndex:i channel:2];
    }    
  }
    //if (debugmode) fprintf(stderr,"read processed G data\n");

  /* Read in processed T data */
  if (dataTLOC != 0) {
    fseek(fp, dataTLOC, SEEK_SET);
    fread(tempdata, sizeof(short), numProcPoints, fp);
    for (i = 0; i < numProcPoints; i++) {
     // tempval = (float)NSSwapBigShortToHost(tempdata[i]);
			tempval = (float)EndianS16_BtoN(tempdata[i]);
      [procTrace setSample:tempval atIndex:i channel:3];
    }
  }
  
  //if (debugmode) fprintf(stderr,"read processed T data\n");

  /* read bases */
  baseLOC = indexEntryValue(fp, indexLOC, BASE_ENTRY, 1, 5);
  baseposLOC = indexEntryValue(fp, indexLOC, BASEPOS_ENTRY, 1, 5);
  fseek(fp, baseLOC, SEEK_SET);
  for (i = 0; i < numBases; i++) {
    fseek(fp, baseLOC + i, SEEK_SET);
    thebase = [[Base alloc] init];
    [thebase setBase:getc(fp)];
    /****
    switch (thebase . base) {
      case 'A': thebase. channel = A_BASE; break;
      case 'T': thebase. channel = T_BASE; break;
      case 'G': thebase. channel = G_BASE; break;
      case 'C': thebase. channel = C_BASE; break;
      case 'N': thebase. channel = UNKNOWN_BASE; break;
    }
    ****/
    fseek(fp, baseposLOC + i*sizeof(short), SEEK_SET);
    fread(&location, sizeof(short), 1, fp);
    location = NSSwapBigShortToHost(location);
    [thebase setLocation:(unsigned int)location];
    [thebase setConf:(char)127];
    //thebase.confidence = 0.5;
    //thebase . owner = ABI_OWNER;
    [baseList addBase:thebase];
    [thebase release];
  }
  //if (debugmode) fprintf(stderr,"read base sequence\n");


  free(tempdata);
}

