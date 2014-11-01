/* "$Id: Base.m,v 1.3 2007/05/23 20:29:54 smvasa Exp $" */

/***********************************************************

Copyright (c) 1996-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

#import "Base.h"



@interface Base(private)
-(char)computeBaseFromConfidences;
@end


@implementation Base

+ baseWithCall:(char)theBase confidence:(unsigned char)confidence;
{
  Base *newBase;

  newBase = [[Base alloc] init];
  newBase->base = theBase;
  newBase->conf = confidence;
  switch(theBase) {
      case 'A': case 'a': newBase->confidences[0]=confidence; break;
      case 'C': case 'c': newBase->confidences[1]=confidence; break;
      case 'G': case 'g': newBase->confidences[2]=confidence; break;
      case 'T': case 't': newBase->confidences[3]=confidence; break;
    case 'N': case 'n': break;
  }
  return [newBase autorelease];
}

+newBase
{
  Base                            *newBase;

  newBase = [[Base alloc] init];
  [newBase autorelease];
  return newBase;
}


+ baseWithCall:(char)theBase floatConfidence:(float)confidence location:(unsigned int)loc
{
  Base *newBase;
  newBase = [[Base alloc] init];
  newBase->base = theBase;
  if (confidence > 1.0) confidence = 1.0;
  if (confidence < 0) confidence = 0.0;
  newBase->conf = (unsigned char)(confidence * 255.0);
  switch(theBase) {
    case 'A': case 'a': newBase->confidences[0]=(unsigned char)(confidence * 255.0); break;
    case 'C': case 'c': newBase->confidences[1]=(unsigned char)(confidence * 255.0); break;
    case 'G': case 'g': newBase->confidences[2]=(unsigned char)(confidence * 255.0); break;
    case 'T': case 't': newBase->confidences[3]=(unsigned char)(confidence * 255.0); break;
    case 'N': case 'n': break;
  }
  newBase->location = loc;
  return [newBase autorelease];
}

+ baseWithChannel:(unsigned)_channel floatConfidence:(float)confidence location:(unsigned int)loc peak:(id <LadderPeak>)_peak;
{
    Base *newBase;
    newBase = [[Base alloc] init];
    [newBase setChannel:_channel];
    switch (_channel)
      {
        case A_BASE: newBase->base = 'A';
            break;
        case T_BASE: newBase->base = 'T';
            break;
        case C_BASE: newBase->base = 'C';
            break;
        case G_BASE: newBase->base = 'G';
            break;
        case UNKNOWN_BASE: newBase->base = 'N';
            break;
        default:
        newBase->base = '-';
      }   
    if (confidence > 1.0) confidence = 1.0;
    if (confidence < 0) confidence = 0.0;
    newBase->conf = (unsigned char)(confidence * 255.0);
    switch(newBase->base) {
      case 'A': case 'a': newBase->confidences[0]=(unsigned char)(confidence * 255.0); break;
      case 'C': case 'c': newBase->confidences[1]=(unsigned char)(confidence * 255.0); break;
      case 'G': case 'g': newBase->confidences[2]=(unsigned char)(confidence * 255.0); break;
      case 'T': case 't': newBase->confidences[3]=(unsigned char)(confidence * 255.0); break;
      case 'N': case 'n': break;
    }
    newBase->location = loc;
    newBase->peak = [_peak retain];
    return [newBase autorelease];

}

+ baseWithChannel:(unsigned)_channel floatConfidence:(float)confidence location:(unsigned int)loc
{
    Base *newBase;
    newBase = [[Base alloc] init];
    [newBase setChannel:_channel];
    switch (_channel)
      {
        case A_BASE: newBase->base = 'A';
            break;
        case T_BASE: newBase->base = 'T';
            break;
        case C_BASE: newBase->base = 'C';
            break;
        case G_BASE: newBase->base = 'G';
            break;
      }   
    if (confidence > 1.0) confidence = 1.0;
    if (confidence < 0) confidence = 0.0;
    newBase->conf = (unsigned char)(confidence * 255.0);
    switch(newBase->base) {
      case 'A': case 'a': newBase->confidences[0]=(unsigned char)(confidence * 255.0); break;
      case 'C': case 'c': newBase->confidences[1]=(unsigned char)(confidence * 255.0); break;
      case 'G': case 'g': newBase->confidences[2]=(unsigned char)(confidence * 255.0); break;
      case 'T': case 't': newBase->confidences[3]=(unsigned char)(confidence * 255.0); break;
      case 'N': case 'n': break;
    }
    newBase->location = loc;
    return [newBase autorelease];

}



+ baseWithCall:(char)theBase confA:(unsigned char)confA confC:(unsigned char)confC confG:(unsigned char)confG confT:(unsigned char)confT;
{
  Base           *newBase;
  int            i;
  unsigned char  maxConf;

  newBase = [[Base alloc] init];
  newBase->base = theBase;
  newBase->confidences[0]=confA;
  newBase->confidences[1]=confC;
  newBase->confidences[2]=confG;
  newBase->confidences[3]=confT;
  maxConf = newBase->confidences[0];
  for(i=1; i<4; i++) {
      if(newBase->confidences[i] > maxConf) maxConf=newBase->confidences[i];
  }
  newBase->conf = maxConf;
  return [newBase autorelease];
}

+ newWithChar:(char)thebase
{	
  id   thePtr;
  thePtr = [[[self alloc] init] autorelease];
  [thePtr setBase:toupper(thebase)];
  return thePtr;
}

+(BOOL)validBase:(char)thebase
{
  if (thebase == 'C' ||
      thebase == 'A' ||
      thebase == 'G' ||
      thebase == 'T' ||
			thebase == 'U' ||
      thebase == 'c' ||
      thebase == 'a' ||
      thebase == 'g' ||
      thebase == 't' ||
			thebase == 'u' ||
      thebase == '.' ||  //place holder used in comparison algorithms
      thebase == '*' ||  //place holder used in comparison algorithms
      thebase == 'N' ||
      thebase == 'n')
    return YES;
  else
    return NO;
}

- init
{
  confidences[0] = 0;
  confidences[1] = 0;
  confidences[2] = 0;
  confidences[3] = 0;
  base = ' ';
  conf = 0;
  other_annotation = NULL;
  location = 0;
  channel = -2;
  return self;
}

- (NSString*)description
{
  NSMutableString  *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@", base=%c", base];
  [tempString appendFormat:@", conf=%f", ((float)conf)/255.0];
  [tempString appendFormat:@", confA=%d", confidences[0]];
  [tempString appendFormat:@", confC=%d", confidences[1]];
  [tempString appendFormat:@", confG=%d", confidences[2]];
  [tempString appendFormat:@", confT=%d", confidences[3]];
  [tempString appendFormat:@", loc=%d", location];
  return tempString;
}

- replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy])
        return self;
    else
        return [super replacementObjectForPortCoder:encoder];
}


- (id)initWithCoder:(NSCoder *)coder
{
  //[super initWithCoder:coder];
  [coder decodeValuesOfObjCTypes:"ccccccI", &base, &conf, &confidences[0], &confidences[1],
      &confidences[2], &confidences[3], &location];
  other_annotation = [coder decodeObject];
  if (other_annotation != NULL)
    [other_annotation retain];
  return self;
}

- (void)setBase:(char)thebase
{
  base = thebase;
}
	
- (char)retBase
{
  return [self base];
}

- (NSString *)strBase
{
    char _base = [self base];
    if (_base == 'A')
      return @"A";
    else if (_base == 'C')
      return @"C";
    else if (_base == 'T')
      return @"T";
    else if (_base == 'G')
      return @"G";
		else if (_base == 'U')
			return @"U";
    else if (_base == 'N')
      return @"N";
    else {
      char thestr[1];
      thestr[0] = _base;
      return [NSString stringWithCString:thestr length:1];
    }
}


- (char)base
{
  if (base != 'Z')
    return base;
  else {
    [self computeBaseFromConfidences];
    return base;
  }
}

- (void)setLocation:(unsigned int)loc;
{
  location = loc;
}

- (unsigned int)location
{
  return location;
}

- (void)setChannel:(int)_channel
{

    channel = (char)_channel;
    switch (_channel)
      {
        case A_BASE: base = 'A';
            break;
        case T_BASE: base = 'T';
            break;
        case C_BASE: base = 'C';
            break;
        case G_BASE: base = 'G';
            break;
        case UNKNOWN_BASE: base = 'N';
            break;
        default:
          base = '-';

      }  
}

- (int)channel;
{
    if (channel == -2)
        switch(base) {
            case 'C': case 'c': channel = 0; break;
            case 'A': case 'a': channel = 1; break;
            case 'G': case 'g': channel = 2; break;
            case 'T': case 't': case 'U': case 'u': channel = 3; break;
            case 'N': case 'n': channel = -1; break;
  }
            return (int)channel;
}

- (void)setConf:(unsigned char)confidence;
{
  conf = confidence;
}

- (void)setFloatConf:(float)confidence
{
  if (confidence<0.0)
    confidence = 0.0;
  if (confidence>1.0)
    confidence = 1.0;
  conf = (unsigned char)(confidence * 255.0);
}

- (unsigned char)retConf
{
  if (base != 'Z')
    return conf;
  else {
    [self computeBaseFromConfidences];
    return conf;
  }		
}

- (float)floatConfidence
{
    return ((float)[self retConf] / 255.0);
}

- (unsigned char)confidence;
{
  return [self retConf];
}

- (void)setConfA:(unsigned char)confidence
{
  confidences[0] = confidence;
  base = 'Z';
}

- (void)setConfC:(unsigned char)confidence
{
  confidences[1] = confidence;
  base = 'Z';
}

- (void)setConfT:(unsigned char)confidence
{
  confidences[3] = confidence;
  base = 'Z';

}

- (void)setConfG:(unsigned char)confidence
{
  confidences[2] = confidence;
  base = 'Z';
}

- (unsigned char)confA
{
  return (confidences[0]);
}

- (unsigned char)confC
{
  return (confidences[1]);
}

- (unsigned char)confT
{
  return (confidences[3]);
}

- (unsigned char)confG
{
  return (confidences[2]);
}

- (void)setAnnotation:(id)obj forKey:(NSString *)key
{
  if (other_annotation == nil) {
    other_annotation = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    }

  [other_annotation setObject:obj forKey:key];
}

- (void)addKeyValuePair:(NSString *)key value:(id)value
{
  if (other_annotation == nil) {
    other_annotation = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    }

  [other_annotation setObject:value forKey:key];
}
	
- (void)changeAnnotationForKey:(NSString *)key value:(id)value
{
  if (other_annotation == nil)
    return;
  [other_annotation setObject:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
  if (other_annotation == nil)
    return nil;
  return [other_annotation objectForKey:key];
}

- (void)dealloc
{
    if (other_annotation != nil)
        [other_annotation release];
    if (peak)
        [peak release];
    [super dealloc];
}

-(id <LadderPeak>)peak
{
    return peak;
}

- (void)setPeak:(id <LadderPeak>)_peak
{
    if (peak)
        [peak release];
    peak = [_peak retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  //[super encodeWithCoder:coder];
  [coder encodeValuesOfObjCTypes:"ccccccI", &base, &conf, &confidences[0], &confidences[1],
    &confidences[2], &confidences[3], &location];
  [coder encodeBycopyObject:other_annotation];
}

/*****
* NSCopying protocol
*****/

- (id)copyWithZone:(NSZone *)zone
{
  Base           *dupSelf;
  unsigned       i;

  dupSelf = [[[self class] allocWithZone:zone] init];

  dupSelf->base = base;
  dupSelf->conf = conf;		
  dupSelf->location = location;		
  for(i=0; i<4; i++)
    dupSelf->confidences[i] = confidences[i];
  if (other_annotation)
      dupSelf->other_annotation = [other_annotation mutableCopyWithZone:zone];
  else
      dupSelf->other_annotation = NULL;
  dupSelf->peak = [peak retain];
  dupSelf->channel = channel;
  return dupSelf;
}

- (NSComparisonResult)comparePosition:(id <BaseProtocol>)obj
{
        if ([self location] < [obj location])
                return NSOrderedAscending;
        else if ([self location] > [obj location])
                return NSOrderedDescending;
        else
                return NSOrderedSame;
}


@end

@implementation Base(private)

-(char)computeBaseFromConfidences
{
  unsigned i;
  char largestbase, largestval;
  char mapping[4] = {'A', 'C', 'G', 'T'};

  largestval = confidences[0];
  largestbase = mapping[0];
  for (i = 1; i < 4; i++) {
    if (confidences[i] > largestval) {
      largestval = confidences[i];
      largestbase = mapping[i];
    }
  }
  conf = largestval;
  return (base = largestbase);
}




@end
