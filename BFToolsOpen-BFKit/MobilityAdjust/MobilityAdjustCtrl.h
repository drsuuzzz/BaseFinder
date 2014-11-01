//
//  MobilityAdjustCtrl.h
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/17/07.
//  Copyright 2007 UNC-CH, Giddings Lab. All rights reserved.
//

#import <BaseFinderKit/GenericToolCtrl.h>


@interface MobilityAdjustCtrl : GenericToolCtrl {
	IBOutlet	NSTextField	*windowID;
	IBOutlet	NSMatrix		*formulaID;
	
	
}
- init;
- (void)awakeFromNib;

- (void)displayParams;
- (void)getParams;

@end
