/* 
 * UserPath.m by Bruce Blumberg, NeXT Computer, Inc.
 * Converted into an object Jan '97 by Ali Ozer
 *
 * You may freely copy, distribute, and re-use the code in this example. NeXT
 * disclaims any warranty of any kind, expressed or implied, as to its fitness
 * for any particular purpose.
 */
#ifndef MACOSX
#import "UserPath.h"
#import <AppKit/NSGraphics.h>
#import <AppKit/NSErrors.h>
#import <math.h>

@implementation UserPath

- (id)init {
    [super init];
    max = 32;
    points = NSZoneMalloc([self zone], sizeof(float) * max);
    ops = NSZoneMalloc([self zone], (2 + (max / 2)) * sizeof(char));
    ping = NO;
    
    return self;
}

/* Frees User Path and its associated buffers
*/
- (void)dealloc {
    free(points);
    free(ops);
    [super dealloc];
}

/* grows the  associated buffers as necessary. buffer size doubles on each call. You never need to call grow directly as it is called as needed by the methods and functions which add elements into the buffer
*/
- (void)growUserPath {
    /* double the size of the internal buffers */
    max *= 2;
    points = NSZoneRealloc([self zone], points, sizeof(float) * max);
    ops = NSZoneRealloc([self zone], ops, (2 + (max / 2)) * sizeof(char));
}

/* Call this to start generating a user path. The cache argument specifies if you want the user path cached at the server (i.e. dps_ucache). If a path needs to be drawn repeatedly, it might make sense to cache it down in the server. In either case, the UserPath object will automatically calculate the bounding box for the path and add the dps_setbbox operator.
*/
- (void)beginUserPath:(BOOL)cache {
    numberOfPoints = numberOfOps = 0;
    cp.x = cp.y = 0;
    bbox[0] = bbox[1] = 1.0e6;
    bbox[2] = bbox[3] = -1.0e6;
    if (cache) {
	ops[numberOfOps++] = dps_ucache;
    }
    ops[numberOfOps++] = dps_setbbox;
    opForUserPath = 0;
}

/* Call this to stop filling the path. Note this does not send the userpath to the server -- use sendUserPath. The op argument should be one of the following:
    dps_uappend, dps_ufill ,dps_ueofill, dps_ustroke, dps_ustrokepath,
    dps_inufill, dps_inueofill, dps_inustroke, dps_def, dps_put.
  These are defined in <dpsclient/dpsNext.h.  
*/
- (void)endUserPath:(int)op {
    opForUserPath = op;
}

/* Sets ping to YES so that after each time a user path is sent down to the window server, an ping is sent after. The purpose is to catch PostScript errors that may be generated by the user path.  Normally ping is NO. 
*/
- (void)setSynchronous:(BOOL)shouldPing {
    ping = shouldPing;
}

- (BOOL)isSynchronous {
    return ping;
}

/* Call this to send the path down to the server. If ping==YES (set via debug:), the function will send an NXPing() after the Path.
*/
- (void)sendUserPath {
    if (opForUserPath != 0) {
        PSDoUserPath(points, numberOfPoints, dps_float, ops, numberOfOps, bbox, opForUserPath);
        if (ping) {
            PSWait();
        }
    }
}

/* Checks if bounding box needs to be enlarged based on x and y 
*/
- (void)checkBoundingBox:(float)x :(float)y {
    if (x < bbox[0]) {
	bbox[0] = x;
    }
    if (y < bbox[1]) {
	bbox[1] = y;
    }
    if (x > bbox[2]) {
	bbox[2] = x;
    }
    if (y > bbox[3]) {
	bbox[3] = y;
    }
}

/* adds x and y to user path. Updates bounding box as necessary
*/
- (void)addPts:(float)x :(float)y {
    if (!((numberOfPoints + 2) < max)) {
	[self growUserPath];
    }
    points[numberOfPoints++] = x;
    points[numberOfPoints++] = y;
    [self checkBoundingBox:x :y];
}

/* adds operator to user path.  Operator should be one of the following:
    dps_moveto, dps_rmoveto, dps_lineto, dps_rlineto, dps_curveto,
    dps_rcurveto, dps_arc, dps_arcn, dps_arct, dps_closepath.
*/
- (void)addOp:(int)op {
    ops[numberOfOps++] = op;
}

/* adds operator and x and y to user path. Operator should be one of the operators above
*/
- (void)add:(int)op :(float)x :(float)y {
  if (!((numberOfPoints + 2) < max)) {
    [self growUserPath];
  }
  ops[numberOfOps++] = op;
  points[numberOfPoints++] = x;
  points[numberOfPoints++] = y;
  [self checkBoundingBox:x :y];
}

/* adds <x y moveto> to user path and updates bounding box 
*/
- (void)moveto:(float)x :(float)y {
  if ((numberOfPoints + numberOfOps) > 11000)
    {
    [self closepath];
    [self endUserPath:dps_ustroke];
    [self sendUserPath];
    [self beginUserPath:YES];
    fprintf(stderr, "Resetting path due to large size");
    } 
  [self add:dps_moveto :x :y];
  cp.x = x;
  cp.y = y;
}

/* adds <x y rmoveto> to user path and updates bounding box 
*/
- (void)rmoveto:(float)x :(float)y {
    if (!((numberOfPoints + 2) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_rmoveto;
    points[numberOfPoints++] = x;
    points[numberOfPoints++] = y;
    cp.x += x;
    cp.y += y;
    [self checkBoundingBox:cp.x :cp.y];
}

/* adds <x y lineto> to user path and updates bounding box 
*/
- (void)lineto:(float)x :(float)y {
  [self add:dps_lineto :x :y];
  cp.x = x;
  cp.y = y;
  if ((numberOfPoints + numberOfOps) > 11000)
    {
    [self closepath];
    [self endUserPath:dps_ustroke];
    [self sendUserPath];
    [self beginUserPath:YES];
    [self moveto:x :y];
    } 
}

/* adds <x y rlineto> to user path and updates bounding box 
*/
- (void)rlineto:(float)x :(float)y {
    if (!((numberOfPoints + 2) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_rlineto;
    points[numberOfPoints++] = x;
    points[numberOfPoints++] = y;
    cp.x += x;
    cp.y += y;
    [self checkBoundingBox:cp.x :cp.y];
}

/* adds <x1 y1 x2 y2 curveto> to user path and updates bounding box
*/
- (void)curveto:(float)x1 :(float)y1 :(float)x2 :(float)y2 :(float)x3 :(float)y3 {
    [self addPts:x1 :y1];
    [self addPts:x2 :y2];
    [self add:dps_curveto :x3 :y3];
    cp.x = x3;
    cp.y = y3;
}

/* adds <x1 y1 x2 y2 rcurveto> to user path and updates bounding box 
*/
- (void)rcurveto:(float)dx1 :(float)dy1 :(float)dx2 :(float)dy2 :(float)dx3 :(float)dy3 {
    if (!((numberOfPoints + 6) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_rcurveto;
    points[numberOfPoints++] = dx1;
    points[numberOfPoints++] = dy1;
    points[numberOfPoints++] = dx2;
    points[numberOfPoints++] = dy2;
    points[numberOfPoints++] = dx3;
    points[numberOfPoints++] = dy3;
    [self checkBoundingBox:cp.x + dx1 :cp.y + dy1];
    [self checkBoundingBox:cp.x + dx2 :cp.y + dy2];
    [self checkBoundingBox:cp.x + dx3 :cp.y + dy3];
    cp.x = dx3;
    cp.y = dy3;

    return;
}

/* adds <x y r ang1 ang2 arc> to user path and updates bounding box 
*/
- (void)arc:(float)x :(float)y :(float)r :(float)ang1 :(float)ang2 {
    if (!((numberOfPoints + 5) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_arc;
    points[numberOfPoints++] = x;
    points[numberOfPoints++] = y;
    points[numberOfPoints++] = r;
    points[numberOfPoints++] = ang1;
    points[numberOfPoints++] = ang2;
    [self checkBoundingBox:x + r :y + r];
    [self checkBoundingBox:x - r :y - r];
    cp.x = x + cos(ang2 / 57.3) * r;
    cp.y = y + sin(ang2 / 57.3) * r;
}

/* adds <x y r ang1 ang2 arcn> to user path and updates bounding box
*/
- (void)arcn:(float)x :(float)y :(float)r :(float)ang1 :(float)ang2 {
    if (!((numberOfPoints + 5) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_arcn;
    points[numberOfPoints++] = x;
    points[numberOfPoints++] = y;
    points[numberOfPoints++] = r;
    points[numberOfPoints++] = ang1;
    points[numberOfPoints++] = ang2;
    [self checkBoundingBox:x + r :y + r];
    [self checkBoundingBox:x - r :y - r];
    cp.x = x + cos(ang2 / 57.3) * r;
    cp.y = y + sin(ang2 / 57.3) * r;
}

/* adds <x1 y1 x2 y2 r arct> to user path and updates bounding box 
*/
- (void)arct:(float)x1 :(float)y1 :(float)x2 :(float)y2 :(float)r {
    if (!((numberOfPoints + 5) < max)) {
	[self growUserPath];
    }
    ops[numberOfOps++] = dps_arcn;
    points[numberOfPoints++] = x1;
    points[numberOfPoints++] = y1;
    points[numberOfPoints++] = x2;
    points[numberOfPoints++] = y2;
    points[numberOfPoints++] = r;
    [self checkBoundingBox:x1 :y1];
    [self checkBoundingBox:x2 :y2];
    cp.x = x2;
    cp.y = y2;
}

/* adds <closepath> to user path and updates bounding box
*/
- (void)closepath {
    ops[numberOfOps++] = dps_closepath;
}

@end

#endif

