/***********************************************************

Copyright (c) 1997-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith 

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

/* "$Id: NDDSServer.h,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

#import <Foundation/Foundation.h>

@class  NDDSServer, NDDSData, NDDSDataManager;

@protocol NDDSServerRequests
- (oneway void)addJobRequest:(bycopy NSMutableDictionary*)paramsObj
                    withData:(NDDSData*)inputData;

- (double)expectedLatency;
- (int)queueLength;
- (bycopy id)queueItemAt:(int)index;
- (NSString*)serverType;
- (BOOL)canQueue;
- (NSDate*)dateQueueLastChanged;

- (bycopy NSData*)iconData;
- (bycopy NSArray*)inputTypes;   //of types NSString
- (bycopy NSArray*)outputTypes;
- (bycopy NSArray*)parameterDefinitions;

- (NDDSDataManager*)localDataManager;

@end


@protocol NDDSServerDelegateMethods
- (oneway void)jobRequestDone:(bycopy NSDictionary*)jobParams
                    inputData:(NDDSData*)inData
                   outputData:(NDDSData*)outData;
@end


@protocol NDDSProcessingObject
+ (NSString*)serverName;
+ (bycopy NSData*)iconData;
+ (bycopy NSArray*)inputTypes;  //of types NSString
+ (bycopy NSArray*)outputTypes;
+ (NSArray*)parameterDefinitions;
- (void)processRequest:(NSMutableDictionary*)request; //inData and outData are added to request
@end

@protocol NDDSAsyncProcessingObject <NDDSProcessingObject>
- (void)setNDDSServer:(id)aServer;
@end



@interface NDDSServer:NSObject <NDDSServerRequests>
{
  Class                 processingObjectClass;
  NDDSDataManager       *localDataManager;
  
  NSMutableDictionary   *paramsID;
  NSMutableArray        *waitingJobsQueue, *activeJobs;

  NSDictionary          *jobTimesDict;
  NSString 		*jobTimesPath;
  
  NSLock                *killLock, *queueEmptyLock;

  BOOL	                killFlag;
  NSDate                *lastQueueChange;
}

- (void)launchServerWithClass:(Class)aClass;
- (void)launchAnotherServerThread;

- (void)jobDone:(NSMutableDictionary*)jobID;
@end

@interface NDDSServerThread:NSObject
{
}

+ (void)startNewServerThreadWithPorts:(NSArray *)portArray;

@end

