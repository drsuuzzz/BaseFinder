/***********************************************************

Copyright (c) 1998-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/* FuzzyEngine.m created by giddings on Thu 23-Jul-1998 */

#import "FuzzyEngine.h"
#import <float.h>
#define sqr(x) ((x) * (x))

@implementation FuzzyEngine

- (float)S:(float)x start:(float)a center:(float)b end:(float)c
{
    if ( (x <= b) && (x > a))
        return (2.0 * sqr((x-a)/(c-a)));
    else if ((x > b) && (x <= c))
        return (1 - 2 * sqr((x-c)/(c-a)));
    else if (x > c)
        return 1.0;
    else
        return 0.0;
}

- (float)S:(float)x midpoint:(float)a width:(float)b 
{
    if (x < (a-b))
        return 0.0;
    else if (((a-b)<=x) && (x < a))
        return (sqr(x - (a-b))/(2 * sqr(b)));
    else if ((a < x) && (x <= (a+b)))
        return (1-(sqr((a+b)-x)/(2 * sqr(b))));
    else return 1.0; 
}

- (float)Z:(float)x midpoint:(float)a width:(float)b
{
    return (1 - [self S:x midpoint:a width:b]);
}

- (float)Z:(float)x start:(float)a center:(float)b end:(float)c
{
    return (1 - [self S:x start:a center:b end:c]);
}


- (float)Pi:(float)x center:(float)a width:(float)b
{
    if (x <= a)
        return [self S:x midpoint:(a - b/2)  width:(b/2)];
    else
        return [self Z:x midpoint:(a + b/2) width:(b/2)];
}

//Something seems wrong with this right now so don't rely on it
- (float)varArgAnd:(int)count, ...
{
    va_list  ap;
    unsigned i;
    float min=FLT_MAX, thisarg;


    va_start(ap, count);
    if (count < 1)
        return 0;
    for (i = 0; i < count; i++) {
        thisarg = va_arg(ap, float);
        if (thisarg < min)
            min = thisarg;
    }
    va_end(ap);
    return min;    
}

- (float)and:(float)arg1 :(float)arg2
{
    return (arg1 > arg2 ? arg2 : arg1);
}

- (float)and:(float)arg1 :(float)arg2 :(float)arg3
{
  float res1 = (arg1 > arg2 ? arg2 : arg1);

  return (res1 > arg3 ? arg3 : arg1);
  //return [self varArgAnd:3, arg1, arg2, arg3];
}

- (float)and:(float)arg1 :(float)arg2 :(float)arg3 :(float)arg4
{
  float res1 = (arg1 < arg2 ? arg1 : arg2);

  return (res1 < arg3 ? res1 : arg3);
 // return [self varArgAnd:4, arg1, arg2, arg3, arg4];
}

- (float)very:(float)arg{
    return sqr(arg);
}

- (float) or:(float)arg1 :(float)arg2
{
  return (arg1 < arg2 ? arg2 : arg1);
}

- (float)or:(float)arg1 :(float)arg2 :(float)arg3
{
  float res1 = (arg1 < arg2 ? arg2 : arg1);

  return (res1 > arg3 ? res1 : arg3);
}

- (float)not:(float)arg1
{
    if (arg1 > 1.0)
        return 0.0;
    else if (arg1 < 0.0)
        return 1.0;
    else
        return (1-arg1);
}


/*- (void)fzzyIF:(float)arg then:(SEL)action
{
    [self fzzyIF:arg then:action withObject:sender];
}*/

- (void)fzzyIF:(float)arg then:(SEL)action withObject:(id)obj
{
    [obj performSelector:action withObject:[NSNumber numberWithFloat:arg]]; 
}

@end
