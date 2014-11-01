
#import <BaseFinderKit/ResourceToolCtrl.h>


@interface MobilityCubicCtrl:ResourceToolCtrl <BFToolMouseEvent>
{
  IBOutlet NSBox   *accessoryView;

  id		displayView;
  id		channelID;
  id		constID;
  int		curChannel, newMethod;

  id		newMethodView;
  id		newMethodID;

  id		slidingModeView;
  id		slideChannelID;
  id		previousView;

  NSMutableArray   *shiftData;
}

- setToDefault;
- (void)displayParams;
- (void)getParams;

- (void)startNew;
- (void)finishNew;
- (void)switchFunctionDisplay:sender;
- (void)showConstants;
- (void)constantsChanged:sender;


- (void)newMethodOK:sender;
- (void)setViewToEnter;
- (void)setViewToDisplay;
- (void)switchSlideChannel:sender;
- (void)fitEquation;

@end
