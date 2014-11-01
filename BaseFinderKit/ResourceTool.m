/* "$Id: ResourceTool.m,v 1.2 2006/08/04 17:23:55 svasa Exp $" */
/***********************************************************

Copyright (c) 1993-2000 Morgan Giddings, Jessica Severin, Lloyd Smith and Mike Koehrsen

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

#import "ResourceTool.h"
#import <GeneKit/AsciiArchiver.h>
#import <ctype.h>

/*****
* Oct 22, 1996 Jessica Severin
*  Finished initial conversion to OpenStep
*
* Jan. 10, 1995
* Changed so resource source  matrix disables "public" option if the
* public directory doesn't exist and can't be created
*
* July 19, 1994 Mike Koehrsen
* Split ResourceTool class into ResourceTool and ResourceToolCtrl,
* in keeping with the general reorganization of the tool class hierarchy.
* Also fixed some minor bugs relating to showing of params loaded from script:
* in some cases the resource pop-up was getting messed up, and the location
* of the resource file (public or private) was not being stored.
*****/


@interface ResourceTool(private)
- (short)resourceSource;
- (void)setResourceSource:(short)value;
@end

@implementation ResourceTool

- init
{
  [super init];
  currentLabel = [[NSMutableString alloc] init];
  return self;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"%@\tcurrentLabel:%@\tsource:%d",
    [super description], currentLabel, resourceSource];
}

// All of these methods should be overridden
// e.g., "Default Matrix", "Default Mobility"
- (NSString *)defaultLabel
{
  return @"";
}

- (NSMutableString*)currentLabel
{
  return currentLabel;
}

- (short)resourceSource
{
  return resourceSource;
}

- (void)setResourceSource:(short)value
{
  resourceSource = value;
}

-(void)readResource:(NSString*)resourcePath
{

}

- (void)writeResource:(NSString*)resourcePath
{
	 
}

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  char   tempBuffer[256];
  
  if (!strcmp(tag,"currentLabel")) {
    [archiver readString:tempBuffer maxLength:255];
    [currentLabel release];
    currentLabel = [[NSMutableString alloc] initWithCString:tempBuffer];
  }
  else
    if(!strcmp(tag,"resourceSource")) [archiver readData:&resourceSource];
  else return [super handleTag:tag fromArchiver:archiver];

  return self;
}


- (void)writeAscii:archiver
{
  [archiver writeString:(char*)[currentLabel cString] tag:"currentLabel"];
  [archiver writeData:&resourceSource type:"s" tag:"resourceSource"];
  return [super writeAscii:archiver];
}

/*****
* NSCopying section
******/
- (id)copyWithZone:(NSZone *)zone
{
  ResourceTool   *dupSelf;

  dupSelf = [super copyWithZone:zone];
  //if(dupSelf->currentLabel != nil) [dupSelf->currentLabel release];
  dupSelf->currentLabel = [currentLabel mutableCopy];
  dupSelf->resourceSource = resourceSource;
  return dupSelf;
}

@end
