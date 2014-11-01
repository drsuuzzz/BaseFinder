/* "$Id: ToolMatrix2.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */
/***********************************************************

Copyright (c) 1994-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "ToolMatrix2.h"

/*****
* April 5, 1994 Jessica Hayden
* Second Generation matrix transformation routines.  This tool is designed to work
* properly on unnormalized data, be able to matrix any number dye data (current data size
* limited to 4x4, but routines can be easily expanded to work with larger dataArrays), and
* to preserve relative dye signal intensity across the transformation.
*
* The new routines are based on inverse matrix routines from "Applied Numerical Linear
* Algebra" by William W. Hager.  They do an LU factorization of the matrix and find the
* inverse by solving Ax=b for x for subsequent columns of the identity matrix.  See
* MatrixRoutines.m for longer description (or Hager).
*
* June 8, 1994 Jessica Hayden
* To create a new matrix, this tool sends data to the 3D/4D scatter plot program instead
* of the old way where the user is asked to pick peaks.
*****/

@implementation ToolMatrix2

- init
{
  [super init];
  removeNegative = YES;
  normalizeMatrix = YES;
  return self;
}

- (NSString *)defaultLabel
{
  return @"Default Matrix";
}

- (NSString *)toolName
{
  return @"Matrixing-2.1";
}

/****
*
* resource handling section (subclass must implement)
*
****/

- (void)writeResource:(NSString*)resourcePath
{
  int   i;
  FILE  *stream;

  stream = fopen([resourcePath fileSystemRepresentation], "w");
  if(stream == NULL) [NSException raise:@"ToolWriteResourceError"
                                 format:@"Couldn't open file for writing"];
  for(i=0;i<4;i++) {
    fprintf(stream, "%f  %f  %f  %f\n", currentMatrix[i][0], currentMatrix[i][1],
            currentMatrix[i][2], currentMatrix[i][3]);
  }
  fclose(stream);
}

- (void)readResource:(NSString*)resourcePath
{
  int          i, rtn;
  BOOL         error=NO;
  NSException  *theException;
  FILE         *stream;
		
  stream = fopen([resourcePath fileSystemRepresentation], "r");
  if(stream == NULL) [NSException raise:@"ToolReadResourceError"
                                 format:@"Couldn't open file"];
  for(i=0;i<4;i++) {
    rtn = fscanf(stream,"%f %f %f %f",&(currentMatrix[i][0]), &(currentMatrix[i][1]),
            &(currentMatrix[i][2]), &(currentMatrix[i][3]));
    if(rtn != 4) error=YES;
  }
  if(normalizeMatrix) normalizeSpecMatrix(currentMatrix, 4);	
  /* matrixes are all saved/loaded as a 4x4, if less than 4x4 rest are zero, so not
     * affect this normalization */
  if(error) {
    theException = [NSException exceptionWithName:@"ToolReadResourceError"
                                           reason:@"Resource file corrupted"
                                         userInfo:nil];
    [theException raise];
  }
  fclose(stream);
}

/****/

- apply
{	
  int            pos, count, chan, numChannels;
  float          vector[8], value;
  float4matrix   invMatrix;

  [self setStatusMessage:@"Applying Matrix"];
  count = [dataList length];
  numChannels = [dataList numChannels];

  invertMatrix2(currentMatrix, invMatrix, numChannels);
  for(pos=0; pos<count; pos++) {
    for(chan=0; chan<numChannels; chan++) {
      vector[chan] = [dataList sampleAtIndex:pos channel:chan];
    }
    vectorTimesMatrix(vector, invMatrix, numChannels);
    for(chan=0; chan<numChannels; chan++) {
      value = vector[chan];
      if(removeNegative && (value<0.0)) value=0.0;
      [dataList setSample:value atIndex:pos channel:chan];
    }
  }
  [dataList setDefaultProcLabels];	
  [self setStatusMessage:nil];
  return [super apply];
}


- (void)setMatrix:(float4matrix)newCurrent
{
  int i,j;

  for (i=0;i<4;i++)
    for (j=0;j<4;j++) {
      currentMatrix[i][j] = newCurrent[i][j];
    }
}

/****
* ASCIIarchiver methods
****/
- (void)beginDearchiving:archiver;
{
  [self init];
  [super beginDearchiving:archiver];
}

- (id)handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"removeNegative"))
    [archiver readData:&removeNegative];
  if (!strcmp(tag,"normalizeMatrix"))
    [archiver readData:&normalizeMatrix];
  if (!strcmp(tag,"currentMatrix"))
    [archiver readData:currentMatrix];
  else return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&removeNegative type:"c" tag:"removeNegative"];
  [archiver writeData:&normalizeMatrix type:"c" tag:"normalizeMatrix"];
  [archiver writeData:currentMatrix type:"[4[4f]]" tag:"currentMatrix"];
  [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolMatrix2    *dupSelf;

  dupSelf = [super copyWithZone:zone];

  memcpy(dupSelf->currentMatrix, currentMatrix, sizeof(currentMatrix));
  dupSelf->removeNegative = removeNegative;
  dupSelf->normalizeMatrix = normalizeMatrix;
  return dupSelf;
}

@end
