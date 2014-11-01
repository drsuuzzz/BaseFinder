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

extern int ngauss;


float fitgauss(float list[], long len, long start, long end,
               float *sigma, float *mean, float *scale);

void gausfit(float x[],float y[],int ndata,float *scale,float *mean,float *sigma);
float specialgausfit(float x[],float y[],int ndata,float *scale,float *mean,float *sigma);

void stats(float data[], int ndata, float *mean, float *sdev, float *hival, float *loval);
