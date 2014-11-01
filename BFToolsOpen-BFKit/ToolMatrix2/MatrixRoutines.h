/* "$Id: MatrixRoutines.h,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */

#import <stdlib.h>
#import <stdio.h>
#import <objc/objc.h>


typedef float float8matrix[8][8];		/* 8x8 float array to hold variable sized matrixes */
typedef float float4matrix[4][4];		/* 4x4 float array */


/*** new variable channel routines ***/
void LU_factorMatrix(float4matrix matrixIn, float4matrix luMatrix, int n);
void forwardSubstitute(float4matrix luMatrix, int n, float* b);	/* for solving Ly=b */
void backSubstitute(float4matrix luMatrix, int n, float* y);		/* for solving Ux=y */
void invertMatrix2(float4matrix matrix, float4matrix invMatrix, int n);
void vectorTimesMatrix(float *vector, float4matrix matrix, int numChannels);

/*** general purpose routines ***/
void matrixMultiply(float4matrix m1, float4matrix m2, float4matrix m3, int size);
void copyMatrix(float4matrix a, float4matrix b, int n);
void showMatrix(float4matrix matrix, int n);
void normalizeSpecMatrix(float4matrix matrix, int n);
