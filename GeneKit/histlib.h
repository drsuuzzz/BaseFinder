/*This was found on the internet circa 1992-93 as an ftp download, with no 
specific copyright notice attached. It has been modified slightly for our purposes. 
Some routines resemble some from Numerical Recipies, and it is not clear whether they were copied
directly or independently derived, and further, what the licensing status was at the time they
were downloaded. 
USE AT YOUR OWN RISK.  WE MAKE NO WARRANTIES REGARDING THIS FILE WHATSOEVER, INCLUDING ITS 
LEGAL STATUS OR YOUR RIGHT (OR NON RIGHT) TO USE IT.
*/
/* Finding a replacement for these routines to clear up the licensing question on this file is a high priority.
*/

void eiginit(double **eigmat,int dim);
void eiginit_zero(double **eigmat,int dim);
void mat_print(float **mat,int dim);
void nrerror(char error_text[]);
float *vector(int nl,int nh);
int *ivector(int nl,int nh);
void free_ivector(int* v,int nl,int nh);
void initvec(double *vec,int dim);
void free_vector(float *v,int nl,int nh);
void free_matrix(float **m,int nrl,int nrh,int ncl,int nch);
float **matrix(int nrl,int nrh,int ncl,int nch);
