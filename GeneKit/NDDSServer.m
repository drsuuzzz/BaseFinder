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

/* "$Id: NDDSServer.m,v 1.2 2006/08/04 20:31:32 svasa Exp $" */

#import "NDDSServer.h"
#import "NDDSData.h"
#import "NDDSDataManager.h"
#import <math.h>

int _NDDSServerUniqueJobIDNumber=0;

@interface NDDSServer (NDDSServerLocalMethods)
- (NSString*)serverVersion;

- (NSMutableDictionary*)getNextJobRequest;
@end


@implementation NDDSServer

- init
{
  [super init];

  killLock = [[NSLock alloc] init];
  queueEmptyLock = [[NSLock alloc] init];

  waitingJobsQueue = [[NSMutableArray alloc] initWithCapacity:10];
  activeJobs = [[NSMutableArray alloc] initWithCapacity:10];
  jobTimesDict = nil;

  lastQueueChange = [[NSDate date] retain];

  localDataManager = [[NDDSDataManager alloc] init];

  [queueEmptyLock lock];
  return self;
}

- (void)dealloc
{
  [waitingJobsQueue release];
  [activeJobs release];
  if (jobTimesDict)
      [jobTimesDict release];
  if (jobTimesPath)
      [jobTimesPath release];
  [localDataManager release];
  [lastQueueChange release];
  [super dealloc];
}

- (NSString*)serverVersion
{
  return [NSString stringWithCString:"NDDSServer version 0.9.1"];
}

- (void)createJobTimesPPL
{
  NSString             *pplPath;
  NSFileManager        *filemanager;
  NSMutableDictionary  *pplDict;
  NSMutableArray       *previousJobTimes;

  if(jobTimesDict != nil) [jobTimesDict release];
  filemanager = [NSFileManager defaultManager];

#ifdef GNUSTEP_BASE_LIBRARY
  pplPath = [NSString pathWithComponents:[NSArray arrayWithObjects:@"NextLibrary", @"NDDS", nil]];
#else
  pplPath = [NSString pathWithComponents:[NSArray arrayWithObjects:
    NSOpenStepRootDirectory(), @"NextLibrary", @"NDDS", nil]];
#endif
  
  if (![filemanager fileExistsAtPath:pplPath])
    [filemanager createDirectoryAtPath:pplPath attributes:nil];

  pplPath = [pplPath stringByAppendingPathComponent:[processingObjectClass serverName]];
  if (![filemanager fileExistsAtPath:pplPath])
    [filemanager createDirectoryAtPath:pplPath attributes:nil];

  pplPath = [pplPath stringByAppendingPathComponent:@"jobTimesPPL"];
  pplDict = [NSMutableDictionary dictionaryWithContentsOfFile:pplPath];
/*jobTimesPPL = [[NSPPL alloc] initWithPath:pplPath
                                     create:YES
                                   readOnly:NO];

  pplDict = [jobTimesPPL rootDictionary]; */
  if (!pplDict)
      pplDict = [NSMutableDictionary dictionary];
  previousJobTimes = [pplDict objectForKey:@"previousJobTimes"];
  if(previousJobTimes == nil) {
    previousJobTimes = [[NSMutableArray alloc] initWithCapacity:100];
    [pplDict setObject:previousJobTimes  forKey:@"previousJobTimes"];
    [pplDict writeToFile:pplPath atomically:YES];
  }
  jobTimesDict = [pplDict retain];
  jobTimesPath = [pplPath retain];
}

- (void)launchServerWithClass:(Class)aClass;
{
  NSConnection    *connectionID;
  
  fprintf(stderr,"\n%s\n\n", [[self serverVersion] cString]); fflush(stderr);

  connectionID = [NSConnection defaultConnection];
  [connectionID setRootObject:self];
  [connectionID registerName:[aClass serverName]];
  [connectionID setDelegate:self];
  [connectionID runInNewThread];

  processingObjectClass = aClass;

  //[self createJobTimesPPL];
  [self launchAnotherServerThread];
}

- (void)launchAnotherServerThread
{
  NSConnection    *threadConnection;
  NSPort          *port1;
  NSPort          *port2;
  NSArray         *portArray;

  port1 = [NSPort port];
  port2 = [NSPort port];
  threadConnection = [[NSConnection alloc] initWithReceivePort:port1
                                                      sendPort:port2];
  [threadConnection setRootObject:self];
  [threadConnection runInNewThread];
  portArray = [NSArray arrayWithObjects:port2, port1, processingObjectClass, nil]; //Ports switched here

  killFlag = NO;
  [NSThread detachNewThreadSelector:@selector(startNewServerThreadWithPorts:)
                           toTarget:[NDDSServerThread class]
                         withObject:portArray];
}

/******
*
* Managing the NSConnection to server
*
********/

- connection:(NSConnection *)conn didConnect:(NSConnection *)newConn
{
  fprintf(stderr,"GetLanesServer:new connection\n"); fflush(stderr);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(senderIsInvalid:)
                                               name:NSConnectionDidDieNotification
                                             object:newConn];
  return newConn;
}

- senderIsInvalid:(NSNotification *)sender
{
  //[self addMessage:"connection broken\n"];
  //[self setConnectMessage:"Waiting for connection"];
  fprintf(stderr,"GetLanesServer:lost connection\n");
  return self;
}

/*****
*
* External Interface methods
*
******/

- (int)testMethod
{
  return 13;
}

- (oneway void)addJobRequest:(bycopy NSMutableDictionary*)paramsObj
                    withData:(NDDSData*)inputData
{		
  //fprintf(stderr,"\nNew job request\n");
  //if([paramsObj isProxy]) fprintf(stderr,"  paramsObj is PROXY\n");
  //else fprintf(stderr,"  paramsObj is NOT proxy\n");

  //if([inputData isProxy]) fprintf(stderr,"  inputData %s is PROXY\n", [[inputData description] cString]);
  //else fprintf(stderr,"  inputData %s is NOT proxy\n", [[inputData description] cString]);

  [inputData setProcessingState:@"queued"];
  [paramsObj  setObject:@"waiting"   forKey:@"jobStatus"];

  if(inputData != nil) [paramsObj setObject:inputData forKey:@"inputData"];
  
  [waitingJobsQueue addObject:paramsObj];

  [lastQueueChange release];
  lastQueueChange = [[NSDate date] retain];

  //[paramsObj release];
  [queueEmptyLock unlock];
}

- (int)queueLength
{
  return [waitingJobsQueue count] + [activeJobs count];
}

- (bycopy id)queueItemAt:(int)index;
{
  id    paramsObj;
  
  if(index<0 || index>=[self queueLength]) return NULL;

  //paramsObj = [[waitingJobsQueue objectAtIndex:index] mutableCopy];
  if(index < [activeJobs count])
    paramsObj = [activeJobs objectAtIndex:index];
  else
    paramsObj = [waitingJobsQueue objectAtIndex:(index - [activeJobs count])];

  return paramsObj;
}

- (double)expectedLatency;
{
  double          total=0.0, average=1.0;
  int             i;
  NSMutableArray  *previousJobTimes;

  previousJobTimes = [jobTimesDict objectForKey:@"previousJobTimes"];
  if((previousJobTimes != nil) && ([previousJobTimes count]>0)) {
    for(i=0; i<[previousJobTimes count]; i++) {
      total += [[previousJobTimes objectAtIndex:i] doubleValue];
    }
    average = total / [previousJobTimes count];
  }

  return (average * [self queueLength]);
}

- (NSString*)serverType
{
  return [processingObjectClass serverName];
}

- (BOOL)canQueue
{
  return YES;
}

- (NSDate*)dateQueueLastChanged;
{
  return lastQueueChange;
}

- (bycopy NSData*)iconData;
{
  return [processingObjectClass iconData];
}

- (bycopy NSArray*)inputTypes
{
  return [processingObjectClass inputTypes];
}

- (bycopy NSArray*)outputTypes
{
  return [processingObjectClass outputTypes];
}

- (bycopy NSArray*)parameterDefinitions
{
  return [processingObjectClass parameterDefinitions];
}

- (NDDSDataManager*)localDataManager;
{
  return localDataManager;
}

/*****
*
*  Methods called from the process threads into the main NSConnection thread
*
******/
- (NSMutableDictionary*)getNextJobRequest
{
  // This method takes the next job off the waiting queue (waitingJobsQueue)
  // moves it into the (activeJobs) queue, and return the job request.
  // This method will block if there are no waiting jobs
  NSMutableDictionary   *nextJob=nil;

  [queueEmptyLock lock];
  
  if([waitingJobsQueue count] > 0) {
    nextJob = [[waitingJobsQueue objectAtIndex:0] retain];
    [waitingJobsQueue removeObjectAtIndex:0];

    [nextJob setObject:@"processing"   forKey:@"jobStatus"];
    [nextJob setObject:[NSDate date]   forKey:@"startDate"];
    [nextJob setObject:[NSNumber numberWithInt:_NDDSServerUniqueJobIDNumber++]
                forKey:@"serverJobID"];
    [[nextJob objectForKey:@"inputData"] setProcessingState:@"processing"];

    [activeJobs addObject:nextJob];
    [nextJob release];

    [lastQueueChange release];
    lastQueueChange = [[NSDate date] retain];
    
    [queueEmptyLock unlock];
    return nextJob;
  }
  
  return nil;
}

- (void)jobDone:(NSMutableDictionary*)jobID;
{
  id	                sender;
  NSMutableDictionary   *returnDict = jobID;
  NDDSData              *inputData, *outputData;
  NSDate                *startDate;
  NSTimeInterval        processingInterval;
  id                    tempObject;
  NSMutableArray        *previousJobTimes;
  int                   i;

  [jobID retain];
  if(jobTimesDict != nil) {
      previousJobTimes = [[jobTimesDict objectForKey:@"previousJobTimes"] retain];
    if(previousJobTimes != nil) {
      startDate = [jobID objectForKey:@"startDate"];
      processingInterval = fabs([startDate timeIntervalSinceNow]);
      tempObject = [NSString stringWithFormat:@"%0.16g", processingInterval];
      [previousJobTimes addObject:tempObject];
      while([previousJobTimes count] > 100) {
        [previousJobTimes removeObjectAtIndex:0];
      }
      //NSLog(@"ppl%@", jobTimesPPL);
      [jobTimesDict writeToFile:jobTimesPath atomically:YES];
      [previousJobTimes release];
    }
  }

  if([[jobID objectForKey:@"jobStatus"] isEqual:@"delayed"]) {
    [jobID release];
    return;
  }

  NS_DURING
    fprintf(stderr,"jobDone issued from thread\n"); fflush(stderr);

    fprintf(stderr,"jobID = %d\n", [[jobID objectForKey:@"serverJobID"] intValue]);
    fprintf(stderr,"activeJobs count = %d\n", [activeJobs count]);
    i=0;
    while(i<[activeJobs count]) {
      tempObject = [activeJobs objectAtIndex:i];
      if([[tempObject objectForKey:@"serverJobID"] isEqualToNumber:[jobID objectForKey:@"serverJobID"]]) {
        [activeJobs removeObjectAtIndex:i];
        fprintf(stderr,"found job at %d\n", i);
      } else
        i++;
    }
    //[activeJobs removeObject:jobID];
    fprintf(stderr, "activeJobs count = %d\n", [activeJobs count]);
    fflush(stderr);

    sender = [jobID objectForKey:@"sender"];

    if([sender isProxy]) fprintf(stderr," sender %d is proxy\n",(int)sender);
    else fprintf(stderr," sender %d is not proxy\n", (int)sender);

    [returnDict setObject:[processingObjectClass serverName]
                   forKey:@"servertype"];

    inputData = [[returnDict objectForKey:@"inputData"] retain];
    outputData = [[returnDict objectForKey:@"outputData"] retain];
    [returnDict removeObjectForKey:@"inputData"];
    [returnDict removeObjectForKey:@"outputData"];

    if([sender respondsToSelector:@selector(jobRequestDone:inputData:outputData:)]) {
      [sender jobRequestDone:returnDict
                   inputData:inputData
                  outputData:outputData];
      fprintf(stderr, " sent sender jobRequestDone\n");
    }
    else
      fprintf(stderr, " jobRequestDone on sender not available\n");
    fflush(stderr);
    
  NS_HANDLER
    NSLog(@"error jobDone: %@", localException);
  NS_ENDHANDLER

  [lastQueueChange release];
  lastQueueChange = [[NSDate date] retain];

  [jobID release];
  fprintf(stderr, "NDDSServer jobDone, finished\n");
  fflush(stderr);
}

- (BOOL)killFlag
{
  BOOL  localFlag=NO;

  [killLock lock];
  localFlag = killFlag;
  [killLock unlock];

  return localFlag;
}

@end

@implementation NDDSServerThread

+ (void)startNewServerThreadWithPorts:(NSArray *)portArray
{
  NSAutoreleasePool     *pool =[[NSAutoreleasePool alloc] init];
  NSConnection          *serverConnection;
  id                    processingObject, queueServer;
  BOOL			doneFlag = NO;
  NSMutableDictionary   *queueItem;
  int			loopNumber=0;

  serverConnection = [NSConnection connectionWithReceivePort:[portArray objectAtIndex:0]
                                                    sendPort:[portArray objectAtIndex:1]];

  processingObject = [[portArray objectAtIndex:2] alloc];
  [processingObject init];

  queueServer = [[serverConnection rootProxy] retain];
  NSLog(@"ownerConnection = %@", queueServer);
  if([processingObject respondsToSelector:@selector(setNDDSServer:)])
    [processingObject setNDDSServer:queueServer];

  while (!doneFlag) {		
    fprintf(stderr,"before getNextJobRequest\n"); fflush(stderr);
    queueItem = [queueServer getNextJobRequest];
    fprintf(stderr,"process item %d : %s\n",loopNumber, [[queueItem description] cString]);	

    if(queueItem != nil) {
      NS_DURING
        loopNumber++;

        [processingObject processRequest:queueItem];

        //[self processFile:queueItem];
        //[self sendMail:params];

        if(![processingObject conformsToProtocol:@protocol(NDDSAsyncProcessingObject)])
          [queueServer jobDone:queueItem];
        
      NS_HANDLER
        NSLog(@"exception during processing of queue entry\n%@", localException);
      NS_ENDHANDLER
    }

    doneFlag = [queueServer killFlag];
  }

  [processingObject release];
  [queueServer release];
  [pool release];
  NSLog(@"thread exiting");
}

@end
