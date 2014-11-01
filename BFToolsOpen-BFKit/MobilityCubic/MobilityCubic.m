/***********************************************************

Copyright (c) 2007 Suzy Vasa

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
NIH Center for AIDS Research


******************************************************************/

#import "MobilityCubic.h"

@implementation MobilityCubic

- init
{
  [super init];
  mobilityFunctionID = [[Mobility3Func alloc] init];
  myBaseList = NULL;
  return self;
}

- (NSString*)description
{
  NSMutableString   *tempString = [NSMutableString stringWithString:[super description]];

  [tempString appendFormat:@"\n    mobilityFunc=%@",[mobilityFunctionID description]];
  return tempString;
}


- (NSString *)defaultLabel
{
  return @"Default Mobility";
}

- (NSString *)toolName
{
  return @"Mobility Shift: Cubic";
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  MobilityCubic     *dupSelf;

  dupSelf = [super copyWithZone:zone];
  //if(dupSelf->mobilityFunctionID != NULL) [dupSelf->mobilityFunctionID release];
  dupSelf->mobilityFunctionID = [mobilityFunctionID copy];
  return dupSelf;
}

- (void)dealloc
{
  [mobilityFunctionID release];
  [super dealloc];
}

/****
*
* resource handling section (subclass must implement)
*
****/

- (void)writeResource:(NSString*)resourcePath
{
  AsciiArchiver   *archiver;

  archiver = [[AsciiArchiver alloc] initForWriting];
  [archiver writeObject:mobilityFunctionID tag:"mobility3FunctionID"];
  [archiver writeToFile:resourcePath atomically:YES];
  [archiver release];
}

- (void)readResource:(NSString*)resourcePath
{
  AsciiArchiver   *archiver;
  id              tempFunc;
  char            tagBuf[MAXTAGLEN];
	NSScanner				*tempscan;
	NSString				*classname=@"Mobility3Func";

  archiver = [[AsciiArchiver alloc] initWithContentsOfFile:resourcePath];
  if(!archiver) return;

  [archiver getNextTag:tagBuf];

  if(strcmp(tagBuf, "mobility3FunctionID") != 0) {
    /***
    [[controller toolMaster] log:
      @"resource file does not have a 'mobilityFunctionID' object"];
    ***/
    NSLog([NSString stringWithFormat:@"  tag='%s'\n", tagBuf]);
    return;
  }
	
	tempscan = [NSScanner scannerWithString:[[NSString alloc] initWithContentsOfFile:resourcePath]];
	[tempscan scanUpToString:classname intoString:nil];
	if ([tempscan isAtEnd]) {
		NSLog([NSString stringWithFormat:@"Incompatible class name\n"]);
		return;
	}
	if ((tempFunc=[archiver readObject])!=nil) {
    if(mobilityFunctionID) [mobilityFunctionID release];
    mobilityFunctionID = [tempFunc retain];
  }
  //mobilityFunctionID = [archiver readObjectWithTag:"mobilityFunctionID"];
  [archiver release];
}

/****/

- (BOOL)modifiesData { return YES; }		//to switch between processor/analyzer

- apply
{	
  int        pos, count, chan, numChannels;
  int        currentShift=0, tempShift;
  int         dataStart=0;
  float      value;
  FILE       *fp;
  NSString   *logPath;

  logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"mobilitycubic.log"];
  fp = fopen([logPath fileSystemRepresentation], "w");

  count = [dataList length];
  numChannels = [dataList numChannels];

  for(chan=0; chan<numChannels; chan++) {
    if(fp!=NULL) fprintf(fp,"mobilityShift for channel %d\n",chan);

    dataStart = 0;

    currentShift = [mobilityFunctionID valueAt:(float)dataStart channel:chan];
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
      tempShift = (int)([mobilityFunctionID valueAt:(double)(pos)
                                            channel:chan] + 0.5);
      if(tempShift != currentShift) {
        if(tempShift < currentShift) {
          if(fp!=NULL) {
            fprintf(fp," insert point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [mobilityFunctionID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          value = [dataList sampleAtIndex:(pos-1) channel:chan];
          value += [dataList sampleAtIndex:pos channel:chan];
          value = value / 2.0;
          [dataList insertSamples:(currentShift-tempShift) atIndex:pos channel:chan];
        }
        else {
          if(fp!=NULL) {
            fprintf(fp," delete point at x=%d, oldShift=%d newShift=%d  %5.2f\n",
                    pos, currentShift, tempShift,
                    [mobilityFunctionID valueAt:(double)pos channel:chan]);
            fflush(fp);
          }
          if (((tempShift-currentShift)+pos) < count)
            [dataList removeSamples:(tempShift-currentShift) atIndex:pos channel:chan];
        }
        currentShift = tempShift;
      }
    }
  }
  if(fp!=NULL) fclose(fp);
  return [super apply];
}

/****
* ASCIIarchiver methods required for scripting
****/
-(void) beginDearchiving:archiver;
{
  [self init];
  [super beginDearchiving:archiver];
}

- handleTag:(char *)tag fromArchiver:archiver;
{
  if (!strcmp(tag,"mobility3FunctionID"))
    mobilityFunctionID = [[archiver readObject] retain];
  else return [super handleTag:tag fromArchiver:archiver];
  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeObject:mobilityFunctionID tag:"mobility3FunctionID"];
  [super writeAscii:archiver];
}
@end
