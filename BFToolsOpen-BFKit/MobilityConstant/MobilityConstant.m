
/* "$Id: MobilityConstant.m,v 1.2 2006/11/15 15:09:23 smvasa Exp $" */
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


#import "MobilityConstant.h"


/*****
* July 19, 1994 Mike Koehrsen
* Split MobilityConstant class into MobilityConstant and MobilityConstantCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
* Also made a minor functionality change: the user can now choose the channel
* to move manually either before or after pressing the "Shift Selected Channel".
* Also, a bug fix: if the user did repeated manual shifts while making a new
* mobility vector, the earlier shifts would be repeated when the later shifts are
* added, so the total shift would be greater than the user intended. Fixed it.
*
* Sept 14, 1994 Jessica Hayden
* Moved MobilityConstant into a loadable tool.  Mobility shift data is now returned from
* MasterView through the -mouseEvent method.
*****/

@implementation MobilityConstant


- (NSString *)defaultLabel
{
  return @"Default Mobility";
}

- (int)currentMobility:(int)channel
{
  if((channel<0) || (channel>=8)) return 0;
  return currentMobility[channel];
}

- (void)setCurrentMobility:(int)shift forChannel:(int)channel
{
  if((channel<0) || (channel>=8)) return;
  currentMobility[channel] = shift;
}

- (void)writeResource:(NSString*)resourcePath
{
  AsciiArchiver   *archiver;
	
  archiver = [[AsciiArchiver alloc] initForWriting];
	[archiver writeArray:currentMobility size:8 type:"i" tag:"MobilityConstantShifts"];
  [archiver writeToFile:resourcePath atomically:YES];
  [archiver release];

}

- (void)readResource:(NSString*)resourcePath
{
	AsciiArchiver   *archiver;
  char            tagBuf[MAXTAGLEN];
	int							cnt;
	
	archiver = [[AsciiArchiver alloc] initWithContentsOfFile:resourcePath];
  if(!archiver) return;
  [archiver getNextTag:tagBuf];
	if(strcmp(tagBuf, "MobilityConstantShifts") != 0) {
    NSLog([NSString stringWithFormat:@"  tag='%s'\n", tagBuf]);
    return;
	}
	cnt = [archiver arraySize];
	if (!cnt) { // problem
		return;
	}
	[archiver readArray:currentMobility];
  [archiver release];
}

- (void)shiftChannel:(int)channel by:(int)shift
{
  int     end;
  Trace   *pointsID = [self dataList];


  if(shift==0) return;
  if(shift>0) {
    [pointsID insertSamples:shift atIndex:0 channel:(unsigned int)channel];
  }
  if(shift<0) {
    [pointsID removeSamples:(-shift) atIndex:0 channel:(unsigned int)channel];
  }

  end = [pointsID length];
  if(shift>0) [pointsID removeSamples:shift atIndex:0];
  if(shift<0) [pointsID setLength:end+shift];
}

- apply
{	
  int		x, numChannels;

  [self setStatusMessage:@"Mobility Shift"];
  numChannels = [dataList numChannels];
  for(x=0;x<numChannels; x++)
    [self shiftChannel:x by:currentMobility[x]];
  [self setStatusMessage:nil];
  return [super apply];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  int version;

  //[super initWithCoder:aDecoder];

  version = [aDecoder versionForClassName:@"MobilityConstant"];
  if (version==0) {
    char junk[255];
    [aDecoder decodeArrayOfObjCType:"i" count:8 at:currentMobility];
    [aDecoder decodeArrayOfObjCType:"c" count:255 at:junk];
    [aDecoder decodeArrayOfObjCType:"c" count:255 at:junk];
  }
  if (version==1) {
    [aDecoder decodeArrayOfObjCType:"i" count:8 at:currentMobility];
  }

  [MobilityConstant setVersion:1];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  //[super encodeWithCoder:aCoder];
  [aCoder encodeArrayOfObjCType:"i" count:8 at:currentMobility];
}

- (NSString *)toolName
{
  return @"Mobility Shift: Constant offset";
}

- handleTag:(char *)tag fromArchiver:archiver
{
  if (!strcmp(tag,"currentMobility")) {
    [archiver readData:currentMobility];
  } else
    return [super handleTag:tag fromArchiver:archiver];

  return self;
}

- (void)writeAscii:archiver
{
  [archiver writeArray:currentMobility size:8 type:"i" tag:"currentMobility"];

  [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  MobilityConstant    *dupSelf;
  int             i;

  dupSelf = [super copyWithZone:zone];
  for(i=0; i<8; i++) dupSelf->currentMobility[i] = currentMobility[i];
  return dupSelf;
}


@end

@implementation MobilityConstantCtrl

- (NSString *)resourceSubdir
{
  return @"Mobilities";
}

- (void)appWillInit
{	
  [super appWillInit];
  [shiftButton setEnabled:NO];
  [shiftSelector setEnabled:NO];
  [self setMobilityMatrixToEnter:NO];	
  [shiftButton setTarget:self];	
  [shiftButton setAction:@selector(toggleShiftMode:)];
  [shiftSelector setTarget:self];
  [shiftSelector setAction:@selector(selectShiftChannel:)];
  shiftMode = 0;
}

- (void)setMobilityMatrixToEnter:(BOOL)state
{
  int			i, j;

  if(state)
    for(j=0; j<2; j++)
      for(i=0; i<4; i++) {
        [[mobilityMatrix cellAtRow:j column:i] setBezeled:YES];
        [[mobilityMatrix cellAtRow:j column:i] setBackgroundColor:[NSColor whiteColor]];
        [[mobilityMatrix cellAtRow:j column:i] setSelectable:YES];
        [[mobilityMatrix cellAtRow:j column:i] setEditable:YES];
      }
        else
          for(j=0; j<2; j++)
            for(i=0; i<4; i++) {
              [[mobilityMatrix cellAtRow:j column:i] setBordered:YES];
              [[mobilityMatrix cellAtRow:j column:i] setBackgroundColor:[NSColor lightGrayColor]];
              [[mobilityMatrix cellAtRow:j column:i] setEditable:NO];
              [[mobilityMatrix cellAtRow:j column:i] setSelectable:NO];
            }
}

- (void)startNew
{
  [shiftButton setEnabled:YES];
  [shiftSelector setEnabled:YES];
  [self setMobilityMatrixToEnter:YES];

  didManualShift = NO;
  [toolMaster registerForEventNotification:self];

  [super startNew];
}

- (void)finishNew
{
  if (shiftMode)
    [self toggleShiftMode:self];

  [shiftButton setEnabled:NO];
  [shiftSelector setEnabled:NO];
  [self setMobilityMatrixToEnter:NO];

  [toolMaster deregisterForEventNotification:self];
  [super finishNew];
}

- (void)cancelNew
{
  if (shiftMode)
    [self toggleShiftMode:self];

  [shiftButton setEnabled:NO];
  [shiftSelector setEnabled:NO];
  [self setMobilityMatrixToEnter:NO];

  [toolMaster deregisterForEventNotification:self];
  [super cancelNew];
}

- setToDefault
{
  int i;

  for (i=0;i<8;i++)
    [dataProcessor setCurrentMobility:0 forChannel:i];

  return [super setToDefault];
}

- (void)getParams
{
  int	i;

  for (i=0;i<8;i++) {
    [dataProcessor setCurrentMobility:[[mobilityMatrix cellAtRow:(i/4) column:(i%4)] intValue]
                           forChannel:i];
  }
}

- (void)displayParams
{
  int		index;

  for(index=0;index<8;index++)
    [[mobilityMatrix cellAtRow:index/4 column:index%4] setIntValue:[dataProcessor currentMobility:index]];

  [super displayParams];
}

- (void)toggleShiftMode:sender
{
  shiftMode = 1-shiftMode;
  [shiftButton setState:shiftMode];

  [toolMaster toggleShiftMode];
  if (shiftMode) {
    if (!makingNew) {[self setToDefault]; [self displayParams];}
    [toolMaster setShiftChannel:4*[shiftSelector selectedRow]+[shiftSelector selectedColumn]];
  }
}

- (void)selectShiftChannel:sender
{	
  [toolMaster setShiftChannel:4*[shiftSelector selectedRow]+[shiftSelector selectedColumn]];
}

- (void)increaseMobility:(int)shift ofChannel:(int)channel
{
  [dataProcessor setCurrentMobility:([dataProcessor currentMobility:channel] + shift)
                         forChannel:channel];
  [self displayParams];
}


- (void)mouseEvent:(range)theRange
{
  int        chan = 4*[shiftSelector selectedRow]+[shiftSelector selectedColumn];

  // theRange.length is the shift amount
  [dataProcessor setCurrentMobility:(theRange.end - theRange.start)
                         forChannel:chan];
  //fprintf(stderr, "shift %d   %d\n", theRange.location, theRange.length);
  [self displayParams];
}

- (void)registerValue:sender
{
  //when a value is entered into mobilityMatrix
  [super registerValue:sender];
  [self displayParams];
}
@end
