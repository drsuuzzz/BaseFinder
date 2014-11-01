//
//  MobilityRoutines.h
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/26/07.
//  Copyright 2007 UNC-CH Giddings Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityFuncProtocol.h"
#import <GeneKit/AsciiArchiver.h>


@interface MobilityFunc1:NSObject <NSCopying, AsciiArchiving, MobilityFunctionProtocol>
{	
  double    A[8], B[8], C[8];
}

- (double)constValue:(int)index channel:(int)chan;
- (void)setConstValue:(int)index channel:(int)chan value:(double)value;
@end

@interface MobilityFunc2:NSObject <NSCopying, MobilityFunctionProtocol, AsciiArchiving>
{	
  double    A[8], B[8], C[8];
}

- (double)constValue:(int)index channel:(int)chan;
- (void)setConstValue:(int)index channel:(int)chan value:(double)value;
@end

@interface Mobility3Func:NSObject <NSCopying, MobilityFunctionProtocol, AsciiArchiving>
{	
  double    A[8], B[8], C[8], D[8];
}

- (double)constValue:(int)index channel:(int)chan;
- (void)setConstValue:(int)index channel:(int)chan value:(double)value;
@end

