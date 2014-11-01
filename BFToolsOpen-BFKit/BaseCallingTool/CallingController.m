/* "$Id: CallingController.m,v 1.2 2007/01/17 01:37:22 smvasa Exp $" */
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

#import "CallingController.h"
#import "ToolBaseCalling.h"
#import <GeneKit/NumericalObject.h>

#define SPACING_OBJ	1
#define HEIGHT_OBJ	0
#define WIDTH_OBJ		2
#define MAX_ALLOWABLE_WIDTH_B	1.6
#define MAX_ALLOWABLE_WIDTH_E	1.6
#define MAX_ALLOWABLE_SPACE	1.85
#define NUM_OBJS	3
#define WIDTH_THRESH 1.5

@implementation CallingController
- init
{
  if(calculationStructures != nil) [calculationStructures  release];
  /* Assumptions - size object will be called for setup bases always
     BEFORE spacing object.  This is because spacing must call size to
     judge confidences for the bases it adds. */
  calculationStructures = [[NSMutableArray alloc] initWithCapacity:4];
  [calculationStructures addObject:[[[SizeObj alloc] initwithWeight:1 minConfidence:0.2] autorelease]];
  [calculationStructures addObject:[[[SpacingObj alloc] initwithWeight:1 minConfidence:0.2] autorelease]];
  [calculationStructures addObject:[[[WidthObj alloc] initwithWeight:1 minConfidence:0.2] autorelease]];

  [[calculationStructures objectAtIndex:SPACING_OBJ] setSizeObj:
    [calculationStructures objectAtIndex:HEIGHT_OBJ]];
  return self;
}

- (void)dealloc
{
  [calculationStructures release];
  [super dealloc];
}

- (void)setParamObj:(id)obj
{
  paramObj=obj;
}


#define MAXIMUM_FINDER_WINDOW	7
- (Sequence *)calculateBaseList:(Trace *)dataStorage
{
  int               i,j,k, l, count, numObjs;
  Sequence          *thebaseList, *newbaseList=NULL;
  float             sum_conf, mult_conf, *confidences, conf;
  float             sum_for_avg, avg=0.5;
  float             prevConf=0;
  float             *weights, weight_sum;
  char              tmpStr[64];
  NumericalObject   *numObj = [[NumericalObject new] autorelease];
  
  numObjs = [calculationStructures count];

  confidences = calloc(numObjs, sizeof(float));
  [paramObj setStatusPercent:0.0]; //don't use, just make sure it's cleared

  [paramObj setStatusMessage:@"Calling Bases:Initialization"];
  [paramObj returnCallingThresholds:&callquit :&finalout :&throwout];
  [paramObj returnObjectWeights:&weights];
  [paramObj returnCallingInts:&highorder :&maxit];
  [paramObj returnTolerances:&beginwidthtol :&endwidthtol :&spacingtol];
   
  [[calculationStructures objectAtIndex:SPACING_OBJ] setHighestOrder:highorder];
  [[calculationStructures objectAtIndex:SPACING_OBJ] setConfThresh:throwout];
  [[calculationStructures objectAtIndex:HEIGHT_OBJ] setConfThresh:throwout];
  for (i = 0; i < numObjs; i++)
    [[calculationStructures objectAtIndex:i] setWeight:weights[i]];

  [paramObj setStatusMessage:@"Calling Bases:Calculate initial base list"];
  thebaseList = [numObj returnInitBases:dataStorage];
  [[calculationStructures objectAtIndex:HEIGHT_OBJ] setupConfidences:thebaseList :dataStorage];
 
  [paramObj setStatusMessage:@"Calling Bases:Prepare base list"];
  [self prepareBaseList:thebaseList :dataStorage];

  //  Get the weighting sum to use during averaging.
  weight_sum = 0;
  for (k = 0; k < numObjs; k++)
    weight_sum += [[calculationStructures objectAtIndex:k] confWeight];

  // MAIN LOOP
  for (i = 0; ((i < maxit) && (fabs((double)(prevConf-avg)) > 0.0001)); i++) {
    [paramObj setStatusMessage:[NSString stringWithFormat:@"Calling Bases:Iteration %d",i]];
    for (j = 0; j < numObjs; j++) {
//      NSLog(@"%d", j);
      [[calculationStructures objectAtIndex:j] setupConfidences:thebaseList :dataStorage];
    }
//    NSLog(@"Done setup");
//    newbaseList = [[thebaseList copy] autorelease];
    newbaseList = [thebaseList copy];
    count = [thebaseList count];

    sum_for_avg = 0;
    k = 0;
    for (l = 0; l < count; l++) {
      sum_conf =0;
      mult_conf = 1;
      for (j = 0; j < numObjs; j++)
        confidences[j] =
          [[calculationStructures objectAtIndex:j] returnConfidence:l];
        conf = [numObj geommean:confidences :weights :numObjs :weight_sum];
      if (conf < throwout) {
        [newbaseList removeBaseAt:k];
      }
      else {
        [[newbaseList baseAt:k] setFloatConf:conf];
        sum_for_avg += conf;
        k += 1;
      }
    }
    prevConf = avg;
    avg = sum_for_avg/(float)[newbaseList count];
    if([paramObj debugmode]) fprintf(stderr, "  iteration: %d, ave conf: %f\n",i, avg);
    thebaseList = newbaseList;

    if (avg > callquit)
      break;		
  }

  sprintf(tmpStr, "Results --------------------------\n");

  // Here we set the spacing so it does it based only on the first
  // order spacing for the final confidence values.
  [[calculationStructures objectAtIndex:SPACING_OBJ] setHighestOrder:1];
  for (j = 0; j < numObjs; j++)
    [[calculationStructures objectAtIndex:j] setupConfidences:thebaseList :dataStorage];

  // Now go through base list and remove low confidence bases, print
  // out confidences.
  for (i = 0; i < [thebaseList count]; i++) {
    if ([[thebaseList baseAt:i] floatConfidence] < finalout) {
      [thebaseList removeBaseAt:i];
      i -= 1;
    }
/*    else {
      sprintf(tmpStr1, "base:%d	", i+1);
      for (j = 0; j < numObjs; j++) {
        confidences[j] = [[calculationStructures objectAtIndex:j]
                                         returnConfidence:i];
        sprintf(tmpStr, "%d:%f	", j,confidences[j]);
        strcat(tmpStr1, tmpStr);
      }
      sprintf(tmpStr,"%f\n", ((aBase *)[thebaseList elementAt:i])->confidence);
      strcat(tmpStr1, tmpStr);
    }
*/
  }
  // Add bases in places where it is needed.
  [paramObj setStatusMessage:@"Calling Bases:Filling Gaps"];
  [self cleanupBaseList:thebaseList :dataStorage];
//  [[calculationStructures objectAtIndex:SPACING_OBJ] dumpSpacings:thebaseList];
  [paramObj setStatusMessage:nil];  //clears status display
  return thebaseList;
}


- (Sequence *)dumpBases:(Trace *)dataStorage
{
  return [self calculateBaseList:dataStorage];
}

- (void)removeExtraBases:(Sequence *)baseList :(Trace *)dataStorage
{
  int count, i;
  Base *thisbase, *nextbase, *prevbase;
  int actualSpace, targetSpace;


  /* first iterate to remove extraneous bases */
  count = [baseList count];
  for (i = 1; i < (count-1); i++) {
    thisbase = (Base *)[baseList baseAt:i];
    nextbase = (Base *)[baseList baseAt:(i+1)];
    prevbase = (Base *)[baseList baseAt:(i-1)];
    actualSpace = abs([nextbase location] - [thisbase location]) +
      abs([prevbase location] - [thisbase location]);
    targetSpace = (int)[[calculationStructures objectAtIndex:SPACING_OBJ]
                                                        spacingAt:i];

    /* Here we look for bases too closely spaced, and remove them */
    if (actualSpace < (MIN_SPACING_THRESH * targetSpace))
      if (([thisbase confidence] < [nextbase confidence]) &&
          ([thisbase confidence] < [prevbase confidence])) {
        [baseList removeBaseAt:i];
        i -= 1;
        count -= 1;
      }
  }
}


- (void)fillGaps:(Sequence *)baseList :(Trace *)dataStorage
{
  Base *thisbase=NULL, *nextbase, *prevbase, *newbase;
  int targetSpace;
  int spaceLeft, spaceRight, count, i, j, k, leftloc, rightloc;
  float maxconf, conf;
  int maxchan, spacing, numadded;
  unsigned numG=0, numC=0;
  float gccontent;

  count = [baseList count];

  for (i = 1; i < (count-1); i++) {
    thisbase = (Base *)[baseList baseAt:i];
    if ([thisbase channel] != -1) {
      switch([thisbase channel]) {
        case 0:
          numC ++;
          break;
        case 2:
          numG ++;
          break;
      }
      if (i >= 8) {
        Base *subtractbase = (Base *)[baseList baseAt:(i-8)];
        switch([subtractbase channel]) {
          case 0:
            numC --;
            break;
          case 2:
            numG --;
            break;
        }        
      }
      gccontent = (float)(numC + numG ) / 8.0; //- abs(numC - numG)
      nextbase = (Base *)[baseList baseAt:(i+1)];
      prevbase = (Base *)[baseList baseAt:(i-1)];
      spaceLeft = abs([thisbase location] - [prevbase location]);
      spaceRight = abs([nextbase location] - [thisbase location]);
      targetSpace = (int)([[calculationStructures objectAtIndex:SPACING_OBJ] spacingAt:i] + 0.5);
      if(targetSpace < 1) targetSpace=1;
      
      /* Check spacing between bases to insert any necessary where there may
         be continuous peaks.  Test to see if space to next base is BIGGER than
         the expected spacing times some threshold amount, and also see if the
         minimum for the signal occurs after the location of the next expected base.
         If so, insert a new one there.  */
      if ((spaceRight > spacingtol * targetSpace) && (gccontent < 0.5))  {
        numadded = 1 + (int)(spaceRight - spacingtol *
                             targetSpace)/targetSpace;
        if (i > 0)
          leftloc = [thisbase  location];
        else
          leftloc = 0;
        rightloc = [nextbase location];
        spacing = (rightloc-leftloc)/(numadded + 1);
        for (k = (numadded-1); k >= 0; k--) {
          newbase = [Base newBase];
          [newbase setLocation: leftloc + spacing * (k+1)];
          maxconf = -FLT_MAX;
          maxchan = 0;
          for (j = 0; j < [dataStorage numChannels]; j++) {
            conf = [[calculationStructures objectAtIndex:HEIGHT_OBJ]
                    returnDataConfidence:[newbase location] :j];
            if (conf > maxconf) {
              maxconf = conf;
              maxchan = j;
            }
          }
          if (maxconf >= throwout) {
            [newbase setChannel : maxchan];
      //      [newbase setBase : '\0'];
          }
          else {
            [newbase setChannel : UNKNOWN_BASE];
            [newbase setBase :'N'];
          }
          [newbase setFloatConf:maxconf];
          [newbase setAnnotation:[NSNumber numberWithInt:CONTROLLER_ADDED_OWNER_ID]
            forKey:@"owner"];
          [baseList insertBase:newbase At:(i+1)];
        }		
        i += numadded-1;
        count += numadded;
      }
    }
  }
}



- (void)fillwidthGaps:(Sequence*)baseList :(Trace*)dataStorage
{
  Base *thisbase=NULL, *nextbase, *prevbase;
  int leftminLoc, rightminLoc,  targetSpace, width, targetwidth;
  int count, i, j, numadded, spacing, channel;
  int leftloc, rightloc, space;
  float maxwidth;
  NumericalObject   *numObj = [[NumericalObject new] autorelease];
  unsigned numG=0, numC=0;
  float gccontent;

  
  count = [baseList count];

  for (i = 1; i < (count-1); i++) {
    thisbase = (Base *)[baseList baseAt:i];
    if ([thisbase channel] != -1) {
      switch([thisbase channel]) {
        case 0:
          numC ++;
          break;
        case 2:
          numG ++;
          break;
      }
      if (i >= 8) {
        Base *subtractbase = (Base *)[baseList baseAt:(i-8)];
        switch([subtractbase channel]) {
          case 0:
            numC --;
            break;
          case 2:
            numG --;
            break;
        }
      } 
      gccontent = ((float)(numC + numG ))/8.0; //- abs(numC - numG)
      nextbase = (Base *)[baseList baseAt:(i+1)];
      prevbase = (Base *)[baseList baseAt:(i-1)];
//      spaceLeft = abs(thisbase->location - prevbase->location);
//      spaceRight = abs(nextbase->location - thisbase->location);
      targetSpace = (int)[[calculationStructures objectAtIndex:SPACING_OBJ]
                                                                spacingAt:i];
      targetwidth = (float) [[calculationStructures objectAtIndex:WIDTH_OBJ]
                                                                widthAt:i];
      leftminLoc = [numObj lefthalfheightpoint:[thisbase location]
                                              :[dataStorage sampleArrayAtChannel:[thisbase channel]]
                                              :[dataStorage length]];
      rightminLoc = [numObj righthalfheightpoint:[thisbase location]
                                                :[dataStorage sampleArrayAtChannel:[thisbase channel]]
                                                :[dataStorage length]];
      width = (int)[numObj halfHeightPeakAveWidth:[thisbase location]
                                                :[dataStorage sampleArrayAtChannel:[thisbase channel]]
                                                :[dataStorage length]];

      maxwidth = beginwidthtol +
        ((endwidthtol - beginwidthtol) * i)/count;

      //			sprintf(tempStr1, "base:%d	width:%d	exp:%d conf:%f chan:%d allow:%f\n", i, width, targetwidth, thisbase->confidence, thisbase->channel, maxwidth);
      //			[distributor addTextAnalysis:tempStr1];
      if (width > maxwidth * targetwidth) {
        float target;
        if (gccontent < 0.5)
          target = 0.8;
        else
          target = 0.05;
        numadded = 2 + (int)(width - maxwidth * targetwidth)/targetwidth;
        spacing = (rightminLoc - leftminLoc) / numadded;
        channel = [thisbase channel];
        if (i > 0)
          leftloc = [[baseList baseAt:(i-1)] location];
        else
          leftloc = 0;
        rightloc = [[baseList baseAt:(i+1)] location];
        //				if (leftloc < leftminLoc)
        //					leftloc = leftminLoc;
        //				if (rightloc > rightminLoc)
        //					rightloc = rightminLoc;
        while (((rightloc - leftloc)/(targetSpace*target)) < (numadded-1))
          numadded -= 1;
        if (numadded <= 1)
          continue;
        space = (rightloc-leftloc)/(numadded + 1);
        [baseList removeBaseAt:i];
        for (j = (numadded-1); j >= 0; j--) {
          Base *newBase = [Base baseWithChannel:channel 
            floatConfidence:[[calculationStructures objectAtIndex:HEIGHT_OBJ]
                                      returnDataConfidence:leftloc + space * (j+1) 
                                                          :channel]
            location:leftloc + space * (j+1)];
          [newBase setAnnotation:[NSNumber numberWithInt:CONTROLLER_ADDED_OWNER_ID] forKey:@"owner"];
          
 /*         newbase.location =  leftloc + space * (j+1);
          newbase.channel = channel;
          newbase.confidence =
            [[calculationStructures objectAtIndex:HEIGHT_OBJ]
                                      returnDataConfidence:newbase.location :[newbase channel]];
          newbase.owner = CONTROLLER_ADDED_OWNER_ID; */
          [baseList insertBase:newBase At:i];
//          [baseList insertElement:&newbase at:i];
        }		
        i += numadded-1;
        count += (numadded -1) ;
      }
    }
  }
}

- (void)cleanupBaseList:(Sequence *)baseList :(Trace *)dataStorage
{
  //	[self removeExtraBases:baseList :dataStorage];
  [self fillwidthGaps:baseList :dataStorage];
  [self fillGaps:baseList :dataStorage];
}

		
- (void)prepareBaseList:(Sequence *)baseList :(Trace *)dataStorage
{	
  int i, j, count, maxchannel, channels, channel;
  float max, conf, iconf;
  Base *base;

  count = [baseList count];
  channels = [dataStorage numChannels];
  for (i = 0; i < count; i++) {
    base = (Base *)[baseList baseAt:i];
    channel = [base channel];
    max = -FLT_MAX;
    iconf = [[calculationStructures objectAtIndex:HEIGHT_OBJ] 
      returnDataConfidence:[base location] 
      :channel];
    for (j = 0; j < channels; j++) {
      conf = [[calculationStructures objectAtIndex:HEIGHT_OBJ]
        returnDataConfidence:[base location]
        :j];
      if ((conf > max) &&
          ((!(((j==0) && (channel==2)) || ((j==2) && (channel==0))))
           || (conf > (1.3 * iconf)))) {
        max = conf;
        maxchannel = j;
      }
    }
    if (max > iconf) {
      [baseList removeBaseAt:i];
      i -= 1;
      count -= 1;
    }
  }
}				
        
#define Aa_THRESH	0.5
#define Ag_THRESH	0.3
#define Ca_THRESH 0.5
#define Gg_THRESH	0.5

- (Sequence*)indexCall:(Trace *)dataStorage :(int)channel
{
  Sequence 	*baseList;
  int            i;
  Base          *base;
  float          c_res, a_res, g_res;

//  [tempPtList addObject:[dataStorage objectAt:channel]];
  baseList = [self calculateBaseList:dataStorage];
  for (i =0; i < [baseList count]; i++) {
    base = (Base *)[baseList baseAt:i];
//    base = (aBase *)[baseList elementAt:i];
    c_res = [dataStorage sampleAtIndex:[base location] channel:C_BASE];
    a_res = [dataStorage sampleAtIndex:[base location] channel:A_BASE];
    g_res = [dataStorage sampleAtIndex:[base location] channel:G_BASE];
/*    c_res = *(float *)[(Storage*)[dataStorage objectAt:C_BASE] elementAt:base->location];
    a_res = *(float *)[(Storage*)[dataStorage objectAt:A_BASE] elementAt:base->location];
    g_res = *(float *)[(Storage*)[dataStorage objectAt:G_BASE] elementAt:base->location];
*/
    if ((a_res > (Aa_THRESH * c_res)) && (g_res > (Ag_THRESH * c_res))) {
      [base setBase:'A']; [base setChannel: A_BASE]; }
    else if (a_res > (Ca_THRESH * c_res)) {
      [base setBase : 'C']; [base setChannel : C_BASE]; }
    else if (g_res > (Gg_THRESH * c_res)) {
      [base setBase:'G']; [base setChannel : G_BASE]; }
    else {
      [base setBase:'T']; [base setChannel : T_BASE]; }
  }
//  [tempPtList free];
  return baseList;
}

@end

