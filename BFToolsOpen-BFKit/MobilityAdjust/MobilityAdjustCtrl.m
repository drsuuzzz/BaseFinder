//
//  MobilityAdjustCtrl.m
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/17/07.
//  Copyright 2007 UNC-CH, Giddings Lab. All rights reserved.
//

#import "MobilityAdjustCtrl.h"
#import "MobilityAdjust.h"


@implementation MobilityAdjustCtrl

- init
{
	NSUserDefaults	*myDefaults;
	NSDictionary		*defaultsDict = [NSDictionary dictionaryWithObjectsAndKeys:
																	@"100",@"Adjust-window",
																	@"0", @"Adjust-formula",
																	nil];
	
	[super init];
	myDefaults = [NSUserDefaults standardUserDefaults];
	[myDefaults registerDefaults:defaultsDict];
	[myDefaults synchronize];
	return self;
}

- (void)awakeFromNib
{
	int		nwindows;
	int		formula;
	
	nwindows = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Adjust-window"] intValue];
	formula = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Adjust-formula"] intValue];
	
	[windowID setIntValue:nwindows];
	[formulaID selectCellAtRow:formula column:0];
	[dataProcessor setWindow:nwindows formula:formula];
}

- (void)displayParams
{
	int	n, f;
	
	[super displayParams];
	[dataProcessor getWindow:&n formula:&f];
	[windowID setIntValue:n];
	[formulaID selectCellAtRow:f column:0];
}

- (void)getParams
{
	NSUserDefaults	*myDefaults=[NSUserDefaults standardUserDefaults];
	int n, f;
	
	[super getParams];
	n = [windowID intValue];
	if (n < 0)
		n = 100;
	f = [formulaID selectedRow];
	
	[dataProcessor setWindow:n formula:f];	
	[myDefaults setInteger:n forKey:@"Adjust-window"];
	[myDefaults setInteger:f forKey:@"Adjust-formula"];
}

@end
