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
 
#include <stdio.h>
#include <math.h>
#include <limits.h>
#include <GeneKit/histlib.h>
#include <GeneKit/ghist.h>
#include <Foundation/Foundation.h>

int ngauss;

float minValDBL(double *array, int numPoints)
{
	float min=1e+30;
	int i;
	
	for (i = 0; i < numPoints; i++) {
		if (array[i] < min)
			min = (float)array[i];
	}
	return min;
}


/*------------------------------------------------------------*/
void gausfit(x,y,ndata,scale,mean,sigma)
float x[],y[],*scale,*mean,*sigma;
int ndata;
{
float *sig,*a;
float **covar,**alpha;
float chisq,chi_pre,alamda,alamd_pre;
int ma,mfit,*lista,i,j;

float *vector(),**matrix();
int *ivector();
void fgauss();
void mrqmin();
FILE *finit;

printf("gaussFit nPoints=%d, scale=%f, mean=%f, sigma=%f\n", ndata,*scale,*mean,*sigma);
for(i=1; i<=ndata; i++) {
	//printf(" %f  %f\n", x[i], y[i]);
}

ma = 3*ngauss;	 /* number of parameters available to fit */
mfit = 3*ngauss; /* number of parameters to fit */


/* allocate memory for matrices and vectors */
covar = matrix(1,ma,1,ma);
alpha = matrix(1,ma,1,ma);

sig = vector(1,ndata);	/* array of sigma's for each point */
a = vector(1,ma);	/* values of parameters:
			   scale = a[1]
			   mean = a[2]
			   sigma = a[3] */
			   
lista = ivector(1,ma);	/* parameters to fit:
			   1 1 1 mean fit all
			   three parameters */

for(i=1;i<=ndata;i++)	/* set sigma's to 1.0 */
	sig[i] = 1.0;	   

/* set initial parameters */
a[1] = *scale;
a[2] = *mean;
a[3] = *sigma;

if(ngauss != 1) {
	if((finit=fopen("initial_val.dat","r"))==NULL) {
		fprintf(stderr,"Cannot open file");
		exit(1);
	}
	i=1;
	while(fscanf(finit,"%f %f %f\n",&a[i],&a[i+1],&a[i+2]) != EOF)
		i+=3;
}

for(i=1;i<=ma;i++)
	lista[i] = i;

alamda = -1.0;
mrqmin(x,y,sig,ndata,a,ma,lista,mfit,covar,alpha,&chisq,fgauss,&alamda);
chi_pre = chisq;
alamd_pre = 0.0;

j = 0;
for(i=0;i<=30;i++)
/*while( (alamda > alamd_pre) || (fabs(chisq - chi_pre) > 0.01) && (j < 30) )*/
	{
	chi_pre = chisq;
	alamd_pre = alamda;
	j++;
	mrqmin(x,y,sig,ndata,a,ma,lista,mfit,covar,alpha,&chisq,fgauss,&alamda);
	/*fprintf(stderr,"alamda=%f,chisq=%f,hgt=%f,mean=%f,sdev=%f\n",alamda,chisq,a[1],a[2],a[3]);*/
	}

*scale = a[1];
*mean = a[2];
*sigma = a[3];
/* *sigma = a[3]/sqrt(2.0); for doing standard variance*/

for(i=1;i<=3*ngauss;i+=3)
	fprintf(stderr,"N = %f, mean = %f, sig = %f, ndata = %d chi2 = %f\n",
			a[i],a[i+1],a[i+2],ndata,chisq );


}

float specialgausfit(x,y,ndata,scale,mean,sigma)
float x[],y[],*scale,*mean,*sigma;
int ndata;
{
  float *sig,*a;
  float **covar,**alpha;
  float chisq,chi_pre,alamda,alamd_pre;
  int ma,mfit,*lista,i,j;

  float *vector(),**matrix();
  int *ivector();
  void fgauss();
  void mrqmin();
  //FILE *finit;

//  printf("gaussFit nPoints=%d, scale=%f, mean=%f, sigma=%f\n", ndata,*scale,*mean,*sigma);
//  for(i=1; i<=ndata; i++) {
//    printf(" %f  %f\n", x[i], y[i]);
//  }

  ngauss=1;
  ma = 3*ngauss;	 /* number of parameters available to fit */
  mfit = 3*ngauss; /* number of parameters to fit */


  /* allocate memory for matrices and vectors */
  covar = matrix(1,ma,1,ma);
  alpha = matrix(1,ma,1,ma);

  sig = vector(1,ndata);	/* array of sigma's for each point */
  a = vector(1,ma);	/* values of parameters:
    scale = a[1]
    mean = a[2]
    sigma = a[3] */

  lista = ivector(1,ma);	/* parameters to fit:
    1 1 1 mean fit all
    three parameters */

  for(i=1;i<=ndata;i++)	/* set sigma's to 1.0 */
    sig[i] = 1.0;	

  /* set initial parameters */
  a[1] = *scale;
  a[2] = *mean;
  a[3] = *sigma;

  //if(ngauss != 1) {
  //	if((finit=fopen("initial_val.dat","r"))==NULL) {
  //		fprintf(stderr,"Cannot open file");
  //		exit(1);
  //	}
  //	i=1;
  //	while(fscanf(finit,"%f %f %f\n",&a[i],&a[i+1],&a[i+2]) != EOF)
  //		i+=3;
  //}

for(i=1;i<=ma;i++)
  lista[i] = i;

alamda = -1.0;
mrqmin(x,y,sig,ndata,a,ma,lista,mfit,covar,alpha,&chisq,fgauss,&alamda);
chi_pre = chisq;
alamd_pre = 0.0;

//for(i=0;i<=30;i++)

j = 0;
while( (alamda > alamd_pre) || ((fabs(chisq - chi_pre) > 0.01) && (j < 30)) )
  {
  chi_pre = chisq;
  alamd_pre = alamda;
  j++;
  mrqmin(x,y,sig,ndata,a,ma,lista,mfit,covar,alpha,&chisq,fgauss,&alamda);
  //fprintf(stderr,"alamda=%f,chisq=%f,hgt=%f,mean=%f,sdev=%f\n",alamda,chisq,a[1],a[2],a[3]);
  }


*scale = a[1];
*mean = a[2];
*sigma = a[3];
/* *sigma = a[3]/sqrt(2.0); for doing standard variance*/

//for(i=1;i<=3*ngauss;i+=3)
//  fprintf(stderr,"N = %f, mean = %f, sig = %f, ndata = %d chi2 = %f\n",
//          a[i],a[i+1],a[i+2],ndata,chisq );

return chisq;
}

/*-----------------------------------------------------------------------*/
void mrqmin(x,y,sig,ndata,a,ma,lista,mfit,covar,alpha,chisq,fgauss,alamda)
float x[],y[],sig[],a[],**covar,**alpha,*chisq,*alamda;
int ndata,ma,lista[],mfit;
void (*fgauss)();
{
  int k,kk,j,ihit;
  static float *da,*atry,**oneda,*beta,ochisq;
  float *vector(),**matrix();
  void mrqcof(),gaussj(),covsrt(),nrerror(),free_matrix(),free_vector();

  if (*alamda < 0.0) {
    oneda=matrix(1,mfit,1,1);
    atry=vector(1,ma);
    da=vector(1,ma);
    beta=vector(1,ma);
    kk=mfit+1;
    for (j=1;j<=ma;j++) {
      ihit=0;
      for (k=1;k<=mfit;k++)
        if (lista[k] == j) ihit++;
      if (ihit == 0)
        lista[kk++]=j;
      else if (ihit > 1) [NSException raise:@"NSRangeException" format:@"Bad LISTA permutation in MRQMIN-1"];
        //nrerror("Bad LISTA permutation in MRQMIN-1");
    }
    if (kk != ma+1) [NSException raise:@"NSRangeException" format:@"Bad LISTA permutation in MRQMIN-2"];
      //nrerror("Bad LISTA permutation in MRQMIN-2");
    *alamda=0.001;
    mrqcof(x,y,sig,ndata,a,ma,lista,mfit,alpha,beta,chisq,fgauss);
    ochisq=(*chisq);
  }
 	for (j=1;j<=mfit;j++) {
          for (k=1;k<=mfit;k++) covar[j][k]=alpha[j][k];
          covar[j][j]=alpha[j][j]*(1.0+(*alamda));
          oneda[j][1]=beta[j];
        }
  gaussj(covar,mfit,oneda,1);
  for (j=1;j<=mfit;j++)
    da[j]=oneda[j][1];
  if (*alamda == 0.0) {
    covsrt(covar,ma,lista,mfit);
    free_vector(beta,1,ma);
    free_vector(da,1,ma);
    free_vector(atry,1,ma);
    free_matrix(oneda,1,mfit,1,1);
    return;
  }
  for (j=1;j<=ma;j++) atry[j]=a[j];
  for (j=1;j<=mfit;j++)
    atry[lista[j]] = a[lista[j]]+da[j];
  mrqcof(x,y,sig,ndata,atry,ma,lista,mfit,covar,da,chisq,fgauss);
  if (*chisq < ochisq) {
    *alamda *= 0.1;
    ochisq=(*chisq);
    for (j=1;j<=mfit;j++) {
      for (k=1;k<=mfit;k++) alpha[j][k]=covar[j][k];
      beta[j]=da[j];
      a[lista[j]]=atry[lista[j]];
    }
  } else {
    *alamda *= 10.0;
    *chisq=ochisq;
  }
  return;
}


/*------------------------------------------------------------------*/
void mrqcof(x,y,sig,ndata,a,ma,lista,mfit,alpha,beta,chisq,fgauss)
float x[],y[],sig[],a[],**alpha,beta[],*chisq;
int ndata,ma,lista[],mfit;
void (*fgauss)();	/* ANSI: void (*funcs)(float,float *,float *,float *,int); */
{
	int k,j,i;
	float ymod,wt,sig2i,dy,*dyda,*vector();
	void free_vector();

	dyda=vector(1,ma);
	for (j=1;j<=mfit;j++) {
		for (k=1;k<=j;k++) alpha[j][k]=0.0;
		beta[j]=0.0;
	}
	*chisq=0.0;
	for (i=1;i<=ndata;i++) {
		(*fgauss)(x[i],a,&ymod,dyda,ma);
		sig2i=1.0/(sig[i]*sig[i]);
		dy=y[i]-ymod;
		for (j=1;j<=mfit;j++) {
			wt=dyda[lista[j]]*sig2i;
			for (k=1;k<=j;k++)
				alpha[j][k] += wt*dyda[lista[k]];
			beta[j] += dy*wt;
		}
		(*chisq) += dy*dy*sig2i;
	}
	for (j=2;j<=mfit;j++)
		for (k=1;k<=j-1;k++) alpha[k][j]=alpha[j][k];
	/*free_vector(dyda,1,ma);*/
}

/*--------------------------------------------------------------------------*/
#define SWAP(a,b) {float temp=(a);(a)=(b);(b)=temp;}

void gaussj(a,n,b,m)
float **a,**b;
int n,m;
{
  int *indxc,*indxr,*ipiv;
  int i,icol=0,irow=0,j,k,l,ll,*ivector();
  float big,dum,pivinv;
  void nrerror(),free_ivector();

  indxc=ivector(1,n);
  indxr=ivector(1,n);
  ipiv=ivector(1,n);
  for (j=1;j<=n;j++) ipiv[j]=0;
  for (i=1;i<=n;i++) {
    big=0.0;
    for (j=1;j<=n;j++) {
      if (ipiv[j] != 1) {
        for (k=1;k<=n;k++) {
          if (ipiv[k] == 0) {
            if (fabs(a[j][k]) >= big) {
              big=fabs(a[j][k]);
              irow=j;
              icol=k;
            }
          } else if (ipiv[k] > 1) [NSException raise:@"NSRangeException" format:@"GAUSSJ: Singular Matrix-1"];
            //nrerror("GAUSSJ: Singular Matrix-1");
        }
      }
    }
    ++(ipiv[icol]);
    if (irow != icol) {
      for (l=1;l<=n;l++) { SWAP(a[irow][l],a[icol][l]) }
      for (l=1;l<=m;l++) { SWAP(b[irow][l],b[icol][l]) }
    }
    indxr[i]=irow;
    indxc[i]=icol;
    if (a[icol][icol] == 0.0) [NSException raise:@"NSRangeException" format:@"GAUSSJ: Singular Matrix-2"];
      //nrerror("GAUSSJ: Singular Matrix-2");
    pivinv=1.0/a[icol][icol];
    a[icol][icol]=1.0;
    for (l=1;l<=n;l++) a[icol][l] *= pivinv;
    for (l=1;l<=m;l++) b[icol][l] *= pivinv;
    for (ll=1;ll<=n;ll++) {
      if (ll != icol) {
        dum=a[ll][icol];
        a[ll][icol]=0.0;
        for (l=1;l<=n;l++) a[ll][l] -= a[icol][l]*dum;
        for (l=1;l<=m;l++) b[ll][l] -= b[icol][l]*dum;
      }
    }
  }

  for (l=n;l>=1;l--) {
    if (indxr[l] != indxc[l]) {
      for (k=1;k<=n;k++) {
        SWAP(a[k][indxr[l]],a[k][indxc[l]]);
      }
    }
  }
  free_ivector(ipiv,1,n);
  free_ivector(indxr,1,n);
  free_ivector(indxc,1,n);
}

#undef SWAP

/*-----------------------------------------------------------------------*/
void covsrt(covar,ma,lista,mfit)
float **covar;
int ma,lista[],mfit;
{
	int i,j;
	float swap;

	for (j=1;j<ma;j++)
		for (i=j+1;i<=ma;i++) covar[i][j]=0.0;
	for (i=1;i<mfit;i++)
		for (j=i+1;j<=mfit;j++) {
			if (lista[j] > lista[i])
				covar[lista[j]][lista[i]]=covar[i][j];
			else
				covar[lista[i]][lista[j]]=covar[i][j];
		}
	swap=covar[1][1];
	for (j=1;j<=ma;j++) {
		covar[1][j]=covar[j][j];
		covar[j][j]=0.0;
	}
	covar[lista[1]][lista[1]]=swap;
	for (j=2;j<=mfit;j++) covar[lista[j]][lista[j]]=covar[1][j];
	for (j=2;j<=ma;j++)
		for (i=1;i<=j-1;i++) covar[i][j]=covar[j][i];
}

/*------------------------------------------------------------*/
void fgauss(x,a,y,dyda,na)
float x,a[],*y,dyda[];
int na;
{
	int i;
	float fac,ex,arg;

	*y=0.0;
	for (i=1;i<=na-1;i+=3)
	{
		arg=(x-a[i+1])/a[i+2];
		ex=exp(-arg*arg);
		fac=a[i]*ex*2.0*arg;
		*y += a[i]*ex;
		dyda[i]=ex;
		dyda[i+1]=fac/a[i+2];
		dyda[i+2]=fac*arg/a[i+2];
	}
}
/*---------------------------------------------*/
void stats(data,ndata,mean,sdev,hival,loval)
float data[],*mean,*sdev,*hival,*loval;
int ndata;
{
int i,ngood;

if (ndata <= 1)
	{
	//fprintf(stderr,"ndata must be at least 2 in stats\n");
	//exit(-1);
  [NSException raise:@"NSRangeException" format:@"ndata must be at least 2 in stats"];
	}
*mean = 0.0;
*hival = data[0];
*loval = data[0];
ngood = 0;
for(i=0;i<ndata;i++)
	{
	if(data[i] > *hival) {
		*hival = data[i];
		*mean = i;
	}
	if(data[i] < *loval)
		*loval = data[i];
	}
}

float fitgauss(float list[], long len, long start, long end,
              float *sigma, float *mean, float *scale)
{
  float *x, *y, min, hival, loval, chisq;
  int i;

//  fprintf(stderr, "here\n");
  x = vector(1, end-start);
  y = vector(1, end-start);
  min = 0;
  //	min = minValDBL(&(list[start]), end-start);
  for (i = 1; i <= (end-start); i++) {
    x[i]=i;
    y[i]=(float)list[start + i] - min;
    }

  stats(y,end-start,mean,sigma,&hival,&loval);
  *scale=hival;
  *sigma=(end-start)/2.0;
  chisq = specialgausfit(x,y,end-start,scale,mean,sigma);
  free_vector(x, 1, end-start);
  free_vector(y, 1, end-start);
  *sigma = (float)fabs((float)*sigma);
  *mean += (float)start;
  return chisq;
  
}
