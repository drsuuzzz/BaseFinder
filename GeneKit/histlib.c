/*This was found on the internet circa 1992-93 as an ftp download, with no 
specific copyright notice attached. It has been modified slightly for our purposes. 
Some routines resemble some from Numerical Recipies, and it is not clear whether they were 
copied directly or independently derived, and further, what the licensing status was at 
the time they were downloaded. 
USE AT YOUR OWN RISK.  WE MAKE NO WARRANTIES REGARDING THIS FILE WHATSOEVER, INCLUDING ITS 
LEGAL STATUS OR YOUR RIGHT (OR NON RIGHT) TO USE IT.
*/
/* Finding a replacement for these routines to clear up the licensing question on this file is a high priority.
*/

#include <stdio.h>
#include <stdlib.h>

/*--------------------------------------------------------------------------*/
/* initializes a matrix of dimension 'dim' to be the identity matrix        */
/*--------------------------------------------------------------------------*/

void eiginit(eigmat,dim)
double **eigmat;
int dim;
{
int i,j;
for(i=1;i<=dim;i++)
	{
	for(j=1;j<=dim;j++)
		{
		if(i==j)
			eigmat[i][j] = 1.0;
		else
			eigmat[i][j] = 0.0;
		}

	}

}



/*--------------------------------------------------------------------------*/
/* initializes a matrix of dimension 'dim' to be the zero matrix            */
/*--------------------------------------------------------------------------*/

void eiginit_zero(eigmat,dim)
double **eigmat;
int dim;
{
int i,j;
for(i=1;i<=dim;i++)
	{
	for(j=1;j<=dim;j++)
		{
		eigmat[i][j] = 0.0;
		}

	}

}

/*------------------------------------------------------------------------*/
/*  matrix multiplication routine					  */
/*------------------------------------------------------------------------*/
/*double mat_mult(in_mat,out_mat,dim)
double **in_mat,**out_mat;
int dim;
{
double **temp_mat;
int i,j,k;
void mat_print();

temp_mat = dmatrix(1,dim,1,dim);
eiginit_zero(temp_mat,dim);

for(i=1;i<=dim;i++)
	{
	for(j=1;j<=dim;j++)
		{
		for(k=1;k<=dim;k++)
			{
			temp_mat[i][j] += in_mat[i][k]*out_mat[k][j];
			}
		}
	}

for(i=1;i<=dim;i++)
	{
	for(j=1;j<=dim;j++)
		{
		out_mat[i][j] = temp_mat[i][j];
		}
	}

}*/

/*---------------------------------------------------------------------------*/
/* This prints a matrix of dimension dim				     */
/*---------------------------------------------------------------------------*/
void mat_print(mat,dim)
float **mat;
int dim;
{
int i,j;

printf("\n");

for(i=1;i<=dim;i++)
	{
	for(j=1;j<=dim;j++)
		{
		printf("%f ",mat[i][j]);
		}
	printf("\n");
	}
}

/*-------------------------------------------------------------------------*/
/* nrerror is a Numerical Recipes subroutine				   */
/*-------------------------------------------------------------------------*/
void nrerror(error_text)
char error_text[];
{
	/*void exit();*/

	printf("run time error ... \n");
	printf("%s\n",error_text);
	printf("...now exiting to system...\n");
	exit(1);
}
/*------------------------------------------------------------------------*/
/* *vector() allocates a vector from index nl of dimension nh		  */
/*------------------------------------------------------------------------*/
float *vector(nl,nh)
int nl,nh;
{
	float *v;

	v=(float *)malloc((unsigned) (nh-nl+1)*sizeof(float));
	if (!v) nrerror("allocation failure in vector()");
	return v-nl;
}
/*------------------------------------------------------------------------*/
/* *ivector() allocates a vector from index nl of dimension nh	  */
/*------------------------------------------------------------------------*/
int *ivector(nl,nh)
int nl,nh;
{
	int *v;

	v=(int *)malloc((unsigned) (nh-nl+1)*sizeof(int));
	if (!v) nrerror("allocation failure in ivector()");
	return v-nl;
}

/*------------------------------------------------------------------------*/
/* free_ivector() is a Numerical Recipes subroutine			  */
/*------------------------------------------------------------------------*/
void free_ivector(v,nl,nh)
int *v;
int nl,nh;
{
	free((char*) (v+nl));
}

/*------------------------------------------------------------------------*/
/* initvec() initializes a vector of dimention dim to all values zero     */
/*------------------------------------------------------------------------*/
void initvec(vec,dim)
double *vec;
int dim;
{
int i;
for(i=1;i<=dim;i++)
	vec[i] = 0.0;

}

/*------------------------------------------------------------------------*/
/* free_vector() is a Numerical Recipes subroutine			  */
/*------------------------------------------------------------------------*/
void free_vector(v,nl,nh)
float *v;
int nl,nh;
{
	free((char*) (v+nl));
}
/*------------------------------------------------------------------------*/
/* free_matrix() is a Numerical Recipes subroutine			  */
/*------------------------------------------------------------------------*/
void free_matrix(m,nrl,nrh,ncl,nch)
float **m;
int nrl,nrh,ncl,nch;
{
	int i;

	for(i=nrh;i>=nrl;i--)
		free((char*) (m[i]+ncl));
	free((char*) (m+nrl));
}

/*------------------------------------------------------------------------*/
/* **dmatrix allocates a double matrix from nrl and ncl to dimensions	  */
/*   	nrh and nch							  */
/*------------------------------------------------------------------------*/
float **matrix(nrl,nrh,ncl,nch)
int nrl,nrh,ncl,nch;
{
	int i;
	float **m;

	m=(float **) malloc((unsigned) (nrh-nrl+1)*sizeof(float*));
	if (!m) nrerror("allocation failure 1 in dmatrix()");
	m -= nrl;

	for(i=nrl;i<=nrh;i++) {
		m[i]=(float *) malloc((unsigned) (nch-ncl+1)*sizeof(float));
		if (!m[i]) nrerror("allocation failure 2 in matrix()");
		m[i] -= ncl;
	}
	return m;
}
/*-------------------------------------------------------------------------*/
