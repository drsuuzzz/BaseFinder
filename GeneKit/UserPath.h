
/* 
 * UserPath is an object which facilitates the use of DPS user paths. You can create a user path,
 * then load it with paths and draw the paths over and over. Here's an example:
 *
 * UserPath *userPath = [[UserPath alloc] init];
 * [userPath beginUserPath:YES];       // initialize user path and cache
 * [userPath moveto:0.0 :0.0];         // add moveto to userpath; update bounding box
 * [userPath rlineto:0.0 :100.0);      // add rlineto to path; update bounding box
 * [userPath rlineto:100.0 :0.0);      // add rlineto to path; update bounding box
 * [userPath rlineto:0.0 :-100.0);     // add rlineto to path; update bounding box
 * [userPath closepath];               // close path
 * [userPath endUserPath:dps_stroke];  // close user path and specify operator
 * [userPath sendUserPath];
 *
 * As you will note, the set of routines manage the allocation and growth of
 * the operator and operand arrays, as well as the calculation of the bounding
 * box. A user path created via these methods may be optionally cached down
 * at the window server, or repeatedly sent down.
 */

#import <Foundation/NSObject.h>

@interface UserPath : NSObject {
    float          *points;
    int             numberOfPoints;
    char           *ops;
    NSPoint         cp;
    int             numberOfOps;
    int             max;
    float           bbox[4];
    int             opForUserPath;
    BOOL            ping;
}

/* Creation/destruction */
- (id)init;				/* Init the path. Can reuse it many times (with multiple begin/end) */
- (void)dealloc;

/* Public methods */
- (void)beginUserPath:(BOOL)cache;	/* Start a new path; if cache=YES, the path is saved in the server */
- (void)endUserPath:(int)op;		/* Finish off the path with the specified drawing operation */
- (void)sendUserPath;			/* Draw the path */
- (void)setSynchronous:(BOOL)flag;	/* If flag = YES, the path is sent down synchronously, for debugging */
- (BOOL)isSynchronous;

/* Path creation methods */
- (void)moveto:(float)x :(float)y;
- (void)rmoveto:(float)x :(float)y;
- (void)lineto:(float)x :(float)y;
- (void)rlineto:(float)x :(float)y;
- (void)curveto:(float)x1 :(float)y1 :(float)x2 :(float)y2 :(float)x3 :(float)y3;
- (void)rcurveto:(float)dx1 :(float)dy1 :(float)dx2 :(float)dy2 :(float)dx3 :(float)dy3;
- (void)arc:(float)x :(float)y :(float)r :(float)ang1 :(float)ang2;
- (void)arcn:(float)x :(float)y :(float)r :(float)ang1 :(float)ang2;
- (void)arct:(float)x1 :(float)y1 :(float)x2 :(float)y2 :(float)r;
- (void)closepath;

/* Internal methods */
- (void)growUserPath;
- (void)checkBoundingBox:(float)x :(float)y;
- (void)addPts:(float)x :(float)y;
- (void)addOp:(int)op;
- (void)add:(int)op :(float)x :(float)y;

@end

