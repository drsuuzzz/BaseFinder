//
//  MobilityRoutines.m
//  ShapeFinder
//
//  Created by Suzy Vasa on 9/26/07.
//  Copyright 2007 UNC-CH, Giddings Lab. All rights reserved.
//

#import "MobilityRoutines.h"

@implementation MobilityFunc1

/***
*
* implementation of the MobilityFuncProtocol object with 
* a fixed equation of the form 
*		f(x) = a/x + bx + c
* where only the constants are archived
***/

- init
{
  int		chan;
	
  for(chan=0; chan<8; chan++) {
    A[chan] = B[chan] = C[chan] = 0.0;
  }
	
  /***
		A[2] = 27835.5;
	B[2] = 0.00344359;
	C[2] = -19.5337;
	
	A[3] = 27048.5;
	B[3] = 0.00305674;
	C[3] = -15.4784;
	***/
  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];
  int               i;
	
  for(i=0; i<4; i++) {
    [tempString appendFormat:@"\n      %f/x  + %fx  + %f",A[i], B[i], C[i]];    
  }
  return tempString;
}

- (double)valueAt:(double)x channel:(int)chan
{
  double		value;
	
  if((chan<0) || (chan >= 8)) return 0.0;
  value = A[chan]/x + B[chan]*x + C[chan];
  return value;
}

- (double)constValue:(int)index channel:(int)chan
{
  if((chan<0) || (chan >= 8)) return 0.0;
  switch(index) {
    case 0: return A[chan];
    case 1: return B[chan];
    case 2: return C[chan];
  }
  return 0.0;
}

- (void)setConstValue:(int)index channel:(int)chan value:(double)value
{
  if((chan<0) || (chan >= 8)) return;
  switch(index) {
    case 0: A[chan]=value; break;
    case 1: B[chan]=value; break;
    case 2: C[chan]=value; break;
  }
}

/****
*
* AsciiArchiver routines
*
****/
- handleTag:(char *)tag fromArchiver:archiver
{
  int cnt;
	
  //printf(" handleTag='%s'\n",tag);
  if (!strcmp(tag,"A_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:A];
  } else if (!strcmp(tag,"B_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:B];
  } else if (!strcmp(tag,"C_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:C];
  } else
    return [super handleTag:tag fromArchiver:archiver];
	
  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeArray:A size:8 type:"d" tag:"A_const"];
  [archiver writeArray:B size:8 type:"d" tag:"B_const"];
  [archiver writeArray:C size:8 type:"d" tag:"C_const"];
	
  [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  //printf(" beginDearchive\n");
  [self init];
  [super beginDearchiving:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  MobilityFunc1     *dupSelf;
	
  dupSelf = [[[self class] allocWithZone:zone] init];
  memcpy(dupSelf->A, A, sizeof(double)*8);
  memcpy(dupSelf->B, B, sizeof(double)*8);
  memcpy(dupSelf->C, C, sizeof(double)*8);
  return dupSelf;
}

@end

@implementation MobilityFunc2

/***
*
* implementation of the MobilityFuncProtocol object with 
* a fixed equation of the form 
*		f(x) = a/x + bx + c
* where only the constants are archived
***/

- init
{
  int		chan;
	
  for(chan=0; chan<8; chan++) {
    A[chan] = B[chan] = C[chan] = 0.0;
  }
	
  /***
		A[2] = 27835.5;
	B[2] = 0.00344359;
	C[2] = -19.5337;
	
	A[3] = 27048.5;
	B[3] = 0.00305674;
	C[3] = -15.4784;
	***/
  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];
  int               i;
	
  for(i=0; i<4; i++) {
    [tempString appendFormat:@"\n      %f  + %fx  + %fx^2",A[i], B[i], C[i]];    
  }
  return tempString;
}

- (double)valueAt:(double)x channel:(int)chan
{
  double		value;
	
  if((chan<0) || (chan >= 8)) return 0.0;
  value = A[chan] + B[chan]*x + C[chan]*x*x;
  return value;
}

- (double)constValue:(int)index channel:(int)chan
{
  if((chan<0) || (chan >= 8)) return 0.0;
  switch(index) {
    case 0: return A[chan];
    case 1: return B[chan];
    case 2: return C[chan];
  }
  return 0.0;
}

- (void)setConstValue:(int)index channel:(int)chan value:(double)value
{
  if((chan<0) || (chan >= 8)) return;
  switch(index) {
    case 0: A[chan]=value; break;
    case 1: B[chan]=value; break;
    case 2: C[chan]=value; break;
  }
}

/****
*
* AsciiArchiver routines
*
****/
- handleTag:(char *)tag fromArchiver:archiver
{
  int cnt;
	
  //printf(" handleTag='%s'\n",tag);
  if (!strcmp(tag,"A_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:A];
  } else if (!strcmp(tag,"B_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:B];
  } else if (!strcmp(tag,"C_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:C];
  } else
    return [super handleTag:tag fromArchiver:archiver];
	
  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeArray:A size:8 type:"d" tag:"A_const"];
  [archiver writeArray:B size:8 type:"d" tag:"B_const"];
  [archiver writeArray:C size:8 type:"d" tag:"C_const"];
	
  [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  //printf(" beginDearchive\n");
  [self init];
  [super beginDearchiving:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  MobilityFunc2     *dupSelf;
	
  dupSelf = [[[self class] allocWithZone:zone] init];
  memcpy(dupSelf->A, A, sizeof(double)*8);
  memcpy(dupSelf->B, B, sizeof(double)*8);
  memcpy(dupSelf->C, C, sizeof(double)*8);
  return dupSelf;
}

@end

@implementation Mobility3Func

/***
*
* implementation of the MobilityFuncProtocol object with 
* a fixed equation of the form 
*		f(x) = a + bx + cx^2 + dx^3
* where only the constants are archived
***/

- init
{
  int		chan;
	
  for(chan=0; chan<8; chan++) {
    A[chan] = B[chan] = C[chan] = D[chan] = 0.0;
  }
	
  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];
  int               i;
	
  for(i=0; i<8; i++) {
    [tempString appendFormat:@"\n      %f  + %fx  + %fx^2  + %fx^3",A[i], B[i], C[i], D[i]];    
  }
  return tempString;
}

- (double)valueAt:(double)x channel:(int)chan
{
  double		value;
	
  if((chan<0) || (chan >= 8)) return 0.0;
  value = A[chan] + B[chan]*x + C[chan]*x*x + D[chan]*x*x*x;
  return value;
}

- (double)constValue:(int)index channel:(int)chan
{
	double	val;
	
  if((chan<0) || (chan >= 8)) return 0.0;
	val = 0.0;
  switch(index) {
    case 0: val = A[chan]; break;
    case 1: val = B[chan]; break;
    case 2: val = C[chan]; break;
		case 3: val = D[chan]; break;
  }
  return val;
}

- (void)setConstValue:(int)index channel:(int)chan value:(double)value
{
  if((chan<0) || (chan >= 8)) return;
  switch(index) {
    case 0: A[chan]=value; break;
    case 1: B[chan]=value; break;
    case 2: C[chan]=value; break;
		case 3: D[chan]=value; break;
  }
}

/****
*
* AsciiArchiver routines
*
****/
- handleTag:(char *)tag fromArchiver:archiver
{
  int cnt;
	
  //printf(" handleTag='%s'\n",tag);
  if (!strcmp(tag,"A_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:A];
  } else if (!strcmp(tag,"B_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:B];
  } else if (!strcmp(tag,"C_const")) {
    cnt = [archiver arraySize];
    if (!cnt) { // problem
      return nil;
    }
    [archiver readArray:C];
  } else if (!strcmp(tag,"D_const")) {
		cnt = [archiver arraySize];
		if (!cnt) {
			return nil;
		}
		[archiver readArray:D];
	} else
    return [super handleTag:tag fromArchiver:archiver];
	
  return self;
}

- (void)writeAscii:archiver
{	
  [archiver writeArray:A size:8 type:"d" tag:"A_const"];
  [archiver writeArray:B size:8 type:"d" tag:"B_const"];
  [archiver writeArray:C size:8 type:"d" tag:"C_const"];
	[archiver writeArray:D size:8 type:"d" tag:"D_const"];
	
  [super writeAscii:archiver];
}

- (void)beginDearchiving:archiver
{
  [self init];
  [super beginDearchiving:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  Mobility3Func     *dupSelf;
	
  dupSelf = [[[self class] allocWithZone:zone] init];
  memcpy(dupSelf->A, A, sizeof(double)*8);
  memcpy(dupSelf->B, B, sizeof(double)*8);
  memcpy(dupSelf->C, C, sizeof(double)*8);
	memcpy(dupSelf->D, D, sizeof(double)*8);
  return dupSelf;
}

@end
