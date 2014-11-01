//
//  MobilityAdjust.m
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/17/07.
//  Copyright 2007 UNC-CH, Giddings Lab. All rights reserved.
//

#import "MobilityAdjust.h"
#include <Accelerate/Accelerate.h>
#import <GeneKit/MobilityRoutines.h>
#import <GeneKit/NumericalObject.h>

@interface MobilityAdjust (Private)
-(void)calcShiftPoints:(NSMutableArray *)shiftData;
- (void) fitEquation:(NSMutableArray *)shiftData :(id)funcID;
- (void) adjust:(id)funcID;
@end

@implementation MobilityAdjust

- init
{
	[super init];
	noWindows = 100;
	theFormula = 0;
	return self;
}

//GenericTool methods
- (NSString *)toolName
{
	return @"Mobility Shift: Adjust";
}

- (BOOL)modifiesData 
{ 
	return YES; 
}

- (BOOL)shouldCache
{
	return YES;
}

- apply 
{
	NSMutableArray	*shiftData;
	id							mobFuncID;
	int							i;
	
	[self setStatusMessage:@"Adjusting shift"];
	
	switch (theFormula) {
		case 0:
			mobFuncID = [[MobilityFunc1 alloc] init];  //non linear
			break;
		case 1:
			mobFuncID = [[MobilityFunc2 alloc] init];  //polynomial
			break;
		case 2:
			mobFuncID = [[Mobility3Func alloc] init];  //cubic
			break;
	}
	shiftData = [[NSMutableArray alloc] init];
	for(i = 0; i < [dataList numChannels]; i++) {    //should really be 1 less then number of channels, come back and fix
		[shiftData addObject:[NSMutableArray array]];
	}
	
	[self calcShiftPoints:shiftData];  //returns shift info
	[self fitEquation:shiftData :mobFuncID]; //returns fitted info
	[self adjust:mobFuncID];  //adjusts data
	
	[shiftData release];
	
	return [super apply];
}

-(float) templateMatchX:(float *)arrayx withY:(float *)arrayy len:(int)size
{
	
}

-(int) calcLog2N:(int) value
	// Quasi decimal to binary conversion in order to count the places
	// for the power of 2
{
	int oper, i, remainder, result;
	
	oper = value; 
	i = 0;
	while (oper != 0) {
		result = oper/2;
		remainder = oper%2;
		i++;
		oper = result;
	}
	return i;
}

-(float) crossCorrX:(float *)arrayx withY:(float *)arrayy len:(int)size
	//FFT code for cross correlation
{	
	UInt32				log2N, n, nOver2, i;
	SInt32				stride;
	COMPLEX_SPLIT	complexNoX, complexNoY, complexNoZ;
	float					*startReal, *gotReal, scale, sum, mean;
	FFTSetup			setupReal;
		
	log2N = [self calcLog2N:size];
	n = 1 << log2N;
	stride = 1;
	nOver2 = n/2;
	//allocate memory for complex and real
	complexNoX.realp = (float *)malloc(nOver2*sizeof(float));
	complexNoX.imagp = (float *)malloc(nOver2*sizeof(float));
	complexNoY.realp = (float *)malloc(nOver2*sizeof(float));
	complexNoY.imagp = (float *)malloc(nOver2*sizeof(float));
	complexNoZ.realp = (float *)malloc(nOver2*sizeof(float));
	complexNoZ.imagp = (float *)malloc(nOver2*sizeof(float));
	startReal = (float *)malloc(n*sizeof(float));
	gotReal = (float *)malloc(n*sizeof(float));
	if (complexNoX.realp == NULL || complexNoX.imagp == NULL || startReal == NULL || gotReal == NULL 
			|| complexNoY.realp == NULL || complexNoY.imagp == NULL 
			|| complexNoZ.realp == NULL || complexNoZ.imagp == NULL) {
		NSLog(@"FFT Filter: error allocating memory");
		return(-1);
	}
	for (i=0; i < size; i++)
		startReal[i] = arrayx[i];
	for (i = size; i < n; i++)
		startReal[i] = 0.0;
		
	//get split complex vector, convert to even/odd array
	//X
	vDSP_ctoz((COMPLEX *) startReal, 2, &complexNoX, 1, nOver2);
	//Y
	for (i=0; i < size; i++)
		startReal[i] = arrayy[i];
	vDSP_ctoz((COMPLEX *) startReal, 2, &complexNoY, 1, nOver2);
	//allocate memory for FFT routines
	setupReal = vDSP_create_fftsetup(log2N, FFT_RADIX2);
	if (setupReal == NULL) {
		printf("FFT Filter: error allocating FFT memory\n");
		return -1;
	}
	//Perform transformation to frequency space--x & y
	vDSP_fft_zrip(setupReal, &complexNoX, stride, log2N, FFT_FORWARD);
	vDSP_fft_zrip(setupReal, &complexNoY, stride, log2N, FFT_FORWARD);
		
	//complex conjugate and multiply
	// Z = XY*
	vDSP_zvcmul(&complexNoY,stride,&complexNoX,stride,&complexNoZ,stride,nOver2);
		
	//Perform inverse of Z
	vDSP_fft_zrip(setupReal,&complexNoZ, stride, log2N, FFT_INVERSE);
	scale = (float)1.0/(2*n);
	vDSP_vsmul(complexNoZ.realp, 1, &scale, complexNoZ.realp, 1, nOver2);
	vDSP_vsmul(complexNoZ.imagp, 1, &scale, complexNoZ.imagp, 1, nOver2);
	vDSP_ztoc(&complexNoZ, 1, (COMPLEX *)gotReal, 2, nOver2);
	sum = 0;
	for (i = 0; i < size; i++) {
		sum += gotReal[i];
	}
	mean=sum/size;
	vDSP_destroy_fftsetup ( setupReal );
	free (startReal);
	free (gotReal);
	free (complexNoX.realp);
	free (complexNoX.imagp);
	free (complexNoY.realp);
	free (complexNoY.imagp);
	free (complexNoZ.realp);
	free (complexNoZ.imagp);
	
	return(mean);
}

-(void)calcShiftPoints:(NSMutableArray *)shiftData
{
	NSDictionary		*dict;
	int							len, nchan, bwindow, ewindow, wsize;
	int							M, tao;
	int							i, j, k, chan, shift;
	float						*X, *Y, val, mVal;
	
	len = [dataList length];
	nchan = [dataList numChannels];
	wsize = (len%noWindows != 0) ? (len/noWindows+1) : (len/noWindows);
	
	X=(float *)calloc(wsize,sizeof(float));
	Y=(float *)calloc(wsize,sizeof(float));
	for (chan=1; chan < 4; chan++) {
		for (i = 0; i < (noWindows-1); i++) {   //loop through each "window"
			bwindow = i*wsize;
			ewindow = (bwindow+wsize-1 > len) ? len-1 : (bwindow+wsize-1);
			M=8;
			tao=M/2;  //integer division
			mVal=shift=-tao;
			for (j=-tao; j <= tao; j++) {
				for (k=0; k < wsize ; k++) {
					X[k] = (bwindow+k >= len) ? 0 : [dataList sampleAtIndex:(bwindow+k) channel:0];
					Y[k] = ((bwindow+k+j < 0) || (bwindow+k+j >= len)) ? 0.0 : [dataList sampleAtIndex:(bwindow+k+j) channel:chan];
				}
				val = [self crossCorrX:X withY:Y len:(ewindow-bwindow+1)];
				if (val >= mVal) {
					mVal=val;
					shift=j;
				}
			}
			dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:(bwindow+(ewindow-bwindow)/2.0)], @"loc", 
																											[NSNumber numberWithFloat:(shift)], @"shift", 
																											nil];		
			[[shiftData objectAtIndex:chan] addObject:dict];
			NSLog(@"chan=%d center=%7.3f shift=%d",chan,(bwindow+(ewindow-bwindow)/2.0),(shift));
		}
	}
	free(X);
	free(Y);
	//return shiftData;  ///??????
}

- (float)polyFitFunction:(float)x :(int)np
{
  //for the NumericalObject version of myfit
	float	value=0.0;
	
	switch (theFormula) {
		case 0:
			value = pow(x, (np-1));
			break;
		case 1: 
		case 2:
			value = pow(x, (np));
			break;
	}
  return value;
}

- (void) fitEquation:(NSMutableArray *)shiftData :(id)funcID
{
	float            *arrayX;		// x values
  float            *arrayY;		// y values
  float            *sig;		// relative weight (significance)
  int              numCoeff=3;
  float            coeffs[4];		// returned constants for fitted polynominal
  int              chan, j, k;
  NSMutableArray   *shiftChannelData;
  NumericalObject  *numObj = [[NumericalObject new] autorelease];
	
  if(shiftData == nil) return;
	//init
  NSLog(@"FitEquation to data");
	switch (theFormula) {
		case 0: 
		case 1:
			numCoeff=3;
			break;
		case 2:
			numCoeff=4;
			break;
	}
	coeffs[0]=coeffs[1]=coeffs[2]=coeffs[3]=0.0;
	
  for(chan=1; chan < [shiftData count]; chan++) {
    shiftChannelData = [shiftData objectAtIndex:chan];
    if([shiftChannelData count] > 0) {
			arrayX = (float *) malloc(sizeof(float) * [shiftChannelData count]);
			arrayY = (float *) malloc(sizeof(float) * [shiftChannelData count]);
			sig = (float *) malloc(sizeof(float) * [shiftChannelData count]);
      for(j=0; j < [shiftChannelData count]; j++) {
        arrayX[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"loc"] floatValue]; //tempShift->loc;
        arrayY[j] = [[[shiftChannelData objectAtIndex:j] objectForKey:@"shift"] floatValue]; //tempShift->shift;
        sig[j] = 1.0;
      }
      [numObj myfit:arrayX :arrayY :sig :[shiftChannelData count] :coeffs :numCoeff :self];
      NSLog(@"fit for channel %d", chan);
      NSLog(@"a=%f  b=%f  c=%f d=%f\n",
						coeffs[0], coeffs[1], coeffs[2], coeffs[3]);
			for (k=0; k < numCoeff;k++) {
				[funcID setConstValue:k channel:chan value:coeffs[k]];
			}
			free(arrayX);
			free(arrayY);
			free(sig);					
    }
    else {
      NSLog(@"fit for channel %d\n", chan);
      NSLog(@"a=%f  b=%f  c=%f d=%f\n",0.0, 0.0, 0.0, 0.0);
			for (k=0; k < numCoeff;k++) {
				[funcID setConstValue:k channel:chan value:0.0];
			}
		}
  }
}

- (void) adjust:(id)funcID
{
	int        pos, count, chan, numChannels;
  int        currentShift=0, tempShift;
  int        dataStart=0;
  float      value;
  FILE       *fp;
  NSString   *logPath;
	
  logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"mobilityadjust.log"];
  fp = fopen([logPath fileSystemRepresentation], "w");
	
  count = [dataList length];
  numChannels = [dataList numChannels];
	
  for(chan=1; chan<numChannels; chan++) {
    if(fp!=NULL) fprintf(fp,"mobility adjust for channel %d\n",chan);
		
    dataStart = 0;
		
    currentShift = [funcID valueAt:(float)dataStart channel:chan];
    if(currentShift>0.0) {
      if(fp!=NULL) { fprintf(fp, "initial delete %d points\n", currentShift); fflush(fp); }
      [dataList removeSamples:currentShift atIndex:0 channel:chan];
			
    }
    else if(currentShift<0.0){
      if(fp!=NULL) { fprintf(fp, "initial insert %d points\n", currentShift); fflush(fp); }
      value = 0.0;
      [dataList insertSamples:-currentShift atIndex:0 channel:chan];
      if(fp!=NULL) { fprintf(fp, "initial insert success\n"); fflush(fp); }
    }
		
    for(pos=dataStart; pos<count; pos++) {
      tempShift = (int)([funcID valueAt:(double)(pos) channel:chan] + 0.5);
      if(tempShift != currentShift) {
        if(tempShift > currentShift) {
          if(fp!=NULL) {
            fprintf(fp," insert point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [funcID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          value = [dataList sampleAtIndex:(pos-1) channel:chan];
          value += [dataList sampleAtIndex:pos channel:chan];
          value = value / 2.0;
          [dataList insertSamples:(tempShift-currentShift) atIndex:pos channel:chan];
        }
        else {
          if(fp!=NULL) {
            fprintf(fp," delete point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [funcID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          if (((currentShift-tempShift)+pos) < count)
            [dataList removeSamples:(currentShift-tempShift) atIndex:pos channel:chan];
        }
        currentShift = tempShift;
      }
    }
  }
  if(fp!=NULL) fclose(fp);	
}

//API with GUI

- (void)setWindow:(int)number formula:(int)formula
{
	noWindows = number;
	theFormula = formula;
}

- (void)getWindow:(int *)number formula:(int *)formula
{
	*number=noWindows;
	*formula=theFormula;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	MobilityAdjust *mySelf;
	
	mySelf = [super copyWithZone:zone];
	mySelf->noWindows = noWindows;
	mySelf->theFormula = theFormula;
	
	return mySelf;
}

//AsciiArchiver
-(void)beginDearchiving:archiver
{
	[self init];
	[super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"Adjust-noWindows"))
		[archiver readData:&noWindows];
	else if (!strcmp(tag,"Adjust-formula"))
		[archiver readData:&theFormula];
//    mobilityFunctionID = [[archiver readObject] retain];
  else 
		return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeData:&noWindows type:"i" tag:"Adjust-noWindows"];
	[archiver writeData:&theFormula type:"i" tag:"Adjust-formula"];
//	[archiver writeObject:mobilityFunctionID tag:"mobility3FunctionID"];
  [super writeAscii:archiver];
}

@end
