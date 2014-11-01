/* "$Id: MobilityPolynomialCtrl.h,v 1.1.1.1 2005/09/07 22:22:02 giddings Exp $" */

#import <BaseFinderKit/ResourceToolCtrl.h>


@interface MobilityPolynomialCtrl:ResourceToolCtrl <BFToolMouseEvent>
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
