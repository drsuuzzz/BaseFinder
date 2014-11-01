/***********************************************************

Copyright (c) 2006 Suzy Vasa 

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
NIH Cystic Fibrosis


******************************************************************/

#import "ToolTRFLP.h"
#import <GeneKit/NumericalObject.h>
#include <GeneKit/ghist.h>
#include <GeneKit/histlib.h>
#include <GeneKit/lmmin.h>
#include <GeneKit/lm_eval.h>

#define lenCustom 26
#define lenROX500 16
#define lenROX1000 17

typedef struct differ {
  int diff;
  int index;
  float height;
  int marker;
} myDiff;

int ROX500[16] = {
  35, 50, 75, 100, 139, 150, 160, 200, 250, 300, 340, 350, 400, 450, 490, 500
};

//int ROX500Len = 16;

int ROX1000[17] = {
  29, 33, 37, 64, 67, 75, 81, 108, 118, 244, 293, 299, 421, 539, 674, 677, 926
};

//int ROX1000Len = 17;

int Custom[26] = {
  25, 30, 40, 50, 75, 100, 125, 150, 200, 250, 300, 350, 400, 450, 475, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000
};
/*0    1   2   3   4   5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25*/

//int CustomLen = 26;


@interface ToolTRFLP (Private)
- (void)setupMyPointers;
- (void)clearMyPointers;
- (int) findLeftInflection:(int)center :(float *)listofD;
- (int) findRightInflection:(int)center :(float *)listofD;
- (void)findPeakBase:(int)chan :(float *)derivative;
- (void)findPeakAreas:(int)chan :(float *)derivative;
- (void)firstDerivative:(int)chan :(float *)derivative;
-(void) primerCorrection:(float *)peaksBlue :(float *)peaksGreen :(float *)peaksRed;
- (void)calculatePeak:(float *)center :(float *)scale :(float *)width :(int)peak :(int)channel :(int)startpos :(int)endpos;
- (void)outputPeaks;
- (void)setupMarkers;
- (void)markers500ROX:(myDiff *)differences;
- (void)markers1000ROX:(myDiff *)differences;
- (void)markers1000ROX:(myDiff *)differences;
-(void)markersCustom:(myDiff *)differences;
-(void)cubicSpline:(double *)x :(double *)y :(int)N :(double *)inX :(int)countIn :(double *)fOfX;
-(void)outAndDiffs:(myDiff *)differences;
@end

@implementation ToolTRFLP

-init
{
  [super init];
  
  myOutFile = nil;
  markerBases = nil;
  peakAreas = nil;
  X = NULL;
  Y = NULL;
  numPairs = 0;
  standard = nil;
  threshold[0] = 20.0;
	threshold[1] = 20.0;
	pstate = 1;
  return self;
}

- (void)dealloc
{
  if (myOutFile != nil)
    [myOutFile release];
  if (markerBases != nil)
    [markerBases release];
  if (peakAreas != nil)
    [peakAreas release];
  if (X != NULL) {
    free(X);
    free(Y);
  }
  if (standard != nil)
    [standard release];
  [super dealloc];
}

- (NSString *)toolName
{
  return @"T-RFLP";
}

- (BOOL)shouldCache 
{ 
  return YES; 
}

- apply
{
	float	*derivBlue, *derivGreen, *derivRed;

  [self setStatusPercent:0.0]; //don't use, just make sure it's cleared
  [self setStatusMessage:@"Calculating Peaks"];
  
	[self setupMyPointers];
    
	derivBlue = (float *)calloc([dataList length], sizeof(float)); 
	derivGreen = (float *)calloc([dataList length], sizeof(float)); 
	derivRed = (float *)calloc([dataList length], sizeof(float)); 
  [self firstDerivative:0 :derivBlue];
	[self firstDerivative:1 :derivGreen];
	[self firstDerivative:3 :derivRed];
	if (pstate)
		[self primerCorrection:derivBlue :derivGreen :derivRed];   //changes derivative
  [self findPeakAreas:0 :derivBlue]; //find 6fam peaks, gaussians
  [self findPeakAreas:1 :derivGreen]; //find hex peaks, gaussians
  [peakAreas sort];
  [self findPeakBase:3 :derivRed]; //find ROX peaks, bases
  
  [self setupMarkers];

  [self outputPeaks];
  
  [self setLadder:peakAreas];
  [self setBaseList:markerBases];
	[self clearMyPointers];
	free(derivBlue);
	free(derivGreen);
	free(derivRed);
  return [super apply];
}

- (void) setupMyPointers
{
	if(markerBases != nil) [markerBases release];
  markerBases = [[Sequence alloc] init];
  if (peakAreas != nil) [peakAreas release];
  peakAreas = [[EventLadder alloc] init];	
}

- (void) clearMyPointers
{
	if(markerBases != nil) [markerBases release];
  if (peakAreas != nil) [peakAreas release];
	markerBases = nil;
	peakAreas = nil;
}

/***
*
* Align 
*
***/
-(void)outputPeaks
{
  int              i, numPeaks;
  Gaussian         *thePeak;
  double           *input;
  double           *output;
  FILE             *fp;
	float						area1, area2;

  numPeaks = [peakAreas count];
  fp = fopen([myOutFile fileSystemRepresentation],"w");
  if (fp == NULL) return;
  fprintf(fp,"Channel\tPosition\tBase\tArea\tRel. Area\n");
  input = (double *) calloc (numPeaks,sizeof(double));
  if (input == NULL) {
    fclose(fp);
    return;
  }
  output = (double *)calloc (numPeaks,sizeof(double));
  if (output == NULL) {
    fclose(fp);
    return;
  }
  for (i = 0; i < numPeaks; i++) {
    thePeak = [peakAreas entryAtPosition:i];
    input[i] = (double)[thePeak center];
		output[i] = 0.0;
  }
  [self cubicSpline:Y :X :numPairs :input :numPeaks :output];
  /*printf("printing the peaks\n");
  for (i = 0; i < numPeaks; i++) {
    printf("%7.3f %7.3f\n",input[i], output[i]);
  }*/
	area1 = area2 = 0.0;
	for (i=0; i < numPeaks; i++) {
		thePeak = [peakAreas entryAtPosition:i];
		if ([thePeak channel] == 0) {
			if (output[i] != 0.0) 
				area1 = area1 + [thePeak area];
		}
		else if ([thePeak channel] == 1) {
			if (output[i] != 0.0)
				area2 = area2 + [thePeak area];
		}
	}
  for (i=0; i < numPeaks; i++) {
    thePeak = [peakAreas entryAtPosition:i];
    if ([thePeak channel] == 0) {           
      if (output[i] != 0.0)
			{
				[thePeak setAnnotation:[NSString stringWithFormat:@"%d",lroundf(output[i])]];
				fprintf(fp,"%d\t%7.3f\t%7.3f\t%7.3f\t%7.3f\n",[thePeak channel],[thePeak center],output[i],[thePeak area],[thePeak area]/area1);
			}
    }
  }
	fprintf(fp,"Total Area: %7.3f\n",area1);
  for (i=0; i < numPeaks; i++) {
    thePeak = [peakAreas entryAtPosition:i];
    if ([thePeak channel] == 1) {
      if (output[i] != 0) {
				[thePeak setAnnotation:[NSString stringWithFormat:@"%d",lroundf(output[i])]];
        fprintf(fp,"%d\t%7.3f\t%7.3f\t%7.3f\t%7.3f\n",[thePeak channel],[thePeak center],output[i],[thePeak area],[thePeak area]/area2);
			}
    }
  }
	fprintf(fp,"Total Area: %7.3f\n",area2);
  fclose(fp);
  free(input);
  free(output);
}

int compareHeight(myDiff *peak1, myDiff *peak2)
//biggest to smallest
{ 
  if (peak1->height < peak2->height)
    return 1;
  if (peak1->height > peak2->height)
    return -1;
  return 0;
}

int compareDiff(myDiff *peak1, myDiff *peak2)
//smallest to largest
{
  if (peak1->diff > peak2->diff)
    return 1;
  if (peak1->diff < peak2->diff)
    return -1;
  return 0;
}

int compareIdx(myDiff *peak1, myDiff *peak2)
//largest to smallest
{
  if (peak1->index < peak2->index)
    return 1;
  if (peak1->index > peak2->index)
    return -1;
  return 0;
}

-(void)cubicSpline:(double *)x :(double *)y :(int)N :(double *)inX :(int)countIn :(double *)fOfX
//this is an implementation of algorithm 3.4 from Numerical Analysis 8th Edition
{
    double *h,*a,*b,*c,*d;
    double *bVector;
    double *l,*u,*z;   
    int   i, j, spline;
    
	//allocate memory
	h = calloc(N,sizeof(double));
	a = calloc(N,sizeof(double));
	b = calloc(N,sizeof(double));
	c = calloc(N,sizeof(double));
	d = calloc(N,sizeof(double));
	bVector = calloc(N,sizeof(double));
	l = calloc(N,sizeof(double));
	u = calloc(N,sizeof(double));
	z = calloc(N,sizeof(double));
    for (i=0; i < N; i++) {
      h[i] = 0.0;
      a[i] = y[i];
      b[i] = 0.0;
      c[i] = 0.0;
      d[i] = 0.0;
    }    
    spline = 0;
    //step 1
    for (i = 0; i < N-1; i++) {
      h[i] = x[i+1] - x[i];
    }
    //step 2 
    for (i = 1; i < N-1; i++) {
      bVector[i] = (3/h[i])*(a[i+1] - a[i]) - (3/h[i-1])*(a[i] - a[i-1]);
    }
    //step 3, next steps are solving a tridiagonal linear system
    l[0] = 1;
    u[0] = 0;
    z[0] = 0;
    //step 4
    for (i = 1; i < N-1; i++) {
      l[i] = 2*(x[i+1] - x[i-1]) - h[i-1]*u[i-1];
      u[i] = h[i]/l[i];
      z[i] = (bVector[i] - h[i-1]*z[i-1])/l[i];
    }
    //step 5
    l[N-1] = 1;
    z[N-1] = 0;
    c[N-1] = 0;
    //step 6
    for (i = N-2; i >= 0; i--) {
      c[i] = z[i] - u[i]*c[i+1];
      b[i] = (a[i+1] - a[i])/h[i] - h[i]*(c[i+1] + 2*c[i])/3;
      d[i] = (c[i+1] - c[i])/(3*h[i]);
    }
    //step 7
		if ([self debugmode]) {
			NSLog(@"      a\t      b\t      c\t      d\n");
			for (i = 0; i < N; i++)
				NSLog(@"%7.3f\t%7.3f\t%7.3f\t%7.3f\n",a[i],b[i],c[i],d[i]);
		}
    for (j = 0; j < countIn; j++) {
      for (i = 0; i < N-1; i++) {
        if ((x[i] <= inX[j]) && (inX[j] <= x[i+1])) {
          spline = i;
          fOfX[j] = (a[spline] + b[spline]*(inX[j] - x[spline]) + 
                    c[spline]*(inX[j]-x[spline])*(inX[j]-x[spline]) + 
                    d[spline]*(inX[j]-x[spline])*(inX[j]-x[spline])*(inX[j]-x[spline]));
        
        }
      }
    }
	free(h);
	free(a);
	free(b);
	free(c);
	free(d);
	free(bVector);
	free(l);
	free(u);
	free(z);

}

-(void)outAndDiffs:(myDiff *)differences
//routine looks for outliers, removes them from the list of possible markers
//and returns the list of differences
{
  int			Q1,Q3;
	int			count, i;
  float		Q1Val, Q3Val, newdiff;
  
  //calculate differences between the peaks
  if (differences == NULL) return;
  count = [markerBases count];
  differences[0].diff = 0;
  differences[0].index = 0;
  differences[0].marker = 0;
  differences[0].height = 0.0;
  for (i=1; i < count; i++) {
    differences[i].diff = [[markerBases baseAt:i] location] - [[markerBases baseAt:i-1] location];
    differences[i].index = i;
    differences[i].marker = 0;
    differences[i].height = 0.0;
    if ([self debugmode]) NSLog(@"%d to %d %d\n",i-1,i,differences[i].diff);
  }
  qsort (differences,count,sizeof(myDiff),(void *)compareDiff);
  if ([self debugmode]) {
		NSLog(@"Sorted\n");
		for (i=1; i < count; i++)
			NSLog(@"index %d difference %d\n", differences[i].index, differences[i].diff);
	}
  
  Q1 = (count-1)/4;
	Q3 = (count-1)*3/4;
	if ((count-1)%4 != 0) {
				Q1++; Q3++;
	}
	Q1Val = differences[Q1].diff;  //first quartile cutoff
	Q3Val = differences[Q3].diff;  //third quartile cutoff
	for (i=1; i < Q1; i++) {
		newdiff = (differences[i].diff > Q1Val) ? (differences[i].diff-Q1Val) : 
																							((differences[i].diff < Q3Val) ? (Q3Val-differences[i].diff) : 0);
		if ((differences[i].index > 10) && 
				((abs(differences[i].index - differences[i+1].index) != 1) && (abs(differences[i].index - differences[i-1].index) != 1))
					&& (newdiff > (Q3Val-Q1Val)*1.5))
				[markerBases removeBaseAt:differences[i].index];
	}
	if (count != [markerBases count]) {
			count = [markerBases count];
			for (i=1; i < count; i++) {
				differences[i].diff = [[markerBases baseAt:i] location] - [[markerBases baseAt:i-1] location];
				differences[i].index = i;
				differences[i].marker = 0;
				differences[i].height = 0.0;
				if ([self debugmode]) NSLog(@"%d to %d %d\n",i-1,i,differences[i].diff);
			}			
			qsort (differences,count,sizeof(myDiff),(void *)compareDiff);
	}
}

- (void)setupMarkers;
{
  myDiff *markDiffs;
  
  markDiffs = (myDiff *)calloc([markerBases count],sizeof(myDiff));
  if (markDiffs == NULL) return;
  [self outAndDiffs:markDiffs];
  if ([standard isEqualTo:@"ROX500"])
    [self markers500ROX:markDiffs];
  else if ([standard isEqualTo:@"ROX1000"])
    [self markers1000ROX:markDiffs];
  else if ([standard isEqualTo:@"Custom"])
    [self markersCustom:markDiffs];
  free(markDiffs);
}

-(void)markers500ROX:(myDiff *)differences
{
  int   i, j, count, step, limitStep;
  int   first, second;
 // int   interval, baseDiff, baseLoc;
  BOOL  found1=NO, found2=NO;
  //int   *diff;
  //Base  *oneBase;
  
  
//calculate differences between the peaks
  //differences = [self outAndDiffs];
  if (differences == NULL) return;
  count = [markerBases count];
  //search for orientation points
  //look in lower quartile first
  step = 6;
  while ((!found1 || !found2) && (step < count)) {
    qsort(differences, step, sizeof(myDiff),(void*)compareIdx);
    for (i=0; i < count; i++) {
      printf("index %d difference %d marker %d\n", differences[i].index, differences[i].diff, differences[i].marker);
    }
    i = 0;
    limitStep = step;
    while (i < limitStep) {
      if ((differences[i].index > 6) && (differences[i].index < 17)) {
        if (!found1 && (differences[i].index - differences[i+1].index) == 1) {
          differences[i].marker = 11;
          differences[i+1].marker = 10;
          i=i+2;
          found1 = YES;
        } 
        else i++;
      }
      else if (differences[i].index < 7) {
        if (!found2 && ((differences[i].index - differences[i+1].index) == 1) &&
            ((differences[i+1].index - differences[i+2].index) ==1)) {
          differences[i].marker = 6;
          differences[i+1].marker = 5;
          differences[i+2].marker = 4;
          found2 = YES;
          i=i+3;
        }
        else i++;
      }
      else {
        i++;
        step++;
      }
    }
  }
  //pad sequence to match the standard
  qsort(differences,count,sizeof(myDiff),(void*)compareIdx);
  printf("\n");
  for (i=0; i < count; i++)
    printf("index %d difference %d marker %d\n", differences[i].index, differences[i].diff, differences[i].marker);
  
  first = second = 0;
  for (i=0; i < count ; i++) {
    if (differences[i].marker == 11)
      first = i;
    if (differences[i].marker == 6)
      second = i;    
  }
       
  if ((second-first) == 5) {
    j=12;
    for (i=first-1; i >= 0; i--) {
      differences[i].marker = j++;
    }
    j=7;
    for (i=second-1; i > first+1; i--)
      differences[i].marker = j++;
    j=3;
    for (i=second+3; i < count; i++)
      differences[i].marker = j--;
  }
  else {
    if (found2) {
      j=7;
      for (i=second-1;i >= 0; i--)
        differences[i].marker =j++;
      j = 3;
      for (i=second+3; i < count ; i++)
        differences[i].marker = j--;
      
    }
    else if (found1) {
      
    }
  }
  printf("\n");
  for (i=0; i < count; i++)
    printf("index %d difference %d marker %d pos %d\n", differences[i].index, differences[i].diff, differences[i].marker, [[markerBases baseAt:differences[i].index] location]);
 //following is specific to ROX GeneScan-500
  if (X != NULL) {
    free(X);
    free(Y);
  }
  X = (double *)calloc(count, sizeof(double));
  Y = (double *)calloc(count, sizeof(double));
  for (i = 0; i< count; i++) {
    X[i] = 0.0;
    Y[i] = 0.0;
  }
  //j = ROX500[15];
  j = differences[count-1].marker;
  j = 0;
  for (i = 0; (j < 17) && (j < count); i++) {
   // if (i < 16) {
      X[i] = ROX500[j];
      Y[i] = [[markerBases baseAt:j] location];
      j++;
   // }
   /* else {
      j += 50;
      X[i] = j;
      Y[i] = [[markerBases baseAt:i] location];
    }*/
    printf("%d %d\n",X[i],Y[i]);
  }
  numPairs = j;
//  input = (int *) calloc (X[count-1],sizeof(int));
//  output = (float *)calloc (X[count-1],sizeof(float));
//  for (i = 0; (i < X[count-1]) && (j < count); i++) {
//    if (i+1 != X[j]) 
//      input[i] = i+1;
//    else
//      j++;
//  }
//  [self cubicSpline:X :Y :count :input :X[count-1] :output];
//  printf("input output count = %d\n", X[count-1]);
/*  for (i = 0; i < X[count-1]; i++) {
    printf("%d %f\n",input[i], output[i]);
  }
  for (j = 0; j < X[count-1]; j++) {
    if (output[j] != 0.0) {
      oneBase = [[Base alloc] init];
      [oneBase setBase:' '];
      [oneBase setConf:(char)255];
      [oneBase setLocation:(int)output[j]];
      [markerBases addBase:oneBase];
      [oneBase release];      
    }
  } 
    
  [markerBases sortByLocation];
  
  printf("final count %d\n",[markerBases count]);*/

}

-(void)markers1000ROX:(myDiff *)differences
{
  int   i, j, count/*, step, limitStep*/;
 // int   Q1, Q3, Q1Val, Q3Val;
  //float check1, check2;
 // float height1, height2;
  //int   first, second;
  // int   interval, baseDiff, baseLoc;
 // BOOL  found1=NO, found2=NO;
  //int   *diff;
  //Base  *oneBase;
  
  
  //calculate differences between the peaks
  //differences = [self outAndDiffs];
  count = [markerBases count];
  //after removing base, should probably recalculate differences, put this stuff in another routine
  
  //search for orientation points
  //look in lower quartile first
/*  step = 6;
  while ((!found1 || !found2) && (step < count)) {
    qsort(differences, step, sizeof(myDiff),(void*)compareIdx);
    for (i=0; i < count; i++) {
      printf("index %d difference %d marker %d\n", differences[i].index, differences[i].diff, differences[i].marker);
    }
    i = 0;
    limitStep = step;
    while (i < limitStep) {
      if ((differences[i].index > 6) && (differences[i].index < 17)) {
        if (!found1 && (differences[i].index - differences[i+1].index) == 1) {
          differences[i].marker = 11;
          differences[i+1].marker = 10;
          i=i+2;
          found1 = YES;
        } 
        else i++;
      }
      else if (differences[i].index < 7) {
        if (!found2 && ((differences[i].index - differences[i+1].index) == 1) &&
            ((differences[i+1].index - differences[i+2].index) ==1)) {
          differences[i].marker = 6;
          differences[i+1].marker = 5;
          differences[i+2].marker = 4;
          found2 = YES;
          i=i+3;
        }
        else i++;
      }
      else {
        i++;
        step++;
      }
    }
  }
  //pad sequence to match the standard
  qsort(differences,count,sizeof(myDiff),(void*)compareIdx);
  printf("\n");
  for (i=0; i < count; i++)
    printf("index %d difference %d marker %d\n", differences[i].index, differences[i].diff, differences[i].marker);
  
  first = second = 0;
  for (i=0; i < count ; i++) {
    if (differences[i].marker == 11)
      first = i;
    if (differences[i].marker == 6)
      second = i;    
  }
  
  if ((second-first) == 5) {
    j=12;
    for (i=first-1; i >= 0; i--) {
      differences[i].marker = j++;
    }
    j=7;
    for (i=second-1; i > first+1; i--)
      differences[i].marker = j++;
    j=3;
    for (i=second+3; i < count; i++)
      differences[i].marker = j--;
  }
  else {
    if (found2) {
      j=7;
      for (i=second-1;i >= 0; i--)
        differences[i].marker =j++;
      j = 3;
      for (i=second+3; i < count ; i++)
        differences[i].marker = j--;
      
    }
    else if (found1) {
      
    }
  }
  printf("\n");
  for (i=0; i < count; i++)
    printf("index %d difference %d marker %d pos %d\n", differences[i].index, differences[i].diff, differences[i].marker, [[markerBases baseAt:differences[i].index] location]);
 */
  //following is specific to ROX GeneScan-1000
  if (X != NULL) {
    free(X);
    free(Y);
  }
  X = (double *)calloc(count, sizeof(double));
  if (X == NULL) {
    printf("error allocating memory for X\n");
    return;
  }
  Y = (double *)calloc(count, sizeof(double));
  if (Y == NULL) {
    printf("error allocating memory for Y\n");
    return;
  }  
  for (i = 0; i< count; i++) {
    X[i] = 0.0;
    Y[i] = 0.0;
  }
  //j = ROX500[15];
  //j = differences[count-1].marker;
  j = 0;
  for (i = 0; (j < 17) && (j < count); i++) {
    // if (i < 16) {
    X[i] = ROX1000[j];
    Y[i] = [[markerBases baseAt:j] location];
    j++;
    // }
    /* else {
      j += 50;
    X[i] = j;
    Y[i] = [[markerBases baseAt:i] location];
    }*/
    printf("%d %d\n",X[i],Y[i]);
  }
  numPairs = j;
  //  input = (int *) calloc (X[count-1],sizeof(int));
  //  output = (float *)calloc (X[count-1],sizeof(float));
  //  for (i = 0; (i < X[count-1]) && (j < count); i++) {
  //    if (i+1 != X[j]) 
  //      input[i] = i+1;
  //    else
  //      j++;
  //  }
  //  [self cubicSpline:X :Y :count :input :X[count-1] :output];
  //  printf("input output count = %d\n", X[count-1]);
  /*  for (i = 0; i < X[count-1]; i++) {
    printf("%d %f\n",input[i], output[i]);
  }
  for (j = 0; j < X[count-1]; j++) {
    if (output[j] != 0.0) {
      oneBase = [[Base alloc] init];
      [oneBase setBase:' '];
      [oneBase setConf:(char)255];
      [oneBase setLocation:(int)output[j]];
      [markerBases addBase:oneBase];
      [oneBase release];      
    }
  } 

  [markerBases sortByLocation];

  printf("final count %d\n",[markerBases count]);*/
  
}

-(void)markersCustom:(myDiff *)differences
{
  int   i, j, k, count;
	int		Q1, end;
	int		orient, size;
	BOOL	found=NO;
  double   *input, *output;
  Base  *oneBase;
  
	orient = 0;
  count = [markerBases count];
	Q1 = (count-1)/4;
	if ((count-1)%4 != 0)
		Q1++;
	i = 1;
	end = Q1;
	//look for orientation point in first quarter
	while ((i < end) && !found) {
		if ((differences[i].index > 10) && (differences[i].index < 20)) {
			k = 1;
			while ((k < end) && !found) {
				if (abs(differences[i].index - differences[k].index) == 1) {
					orient = (differences[i].index < differences[k].index) ? differences[i].index-1 : differences[k].index-1;
					found = YES;
				}
				else
					k++;
			}
		}
		i++;
		if (!found && (i==end) && (end != count))
			end++;
	}
	//arrays for cubic spline, known x,y values for size standard, x=time, y = base
  if (X != NULL) {
    free(X);
    free(Y);
  }
  X = (double *)calloc(lenCustom, sizeof(double));
  if (X == NULL) {
    printf("error allocating memory for X\n");
    return;
  }
  Y = (double *)calloc(lenCustom, sizeof(double));
  if (Y == NULL) {
    printf("error allocating memory for Y\n");
		free(X);
    return;
  }  
  for (i = 0; i< lenCustom; i++) {
    X[i] = 0.0;
    Y[i] = 0.0;
  }
	//should find close grouping of standards representing base 450, 475, and 500
	//build input values around these points if found
	if (orient == 0) {
		j = 0;
		for (i = 0; (j < lenCustom) && (i < count); i++) {
			X[j] = Custom[j];
			Y[j] = [[markerBases baseAt:i] location];
			j++;
		}
	}
	else {
		j = 13;
		for (i = orient; i < count && (j < lenCustom); i++) {
			X[j] = Custom[j];
			Y[j] = [[markerBases baseAt:i] location];
			j++;
		}
		if (i < count)  //remove invalid marker peaks
			for (j=i; j < count; j++)
				[markerBases removeBaseAt:j];
		j = 12;
		for (i = orient-1; i >=0 && j >= 0 ; i--) {
			X[j] = Custom[j];
			Y[j] = [[markerBases baseAt:i] location];
			j--;
		}
		if (i >= 0)  //remove invalid marker peaks
			for (j=i; j >= 0; j--)
				[markerBases removeBaseAt:j];
	}
	if ([self debugmode] ) {
		for (i = 0; i < lenCustom; i++)
			NSLog(@"X=%7.3f Y=%7.3f\n",X[i],Y[i]);
	}
	numPairs = lenCustom;
	j = 0;
	for (i = 0; (i < lenCustom) && (j < count); i++) {
		if (X[i] != 0.0) {
			X[j] = X[i];
			Y[j++] = Y[i];
		}
		else { //if = 0
			numPairs--;
		}
	}
	if ([self debugmode] ) {
		for (i = 0; i < numPairs; i++)
			NSLog(@"X=%7.3f Y=%7.3f\n",X[i],Y[i]);
	}
	//arrays for interpolated values, all points between size standard
	size = X[numPairs-1]-X[0]+1;
  input = (double *) calloc (size,sizeof(double));
  output = (double *)calloc (size,sizeof(double));
  j = 0; k = 0;
  for (i = X[0]; (i < X[numPairs-1]) && (j < numPairs) && (k < size); i++) {
    input[k] = 0.0;
    output[k] = 0.0;
    if (i != X[j]) 
      input[k++] = i;
    else {
			j++;
			k++;
		}
  }
	//find points between known size standard locations
  [self cubicSpline:X :Y :numPairs :input :size :output];
  //printf("input output count = %7.3f\n", X[count-1]);
  //for (i = 0; i < size; i++) {
  //  printf("%7.3f %7.3f\n",input[i], output[i]);
  //}
  for (j = 0; j < size; j++) {
    if (output[j] != 0.0) {
      oneBase = [[Base alloc] init];
      [oneBase setBase:' '];
      [oneBase setConf:(char)255];
      [oneBase setLocation:(int)output[j]];
      [markerBases addBase:oneBase];
      [oneBase release];      
    }
  } 

  [markerBases sortByLocation];
	[markerBases setOffset:X[0]];

  //printf("final count %d\n",[markerBases count]);
  free(input);
  free(output);
  
}


/****
*
* Peak Finding methods
*
****/

- (void)firstDerivative:(int)chan :(float *)derivative
{
  int		i, j, k, numUsed;
  float		temp1, temp2, derivVal;
  
  k = 0;
  for(i=0; i<[dataList length]; i++) {
    derivVal = 0.0;
    numUsed = 0;
    for(j=-2; j<=2; j++) {
      if((i+j >= 0) && (i+j < [dataList length]) && (j!=0)) {
        temp1 = [dataList sampleAtIndex:i channel:chan];
        temp2 = [dataList sampleAtIndex:(i+j) channel:chan];
        derivVal += (temp2 - temp1) / (float)j;
        numUsed++;
      }
    }
    if(numUsed > 0) derivVal = derivVal / numUsed;
    derivative[k++] = derivVal;
  }
}

- (void)findPeakBase:(int)chan :(float *)derivative
{
  float    aveHeight,max;
  int      i, numPeaks, factor;
  Base     *oneBase;
  BOOL     wasPos;
  myDiff   *savePeaks;

  aveHeight = 0.0;
  max = 0.0;
    
  if([dataList sampleAtIndex:0 channel:chan] > 0.0) wasPos=YES;
  else wasPos = NO;
  
  savePeaks = (myDiff *)calloc([dataList length],sizeof(myDiff));
  numPeaks=0;
  //find all of the peaks
  for(i=1; i<[dataList length]; i++) {
    if(wasPos && (derivative[i] <= 0.0)) {
      savePeaks[numPeaks].index = i-1;
      savePeaks[numPeaks].height = [dataList sampleAtIndex:i-1 channel:chan];
      numPeaks++;
      wasPos = NO;
    }
    if(derivative[i] > 0.0) wasPos = YES;
  }
  qsort (savePeaks, numPeaks,sizeof(myDiff),(void *)compareHeight);
  //don't consider very, very tall peaks as part of peak average
  for (i = 0; i < numPeaks-1; i++) {
    factor = savePeaks[i].height / savePeaks[i+1].height;
    if ((factor < 2) && (max < savePeaks[i].height)) 
      max = savePeaks[i].height;
  }
  aveHeight = max/3;
  
  for(i=0; i < numPeaks; i++) {
    if([dataList sampleAtIndex:savePeaks[i].index channel:chan] >= aveHeight) {
      oneBase = [Base newWithChar:' '];
      [oneBase setConf:(char)255];
      [oneBase setLocation:savePeaks[i].index];
      [markerBases addBase:oneBase];
    }
  }
  
  [markerBases sortByLocation];

  free(savePeaks);
}

- (int) findLeftInflection:(int)center :(float *)listofD
{
	int		i, points;
	BOOL	found;
	
	points = [dataList length];
	found = NO;
	if (center >= points) return center;
	i = center;
	while (i >= 0 && !found) {
		i--;
		if (listofD[i] <= 0.0)
			found = YES;				
	}
	return i;
}

- (int) findRightInflection:(int)center :(float *)listofD
{
	int		i, points;
	BOOL	found;
	
	points = [dataList length];
	found = NO;
	if (center >= points) return center;
	i = center;
	while (i < points && !found) {
		i++;
		if (listofD[i] >= 0.0)
			found = YES;				
	}
	return i;
}

-(void) primerCorrection:(float *)peaksBlue :(float *)peaksGreen :(float *)peaksRed
{
	float	yMax, val, newVal;
	float	temp1, temp2, derivVal;
	float *peaks;
	int		i, j, chan, xMax, numPoints, numUsed;
	int		lear, rear, lowlft, lowrgt, lother, rother;
	BOOL	found;
	
	numPoints = [dataList length];
	for (chan=0; chan<2; chan++) {
		yMax = 0.0; xMax = 0;
		if (chan == 0)
			peaks = peaksBlue;
		else
			peaks = peaksGreen;
		for (i=0; i < numPoints; i++) {
			if ([dataList sampleAtIndex:i channel:chan] > yMax) {
				xMax = i;
				yMax = [dataList sampleAtIndex:i channel:chan];
			}	
		}
		lowlft = [self findLeftInflection:xMax :peaks];
		lowrgt = [self findRightInflection:xMax :peaks];
		lear = xMax;
		rear = xMax;
		if ([dataList sampleAtIndex:lowlft channel:chan]+100 < [dataList sampleAtIndex:lowrgt channel:chan])  {  //look for other ear to the right
			i = lowrgt;
			found = NO;
			while ((numPoints > i) && !found) {
				i++;
				if (peaks[i] <= 0.0)
					found = YES;				
			}
			rear = i;
		}
		else if ([dataList sampleAtIndex:lowlft channel:chan] > [dataList sampleAtIndex:lowrgt channel:chan]+100) { //look for other ear to the left
			i = lowlft;
			found = NO;
			while (i >= 0 && !found) {
				i--;
				if (peaks[i] >= 0.0)
					found = YES;				
			}
			lear = i;
		}
	//else //no bat ears
	//remove peaks within peak
		if (chan == 0) {
			rother = [self findRightInflection:rear :peaksGreen];
			lother = [self findLeftInflection:lear :peaksGreen];
			for (i = lother; i <= rother; i++) {
				[dataList setSample:0.0 atIndex:i channel:1];
				peaksGreen[i] = 0.0;
			}
		}
		else {
			rother = [self findRightInflection:rear :peaksBlue];
			lother = [self findLeftInflection:lear :peaksBlue];
			for (i = lother; i <= rother; i++) {
				[dataList setSample:0.0 atIndex:i channel:0];
				peaksBlue[i] = 0.0;
			}
		}
		rother = [self findRightInflection:rear :peaksRed];
		lother = [self findLeftInflection:lear :peaksRed];
		for (i=lother; i <= rother; i++) {
			[dataList setSample:0.0 atIndex:i channel:3];
			peaksRed[i] = 0.0;
		}
	//fix bat ear
		if ([dataList sampleAtIndex:lear channel:chan] > [dataList sampleAtIndex:rear channel:chan])
			val = [dataList sampleAtIndex:lear channel:chan];
		else
			val = [dataList sampleAtIndex:rear channel:chan];
		for (i = lear+1; i <rear; i++) {
			newVal = 2*val - [dataList sampleAtIndex:i channel:chan];
			[dataList setSample:newVal atIndex:i channel:chan];
		}
		//calculate new derivative
		for (i = lear; i <= rear; i++) {
			derivVal = 0.0;
			numUsed = 0;
			for(j=-2; j<=2; j++) {
				if((i+j >= 0) && (i+j < [dataList length]) && (j!=0)) {
					temp1 = [dataList sampleAtIndex:i channel:chan];
					temp2 = [dataList sampleAtIndex:(i+j) channel:chan];
					derivVal += (temp2 - temp1) / (float)j;
					numUsed++;
				}
			}
			if(numUsed > 0) derivVal = derivVal / numUsed;
			peaks[i] = derivVal;
		}
	}
}

- (void)findPeakAreas:(int)chan :(float *)derivative
{
	float    scale, width, center;
	float		 tempPeak;
  int      i, numPeaks, numPoints;
  BOOL     wasPos;
  Gaussian *ladderEntry;
  myDiff   *savePeaks;
	int			 leftPos, rghtPos;
  
  numPoints = [dataList length];
  if([dataList sampleAtIndex:0 channel:chan] > 0.0) wasPos=YES;
  else wasPos = NO;
  
  savePeaks = (myDiff *)calloc([dataList length],sizeof(myDiff));
  numPeaks=0;
  //find all of the peaks
  for(i=1; i<[dataList length]; i++) {
		tempPeak = [dataList sampleAtIndex:i-1 channel:chan];
    if(wasPos && (derivative[i] <= 0.0) && 
			 (tempPeak > threshold[chan])) {
      savePeaks[numPeaks].index = i-1;
      savePeaks[numPeaks].height = tempPeak;
      numPeaks++;
      wasPos = NO;
    }
    if(derivative[i] > 0.0) wasPos = YES;
  }
  qsort (savePeaks, numPeaks, sizeof(myDiff),(void *)compareHeight);
	//maxno = numPeaks*threshold;
	
	printf("Channel %d\n",chan);
	for (i = 0; i < numPeaks; i++) {
		printf("%d %7.3f\n",savePeaks[i].index,savePeaks[i].height);
	}

  for (i=0; i < numPeaks; i++) {
		leftPos = [self findLeftInflection:savePeaks[i].index :derivative];
		rghtPos = [self findRightInflection:savePeaks[i].index :derivative];
		[self calculatePeak:&center :&scale :&width :savePeaks[i].index :chan :leftPos :rghtPos];

			scale = scale/sqrt(2*3.14159265*width);
      ladderEntry = [Gaussian GaussianWithWidth:width 
                                          scale:scale 
                                         center:center];
      if ([self debugmode])
        NSLog(@"center: %f scale: %f width: %f area: %f",[ladderEntry center],[ladderEntry scale],[ladderEntry width], [ladderEntry area]);
      [ladderEntry setChannel:chan];
      [peakAreas addEntry:ladderEntry];
  }
  
  free(savePeaks);
}

double gauss_fit_function( double t, double* p )
{
/*p[0] = scale
  p[1] = width
  p[2] = center */
  double  power, y, scale;
 
  power = (t - p[2])/p[1];
  scale = p[0]/sqrt(2*3.14159265*p[1]);
  y = scale * exp(-0.5*power*power);
  return y;
}

void my_print( int n_par, double* par, int m_dat, double* fvec, 
                       void *data, int iflag, int iter, int nfev )
/*
 *       data  : for soft control of printout behaviour, add control
 *                 variables to the data struct
 *       iflag : 0 (init) 1 (outer loop) 2(inner loop) -1(terminated)
 *       iter  : outer loop counter
 *       nfev  : number of calls to *evaluate
 */
{
	double f, y, t;
	int i;
	lm_data_type *mydata;
	mydata = (lm_data_type*)data;
	
		if (iflag==2) {
			printf ("trying step in gradient direction\n");
		} else if (iflag==1) {
			printf ("determining gradient (iteration %d)\n", iter);
		} else if (iflag==0) {
			printf ("starting minimization\n");
		} else if (iflag==-1) {
			printf ("terminated after %d evaluations\n", nfev);
		}
		
//		printf( "  par: " );
//		for( i=0; i<n_par; ++i )
//			printf( " %12g", par[i] );
//		printf ( " => norm: %12g\n", lm_enorm( m_dat, fvec ) );
		
		if ( iflag == -1 ) {
			printf( "  fitting data as follows:\n" );
			for( i=0; i<m_dat; ++i ) {
				t = (mydata->user_t)[i];
				y = (mydata->user_y)[i];
				f = mydata->user_func( t, par );
				printf( "    t[%2d]=%12g y=%12g fit=%12g residue=%12g\n",
								i, t, y, f, y-f );
			}
		}
}

-(void)calculatePeak:(float *)center :(float *)scale :(float *)width :(int)peak :(int)channel :(int)startpos :(int)endpos
{
  float             min;
  float             *dataPtr;
  double            *gaussData, *x;
  int               i, j, /*startpos, endpos,*/ noPoints, points;
  NumericalObject   *numObj=[[NumericalObject alloc] init];
  lm_control_type   control;
  lm_data_type      data;
  double            coeff[3];

  *center = 0.0;
  *scale = 0.0;
  *width = 0.0;
  points = [dataList length];
	dataPtr = (float *)calloc(points, sizeof(float));
	for(i=0; i<points; i++)
		dataPtr[i] = [dataList sampleAtIndex:i channel:channel];    
  //startpos = [numObj findleftminloc:peak :dataPtr :points];
  //endpos = [numObj findrightminloc:peak :dataPtr :points];
  noPoints = endpos - startpos + 1;
  min = [numObj minVal:&(dataPtr[startpos]) numPoints:noPoints];
  gaussData = (double *)calloc(noPoints, sizeof(double));
  x = (double *)calloc(noPoints, sizeof(double));
  for (j=0; j < noPoints; j++) {
    gaussData[j] = (double)(dataPtr[startpos + j] - min);
    x[j] = (double)j;
  }
  coeff[0] = coeff[1] = coeff[2] = 1.0;
NS_DURING
  lm_initialize_control(&control);
  data.user_func = gauss_fit_function;
  data.user_t = x;
  data.user_y = gaussData;
  lm_minimize (noPoints, 3, coeff, lm_evaluate_default, my_print, &data, &control);
  
 NS_HANDLER
  NSLog(@"error during gaussian fitting\n%@",[localException description]);
  NSRunAlertPanel(@"Error loading script", @"%@", @"OK", nil, nil, localException);
NS_ENDHANDLER
  coeff[0] = fabs(coeff[0]);
  coeff[1] = fabs(coeff[1]);
  coeff[2] = fabs(coeff[2]);
  *center = (float)(startpos + coeff[2]);
  *scale = (float)coeff[0];
  *width = (float)coeff[1];
  //printf("area %f width %f center %f\n",*scale, *width, *center);
  free(x);
  free(gaussData);
	free(dataPtr);
	[numObj release];
}

/***
*
* Protocol Interface to UI Controller
*
***/
- (NSString *)getOutFile
{
  return myOutFile;
}

- (void) saveOutFile:(NSString*)outFile
{
    if (myOutFile != nil) [myOutFile release];
    myOutFile = [outFile copy];
}

- (void) setTheData:(NSString *)marker :(float *)thresh :(int)primerState
{
	standard = [marker copy];
  threshold[0] = thresh[0];
	threshold[1] = thresh[1];
	pstate = primerState;
}

- (NSString *) getTheData:(float *)thresh :(int *)primerState
{
	thresh[0] = threshold[0];
	thresh[1] = threshold[1];
	*primerState = pstate;
	return standard;
}

/***
*
* Coder
*
***/

- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];
  
}

/***
*
* Ascii Archiver functionality
*
***/
- (void)beginDearchiving:archiver
{
  [self init];
  [super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver
{
  char  tmpStrng[1000];
  
  if (!strcmp(tag,"myOutFile")) {
    [archiver readData:tmpStrng];
    myOutFile = [[NSString alloc] initWithString:[NSString stringWithCString:tmpStrng]];
  }
  else if (!strcmp(tag,"standard")) {
    [archiver readData:tmpStrng];
    standard = [[NSString alloc] initWithString:[NSString stringWithCString:tmpStrng]];
  }
  else if (!strcmp(tag, "threshold"))
    [archiver readData:threshold];
	else if (!strcmp(tag, "primerState"))
		[archiver readData:&pstate];
  else
    return [super handleTag:tag fromArchiver:archiver];
		
  return self;
}

- (void)writeAscii:archiver
{
  char  *tmpStrng;
  
  if (myOutFile != nil) {
    tmpStrng = (char *)calloc([myOutFile length]+1,sizeof(char));
    [myOutFile getCString:tmpStrng];
    [archiver writeArray:tmpStrng size:([myOutFile length]+1) type:"c" tag:"myOutFile"];
    free(tmpStrng);
  }
  if (standard != nil) {
    tmpStrng = (char *)calloc([standard length]+1,sizeof(char));
    [standard getCString:tmpStrng];
    [archiver writeArray:tmpStrng size:([myOutFile length] + 1) type:"c" tag:"standard"];
  }
  [archiver writeArray:threshold size:2 type:"f" tag:"threshold"];
	[archiver writeData:&pstate type:"i" tag:"pstate"];

  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolTRFLP     *dupSelf;

  dupSelf = [super copyWithZone:zone];

	if (myOutFile != nil)
		dupSelf->myOutFile = [myOutFile copy];
  if (standard != nil)
    dupSelf->standard = [standard copy];
  dupSelf->threshold[0] = threshold[0];
	dupSelf->threshold[1] = threshold[1];
	dupSelf->pstate = pstate;
  return dupSelf;
}

@end
