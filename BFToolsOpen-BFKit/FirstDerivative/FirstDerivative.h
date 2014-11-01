
/* "$Id: FirstDerivative.h,v 1.1.1.1 2005/09/07 22:22:01 giddings Exp $" */

#include <AppKit/AppKit.h>
#include <BaseFinderKit/GenericToolCtrl.h>


@interface FirstDerivative:GenericTool
{	
  BOOL    shouldRescale;
}

- (Trace*)firstDerivative:(Trace*)inData;

- (BOOL)shouldRescale;
- (void)setShouldRescale:(BOOL)value;
@end


@interface FirstDerivativeCtrl:GenericToolCtrl
{
  IBOutlet NSButton    *scaleSwitch;
}
@end