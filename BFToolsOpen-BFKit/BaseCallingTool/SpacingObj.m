/* "$Id: SpacingObj.m,v 1.2 2007/01/24 19:34:06 smvasa Exp $" */
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

#define HIGHESTORDER 3
#import "SpacingObj.h"
#import "SizeObj.h"
#import <math.h>
#import <GeneKit/NumericalObject.h>
//#import "SeqList.h"

float a0, a1, a2;

float confidenceAtBase(int base, Sequence *baseList) {
	Base *leftBase, *centerBase, *rightBase;
	float xl, xfit, xr, cl, cr, center, conf, ldiff, rdiff;
	
	if ((base < 0) || (base >= [baseList count]))
		return 0;
	else if (base == 0) {
		leftBase = rightBase = (Base*)[baseList baseAt:(base + 1)];
		centerBase = (Base *)[baseList baseAt:base];
	}
	else if (base == ([baseList count]-1)) {
		leftBase = rightBase = (Base *)[baseList baseAt:(base - 1)];
		centerBase = (Base *)[baseList baseAt:base];
	}
	else {
		leftBase = (Base *)[baseList baseAt:(base - 1)];
		centerBase = (Base *)[baseList baseAt:(base)];
		rightBase = (Base *)[baseList baseAt:(base+1)];
	}
	
	xl = fabs([leftBase location] - [centerBase location]);
	xr = fabs([rightBase location] - [centerBase location]);
        center = (float) ([centerBase location]);
        xfit = a0 + a1*center + a2 * center * center; /* the fitting function */
        // A quick hack to try to accomadate GC compressions (i.e. relax the penalty)
	if ((([leftBase base] == 'G') && ([centerBase base] == 'C')) ||
			(([leftBase base] == 'C') && ([centerBase base] == 'G'))) 
			xl = (xl + xfit)/2;
	if ((([rightBase base] == 'G') && ([centerBase base] == 'C')) ||
			(([rightBase base] == 'C') && ([centerBase base] == 'G'))) 
			xr = (xr + xfit)/2;
	cl = fabs([leftBase floatConfidence]);
	cr = fabs([rightBase floatConfidence]);
	
	ldiff = fabs(xl-xfit);
	rdiff = fabs(xr-xfit);
//	conf = 1 - sqrt(pow(ldiff,2.5) * cl + 
//							    pow(rdiff,2.5) * cr)/(sqrt(2) * 
//									xfit);
// *** Most recent one
//	conf = 1 - sqrt(pow(ldiff,2.1) * cl + 
//							    pow(rdiff,2.1) * cr)/(sqrt(2) * 
//									xfit);
	conf = (1 - sqrt(pow(ldiff, 2.1) * cl)/xfit) *
					(1 - sqrt(pow(rdiff, 2.1) * cr)/xfit);
//		conf = 1 - exp( -5 + 5*(ldiff+rdiff)/(xfit*2));

//	if ((base % 20) == 0) {
//		sprintf(fun, "base:%d xl:%f  xr:%f  xfit:%f  conf:%f\n", base, xl, xr, //xfit, conf);
//		[distributor addTextAnalysis:fun];
//	}
	if ((conf < 0) || (conf > 1))
		conf = 0.5;
	return conf;
}


@implementation SpacingObj
static	float K[3][20000];


- initwithWeight:(float)Weight minConfidence:(float)conf
{
	[super init];
	addedBases = NO;
	weight = Weight;
	lowConfThresh = conf;
	highestorder = HIGHESTORDER;
	return self;
	
}
	          


- (void)calculateSpacings:(Sequence *)baseList :(int *)count
{
  int i,j;
  int mycount=0, totalCount=0;
  int internalIterations;
  Base *firstBase, *secondBase;

  totalCount = [baseList count];
  for (i = 0; i < (totalCount-highestorder); i++) {
    firstBase = (Base *)[baseList baseAt:i];
    if (([firstBase floatConfidence]) < lowConfThresh)
      continue;
    if ([[firstBase valueForKey:@"owner"] intValue] == BASEOWNERLABEL)
      continue;
    internalIterations = highestorder;
    for (j = 1; ((j <= internalIterations) && ((i+j) < totalCount));
         j++) {
      secondBase = (Base *)[baseList baseAt:(i+j)];
      if (([secondBase  floatConfidence]) < lowConfThresh) {
        internalIterations += 1;
        continue;
      }
      if ([firstBase location] < [secondBase location]) {
        K[0][mycount] = [firstBase location] + ([secondBase location] -
                                               [firstBase location])/2;
        K[1][mycount] = ([secondBase location] - [firstBase location]);
        K[2][mycount] = 1-([secondBase floatConfidence] + [firstBase floatConfidence])/2;
        mycount++;
      }
    }
  }
  *count = mycount;
}




- (void)dumpSpacings:(Sequence *)baseList
{
  int i,count;
  FILE *fp1, *fp2;
  float A[4]={0,0,0,0};

  [self calculateSpacings:baseList :&count];
  [self fitCurveToSpacings:A :count :3];
  fp2 = fopen("Curve.fit.data","w");
  if(fp2 != NULL) {
    fprintf(fp2, "%e + %e * x + %e * x^2\n", A[0], A[1], A[2]);
    fclose(fp2);
  }

  fp1 = fopen("Spacings.data", "w");
  if(fp1 != NULL) {
    for (i = 0; i < count; i++) {
      fprintf(fp1, "%f	%f	%f\n", K[0][i], K[1][i], K[2][i]);
    }
    fclose(fp1);
  }
}


- addNecessaryBases:(Sequence *)baseList :(Trace *)Data
{
  int count,channels,i,j,k;
  id oldbaseList;
  int leftminloc, location;
  int rightminloc;
  int datacount;
  Base *thebase, *rightbase, *leftbase, *newbase;
  float max = -FLT_MAX, response;
  int spacing, newlocation;
  float *data;
  NumericalObject    *numObj = [[NumericalObject new] autorelease];

  oldbaseList = [baseList copy];
  count = [oldbaseList count];
  for (i = 1; i < (count-1); i++) {
    thebase = (Base *)[baseList baseAt:i];
    location = [thebase location];
    data = [Data sampleArrayAtChannel:[thebase channel]];
    datacount = [Data length];
    leftminloc = [numObj findleftminloc:location :data :datacount];
    rightminloc = [numObj findrightminloc:location :data :datacount];
    spacing = (int) (a0 + a1*location + a2 * location * location);
    if ((rightminloc > (location + spacing)) && (rightminloc != 0)) {
      k = i+1;
      rightbase = (Base *)[baseList baseAt:k];
      while ((k < (count-1)) && (([rightbase channel]) != [thebase channel]))
      {
        k += 1;
        rightbase = (Base *)[baseList baseAt:k];
      }
      newlocation = location+spacing;
      if (newlocation < [rightbase location]) {
        channels = [Data numChannels];
        max = -FLT_MAX;
        response = [Data sampleAtIndex:newlocation channel:[thebase channel]];
//        *(float *)  [(Storage*)[Data objectAt:(thebase->channel)] elementAt:newlocation];
        for (j = 0; j < channels; j++)
          if ([Data sampleAtIndex:newlocation channel:j] > max)
            max = [Data sampleAtIndex:newlocation channel:j];
        if (max == response) {
          newbase = [Base baseWithCall:[thebase base] 
            floatConfidence:[sizeObj returnConfidence:(i+1)] 
            location:newlocation];
          [newbase setChannel:[thebase channel]];
          [newbase setAnnotation:[NSNumber numberWithInt:BASEOWNERLABEL] forKey:@"owner"];
          [baseList insertBase:newbase At:(i+1)];
        /*  newbase.location = newlocation;
          newbase.channel = thebase->channel;
          newbase.base = thebase->base;
          newbase.owner = BASEOWNERLABEL;
          [baseList insertElement:&newbase at:(i+1)];
          newbase.confidence = [sizeObj returnConfidence:(i+1)]; */
        }
      }
    }
    if ((leftminloc < (location - spacing)) && (leftminloc !=0)) {
      k = i-1;
      leftbase = (Base *)[baseList baseAt:k];
      while ((k > 0) && ([leftbase channel] != [thebase channel])) {
        k -= 1;
        leftbase = (Base *)[baseList baseAt:k];
      }
      newlocation = location-spacing;
      if (newlocation > [leftbase location]) {
        channels = [Data numChannels];
        max = -FLT_MAX;
        response = [Data sampleAtIndex:newlocation channel:[thebase channel]];
        for (j = 0; j < channels; j++)
          if ([Data sampleAtIndex:newlocation channel:j] > max)
            max = [Data sampleAtIndex:newlocation channel:j];
        if (max == response) {
          newbase = [Base baseWithCall:[thebase base] 
            floatConfidence:[sizeObj returnConfidence:(i+1)] 
            location:newlocation];
          [newbase setChannel:[thebase channel]];
          [newbase setAnnotation:[NSNumber numberWithInt:BASEOWNERLABEL] forKey:@"owner"];
          [baseList insertBase:newbase At:(i+1)];

      /*    newbase.location = newlocation;
          newbase.channel = thebase->channel;
          newbase.base = thebase->base;
          newbase.owner = BASEOWNERLABEL;
          [baseList insertElement:&newbase at:i];
          newbase.confidence = [sizeObj returnConfidence:i]; */
        }
      }
    }
  }
  return self;

}


- (void)setupConfidences:(Sequence *)baseList :(Trace *)Data
{
	int count;
	float A[3];
	
	[self calculateSpacings:baseList :&count];
	[self fitCurveToSpacings:A :count :3];
	a0 = A[0]; a1 = A[1]; a2 = A[2];
        
        if (thebaseList)
          [thebaseList release];
        if (thedataList)
          [thedataList release];
	thebaseList = [baseList retain];
	thedataList = [Data retain]; 
}


- fitCurveToSpacings:(float *)coeff :(int) numPoints :(int)numCoeff
{
  NumericalObject   *numObj = [[NumericalObject new] autorelease];

  [numObj polyFit:K[0] :K[1] :K[2] :numPoints :coeff :numCoeff];
  return self;
}


- (void)setWeight:(float)Weight
{
	weight = Weight; 
}
- (float)confWeight
{
	return weight;
}

- (float)returnWeightedConfidence:(int)baseNumber 
{

	return(confidenceAtBase(baseNumber, thebaseList)*weight);
}
	
- (float)returnConfidence:(int)baseNumber
{
	return(confidenceAtBase(baseNumber, thebaseList));
}

- (void)setConfThresh:(float)thresh
{
	lowConfThresh = thresh; 
}

- (void)setHighestOrder:(int)order
{
	highestorder = order; 
}


- (void)setSizeObj:(id)theobject
{
	sizeObj = theobject; 
}

- (void)removeGuessedBases:(Sequence*)baseList :(Trace*)Data
{ 	int i;
	Base *thebase;

	for (i = 0; i < [baseList count]; i++) {
		thebase = (Base *)[baseList baseAt:i];
		if ([[thebase valueForKey:@"owner"] intValue] == BASEOWNERLABEL)
			[baseList removeBaseAt:i];
	} 
}

- (float)spacingAt:(int)baseNum
{	float base;

	base = (float) baseNum;
	
	return (a0 + a1 * base + a2 * base * base);
}

- (void)finishCalling
{

 
}

- (void)dealloc
{
  if (thebaseList)
    [thebaseList release];
  if (thedataList)
    [thedataList release]; 
  [super dealloc];
}


@end