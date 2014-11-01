/* "$Id: ShapeObj.m,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */

#import "NumericalRoutines.h"
#import "SpacingObj.h"
#import <AppKit/NSApplication.h>

@implementation ShapeObj


- initwithWeight:(float)Weight minConfidence:(float)conf
{
	[super init];
	weight = Weight;
	lowConfThresh = conf;
	highestorder = HIGHESTORDER;
	return self;
	
}
	          






- (void)setupConfidences:(id)baseList :(id)Data
{
	int count;
	float A[3];
	
	[self calculateSpacings:baseList :&count];
	[self fitCurveToSpacings:A :count :3];
	a0 = A[0]; a1 = A[1]; a2 = A[2];
	thebaseList = baseList;
	thedataList = Data; 
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
	aBase *leftBase, *centerBase, *rightBase;
	float xl, xfit, xr, cl, cr, center, conf, ldiff, rdiff;
	
	if ((baseNumber < 0) || (baseNumber >= [thebaseList count]))
		return 0;
	else if (baseNumber == 0) {
		leftBase = rightBase = [thebaseList elementAt:(baseNumber + 1)];
		centerBase = [thebaseList elementAt:baseNumber];
	}
	else if (baseNumber == ([thebaseList count]-1)) {
		leftBase = rightBase = [thebaseList elementAt:(baseNumber - 1)];
		centerBase = [thebaseList elementAt:baseNumber];
	}
	else {
		leftBase = [thebaseList elementAt:(baseNumber - 1)];
		centerBase = [thebaseList elementAt:(baseNumber)];
		rightBase = [thebaseList elementAt:(baseNumber+1)];
	}
	
	xl = fabs(leftBase->location - centerBase->location);
	xr = fabs(rightBase->location - centerBase->location);
	center = (float) (centerBase->location);
	xfit = a0 + a1*center + a2 * center * center; /* the fitting function */
	cl = fabs(leftBase->confidence);
	cr = fabs(rightBase->confidence);
	
	ldiff = fabs(xl-xfit);
	rdiff = fabs(xr-xfit);
	conf = 1 - sqrt(pow(ldiff,2) * cl + 
							    pow(rdiff,2) * cr)/(sqrt(2) * 
									xfit);
							
	return conf*weight;
}
	
- (float)returnConfidence:(int)Location withWeight:(BOOL)yes_no;
{
	aBase *leftBase, *centerBase, *rightBase;
	float xl, xfit, xr, cl, cr, center, conf;
	
	if ((Location < 0) || (Location >= [thebaseList count]))
		return 0;
	else if (Location == 0 ) {
		leftBase = rightBase = [thebaseList elementAt:(Location + 1)];
		centerBase = [thebaseList elementAt:Location];
	}
	else if (Location == ([thebaseList count]-1)) {
		leftBase = rightBase = [thebaseList elementAt:(Location - 1)];
		centerBase = [thebaseList elementAt:Location];
	}
	else {
		leftBase = [thebaseList elementAt:(Location - 1)];
		centerBase = [thebaseList elementAt:(Location)];
		rightBase = [thebaseList elementAt:(Location+1)];
	}
	
	xl = fabs(leftBase->location - centerBase->location);
	xr = fabs(rightBase->location - centerBase->location);
	center = (float) (centerBase->location);
	xfit = a0 + a1*center + a2 * center * center; /* the fitting function */
	cl = fabs(leftBase->confidence);
	cr = fabs(rightBase->confidence);
	
	conf = 1 - sqrt((xl-xfit)*(xl-xfit) * cl + (xr - xfit)*(xr - xfit) * cr)/(sqrt(2) * xfit);
	if (yes_no)
		return (conf*weight);
	else
		return conf;

}

- (void)setConfThresh:(float)thresh
{
	lowConfThresh = thresh; 
}

- (void)setHighestOrder:(int)order
{
	highestorder = order; 
}


@end