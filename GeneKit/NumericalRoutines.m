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

/* "$Id: NumericalRoutines.m,v 1.3 2006/08/04 20:31:32 svasa Exp $" */

#import "NumericalRoutines.h"
#import <stdlib.h>
#import <stdio.h>
#include "FFT.h"

#define C(t, I, SIGC, A)	((I) * exp(-(1/(2 * (SIGC*SIGC))) * (t*t)) - (A))
#define INITIALBASEOWNER 0
#define Gaussian(X, SIG)	(exp(-X*X/(SIG*SIG)))
#define InvGaussian(X, SIG) (1 - exp(-X*X/(SIG*SIG)))
#define CUTOFF(X, low, high) (InvGaussian(X, low) * Gaussian(X,high))

@protocol UpdateBoxProtocol
- (BOOL)updatePercent:sender :(float)percent;
@end

void normalizeToArea(float area,float *array,int numPoints)
{
	float sum=0, multiplier;
	int i;
	
	for (i = 0; i < numPoints; i ++)
		sum += array[i];
	
	multiplier = area/sum;
	
	for (i = 0; i < numPoints; i++) 
		array[i] = array[i] * multiplier;	
}

void histogram(float *array, int numPoints, int *dist)
{
	/*FILE *fp;
	int total=0;*/
	double max,min, range;
	int i;
		
	
	max = maxVal(array,numPoints);
	min = minVal(array,numPoints);
	range = max - min;

	if (range == 0) {
#ifdef	DEBUG_MSG
		fprintf(stderr, "Range has zero distribution. Can't calc. Histo");
#endif
		return;
	}
	
	for (i = 0; i <= 100; i++)
		dist[i] = 0;
// There isn't an "rint" for windows so We'll try it with
// Built in C rounding and see what happens
        for (i = 0; i < numPoints; i++) 
		dist[(int)(100*(array[i]-min)/range)] += 1;
}

void histogram2(float *array, int numPoints, int *dist, int numSlots)
{
	double max,min, range;
	int i;

	max = maxVal(array,numPoints);
	min = minVal(array,numPoints);
	range = max - min;

	if (range == 0) return;
	
	for (i = 0; i <= numSlots; i++)
		dist[i] = 0;
	for (i = 0; i < numPoints; i++) 
		dist[(int)((numSlots*(array[i]-min))/range)] += 1;
}


void cutoffHistogram(float *array,int numPoints,float thresh,int type)
{
	int			dist[101];
	int 		i, total;
	float 	cutoff, min, range, max;
	
	histogram(array,numPoints,dist);

	max = maxVal(array,numPoints);
	min = minVal(array,numPoints);
	range = max - min;
	
	/* type is bit coded.  Bit 1 turns on/off cutoff of low hist values.
		Bit 2 turns on/off cutoff of hi hist values.
	*/
	if(type&1) {
		total = 0;
		i = -1;
		do {
			i += 1;
			total += dist[i];
		} while (total < (int) (numPoints * (thresh * 0.01)));
		if (i < 0) 
			i = 0;
		cutoff = min + range * ((double) i) * 0.01;
		
		for (i = 0; i < numPoints; i++)
			if (array[i] < cutoff)
				array[i] = cutoff;
	}
	
	if(type&2) {
		total = 0;
		i = 101;
		do {
			i -= 1;
			total += dist[i];
		} while (total < (int) (numPoints * (thresh * 0.01)));
		if (i > 100)
			i = 100;
		cutoff = min + range * (double) i * 0.01;
		
		for (i = 0; i < numPoints; i++)
			if (array[i] > cutoff)
				array[i] = cutoff;
	}
}

void dumpHistogram(float *array,int numPoints)
{
  int i;
  FILE *fp;	
  int	dist[101];

  histogram(array,numPoints,dist);
  fp = fopen("Histogram","a");
  if(fp == NULL) return;

  fprintf(fp, "\n\nHistogram:\n");
  fprintf(fp, "%% range		# Points\n");
  for (i = 0; i <= 100; i++)
    fprintf(fp, "%d		%d\n", i, dist[i]);
  fclose(fp);
}


#define STANDARDCONFIDENCE	0.6
/* This routine takes a list of points and creates an initial list of "bases" simply based on maxima found.  The id is the pointer to the baseList returned, which will only be different from the one passed in if the one passed in was NULL.  numPoints is the number of points in the pointList (four channel) structure. */
/*
id returnInitBases(id pointList, id baseList, int numPoints, int window)
{
	int i,j;
	id resultingMaxima;
	int maximaCount;
 	aBase oneBase;
	int numChannels;
	

	//printf("returnInitBases baseList=%d\n",(int)baseList);
	if (baseList == (id)NULL)
		baseList = [[ArrayStorage alloc] initCount:0
			elementSize:(sizeof(aBase))
			description:"ifici"];
	else {
		[baseList release];
		baseList = [[ArrayStorage alloc] initCount:0
			elementSize:(sizeof(aBase))
			description:"ifici"];
	}
	 
	numChannels = [pointList count];
	for (i = 0; i < numChannels; i++) {
		resultingMaxima = findMaxima1([[pointList objectAt:i] returnDataPtr],
			numPoints, NULL);
		maximaCount = [resultingMaxima count];
		for (j = 0; j < maximaCount; j++) {
			oneBase.location = *(int *)[resultingMaxima elementAt:j];
			oneBase.confidence = STANDARDCONFIDENCE;
			oneBase.channel = i;
			oneBase.owner = INITIALBASEOWNER;
			switch (i) {
				case A_BASE:	oneBase.base = 'A';
					break;
				case T_BASE: oneBase.base = 'T';
					break;
				case C_BASE: oneBase.base = 'C';
					break;
				case G_BASE: oneBase.base = 'G';
					break;
				};
			[baseList addElement:&oneBase];
		}
		[resultingMaxima release];
	};
 	baseList = sortBaseList(baseList); 
	return baseList;
}
*/
/*
id findMaxima(float *numbers, int numPoints, int window) {
	return findMaxima1(numbers, numPoints, NULL);

}
*/
/*
id findMaxima1(float *numbers, int numPoints,  id theStorage) {

	id theMaximaStorage;
	int i, center, left, right;
	
	if (theStorage == NULL)
		theMaximaStorage = [[ArrayStorage alloc] initCount:0
			elementSize:(sizeof(int)) description:"i"];
	else
		theMaximaStorage = theStorage;
		
	for (i = 1; i < (numPoints - 1); i++) {
		if ((numbers[i] > numbers[i-1]) && (numbers[i] > numbers[i+1]))
			[theMaximaStorage addElement:&i];
		else if ((numbers[i] > numbers[i-1]) && (numbers[i] == numbers[i+1])) {
			left = i;
			while ((numbers[i] == numbers[i+1]) && (i < (numPoints+1)))
				i++;
			if (numbers[i] > numbers[i+1]) {
				right = i;
				center = left + (right-left)/2;
				[theMaximaStorage addElement:&center];
			}
		}
	}
	
	return theMaximaStorage;
}
*/
/*
id findInflections(float *numbers, int numPoints,  id theStorage) {

	id theInflectionStorage;
	int loc, center, left, right;
	
	if (numPoints < 3)
		return NULL;
	if (theStorage == NULL)
		theInflectionStorage = [[ArrayStorage alloc] initCount:0
			elementSize:(sizeof(int)) description:"i"];
	else
		theInflectionStorage = theStorage;
	
	loc = 0;
	while (loc < (numPoints-1)) {
		left = findupdowninflection(loc, numbers, numPoints);	
		right = finddownupinflection(left, numbers, numPoints);
		center = findrightmaxloc(left, numbers, numPoints);
		if (center > right) 
			center = left + (right - left)/2;
		[theInflectionStorage addElement:&center];
		loc = right;
	}

	return theInflectionStorage;	
			
}
*/
int findupdowninflection(int location, float *numbers, int numPoints) {
	int i;
	float lastslope, thisslope;
	
	if ((numPoints - location) < 4)
		return (numPoints - 1);
	
	lastslope = numbers[location] - numbers[location+1];
	for (i = location+1; i < (numPoints-1); i++) {
		thisslope = numbers[i] - numbers[i+1];
		if (thisslope > lastslope)
			return i;
		lastslope = thisslope;
	}
	return i;
}

int finddownupinflection(int location, float *numbers, int numPoints) {
	int i;
	float lastslope, thisslope;
	
	if ((numPoints - location) < 4)
		return (numPoints - 1);
	
	lastslope = numbers[location] - numbers[location+1];
	for (i = location+1; i < (numPoints-1); i++) {
		thisslope = numbers[i] - numbers[i+1];
		if (thisslope < lastslope)
			return i;
		lastslope = thisslope;
	}
	return i;
}

int findrightmaxloc(int location, float *numbers, int numPoints) {
	
	int i, left;
	
	
	for (i = location; i < (numPoints-1); i++) {
		if ((numbers[i] > numbers[i-1]) && (numbers[i] > numbers[i+1]))
			return i;
		else if ((numbers[i] > numbers[i-1]) && (numbers[i] == numbers[i+1])) {
			left = i;
			while ((numbers[i] == numbers[i+1]) && (i < (numPoints-1)))
				i+=1;
			if (numbers[i] > numbers[i+1])
				return (left + (i-left)/2);
		}
	}
	return (numPoints-1);  /* min not found */
}


/*


id findMinima(float *numbers, int numPoints, id theStorage) {

	id theMinimaStorage;
	int i, center, left, right;
	
	if (theStorage == NULL)
		theMinimaStorage = [[ArrayStorage alloc] initCount:0
			elementSize:(sizeof(int)) description:"i"];
	else
		theMinimaStorage = theStorage;
		
	for (i = 1; i < (numPoints - 1); i++) {
		if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
			[theMinimaStorage addElement:&i];
		else if ((numbers[i] < numbers[i-1]) && (numbers[i] == numbers[i+1])) {
			left = i;
			while ((numbers[i] == numbers[i+1]) && (i < (numPoints+1)))
				i++;
			if (numbers[i] < numbers[i+1]) {
				right = i;
				center = left + (right-left)/2;
				[theMinimaStorage addElement:&center];
			}
		}
	}
	
	return theMinimaStorage;
}
*/

int findrightminloc(int location, float *numbers, int numPoints) {
	
	int i, left;
	
	
	for (i = location; i < (numPoints-1); i++) {
		if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
			return i;
		else if ((numbers[i] < numbers[i-1]) && (numbers[i] == numbers[i+1])) {
			left = i;
			while ((numbers[i] == numbers[i+1]) && (i < (numPoints-1)))
				i+=1;
			if (numbers[i] < numbers[i+1])
				return left;
		}
	}
	return (numPoints-1);  /* min not found */
}


int findleftminloc(int location, float  *numbers, int numPoints) {
	
	int i, right;
	
	
	for (i = location; i > 0; i--) {
		if ((numbers[i] < numbers[i-1]) && (numbers[i] < numbers[i+1]))
			return i;
		else if ((numbers[i] < numbers[i+1]) && (numbers[i] == numbers[i-1])) {
			right = i;
			while ((numbers[i] == numbers[i-1]) && (i > 0))
				i-=1;
			if (numbers[i] < numbers[i-1])
				return right;
		}
	}
	return 0;  /* min not found */
}



/* This does probably the most inneficient job of sorting I could have 
imagined - but it should sort the bases present in order of location. */
/*id sortBaseList(id baseStorageStruct) {
	int i,j;
	int count, loc;
	int min;	
	aBase	 *theBase, *otherBase, swap;
	aBase *baseArray;

	
	count = [baseStorageStruct count];
	baseArray = (aBase *)[baseStorageStruct returnDataPtr];
	for (i = 0; i < count; i++) {
		min = baseArray[i].location;
		loc = i;
		for (j = i; j < count; j++) {
			if ((baseArray[j].location) < min) {
				min = (baseArray[j].location);
				loc = j;
			}
		};
		if (loc != i) {
			theBase = &baseArray[i];
			otherBase = &baseArray[loc];
			swap = *theBase;
			*theBase = *otherBase;
			*otherBase = swap;
		}
	}
	return baseStorageStruct;
	
}		

*/
void Zconvolve(float *numbers, int numPoints, float FWHM, float M, float offsetPcent, float rangePcent, id updateBox, id sender)
{
	float A=0.0;
	float Ioc = 1;
	int j,k;  		/* Loop Variables */
	float  result[numPoints];
	int t, update;
	float *gaussian, *middle;
	

	/* calculate area A of integral */
//	A = sqrt(Pi/2) * (Ioc * FWHM / M ) * erf( M / (sqrt(2) * FWHM));
//!Needs fixing!!	
	gaussian = calloc(((int)M)*2+1, sizeof(float));
	middle = gaussian + ((int)M);
	for (k = -(int)M; k <= (int)M; k++)
		middle[k] = C((float)k,Ioc,FWHM,A);
		
		/* Convolution Loop */
		update = numPoints/40;
		for (j = 0; j < numPoints; j++) {
			if ((j%update) == 0)
				[updateBox updatePercent:sender :(float)(offsetPcent*100 + rangePcent*j*100/numPoints)];	
			result[j] = 0;
			for (k = -(int)M; k <= (int)M; k ++) {
				t = (j + k);
				if (t < 0) 
					t = 0;
				if (t > numPoints)
					t = numPoints;
				result[j] += numbers[t] * middle[k];
			}
			if (result[j] < 0) result[j] = 0;
		}
		[updateBox updatePercent:sender :(float)(offsetPcent*100 + 
			rangePcent*100)];
		for (j = 0; j < numPoints; j++) 
			numbers[j] = result[j];
}

void convolve(float *array, long size, float sig, int M) {
	register float sum;
	static float *temp=NULL;
	static int oldsize;
	int i, j;
	static float *conv=NULL;
	static int oldconvsize=0;
	float *center;
	
		if (temp == NULL) {
			temp = (float *) calloc(size, sizeof(float));
			oldsize = size;
		}
		else if (oldsize < size) {
			temp = (float *) realloc(temp, size * sizeof(float));
			oldsize = size;
		}
			
		if (conv == NULL) {
			conv = (float *) calloc(M*2+1, sizeof(float));
			oldconvsize = M*2+1;
		}
		else if (oldconvsize < (M*2+1)) {
			conv = (float *) realloc (conv, (M*2+1)*sizeof(float));
			oldconvsize = M*2+1;
		}
		
		center = &conv[M];
		for (j = -M; j <= M; j++)
			center[j] = C((float)j, 1, sig, 0);
		
		for (i = M; i < (size-M); i++) {
//		if ((i % (size / 10)) == 0)
//			fprintf(stderr,".%0.0f%%", rint(((double)i/size)*100));
		sum = 0;
		for (j = -M; j <= M; j++)
			sum += array[i + j] * center[j];
		temp[i] = sum;
	}
	for (i = M; i < (size - M); i++)
		array[i] = temp[i];
}

#define DSPFFT_SIZE 1024
#define REAL 0
#define COMPLEX 1
void fftFilter(float *array, long size, float lowcut, float hicut, int useDSP)
{	int numbuf, i, j, numpoints;
	int padsize; /* Size of zero padding necessary */
	float *fftinarray, *fftoutarray, *tmp, temp;
	int startinput, startoutput, start;
	int windowpad = hicut+50, realwindow;


	/* set up padding, and allocate arrays */	
		normalizeToRange(0, 1, array, size); 
		realwindow = DSPFFT_SIZE - windowpad;
		numbuf = (int)ceil(((float)size)/realwindow);
		numpoints = numbuf * DSPFFT_SIZE;
		padsize = numpoints - size;
		fftinarray = (float *)calloc(numbuf*DSPFFT_SIZE,sizeof(float));
		fftoutarray = (float *)calloc(2*numbuf*DSPFFT_SIZE,sizeof(float));
		tmp = (float *)calloc(2*numbuf*DSPFFT_SIZE,sizeof(float));

	/* zero pad ends, and transfer to dsp input array */
		for (i = 0; i < numbuf; i++) {
			startinput = i * realwindow - windowpad/2; startoutput = i * DSPFFT_SIZE;
			for (j = 0; ((j < DSPFFT_SIZE) && ((j+startinput) < size)); j++) {
				if(startinput+j < 0) fftinarray[startoutput + j] = 0.0;
				else fftinarray[startoutput + j] = array[startinput + j];
			}
		}
	
	/* Perform the transform */
		cfft(fftinarray, fftoutarray, REAL, numbuf, DSPFFT_SIZE);
		for (i = 0; i < numbuf; i++) 
			for (j = 0; j < DSPFFT_SIZE; j++) {
				temp = sqrt(pow(fftoutarray[i*2*DSPFFT_SIZE + j],2) + 
										pow(fftoutarray[((i*2)+1)*DSPFFT_SIZE + j], 2));
			}
	
	
	/* Conjugate to prepare for inverse transform */
		for (i = 0; i < numbuf; i++) {
			start = i * 2 * DSPFFT_SIZE;
			for (j = 0; j < (DSPFFT_SIZE/2); j++) {
				fftoutarray[j+start] *=  CUTOFF((float)j, lowcut, hicut);
				fftoutarray[j+start + DSPFFT_SIZE] *= 
						(-CUTOFF((float)j, lowcut, hicut)); /* Imag */
				fftoutarray[start + DSPFFT_SIZE - (j+1)] *= 
						CUTOFF((float)j, lowcut, hicut);
				fftoutarray[start + 2*DSPFFT_SIZE - (j+1)] *= 
						(-CUTOFF((float)j, lowcut, hicut));
			} 
		}
	
	/* Now, the inverse transform */
		cfft (fftoutarray, tmp, COMPLEX, numbuf, DSPFFT_SIZE);
		for (i = 0; i < numbuf; i++) 
			for (j = 0; j < DSPFFT_SIZE; j++) {
				temp = sqrt(pow(fftoutarray[i*2*DSPFFT_SIZE + j],2) + 
										pow(fftoutarray[((i*2)+1)*DSPFFT_SIZE + j], 2));
			}

	/* Now extract only the real values to put back into the original array*/
		for (i = 0; i < numbuf; i ++) {
			startinput = i * realwindow; startoutput = 2*i * DSPFFT_SIZE + windowpad/2;
			for (j = 0; ((j < realwindow) && ((j+startinput) < size)); j++) {
				array[startinput + j] = tmp[startoutput + j] ;
				/** array[startinput + j] = fftinarray[startoutput + j] ; **/
			}
		}
	
#ifdef OLDCODE
	//		for (j = 0; j < ((2*i+1)*DSPFFT_SIZE); j++)	{
	//			if (k >= size)
	//				break;
	//			array[k++] = tmp[j];
	//		}	
#endif

	/* Normalize and free necessary arrays */
		normalizeToRange(0, 1, array, size);			
		free(fftinarray);
		free(fftoutarray);
		free(tmp);
	
	}
	
/* Performs gauss-jordan elimination on a matrix.
 	 n = cols 
	 m = rows
	 A[m][n]
*/
void
mygaussj(float (*A)[], int m, int n, float b[], float x[])
{
	float               (*a)[n], B[m][n];
	int                 i, j, k;
	int                 reorder[m];
	float               max_col, max_row, pivot, mult, sum;
	int                 pivot_row = 0, tmp, row;

	a = A;

 /* Set up indices of pivots */
	for (i = 0; i < m; i++)
		reorder[i] = i;
	for (i = 0; i < m; i++) {
		for (j = 0; j < n; j++) {
			B[i][j] = a[i][j];
		}
	}

#ifdef	DEBUG_MSG
	printf("\nInitial B:");
	for (i = 0; i < m; i++)
		printf("%f	", b[reorder[i]]);
	printf("\n");
 /* Now, it SHOULD be lower triangular, so back-substitute */
#endif


 /* Loop over each row! */
	for (i = 0; i < m; i++) {
		max_row = -FLT_MAX;

	/* Go down each row, to find pivot */
		for (j = i; j < m; j++) {
			row = reorder[j];
			max_col = -FLT_MAX;
		/* search in each column of row for maximal element to rescale */
			for (k = i; k < n; k++)
				if (fabs(a[row][k]) > max_col)
					max_col = fabs(a[row][k]);

			if ((fabs(a[row][i]) / max_col) > max_row) {
				pivot_row = j;
#ifdef	DEBUG_MSG
				printf("a[][] = %f, max_col = %f, a/max_col = %f\n",
					   a[row][i], max_col, a[row][i] / max_col);
				max_row = fabs(a[row][i] / max_col);
				printf("max_row = %f\n", max_row);
#endif
			}
		}
		tmp = reorder[i];
		reorder[i] = reorder[pivot_row];
		reorder[pivot_row] = tmp;


		pivot = a[reorder[i]][i];
		pivot_row = reorder[i];

	/* Now, do the actual division since pivot was found */
		for (j = i + 1; j < m; j++) {
			row = reorder[j];
			mult = pivot / a[row][i];
			for (k = i; k < n; k++)
				a[row][k] = mult * a[row][k] - a[pivot_row][k];
			b[row] = mult * b[row] - b[pivot_row];
		}

#ifdef	DEBUG_MSG
		printf("\nafter row %d:\n", i);
		for (l = 0; l < m; l++) {
			for (k = 0; k < n; k++)
				printf("%2.2f\t", a[reorder[l]][k]);
			printf("\n");
		}
		printf("\n B at row %d: ", i);
		for (l = 0; l < m; l++)
			printf("%f	", b[reorder[l]]);
		printf("\n");
#endif

	}

#ifdef DEBUG_MSG
	printf("\nFinal Matrix:\n");
	for (i = 0; i < m; i++) {
		for (j = 0; j < n; j++)
			printf("%2.2f\t", a[reorder[i]][j]);
		printf("\n");
	}

	printf("\nfinal B:");
	for (i = 0; i < m; i++)
		printf("%f	", b[reorder[i]]);
	printf("\n");
 /* Now, it SHOULD be lower triangular, so back-substitute */

	printf("\nfinal Reorder:");
	for (i = 0; i < m; i++)
		printf("%d	", reorder[i]);
	printf("\n");
 /* Now, it SHOULD be lower triangular, so back-substitute */
#endif

	for (i = (m - 1); i >= 0; i--) {
		sum = 0;
		for (j = (i + 1); j < m; j++)
			sum += a[reorder[i]][j] * x[j];
		x[i] = (1 / a[reorder[i]][i]) * (b[reorder[i]] - sum);
	}

#ifdef	DEBUG_MSG

	for (i = 0; i < n; i++)
		printf("X[%d] = %f\n", i, x[i]);

	for (i = 0; i < n; i++) {
		sum = 0;
		for (j = 0; j < n; j++)
			sum += B[i][j] * x[j];

		printf("\nSum[%d] = %f\n", i, sum);
	}
#endif

}
		
void fpoly(float x,float p[],int np)
{
	int j;

	p[1]=1.0;
	for (j=2;j<=np;j++) p[j]=p[j-1]*x;
}



float polyx(float x, int np)
{	int i;
	float result = 1;


	for (i = 0; i < np; i++)
		result *= x;
		
	return result;
}
	


void myfit(float x[], float y[], float sig[], int n, float a[], 
						int m, float (*funcs)(float,int))
{
	float alpha[m][m], beta[m];
	int i,j,k;
	float sum;
	
	for (k = 0; k < m; k++) {
		for (j = 0; j < m; j++) {
			sum = 0;
			for (i = 0; i < n; i++)
				sum += funcs(x[i],j) * funcs(x[i],k)/sig[i];
			alpha[k][j] = sum;
		}
		sum = 0;
		for (i=0; i < n; i++)
			sum += y[i] * funcs(x[i],k)/sig[i];
		beta[k] = sum;
	}
	
	mygaussj(alpha, m, m, beta, a);
	
}
		
/*
int maxChanResponse(int location, id Data) {
	int i, channel=0;
	float max = -FLT_MAX;
	float response;
	
	
	for (i = 0; i < [Data count]; i++) {
		response = * (float *)[[Data objectAt:i] elementAt:location];
		if (response > max) {
			channel = i;
			max = response;
		}
	}
	return channel;
}
*/

/*
void secondOrderMaxFit(id Data, int chan, float A[], int n)
{
	id maxStorage;
	id secondOrderMaxStorage;
	int numPoints, i, j;
	float *numbers, *maxnums;
	int maxcount;
	float *fitnums[3];
	int *soMaxNums,  *tmp, right, center, left;
	
	numbers = (float *)[[Data objectAt:chan] returnDataPtr];
	numPoints = [[Data objectAt:chan] count];

	maxStorage = [[ArrayStorage alloc] initCount:0
		elementSize:(sizeof(int)) description:"i"];
	secondOrderMaxStorage = [[ArrayStorage alloc] initCount:0
		elementSize:(sizeof(int)) description:"i"];
	findMaxima1(numbers, numPoints, maxStorage);

	maxnums = (float *)calloc([maxStorage count]+1, sizeof(float));

	maxcount= [maxStorage count];
	tmp = (int *)[maxStorage returnDataPtr];
	for (i = 0; i < maxcount; i++) {
		maxnums[i] =  numbers[tmp[i]];
	}

	for (i = 1; i < (maxcount - 1); i++) {
		if ((maxnums[i] > maxnums[i-1]) && (maxnums[i] > maxnums[i+1]))
			[secondOrderMaxStorage addElement:&tmp[i]];
		else if ((maxnums[i] > maxnums[i-1]) && (maxnums[i] == maxnums[i+1])) {
			left = i;
			while ((maxnums[i] == maxnums[i+1]) && (i < (maxcount+1)))
				i++;
			if (maxnums[i] > maxnums[i+1]) {
				right = i;
				center = left + (right-left)/2;
				[secondOrderMaxStorage addElement:&tmp[center]];
			}
		}
	}



	soMaxNums = (int *)[secondOrderMaxStorage returnDataPtr];
	for (i = 0; i < 3; i++)
		fitnums[i] = (float *)calloc([secondOrderMaxStorage count], sizeof(float));
	for (j = 0; j < [secondOrderMaxStorage count]; j++) {
		fitnums[0][j] = (float) soMaxNums[j];
		fitnums[1][j] = (float) numbers[soMaxNums[j]];
		fitnums[2][j] = 1;
	}
	myfit(fitnums[0], fitnums[1], fitnums[2], [secondOrderMaxStorage count],
				A, n, polyx);
	//fprintf(stderr,"a0:%e a1:%e a2:%e\n", A[0], A[1], A[2]);

	for (i = 0; i < 3; i++)
		free(fitnums[i]);
	[maxStorage release];
	[secondOrderMaxStorage release];
	free(maxnums);
}	


void secondOrderMinFit(id Data, int chan, float A[], int n)
{
	id minStorage;
	id secondOrderminStorage;
	int numPoints, i, j;
	float *numbers, *minnums;
	int mincount;
	float *fitnums[3];
	int *sominNums,  *tmp, right, center, left;
	
	numbers = (float *)[[Data objectAt:chan] returnDataPtr];
	numPoints = [[Data objectAt:chan] count];

	minStorage = [[ArrayStorage alloc] initCount:0
		elementSize:(sizeof(int)) description:"i"];
	secondOrderminStorage = [[ArrayStorage alloc] initCount:0
		elementSize:(sizeof(int)) description:"i"];
	findMinima(numbers, numPoints, minStorage);

	minnums = (float *)calloc([minStorage count]+1, sizeof(float));

	mincount= [minStorage count];
	tmp = (int *)[minStorage returnDataPtr];
	for (i = 0; i < mincount; i++) {
		minnums[i] =  numbers[tmp[i]];
	}

	for (i = 1; i < (mincount - 1); i++) {
		if ((minnums[i] < minnums[i-1]) && (minnums[i] < minnums[i+1]))
			[secondOrderminStorage addElement:&tmp[i]];
		else if ((minnums[i] < minnums[i-1]) && (minnums[i] == minnums[i+1])) {
			left = i;
			while ((minnums[i] == minnums[i+1]) && (i < (mincount+1)))
				i++;
			if (minnums[i] < minnums[i+1]) {
				right = i;
				center = left + (right-left)/2;
				[secondOrderminStorage addElement:&tmp[center]];
			}
		}
	}



	sominNums = (int *)[secondOrderminStorage returnDataPtr];
	for (i = 0; i < 3; i++)
		fitnums[i] = (float *)calloc([secondOrderminStorage count], sizeof(float));
	for (j = 0; j < [secondOrderminStorage count]; j++) {
		fitnums[0][j] = (float) sominNums[j];
		fitnums[1][j] =  numbers[sominNums[j]];
		fitnums[2][j] = 1;
	}
	myfit(fitnums[0], fitnums[1], fitnums[2], [secondOrderminStorage count],
				A, n, polyx);
	//fprintf(stderr,"a0:%e a1:%e a2:%e\n", A[0], A[1], A[2]);
	for (i = 0; i < 3; i++)
		free(fitnums[i]);
	[minStorage release];
	[secondOrderminStorage release];
	free(minnums);
}	



void normalizeFitChan(id Data, int chan)
{
	float minPoly[3], maxPoly[3];
	float *numbers;
	float minval, maxval;
	int numPoints,i;
	
	secondOrderMinFit(Data, chan, minPoly, 3);
	secondOrderMaxFit(Data, chan, maxPoly, 3);
	numbers = (float *)[[Data objectAt:chan] returnDataPtr];
	numPoints = [[Data objectAt:chan] count];
	for (i = 0; i < numPoints; i++) {
		minval = minPoly[0] + minPoly[1] * (float)i + minPoly[2]*(float)i*(float)i;
		maxval = maxPoly[0] + maxPoly[1] * (float)i + maxPoly[2]*(float)i*(float)i;
		numbers[i] -= minval;
		numbers[i] /= fabs(maxval - minval);
	}
	
}
*/

void normalizeWithCommonScale(Trace *data)
{	
  float 	scale, *dataArray;
  float 	smallestscale=FLT_MAX;
  int 		channel, j, numChannels, numPoints;

  numChannels = [data numChannels];
  numPoints = [data length];
  dataArray = (float *)calloc(numPoints, sizeof(float));
  for (channel=0; channel<numChannels; channel++) {
    for(j=0; j<numPoints; j++)
      dataArray[j] = [data sampleAtIndex:j channel:channel];
    scale = scaleFactor(0.0, 1.0, dataArray, numPoints);
    if (scale < smallestscale)
      smallestscale = scale;
  }
  if (smallestscale==1.0) return;

  for (channel=0; channel<numChannels; channel++) {
    for(j=0; j<numPoints; j++)
      dataArray[j] = [data sampleAtIndex:j channel:channel];
    normalizeBy(smallestscale, 0.0, dataArray, numPoints);
    //[[data objectAt:channel] autoCalcParams];
    for(j=0; j<numPoints; j++)
      [data setSample:dataArray[j] atIndex:j channel:channel];
  }
  free(dataArray);
  return;
}


void normalizeToRange(float lowBound, float highBound, float *array,
                      int numPoints)
{
  int i;
  float max, min, multiplier,width;

  max = maxVal(array, numPoints);
  min = minVal(array, numPoints);
  width = max - min;
  if (width == 0)
    multiplier = 0;
  else
    multiplier = (float)fabs((double)highBound-lowBound)/
						fabs((double)max - min);

  for (i = 0; i < numPoints; i++)
    array[i] = (array[i]-min)  * multiplier + lowBound;
}

void normalizebyWindows(float *array, 
											int numPoints, int windowsize)
{
	int numwindows = numPoints / windowsize, window,i, j;	
	int windowstart;
	float mins[numwindows+1], scales[numwindows+1];
	float min, max;
	float scaleintcpt, scaleslope;
	float minintcpt, minslope;

	//	First, find the values for the various windows	
	for (window = 0; window < numwindows; window++) {
		min = FLT_MAX; max = -FLT_MAX;
		for (j = windowsize * window; j < (windowsize * (window + 1)); j++) {
			if (array[j] > max)
				max = array[j];
			if (array[j] < min)
				min = array[j];
		}
		mins[window] = min;
		scales[window] = 1/(max-min);
	}
		min = FLT_MAX; max = -FLT_MAX;
	if ((numPoints - numwindows*windowsize ) < (windowsize/2))
		windowstart = numPoints - windowsize/2;
	else
		windowstart = numwindows*windowsize;
	for (j = windowstart; j < numPoints; j++) {
			if (array[j] > max)
				max = array[j];
			if (array[j] < min)
				min = array[j];
	}
	if ((j == 0) || (min == max)) {
		mins[numwindows] = mins[numwindows-1];
		scales[numwindows] = mins[numwindows - 1];
	}
	else {
    	mins[numwindows] = min;
			scales[numwindows] = 1/(max-min);
	}

	minintcpt = minVal(array, numPoints);	
	// Now, rescale the data
	for (window = 0; window < (numwindows-1); window++) {
		windowstart = window*windowsize + windowsize/2;
		scaleslope = (scales[window+1] - scales[window])/
								windowsize;
		scaleintcpt = scales[window];
		minintcpt = mins[window];
		minslope = (mins[window+1] - mins[window]) / windowsize;
		for (j = windowstart; j < (windowstart + windowsize); j++) 
			array[j] = (array[j] - (minintcpt + minslope * (j-windowstart))) *
								 (scaleintcpt + scaleslope * (j - windowstart));
	}

	
//	for ( i = 0; i < (windowsize/2); i ++)
//		array[i] = (array[i] - mins[0]) * scales[0];
	windowstart = numwindows*windowsize - windowsize/2;
	scaleslope = (scales[numwindows] - scales[numwindows-1])/
							(windowsize/2);
	scaleintcpt = scales[numwindows-1];
	minintcpt = mins[numwindows-1];
	minslope = (mins[numwindows] - mins[numwindows-1]) / (windowsize/2);
	for (j = windowstart; j < (windowstart + (windowsize/2)); j++) 
		array[j] = (array[j] - (minintcpt + minslope * (j-windowstart))) *
								(scaleintcpt + scaleslope * (j - windowstart));
								
	for ( i = 0; i < windowsize/2; i++)
			array[i] = (array[i] - mins[0]) * scales[0];	
	for ( i = (numwindows * windowsize); i < numPoints; i++)	
		array[i] = (array[i] - mins[numwindows]) * scales[numwindows];
		
		
		
}

float maxVal(float *array, int numPoints)
{
	float max=-FLT_MAX;
	int i;
	
	for (i = 0; i < numPoints; i++) {
		if (array[i] > max)
			max = array[i];
	}
	return max;
}

float minVal(float *array, int numPoints)
{
	float min=FLT_MAX;
	int i;
	
	for (i = 0; i < numPoints; i++) {
		if (array[i] < min)
			min = array[i];
	}
	return min;
}

void chopNormalize(float *array, int numPoints, float chopVal)
{
	/** normalizes data to 0-1, then chops all data values below 'chopVal'
		to chopVal, then re-normalizes to 0-1.
	**/
	int			i;
	
	normalizeToRange(0.0, 1.0, array, numPoints);
	if(chopVal<=0.0) return;
	if(chopVal >=1.0) chopVal=1.0;
	for(i=0; i<numPoints; i++) {
		if(array[i]<chopVal) array[i]=chopVal;
	}
	normalizeToRange(0.0, 1.0, array, numPoints);
	return;
}

float scaleFactor(float lowBound, float highBound, float *array, 
		int numPoints)
{
	float max, min, multiplier,width;
	
	max = maxVal(array, numPoints);
	min = minVal(array, numPoints);
	width = max - min;
	if (width == 0)
		multiplier = 0;
	else
		multiplier = (float)fabs((double)highBound-lowBound)/
						width;
	
	return multiplier;
}

void normalizeBy(float scale, float lowBound, float *array, 
											int numPoints)
{
	int i;
	float min;
	
	min = minVal(array, numPoints);
	
	for (i = 0; i < numPoints; i++) 
		array[i] = (array[i]-min)  * scale + lowBound;
}
 
  
float geommean(float *values, float *weights, int count, float sum) {
  float denom=0;
	int i;
	
	for (i = 0; i < count; i++)
		if (values[i] != 0.0) 
			denom	+= (1/values[i])*weights[i];
		else
			return 0;
	return(sum/denom);
}

int countmin(int location, float *nums, int channel)
{
//	if (nums[location] < ((LOWCUTOFF/100) * //abs(expectedMinHeight(channel,location))
//												+ expectedMinHeight(channel,location)))
		return YES;
//	else
//		return NO;
}


float peakwidth(int location, float *numbers, int numPoints, int channel)
{	int templeftloc, temprightloc;

	// Scan to the left until min value is likely to REALLY be a minimum
	templeftloc = findleftminloc(location, numbers, numPoints);
	while((templeftloc > 0) && (!countmin(templeftloc, numbers, channel)))
		templeftloc = findleftminloc(templeftloc-1, numbers, numPoints);

	//Scan to the right until max value is high enough to really be maximum
	temprightloc = findrightminloc(location,numbers,numPoints);
	while((temprightloc < (numPoints-1))&&(!countmin(temprightloc, numbers, channel)))
		temprightloc = findrightminloc(temprightloc+1, numbers, numPoints);
		
		return abs(temprightloc - templeftloc);
//	return abs(findrightminloc(location, numbers, numPoints) -
//	           findleftminloc(location, numbers, numPoints));

}

int lefthalfheightpoint(int location, float *numbers, int numPoints)
{
	int leftminloc, i;
	float leftmin, halfcutoff;
	
	leftminloc = findleftminloc(location, numbers, numPoints);
	leftmin = numbers[leftminloc];
	halfcutoff = (numbers[location] - leftmin)/2 + leftmin;
	for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;

	return i;
}

int righthalfheightpoint(int location, float *numbers, int numPoints)
{
	int rightminloc, i;
	float rightmin, halfcutoff;
	
	rightminloc = findrightminloc(location, numbers, numPoints);
	rightmin = numbers[rightminloc];
	halfcutoff = (numbers[location] - rightmin)/2 + rightmin;
	for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++) ;

	return i;
}

// Find the peak width based on half height measure
int halfHeightPeakWidth(int location, float *numbers, int numPoints)
{
	float leftmin, rightmin, maxmin, halfcutoff;
	int leftminloc, rightminloc;
	int i;
	int lefthalfheightloc, righthalfheightloc;
	
	
	leftminloc = findleftminloc(location, numbers, numPoints);
	rightminloc = findrightminloc(location, numbers, numPoints);
	leftmin = numbers[leftminloc];
	rightmin = numbers[rightminloc];
	
	maxmin = (leftmin > rightmin ? leftmin : rightmin);
	halfcutoff = (numbers[location] - maxmin)/2 + maxmin;

	for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;
	lefthalfheightloc = i;
	
	for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++);
	righthalfheightloc = i;
	
	return  (righthalfheightloc - lefthalfheightloc);
	
}
	
// Find the peak width based on half height measure
int halfHeightPeakAveWidth(int location, float *numbers, int numPoints)
{
	float leftmin, rightmin, halfcutoff;
	int leftminloc, rightminloc;
	int i;
	int lefthalfheightloc, righthalfheightloc;
	
	
	leftminloc = findleftminloc(location, numbers, numPoints);
	rightminloc = findrightminloc(location, numbers, numPoints);
	leftmin = numbers[leftminloc];
	rightmin = numbers[rightminloc];
	
//	minmin = (leftmin < rightmin ? leftmin : rightmin);

	halfcutoff = (numbers[location] - leftmin)/2 + leftmin;
	for (i = location; ((i >= 0) && (numbers[i]>halfcutoff)); i--) ;
	lefthalfheightloc = i;
	
	halfcutoff = (numbers[location] - rightmin)/2 + rightmin;
	for (i = location; ((i < numPoints) && (numbers[i]>halfcutoff)); i++);
	righthalfheightloc = i;
	
	return  (righthalfheightloc - lefthalfheightloc);
	
}
	
void polyFit(float *arrayX,float *arrayY,float *sig,int numPoints,float *coeffecients,int numCoeff)
{	
	myfit(arrayX, arrayY, sig, numPoints, coeffecients, numCoeff, polyx);	
}  	

BOOL findBaselineMinima(float* data, int startX, int endX, 
												int *minX)
{
	BOOL		newPoint = NO;
	int			i, minPos=0;
	float		minValue=0.0, baseline, value=0;
	float		startY, endY;
	
	startY = data[startX]; endY = data[endX];
	
	for(i=startX; i<endX; i++) {
		baseline = ((float)(i-startX)*(endY-startY))/((float)(endX-startX)) + startY;
		value = data[i] - baseline;
		if(value < minValue) {	//find smallest point that is less than 0.0
			newPoint = YES;
			minValue = value;
			minPos = i;
		}
	}
	*minX = minPos;
	return newPoint;
}

