 
/* "$Id: ToolSignalDecay.m,v 1.9 2007/05/23 20:31:30 smvasa Exp $" */
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
NIH Center for AIDS research

******************************************************************/

#import "ToolSignalDecay.h"
#include <GeneKit/lmmin.h>
#include <GeneKit/lm_eval.h>

@interface ToolSignalDecay (Private)
- (void)calculateCurve:(double *)consts :(NSArray *)myData;
- (void)firstDerivative:(int)chan :(float *)derivative;
- (NSArray*)collectPoints:(Trace*)traceData
							 forChannel:(int)channel;
- (void)adjustData:(Trace*)traceData forChannel:(int)channel reScale:(int)val;
@end

@implementation ToolSignalDecay

typedef struct peaks {
  int index;
  float height;
} myPeaks_t;

-init
{
	[super init];
	coeff[0] = 1000000;
	coeff[1] = 0.999;
	coeff[2] = 10000;
	scale = 1000;
	rangeFrom = -1;
	rangeTo = -1;
	return self;
}

- (NSString *)toolName
{
  return @"Signal Decay Correction";
}

- (BOOL)shouldCache 
{ 
  return YES; 
}
- apply
{	
  int       channel;
  Trace     *traceData;
  NSArray   *myPoints;
	
  [self setStatusMessage:@"Correcting Decay"];
  traceData = [self dataList];
  for(channel=0;channel<8;channel++) {
    if(selChannels[channel]) {
      myPoints =  [self collectPoints:traceData
													 forChannel:channel];
			
      [self calculateCurve:coeff :myPoints];
			
      [self adjustData:traceData forChannel:channel reScale:scale];
    }
  }
  [self setStatusMessage:nil];
  return [super apply];
}

- (void)firstDerivative:(int)chan :(float *)derivative
{
  int		i, j, k, numUsed;
  float		temp1, temp2, derivVal;
  
  k = 0;
  for(i=0; i<[dataList length]; i++) {
    derivVal = 0.0;
    numUsed = 0;
    for(j=-3; j<=3; j++) {
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

int compareHeight(myPeaks_t *peak1, myPeaks_t *peak2)
//largest to smallest
{
  if (peak1->height < peak2->height)
    return 1;
  if (peak1->height > peak2->height)
    return -1;
  return 0;
}

static int compareIndex(id peak1, id peak2, void *context)
//smallest to largest
{
	myPeaks_t	thePeak1;
	myPeaks_t thePeak2;
	
	[peak1 getValue:&thePeak1];
	[peak2 getValue:&thePeak2];
  if (thePeak1.index > thePeak2.index)
    return NSOrderedDescending;
  if (thePeak1.index < thePeak2.index)
    return NSOrderedAscending;
  return NSOrderedSame;
}
//this function isn't used yet
- (void) calcStats:(myPeaks_t *)thePeaks :(int)howMany :(float *)mu :(float *)sigma
{
	int		i, N;
	float sumX, sumX2;
	
	sumX = sumX2 = 0.0;
	N = howMany;
	for (i = 0; i < howMany; i++) {
		sumX = sumX + thePeaks[i].height;
		sumX2 = sumX2 + thePeaks[i].height*thePeaks[i].height;
		if (thePeaks[i].height == 0)
			N--;
	}
	*mu = sumX/N;
	//sample standard deviation
	*sigma = sqrt((sumX2 - N*(*mu)*(*mu))/(N - 1));
}

- (NSArray*)collectPoints:(Trace*)traceData
                forChannel:(int)channel
{
  NSMutableArray  *thePoints;
  int             i, j, k, numPoints;
  myPeaks_t				*savePeaks;
  float           *derivative;
  int             numPeaks, Q1, Q3;
  float           Q1Val, Q3Val, IQR, diff;
	BOOL						wasPos=YES;

  if(traceData == nil) return nil;
	numPoints = [traceData length];
  derivative = (float *)calloc(numPoints, sizeof(float));
	[self firstDerivative:channel :derivative];
	thePoints = [NSMutableArray array];
  savePeaks = (myPeaks_t *)calloc(rangeTo-rangeFrom+1,sizeof(myPeaks_t));
  //find all of the peaks
	numPeaks = 0;
	for (j=rangeFrom; j < rangeTo && j < numPoints; j++) {
		if(wasPos && (derivative[j] <= 0.0)) {
			savePeaks[numPeaks].index = j-1;
			savePeaks[numPeaks].height = [traceData sampleAtIndex:j-1 channel:channel];
			numPeaks++;
			wasPos = NO;
		}
		if(derivative[j] > 0.0) 
			wasPos = YES;
	}	
	//sort based on height
	qsort(savePeaks,numPeaks,sizeof(myPeaks_t),(void *)compareHeight);
	//identify interquartile range
	Q1 = (numPeaks)/4;
	if ((numPeaks)%4 != 0)
		Q1++;
	Q3 = numPeaks*3/4;
	if ((numPeaks*3)%4 !=0 ) 
		Q3++;
	Q1Val = savePeaks[Q1].height;
	Q3Val = savePeaks[Q3].height;
	IQR = Q1Val - Q3Val;
	for (k = 0; k < numPeaks; k++) {
	//identify outliers and remove the really tall peaks and really small peaks
		if (savePeaks[k].height > Q1Val) {
			diff = savePeaks[k].height-Q1Val;
			if (diff >= 3*IQR) {
				savePeaks[k].height = 0;
				savePeaks[k].index = 0;
			}
		}
		else if (savePeaks[k].height < Q3Val) {
			diff = Q3Val - savePeaks[k].height;
			if (diff >= 3*IQR) {
				savePeaks[k].height = 0;
				savePeaks[k].index = 0;
			}
		}
	}
	for (i = 0; i < numPeaks; i++) {
		if (savePeaks[i].height != 0) {
			if ([self debugmode]) NSLog(@"Point added %d %7.3f\n",savePeaks[i].index,savePeaks[i].height);
			[thePoints addObject:[NSValue value:&savePeaks[i] withObjCType:@encode(myPeaks_t)]];
		}
	}
	[thePoints sortUsingFunction:compareIndex context:nil];
	free(savePeaks);
	free(derivative);
  return thePoints;
}

double decay_fit_function( double t, double* p )
{
  double  y, base, term2;
	
	base = p[1];
	term2 = pow(base,t);
	y = p[0]*term2+p[2];
	return y;
}

- (void)adjustData:(Trace*)traceData forChannel:(int)channel reScale:(int)val
{
  int           x;
	double				decay,dropoff;
	float					height;
	
	for (x = rangeFrom; x <= rangeTo && x < [traceData length]; x++){
		decay = decay_fit_function(x,coeff);
		height = [traceData sampleAtIndex:x channel:channel];
		dropoff = height/decay*(val);
		[traceData setSample:(float)dropoff atIndex:x channel:channel];
	}
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
		//	printf ("trying step in gradient direction\n");
		} else if (iflag==1) {
		//	printf ("determining gradient (iteration %d)\n", iter);
		} else if (iflag==0) {
		//	printf ("starting minimization\n");
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

-(void)calculateCurve:(double *)consts :(NSArray *)myData
{
  double            *curveData, *x;
  int               j, points;
  lm_control_type   control;
  lm_data_type      data;
  double            p[3];
	myPeaks_t					thePeak;
	
  points = [myData count];
	curveData = (double *)calloc(points, sizeof(double));
	x = (double *)calloc(points, sizeof(double));
  for (j=0; j < points; j++) {
		[[myData objectAtIndex:j] getValue:&thePeak];
    curveData[j] = (double)(thePeak.height);
    x[j] = (double)thePeak.index;
		//printf("%7.3f %7.3f\n",curveData[j],x[j]);
  }
  p[0] = consts[0];
	p[1] = consts[1];
	p[2] = consts[2];
	NS_DURING
		lm_initialize_control(&control);
		data.user_func = decay_fit_function;
		data.user_t = x;
		data.user_y = curveData;
		lm_minimize (points, 3, p, lm_evaluate_default, my_print, &data, &control);
		
	NS_HANDLER
		NSLog(@"error during curve fitting\n%@",[localException description]);
		NSRunAlertPanel(@"Error loading script", @"%@", @"OK", nil, nil, localException);
	NS_ENDHANDLER
  consts[0] = p[0];
  consts[1] = p[1];
  consts[2] = p[2];
  //printf("area %f width %f center %f\n",*scale, *width, *center);
  free(x);
  free(curveData);
}

/***
*
* UI Interface section
*
***/
- (void)setValues:(double *)inCoeff :(int)size
{
	coeff[0] = inCoeff[0];
	coeff[1] = inCoeff[1];
	coeff[2] = inCoeff[2];
	scale = size;
}

-(void)getValues:(double *)decays :(int *)size  :(int *)from :(int *)to
{
	decays[0] = coeff[0];
	decays[1] = coeff[1];
	decays[2] = coeff[2];
	*size = scale;
	*from = rangeFrom;
	*to = rangeTo;
}

- (void)setRange:(int)from :(int)to
{
	if (((from != to) && (to > from)) || 
			(from == -1 && to == -1)) {
		rangeFrom = from;
		rangeTo = to;
	}
	else {
		rangeFrom = -1;
		rangeTo = -1;
	}
}

/***
*
* Coder
*
***/
- (id)initWithCoder:(NSCoder *)aDecoder
{
  //[super initWithCoder:aDecoder];

//  [aDecoder decodeValueOfObjCType:"i" at:&windowWidth];
//  [aDecoder decodeValueOfObjCType:"d" at:&coeff[0]];
//  [aDecoder decodeValueOfObjCType:"d" at:&coeff[1]];
//  [aDecoder decodeValueOfObjCType:"d" at:&coeff[2]];
//  [aDecoder decodeValueOfObjCType:"i" at:&rangeFrom];
//  [aDecoder decodeValueOfObjCType:"i" at:&rangeTo];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];

//  [aCoder encodeValueOfObjCType:"i" at:&windowWidth];
//  [aCoder encodeValueOfObjCType:"d" at:&coeff[0]];
//  [aCoder encodeValueOfObjCType:"d" at:&coeff[1]];
//  [aCoder encodeValueOfObjCType:"d" at:&coeff[2]];
//  [aCoder encodeValueOfObjCType:"i" at:&rangeFrom];
//  [aCoder encodeValueOfObjCType:"i" at:&rangeTo];
}


/***
*
* Ascii Archiver
*
***/
- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"scale"))
    [archiver readData:&scale];
  else if (!strcmp(tag,"decayA"))
		[archiver readData:&coeff[0]];
	else if (!strcmp(tag,"decayB"))
		[archiver readData:&coeff[1]];
	else if (!strcmp(tag,"decayC"))
		[archiver readData:&coeff[2]];
	else if (!strcmp(tag,"rangeFrom"))
		[archiver readData:&rangeFrom];
	else if (!strcmp(tag,"rangeTo"))
		[archiver readData:&rangeTo];
	else
    return [super handleTag:tag fromArchiver:archiver];
		
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&scale type:"i" tag:"scale"];
	[archiver writeData:&coeff[0] type:"d" tag:"decayA"];
	[archiver writeData:&coeff[1] type:"d" tag:"decayB"];
	[archiver writeData:&coeff[2] type:"d" tag:"decayC"];
	[archiver writeData:&rangeFrom type:"i" tag:"rangeFrom"];
	[archiver writeData:&rangeTo type:"i" tag:"rangeTo"];

  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ToolSignalDecay     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  dupSelf->scale = scale;
	dupSelf->coeff[0] = coeff[0];
	dupSelf->coeff[1] = coeff[1];
	dupSelf->coeff[2] = coeff[2];
	dupSelf->rangeFrom = rangeFrom;
	dupSelf->rangeTo = rangeTo;

  return dupSelf;
}

@end
