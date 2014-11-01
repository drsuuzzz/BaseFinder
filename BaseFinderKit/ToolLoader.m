 /* "$Id: ToolLoader.m,v 1.2 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, and Lloyd Smith

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

//#define TOOLSTREXT @"bundle"

#import <GenericToolCtrl.h>
#import "ToolLoader.h"
#import "ABIProcessTool.h"

@protocol ToolLoaderLocalMethods
//- (GenericToolCtrl*)controllerForClass:theClass;

- (void)registerForEventNotification:tool;
- (void)deregisterForEventNotification:tool;

- (void)loadToolDir:(NSString *)path;
- (void)loadLibDir:(NSString *)path;
- (void)loadTool:(NSString *)fileName;
@end

id   theOneAndOnlyToolLoader = nil;

@implementation ToolLoader

+ (id)loader
{
  if(theOneAndOnlyToolLoader == nil) {
    theOneAndOnlyToolLoader = [[ToolLoader alloc] init];
  }
  return theOneAndOnlyToolLoader;
}

- init
{
  [super init];

  tools = nil;
  toolnames = nil;
  libraryNames = nil;
  currToolIx = -1;
  debugMode = NO;
  loadPublic = YES;
  loadPrivate = YES;

  return self;
}

- (void)setLoadPublic:(BOOL)value
{
  loadPublic = value;
}

- (void)setLoadPrivate:(BOOL)value
{
  loadPrivate = value;
}

- (void)setDebugMode:(BOOL)value
{
  debugMode = value;
}

- (void)loadTool:(NSString *)fileName
{
  id        theBundle;
  id        processorClass;
  //id        controllerClass;
  //NSString  *ctrlName;

  // check tool class name  against loadedToolsNames
  if ([toolnames containsObject:fileName]) {
    if(debugMode) fprintf(stderr,"    didn't load %s because it's already been loaded\n", [fileName cString]);
    return;
  }
  if ([libraryNames containsObject:fileName]) {
    NSLog(@"Error loading bundle: %@ exists in both NSLibraries and NSTools.\n\nThis bundle will probably not function properly. Please remove one of these bundles from\n/LocalLibrary/Basefinder or\n<your home>/Library/BaseFinder", fileName);
    [toolnames addObject:fileName];
    return;
  }

  NS_DURING
    //theBundle=[[NSBundle alloc] initWithPath:fileName];
    theBundle=[NSBundle bundleWithPath:fileName];
    processorClass = [theBundle classNamed:[fileName stringByDeletingPathExtension]];
    //NSLog(@"processorClass=%@", processorClass);

    /* stuff related to controller class not need in commandLine
    ctrlName = [[fileName stringByDeletingPathExtension] stringByAppendingString:CTRLSUF];
    controllerClass = [theBundle classNamed:ctrlName];
    //NSLog(@"controllerClass=%@", controllerClass);
    if(controllerClass == NULL) {
      // failed to load class because it already exists
      if(debugMode) fprintf(stderr,"failed to load\n");
      [theBundle release];
    }
    //[tools addObject:[[processorClass new] autorelease]];
    */

    [tools addObject:processorClass];
    [toolnames addObject:fileName];

    // Load help from the bundle:
    //[[NXHelpPanel new] addSupplement:@"SuppHelp" inPath:[theBundle directory]];
  NS_HANDLER
    NSLog(@"exception during -loadTool %s: %@\n", fileName, localException);
  NS_ENDHANDLER
}



- (void)loadLibDir:(NSString *)path
{
  NSFileManager *filemanager;
  NSString *file;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;
      
  if(debugMode) fprintf(stderr,"loading libs from '%s'\n",[path cString]);
  filemanager = [NSFileManager defaultManager];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
      return;
  contents = [filemanager directoryContentsAtPath:path];
  enumerator = [contents objectEnumerator];
  while ((file = [enumerator nextObject])) {
    if ([libraryNames containsObject:file]) {
      if(debugMode) fprintf(stderr,"    didn't load %s because it's already been loaded\n", [file cString]);
    } else
      if ([[file pathExtension] isEqualToString:TOOLSTREXT]) {
        if(debugMode) fprintf(stderr, " '%s'\n",[file cString]);
        NSLog(@" '%s'",[file cString]);
        [[[NSBundle alloc] initWithPath:[path stringByAppendingPathComponent:file]] principalClass];
        [libraryNames addObject:file];
      }
  }
}

- (void)loadToolDir:(NSString *)path
{
  NSFileManager *filemanager;
  NSString *file, *oldDir;
  NSArray *contents;
  BOOL isDir=NO;
  NSEnumerator *enumerator;

  if(debugMode) fprintf(stderr,"loading tools from '%s'\n",[path cString]);
  filemanager = [NSFileManager defaultManager];
  oldDir = [[filemanager currentDirectoryPath] copy];
  if (![filemanager fileExistsAtPath:path isDirectory:&isDir] || !isDir)
    return;
  if(![filemanager changeCurrentDirectoryPath:path])
    return;
  contents = [filemanager directoryContentsAtPath:[filemanager currentDirectoryPath]];
  enumerator = [contents objectEnumerator];
  while (file = [enumerator nextObject]) {
    if ([[file pathExtension] isEqualToString:TOOLSTREXT]) {
      if(debugMode) fprintf(stderr, " '%s'\n",[file cString]);
      [self loadTool:file];
    }
  }
  [filemanager changeCurrentDirectoryPath:oldDir];
  [oldDir release];
}

- loadToolsORIG
{		
  /** Local Tools higher priority over Public Tools.
  ** i.e. local version of a tools will be the one loaded
  **/

  toolnames = [[NSMutableArray arrayWithCapacity:5] retain];
  libraryNames = [[NSMutableArray arrayWithCapacity:5] retain];
  
  if(debugMode) fprintf(stderr,"Loading Personal Libraries");
  [self loadLibDir :[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSLibraries"]];

  //if(debugMode) fprintf(stderr,"Loading Public Libraries\n");
  //[self loadLibDir:[NSString pathWithComponents:[NSArray arrayWithObjects:
  //  NSOpenStepRootDirectory(), @"LocalLibrary", @"BaseFinder", @"NSLibraries", nil]]];

  if(debugMode) fprintf(stderr,"Loading Personal Tools");
  [self loadToolDir:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSTools"]];

  //if(debugMode) fprintf(stderr,"Loading Public Tools\n");
  //[self loadToolDir:[NSString pathWithComponents:[NSArray arrayWithObjects:
  //  NSOpenStepRootDirectory(), @"LocalLibrary", @"BaseFinder", @"NSTools", nil]]];
 	
  currToolIx = -1;
  return self;	
}

- (void)loadTools
{
  /** Local Tools higher priority over Public Tools.
  ** i.e. local version of a tools will be the one loaded
  **/
  tools = [[NSMutableArray array] retain];
  toolnames = [[NSMutableArray arrayWithCapacity:5] retain];
  libraryNames = [[NSMutableArray arrayWithCapacity:5] retain];

  //first add the ABIProcessed place holder tool
  [tools addObject:[ABIProcessTool class]];
  [toolnames addObject:@"ABIProcessTool.bundle"];

  if(loadPrivate) {
    if(debugMode) fprintf(stderr,"Loading Personal Libraries");
#ifdef WIN32
    [self loadLibDir :[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSLibrariesNT"]];
#else
    [self loadLibDir :[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSLibraries"]];
#endif
  }

  if(loadPublic) {
    if(debugMode) fprintf(stderr,"Loading Public Libraries\n");
    [self loadLibDir:[NSString pathWithComponents:[NSArray arrayWithObjects:
      NSOpenStepRootDirectory(), @"LocalLibrary", @"BaseFinder", @"NSLibraries", nil]]];
  }

  if(loadPrivate) {
    if(debugMode) fprintf(stderr,"Loading Personal Tools");
#ifdef WIN32
    [self loadToolDir:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSToolsNT"]];
#else
    [self loadToolDir:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/BaseFinder/NSTools"]];
#endif
  }

  if(loadPublic) {
    if(debugMode) fprintf(stderr,"Loading Public Tools\n");
    [self loadToolDir:[NSString pathWithComponents:[NSArray arrayWithObjects:
      NSOpenStepRootDirectory(), @"LocalLibrary", @"BaseFinder", @"NSTools", nil]]];
  }

  currToolIx = -1;
}

- (NSMutableArray*)tools
{
  if(tools == nil) [self loadTools];
  return tools;
}

/*
- (GenericToolCtrl*)controllerForClass:theClass
{
  int i,count=[tools count];
  id currTool;

  for (i=0;i<count;i++) {
    currTool = [tools objectAtIndex:i];
    if([[currTool dataProcessor] class]==theClass)
      return currTool;
  }
  return nil;
}
*/

- (void)registerForEventNotification:tool
{
  if (![eventNotifyList containsObject:tool]) [eventNotifyList addObject:tool]; 
}

- (void)deregisterForEventNotification:tool
{
  [eventNotifyList removeObject:tool]; 
}

- (void)log:(NSString*)message;
{
  NSLog(message);
}

@end
