/* "$Id: FFT.c,v 1.2 2006/08/04 20:31:32 svasa Exp $" */
/***********************************************************

Copyright (c) 1992-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/***************
*
*  FFT module
*
****************/

#include "FFT.h"
#include "math.h"
//#include <SANE.h>
//#include <FixMath.h>
#include <stdio.h>
#include <stdlib.h>

/* Fract				sinTable[1024], cosTable[1024]; */


/*******   LOCAL FUNCTIONS TO THE MODULE    **********/
void MakeTrigTables(long size);
long BitReverse (long value, long numBits);
long OldBitReverse (long value, long numBits);



/*******   IMPLEMENTATION    **********/
long BitReverse (long value, long numBits)
{
	long		i, reversed;
	
	reversed = 0;
	
	for(i=0;i<numBits;i++) {
		reversed = (reversed<<1) + (value&1);
		value = (value>>1);
	}
	return(reversed);
}


long OldBitReverse (long value, long numBits)
{
	long		i, temp, reversed;
	
	reversed = 0;
	
	for(i=0;i<numBits;i++) {
		temp = value/2;
		reversed = reversed*2 + (value - 2*temp);
		value = temp;
	}
	return(reversed);
}



#ifdef OLDMACCODE
/* fixed point fft specifically using macintosh Fract type */

void MakeTrigTables(long size)
{
	/* fixed point trig tables to improve speed on machines without FP-coprocessors */
	long				i;
	Fixed				temp;
	extended			tempVal;
	double			tempDub;

	sinTable = malloc
	for(i=0;i<size;i++) {
		tempDub = (6.283185 * i) / size, &tempVal;
		x96tox80(&tempDub, &tempVal);
		/* temp = X2Fix((6.283185 * i) / size); */
		temp = X2Fix(tempVal);
		sinTable[i] = FracSin(temp);
		cosTable[i] = FracCos(temp);
	}
}


void InitFFT(long size)
{
	MakeTrigTables(size);
}


void FFT(Fract *realArray, Fract *imagArray, long size)
{
	long			n2, nu, nu1, i, j, k, factor, m, p;
	Fract			tempReal, tempImag, cosValue, sinValue;
	Fixed			arg;
		
	nu = (long) (log((double)size)/log((double)2));
	n2 = size / 2;
	nu1 = nu-1;
	k = 0;
	
	for(j=0;j<nu;j++) {
lbl:		
		for(i=0;i<n2;i++) {
			factor=1;
			for(m=0;m<nu1;m++) factor=2*factor;
			
			p = BitReverse(k/factor, nu);

			/* before lookup tables, which sped it up by about 2x
			arg = X2Fix(6.283185 * p / size);
			cosValue = FracCos(arg);
			sinValue = FracSin(arg);
			*/
			cosValue = cosTable[p];
			sinValue = sinTable[p];
			
			tempReal = FracMul(realArray[k+n2],cosValue) + FracMul(imagArray[k+n2],sinValue);
			tempImag = FracMul(imagArray[k+n2],cosValue) - FracMul(realArray[k+n2],sinValue);
			
			realArray[k+n2] = realArray[k] - tempReal;
			imagArray[k+n2] = imagArray[k] - tempImag;
			realArray[k] = realArray[k] + tempReal;
			imagArray[k] = imagArray[k] + tempImag;
			
			k++;
		}
		k = k + n2;
		if (k<size) goto lbl;
		k=0;
		nu1--;
		n2 = n2/2;
	}
	
	for(k=0;k<size;k++) {
		i = BitReverse(k,nu);
		if(i>k) {
			tempReal = realArray[k];
			tempImag = imagArray[k];
			
			realArray[k] = realArray[i];
			imagArray[k] = imagArray[i];
			realArray[i] = tempReal;
			imagArray[i] = tempImag;
		}
	}
}
#endif


void FFT_double(double *realArray, double *imagArray, long size)
{
	long			n2, nu, nu1, i, j, k, factor, m;
	double		tempReal, tempImag, p, arg, cosValue, sinValue;
	
	nu = (long) (log(size)/log(2));
	n2 = size / 2;
	nu1 = nu-1;
	k = 0;
	
	for(j=0;j<nu;j++) {
lbl:		for(i=0;i<n2;i++) {
			factor=1;
			for(m=0;m<nu1;m++) factor=2*factor;
			
			p = (double)BitReverse(k/factor, nu);
			arg = 6.283185 * p / size;
			cosValue = cos(arg);
			sinValue = sin(arg);
			
			tempReal = realArray[k+n2]*cosValue + imagArray[k+n2]*sinValue;
			tempImag = imagArray[k+n2]*cosValue - realArray[k+n2]*sinValue;
			
			realArray[k+n2] = realArray[k] - tempReal;
			imagArray[k+n2] = imagArray[k] - tempImag;
			realArray[k] = realArray[k] + tempReal;
			imagArray[k] = imagArray[k] + tempImag;
			
			k++;
		}
		k = k + n2;
		if (k<size) goto lbl;
		k=0;
		nu1--;
		n2 = n2/2;
	}
	
	for(k=0;k<size;k++) {
		i = BitReverse(k,nu);
		if(i>k) {
			tempReal = realArray[k];
			tempImag = imagArray[k];
			
			realArray[k] = realArray[i];
			imagArray[k] = imagArray[i];
			realArray[i] = tempReal;
			imagArray[i] = tempImag;
		}
	}
}


void FFT_float(float *realArray, float *imagArray, long size)
{
	long			n2, nu, nu1, i, j, k, factor, m;
	float		tempReal, tempImag, p, arg, cosValue, sinValue;

	nu = (long) (log(size + .05)/log(2));
	/* The .05 in the above line is to jiggle nu up to the right value;
	 * Without it, nu is off by one on intel machines
	 */
	 
	n2 = size / 2;
	nu1 = nu-1;
	k = 0;
	
	for(j=0;j<nu;j++) {
lbl:		for(i=0;i<n2;i++) {
			factor=1;
			for(m=0;m<nu1;m++) factor=2*factor;
			
			p = (float)BitReverse(k/factor, nu);
			arg = 6.283185 * p / size;
			cosValue = (float)cos((double)arg);
			sinValue = (float)sin((double)arg);
			
			tempReal = realArray[k+n2]*cosValue + imagArray[k+n2]*sinValue;
			tempImag = imagArray[k+n2]*cosValue - realArray[k+n2]*sinValue;
			
			realArray[k+n2] = realArray[k] - tempReal;
			imagArray[k+n2] = imagArray[k] - tempImag;
			realArray[k] = realArray[k] + tempReal;
			imagArray[k] = imagArray[k] + tempImag;
			
			k++;
		}
		k = k + n2;
		if (k<size) goto lbl;
		k=0;
		nu1--;
		n2 = n2/2;
	}
	
	for(k=0;k<size;k++) {
		i = BitReverse(k,nu);
		if(i>k) {
			tempReal = realArray[k];
			tempImag = imagArray[k];
			
			realArray[k] = realArray[i];
			imagArray[k] = imagArray[i];
			realArray[i] = tempReal;
			imagArray[i] = tempImag;
		}
	}
}


void Test(void)
{
	long		temp;
	
	for(temp=0;temp<16;temp++)
		printf("%d  %d\n",(int)temp,(int)BitReverse(temp,4));
}


void cfft (float *input, float *output, int complex, int number_of_blocks, int fft_size)
{
	/* given the entire input data array, it breaks it up into buffers and does
		the fft on each buffer putting the transformed data into the output array.
		The input array can either be organized as reals or complex numbers. but the
		routine always returns the data organized as complex numbers.  The complex
		organization is that each block (2*fft_size) first has fft_size real components
		followed by fft_size imaginary components.
	*/
	float		*realBuffer, *complexBuffer;
	int			buffer, i;

	realBuffer = (float*) malloc(sizeof(float)*fft_size);
	complexBuffer = (float*) malloc(sizeof(float)*fft_size);
	
	for(buffer=0; buffer<number_of_blocks; buffer++) {
		if(complex)
			for(i=0; i<fft_size; i++) {
				realBuffer[i] = input[buffer*fft_size*2 + i];
				complexBuffer[i] = input[buffer*fft_size*2 + fft_size + i];
			}
		else
			for(i=0; i<fft_size; i++) {
				realBuffer[i] = input[buffer*fft_size + i];
				complexBuffer[i] = 0.0;
			}
		FFT_float(realBuffer, complexBuffer, fft_size);
		for(i=0; i<fft_size; i++) {
			output[buffer*fft_size*2 + i] = realBuffer[i];
			output[buffer*fft_size*2 + fft_size + i] = complexBuffer[i];
		}		
	}
	return;
}


