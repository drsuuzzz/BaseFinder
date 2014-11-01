/* "$Id: ShapeObj.h,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */

#import <Foundation/NSObject.h>
#import <objc/objc.h>



@interface ShapeObj:NSObject
{
	id numericalObj;
	id thebaseList;
	id thedataList;
	float weight;
	float lowConfThresh;
}
- initwithWeight:(float)Weight minConfidence:(float)conf;
- (void)setupConfidences:(id)baseList :(id)Data;
- (void)setWeight:(float)Weight;
- (float)confWeight;
- (float)returnWeightedConfidence:(int)baseNumber;
- (float)returnConfidence:(int)Location withWeight:(BOOL)yes_no;
- (void)setConfThresh:(float)thresh;
- (void)setHighestOrder:(int)order;
@end
