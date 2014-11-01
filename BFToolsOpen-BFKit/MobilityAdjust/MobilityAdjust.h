//
//  MobilityAdjust.h
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/17/07.
//  Copyright 2007 UNC-CH, Giddings Lab. All rights reserved.
//

#import <BaseFinderKit/GenericTool.h>


@interface MobilityAdjust : GenericTool {
	int	noWindows;
	int theFormula;
}

-init;
- (id)copyWithZone:(NSZone *)zone;

//GenericTool methods
- apply;
- (NSString *)toolName;
- (BOOL)modifiesData ;
- (BOOL)shouldCache;
-(void)beginDearchiving:archiver;
- handleTag:(char *)tag fromArchiver:archiver;
- (void)writeAscii:archiver;

//API with GUI
- (void)setWindow:(int)number formula:(int)formula;
- (void)getWindow:(int *)number formula:(int *)formula;

@end
