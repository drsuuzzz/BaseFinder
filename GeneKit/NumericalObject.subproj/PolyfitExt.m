/* "$Id: PolyfitExt.m,v 1.4 2007/06/04 21:34:55 smvasa Exp $" */
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

#import <PolyfitExt.h>


@implementation NumericalObject(PolyfitExt)


- (float)polyFitFunction:(float)x :(int)np
{	
  //was polyx
  int i;
  float result = 1;

  for (i = 0; i < np; i++)
    result *= x;

  return result;
}


- (void)polyFit:(float*)arrayX :(float*)arrayY :(float*)sig :(int)numPoints :(float*)coeffecients :(int)numCoeff
{	
  [self myfit:arrayX :arrayY :sig :numPoints :coeffecients :numCoeff :self];	
}  	


- (void)myfit:(float*)x :(float*)y :(float*)sig :(int)n :(float*)a
             :(int)m :(id)polyFuncObj
{
  //The polyFuncObj needs to implement the method
  // - polyFitFunction:(float)x :(int)np;
  
  float alpha[m][m], beta[m];
  int i,j,k;
  float sum;

  for (k = 0; k < m; k++) {
    for (j = 0; j < m; j++) {
      sum = 0;
      for (i = 0; i < n; i++)
        sum += [polyFuncObj polyFitFunction:x[i] :j] * [polyFuncObj polyFitFunction:x[i] :k]/sig[i];
      alpha[k][j] = sum;
    }
    sum = 0;
    for (i=0; i < n; i++)
      sum += y[i] * [polyFuncObj polyFitFunction:x[i] :k]/sig[i];
    beta[k] = sum;
  }

  [self mygaussj:(float **)alpha :m :m :(float *)beta :a];
}
		
	
- (void)mygaussj:(float**)A :(int)m :(int)n :(float*)b :(float*)x
{
  /* Performs gauss-jordan elimination on a matrix.
  n = cols
  m = rows
  A[m][n]
  */

  float               (*a)[n], B[m][n];
  int                 i, j, k;
  int                 reorder[m];
  float               max_col, max_row, pivot, mult, sum;
  int                 pivot_row = 0, tmp, row;

	a = (float**)A;
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

@end
