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

/* "$Id: NumericalRoutines.h,v 1.5 2006/08/04 20:31:32 svasa Exp $" */

#import <Foundation/NSObject.h>
//#import <GeneKit/ArrayStorage.h>
#import <GeneKit/Trace.h>
#import <GeneKit/NumericalLibraryTypes.h>
#import <GeneKit/Base.h>
//#import <objc/List.h>
#import <math.h>
#import <float.h>
#import <memory.h>
#import <stdio.h>
#define Pi M_PI
/* base channels */
/*#define UNKNOWN_BASE -1
#define A_BASE	1
#define T_BASE	3
#define G_BASE	2
#define C_BASE	0 */


void normalizeToArea(float area,float *array,int numPoints);
void histogram(float *array, int numPoints, int *dist);
void histogram2(float *array, int numPoints, int *dist, int numSlots);
void cutoffHistogram(float *array,int numPoints,float thresh,int type);
void dumpHistogram(float *array,int numPoints);
id returnInitBases(id pointList, id baseList, int numPoints, int window);
//id findMaxima(float *numbers, int numPoints, int window);
//id findMinima(float *numbers, int numPoints, id theStorage);
//id findMaxima1(float *numbers, int numPoints, id theStorage);
int findrightminloc(int location,  float *numbers, int numPoints);
int findleftminloc(int location,  float  *numbers, int numPoints);
id sortBaseList(id baseStorageStruct);
void Zconvolve(float *numbers, int numPoints, float FWHM, float M, float 
						offsetPcent, float rangePcent, id updateBox, id sender);
void convolve(float *array, long size, float sig, int M);
void myfit(float x[], float y[], float sig[], int n, float a[], 
						int m, float (*funcs)(float,int));
void fftFilter(float *array, long size, float lowcut, float hicut, int useDSP);
void mygaussj(float (*A)[], int m, int n, float b[], float x[]);
float polyx(float x, int np);
int maxChanResponse(int location, id Data);
//void normalizeFitChan(id Data, int chan);
//void secondOrderMaxFit(id Data, int chan, float A[], int n);
//void secondOrderMinFit(id Data, int chan, float A[], int n);
void normalizeToRange(float lowBound, float highBound, float *array, int numPoints);
float maxVal(float *array, int numPoints);
float minVal(float *array, int numPoints);
void chopNormalize(float *array, int numPoints, float chopVal);
void normalizeWithCommonScale(Trace *data);
float scaleFactor(float lowBound, float highBound, float *array, int numPoints);
void normalizeBy(float scale, float lowBound, float *array, int numPoints);
float geommean(float *values, float *weights, int count, float sum);
int countmin(int location, float *nums, int channel);
float peakwidth(int location, float *numbers, int numPoints, int channel);
int righthalfheightpoint(int location, float *numbers, int numPoints);
int lefthalfheightpoint(int location, float *numbers, int numPoints);
int halfHeightPeakWidth(int location, float *numbers, int numPoints);
int halfHeightPeakAveWidth(int location, float *numbers, int numPoints);
//id findInflections(float *numbers, int numPoints,  id theStorage);
int findupdowninflection(int location, float *numbers, int numPoints);
int finddownupinflection(int location, float *numbers, int numPoints);
int findrightmaxloc(int location, float *numbers, int numPoints);
void normalizebyWindows(float *array, int numPoints, int windowsize);
void polyFit(float *arrayX,float *arrayY,float *sig,int numPoints,float *coeffecients,int numCoeff);
BOOL findBaselineMinima(float* data, int startX, int endX, int *minX);
