
/* "$Id: MatrixRoutines.m,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */

#import <float.h>
#include <math.h>
#import "MatrixRoutines.h"


/*****
*
* general purpose functions
*
******/
void matrixMultiply(float4matrix m1, float4matrix m2, float4matrix m3, int size)
{
	int			row, col, i;
	float		sum;
	
	for(row=0; row<size; row++) {
		for(col=0; col<size; col++) {
			sum = 0.0;
			for(i=0; i<size; i++) {
				sum = sum + m1[row][i] * m2[i][col];
			}
			m3[row][col] = sum;
		}
	}
	return;
}

void normalizeMatrix(float4matrix matrix, int size) 
{
	short     	i, j;
	float       maxVal=-FLT_MAX;

	/* find maximum value in diagonal of matrix */
	for (i = 0; i < size; i++)
		if (matrix[i][i] > maxVal)
			maxVal = matrix[i][i];
			
	/* use max value to normalize matrix */
	for (i = 0; i < size; i++)		
		for (j = 0; j < size; j++)
			matrix[i][j] /= maxVal;
	return;
}

void copyMatrix(float4matrix a, float4matrix b, int n)
{
	int			i,j;
	
	for(i=0; i<n; i++)
		for(j=0; j<n; j++)
			b[i][j] = a[i][j];
	return;
}

void showMatrix(float4matrix matrix, int n)
{
	int			i,j;
	
	for(i=0; i<n; i++) {
		for(j=0; j<n; j++)
			printf("%f  ", matrix[i][j]);
		printf("\n");
	}
	return;
}

void normalizeSpecMatrix(float4matrix matrix, int n)
{
	/* each column of the matrix corresponds to a dye 
	 * profile across the spectral channels.
	 * row=spec, col=dye. Normalize each dye so strongest spec
	 * signal for each dye is 1.0
	 */
	int				i,j;
	float			r;

	/* find maximum value in each column of matrix */
	for(j=0; j<n; j++) {
		r=0.0;
		for (i = 0; i < n; i++)
				r += matrix[i][j] * matrix[i][j];
		r = sqrt(r);
		for (i = 0; i < n; i++)		
				matrix[i][j] /= r;
	}
	return;
}

void OLDnormalizeSpecMatrix(float4matrix matrix, int n)
{
	/* each column of the matrix corresponds to a dye 
	 * profile across the spectral channels.
	 * row=spec, col=dye. Normalize each dye so strongest spec
	 * signal for each dye is 1.0
	 */
	int				i,j;
	float			maxVal=-FLT_MAX;

	/* find maximum value in each column of matrix */
	for(j=0; j<n; j++) {
		maxVal=-FLT_MAX;
		for (i = 0; i < n; i++)
			if (matrix[i][j] > maxVal)
				maxVal = matrix[i][j];
				
		for (i = 0; i < n; i++)		
				matrix[i][j] /= maxVal;
	}
	return;
}


/******
*
* W.W. Hager Matrix manipulation routines
*
******/
void vectorTimesMatrix(float *vector, float4matrix matrix, int numChannels)
{
	float  					  temp[8];
	register int 			i,j;

	for (i = 0; i < numChannels; i++) {
		temp[i] = 0.0;
		for(j=0; j<numChannels; j++) {
			temp[i] += vector[j] * matrix[i][j];
		}
	}
	for(j=0; j<numChannels; j++)
		vector[j] = temp[j];
	return;
}

void LU_factorMatrix(float4matrix matrixIn, float4matrix luMatrix, int n)
{
	/* from Hager W.W.(1988) Applied Numerical Linear Algebra p59 */
	
	int			i,j,k;
	int			nm1, kp1;
	float		t;
	
	/* first copy matrixIn into luMatrix, since algorithm operates and
	 * replaces the matrix it operates on */
	for(i=0; i<n; i++) 
		for(j=0; j<n; j++) 
			luMatrix[i][j] = matrixIn[i][j];
	
	/* row elimination of matrix */
	nm1 = n-1;
	for(k=0; k<nm1; k++) {
		kp1 = k + 1;
		t = luMatrix[k][k];
		for(i=kp1; i<n; i++)
			luMatrix[i][k] = luMatrix[i][k]/t;
		for(j=kp1; j<n; j++) {
			t = luMatrix[k][j];
			for(i=kp1; i<n; i++)
				luMatrix[i][j] = luMatrix[i][j] - luMatrix[i][k]*t;
		}
	}
	return;
}

void forwardSubstitute(float4matrix luMatrix, int n, float* b)
{
	/* from Hager W.W.(1988) Applied Numerical Linear Algebra p50 */
	/* converted from fortran */
	/* to solve Ly=b for y.  The result y is returned in vector b */
	
	int			i, j, im1;
	float		t;
	
	for(i=2; i<=n; i++) {
		im1 = i - 1;
		t = b[i-1];
		for(j=1; j<=im1; j++)
			t = t - luMatrix[i-1][j-1] * b[j-1];
		b[i-1] = t;
	}
	return;
}

void backSubstitute(float4matrix luMatrix, int n, float* y)
{
	/* from Hager W.W.(1988) Applied Numerical Linear Algebra p50 */
	/* converted from fortran */
	/* to solve Ux=y for x.  The result x is returned in vector y */
	
	int			i, ip1, j;
	float		t;
	
	y[n-1] = y[n-1]/luMatrix[n-1][n-1];
	for(i=n-2; i>=0; i--) {
		ip1 = i + 1;
		t = y[i];
		for(j=ip1; j<n; j++)
			t = t - luMatrix[i][j] * y[j];
		y[i] = t / luMatrix[i][i];
	}
	return;
}

void invertMatrix2(float4matrix matrix, float4matrix invMatrix, int n)
{
	/* Invert matrix 'matrix' by successively solving Ax=b
	 * where b is successive columns from the identity matrix
	 * The inverse of A will be created by combining the series 
	 * of 'x' vectors from above into a matrix. */
	int							row, col;
	float4matrix		luMatrix;
	float					 	tempCol[4];

	//printf("original matrix\n");
	//showMatrix(matrix, n);
	
	LU_factorMatrix(matrix, luMatrix, n);
	//printf("LU matrix\n");
	//showMatrix(luMatrix, n);
	
	for(col=0; col<n; col++) {
		/* setup 'b' to the appropriate column of the identity matrix */
		for(row=0; row<n; row++) {
			tempCol[row] = 0.0;
		}
		tempCol[col] = 1.0;
		/*
		tempCol[0] = 4.0;
		tempCol[1] = 13.0;
		tempCol[2] = 7.0;
		tempCol[3] = 0.0;
		printf("I col:%d = ",col);
		for(row=0; row<n; row++) printf("%f  ",tempCol[row]);
		printf("\n");
		*/

		forwardSubstitute(luMatrix, n, tempCol);	/* for solving Ly=b */
		backSubstitute(luMatrix, n, tempCol);		/* for solving Ux=y */

		/* then copy the inverse solution for that column into the invMatrix */
		for(row=0; row<n; row++) {
			invMatrix[row][col] = tempCol[row];
		}
	}
	//printf("inverse matrix\n");
	//showMatrix(invMatrix, n);
	
	/****
	matrixMultiply(matrix, invMatrix, luMatrix, n);
	printf("A * A-1 = I?\n");
	showMatrix(luMatrix, n);
	****/
	return;
}


