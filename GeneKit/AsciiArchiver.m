/* "$Id: AsciiArchiver.m,v 1.3 2006/08/04 20:31:35 svasa Exp $" */
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

#import "AsciiArchiver.h"


char *aaErrorMessages[] = {
  /* AA_classUnknown */			"Object class unknown",
  /* AA_syntaxError */			"Syntax error"
};

// These constants, and several of the AA... routines below, are closely
// derived from gcc source code
#define _C_ID       '@'
#define _C_CHR      'c'
#define _C_UCHR     'C'
#define _C_SHT      's'
#define _C_USHT     'S'
#define _C_INT      'i'
#define _C_UINT     'I'
#define _C_LNG      'l'
#define _C_ULNG     'L'
#define _C_FLT      'f'
#define _C_DBL      'd'
#define _C_CHARPTR  '*'
#define _C_ARY_B    '['
#define _C_ARY_E    ']'
#define _C_STRUCT_B '{'
#define _C_STRUCT_E '}'

@implementation AsciiArchiver:NSObject

/* Read stream until a balanced set of delimiters has been seen;
* If discard, just throw it all away and return NULL,
* else allocate a string and return the stuff between the delimiters
* Treat any char preceded by a '\' as an escaped literal
*/
- (char*)AAreadDelimitedString:(char*)delims :(BOOL)discard
{
  int delimCnt = 0;
  BOOL firstFound = NO, escaped=NO;
  char c='\0';
  char *buf=NULL;
  int bufLength=0, bufAlloc=32;

#define BUFAPPEND(C) { if(bufLength==bufAlloc) { bufAlloc *= 2; buf=realloc(buf,bufAlloc); } \
  buf[bufLength++]=C; }
	
  if (strlen(delims)<2)
    return NULL;

  if (!discard) {
    buf=(char *)malloc(bufAlloc);
  }
  while((!firstFound || (delimCnt!=0)) && ((c=*(readDataPtr++))!='\0')) {
    if(c=='\\') {
      escaped=YES;
      continue;
    }
    if (firstFound && !discard)
      BUFAPPEND(c);
    // if the delims are different, find a balanced set:
    if (delims[0]!=delims[1]) {
      if(c==delims[0] && !escaped) {
        firstFound=YES;
        delimCnt++;
      } else if(c==delims[1] && !escaped)
        delimCnt--;
    } else { //just find a pair
      if(c==delims[0] && !escaped) {
        if (!firstFound) {
          firstFound = YES;
          delimCnt++;
        } else {
          delimCnt--;
        }
      }
    }
    escaped=NO;
  }

  if (c=='\0') {
    free(buf);
    return NULL;
  }

  if (!discard) {
    buf[--bufLength]='\0'; // get rid of closing delimiter
    buf=realloc(buf,bufLength+1);
    return buf;
  } else {free(buf); return NULL;}
}			


//Read stream past the next EOL
- (void)AAreadToEOL
{
  char c;

  while((c=*(readDataPtr++))!='\0' && c != '\n');
}

// Return the next non-whitespace char
- (char)AAlookahead
{
  char c;

  while ((c=*(readDataPtr++)) && (isspace((int)c) || c == '\r')) {
    //if (debugmode) fprintf(stderr, "AAlookahead c=0%o  c='%c'\n", c, c);
  }

  c=*(--readDataPtr);

  return c;
}

// Given an array element descriptor, pulls out everything within [] and puts it into buf
- (void)AAextractElementDescriptor:(const char*)desc :(char*)buf :(int*)cnt
{
  int adlen;
  const char *s, *s1;
  int bcount=1; // bracket count, for balancing

  for (s = desc + 1;*s>='0' && *s<='9';s++);
  for (s1 = s; ;s1++) {
    if (*s1==_C_ARY_B)
      bcount++;
    if (*s1==_C_ARY_E)
      bcount--;
    if (bcount==0)
      break;
  }
  adlen = (unsigned long)s1-(unsigned long)s;

  sscanf(desc+1,"%d",cnt);

  strncpy(buf,s,adlen);
  buf[adlen]='\0';

}	

// next two are right out of GCC source:
- (int)AAtypeAlign:(const char*)type
{
  switch(*type) {
    case _C_ID:
    		return __alignof__(id);
      break;
    case _C_CHR:
      return __alignof__(char);
      break;
    case _C_UCHR:
      return __alignof__(unsigned char);
      break;
    case _C_SHT:
      return __alignof__(short);
      break;
    case _C_USHT:
      return __alignof__(unsigned short);
      break;
    case _C_INT:
      return __alignof__(int);
      break;
    case _C_UINT:
      return __alignof__(unsigned int);
      break;
    case _C_LNG:
      return __alignof__(long);
      break;
    case _C_ULNG:
      return __alignof__(unsigned long);
      break;
    case _C_FLT:
      return __alignof__(float);
      break;
    case _C_DBL:
      return __alignof__(double);
      break;
    case _C_CHARPTR:
      return __alignof__(char*);
      break;
    case _C_ARY_B:
      while (isdigit((int)(*++type))) /* do nothing */;
      return [self AAtypeAlign:type];
    case _C_STRUCT_B:
    {
      struct { int x; double y; } fooalign;
      int align;
      type++;
      if (*type != _C_STRUCT_E) {
        align = [self AAtypeAlign:type];
        return align > __alignof__(fooalign) ? align : __alignof__(fooalign);
      } else
        return __alignof__ (fooalign);
    }
    default:
      return -1;
  }
}

- (char*)AAskipTypespec:(char*)type
{
  switch (*type) {

    /* The following are one character type codes */
    case _C_ID:
    case _C_CHR:
    case _C_UCHR:
    case _C_CHARPTR:
    case _C_SHT:
    case _C_USHT:
    case _C_INT:
    case _C_UINT:
    case _C_LNG:
    case _C_ULNG:
    case _C_FLT:
    case _C_DBL:
      return ++type;
      break;

    case _C_ARY_B:
      /* skip digits, typespec and closing ']' */

      while(isdigit((int)(*++type)));
      type = [self AAskipTypespec:type];
      if (*type == _C_ARY_E)
        return ++type;
      else
        return NULL;

    case _C_STRUCT_B:
      /* skip name, and elements until closing '}'  */

      type++;
      while (*type != _C_STRUCT_E) { type = [self AAskipTypespec:type]; }
        return ++type;

    default:
      return NULL;
  }
}

- (int)AAtypeSize:(const char*)type
{
  int len = strlen(type);

  if (len==0) return -1;

  switch(type[0]) {
    case _C_INT:
    case _C_UINT:return sizeof(int);
    case _C_SHT:
    case _C_USHT:return sizeof(short);
    case _C_LNG:
    case _C_ULNG:return sizeof(long);
    case _C_FLT:return sizeof(float);
    case _C_DBL:return sizeof(double);
    case _C_CHR:
    case _C_UCHR:return sizeof(char);
    case _C_CHARPTR:return sizeof(char *);
    case _C_ID:return sizeof(id);
      // The last two cases are right out of GCC source, almost:
    case _C_ARY_B:
    {
      int cnt = atoi(type+1);
      int size, align;

      while (isdigit((int)(*++type)));
      size = [self AAtypeSize:type];
      align = [self AAtypeAlign:type];

      if ((size % align) != 0)
        size += align - (size % align);

      return cnt*size;
    }
      break;
    case _C_STRUCT_B:
		    {
                      int acc_size = 0;
                      int align;
                      type++;
                      while (*type != _C_STRUCT_E) {
                        align = [self AAtypeAlign:type];       /* padd to alignment */
                        if ((acc_size % align) != 0)
                          acc_size += align - (acc_size % align);
                        acc_size += [self AAtypeSize:type];   /* add component size */
                        type = [self AAskipTypespec:(char*)type];	         /* skip component */
                      }
                      return acc_size;
                    }
      break;
  }
		
  return -1;
}

/*****
*
* Initialization / dealloc section
*
******/

- (id)initWithContentsOfFile:(NSString *)path
{
  expectingTag = YES;
  fileName = [path copy];
  initFromFilename = YES;
  dirty = NO;
  mode = AA_readOnly;

  nestingLevel = 0;

  knownObjects = [[NSMutableArray alloc] init];
  aaData = [[NSMutableString alloc] initWithContentsOfFile:path];
  readDataPtr = (char*)[aaData cString];

  return self;	
}

- (id)initWithAsciiData:(NSString*)data
{
  expectingTag = YES;
  fileName = NULL;
  initFromFilename = NO;
  dirty = NO;
  mode = AA_readOnly;

  nestingLevel = 0;

  knownObjects = [[NSMutableArray alloc] init];
  aaData = [data copy];
  readDataPtr = (char*)[aaData cString];

  return self;	
}

- (id)initForWriting
{
  expectingTag = NO;
  fileName = NULL;
  initFromFilename = NO;
  dirty = NO;
  mode = AA_writeOnly;
  readDataPtr = NULL;
  
  nestingLevel = 0;

  knownObjects = [[NSMutableArray alloc] init];
  aaData = [[NSMutableString alloc] initWithCapacity:1024];
  
  return self;	
}

- (void)dealloc
{
  //if(dirty) [self flushToDisk];

  if(aaData != nil) [aaData release];
  if(fileName != nil) [fileName release];
  [knownObjects release];

  [super dealloc];
}

- (BOOL)flushToDisk
{
  if (initFromFilename && (mode == AA_writeOnly)) {
    //if(fflush(stream) == '\0') return NO;
    dirty = NO;
  }
  return YES;
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;
{
  BOOL ok;
  
  if(mode != AA_writeOnly) return NO;
  ok = [aaData writeToFile:path  atomically:flag];
  if(ok) dirty=NO;
  return ok;
}

- (NSString*)asciiRepresentation;
{
  return [[aaData copy] autorelease];
}

/*****
*
* Write AsciiArchiver representation section
*
*****/

- writeObject:object tag:(const char *)tag
{
  unsigned int oid;
  int i;
  BOOL wasAbsent = ([knownObjects indexOfObject:object] == NSNotFound);

  if (![object respondsToSelector:@selector(writeAscii:)])
    return nil;

  if (![knownObjects containsObject:object]) [knownObjects addObject:object];
  oid = [knownObjects indexOfObject:object];

  if (tag[0]) {
    for (i=0;i<nestingLevel;i++)
      [aaData appendString:@"\t"];
    [aaData appendFormat:@"%s :@ = ", tag];
    //fprintf(stream,"%s :@ = ",tag);
  }
  if (wasAbsent) {
    if([object isKindOfClass:[NSObject class]])
      [aaData appendFormat:@"%u (%s) {\n",oid,[[[object class] description] cString]];
      //fprintf(stream,"%u (%s) {\n",oid,[[[object class] description] cString]);
    else {
      NSObject  *tempObject = (NSObject*)[object class];
      [aaData appendFormat:@"%u (%s) {\n",oid,(char*)[tempObject name]];
      //fprintf(stream,"%u (%s) {\n",oid,(char*)[tempObject name]);
    }
    //fprintf(stream,"%u (%s) {\n",oid,[[[object class] name] cString]);
    nestingLevel++;
    [object writeAscii:self];
    nestingLevel--;
    for (i=0;i<nestingLevel;i++)
      [aaData appendString:@"\t"];
      //fputc('\t', stream);
    [aaData appendString:@"}\n"];
    //fprintf(stream,"}\n");		
  }
  else
    [aaData appendFormat:@"%u\n",oid];
    //fprintf(stream,"%u\n",oid);
		
  dirty = YES;
		
  return self;
}

- writeArray:(void *)data size:(int)count type:(const char *)descriptor tag:(const char *)tag
{
  int i, ts;

  ts = [self AAtypeSize:descriptor];

  if (ts<=0)
    return nil;
		
  if(tag[0]) {
    for(i=0;i<nestingLevel;i++)
      [aaData appendString:@"\t"];
      //fputc('\t', stream);
    [aaData appendFormat:@"%s :[%d%s] = {\n",tag,count,descriptor];
    //fprintf(stream,"%s :[%d%s] = {\n",tag,count,descriptor);
  } else
    [aaData appendString:@"{\n"];
    //fprintf(stream,"{\n");
		
  nestingLevel++;
  for (i=0;i<count;i++)
    [self writeData:data+(ts*i) type:descriptor tag:""];
  nestingLevel--;
  for(i=0;i<nestingLevel;i++)
    [aaData appendString:@"\t"];
    //fputc('\t', stream);		
  [aaData appendString:@"}\n"];
  //fprintf(stream,"}\n");

  dirty = YES;
		
  return self;
}

- writeString:(char *)string tag:(const char *)tag
{
  char c;
  int i;

  if(tag[0]) {
    for(i=0;i<nestingLevel;i++)
      [aaData appendString:@"\t"];
      //fputc('\t', stream);
    [aaData appendFormat:@"%s :* = ",tag];
    //fprintf(stream,"%s :* = ",tag);
  }

  [aaData appendString:@"\""];
  //fputc('"', stream);
  for (i=0;(c=((char *)string)[i]);i++) {
    if (c=='\"')
      [aaData appendString:@"\\"];
      //fputc('\\', stream);
    [aaData appendFormat:@"%c", c];
    //fputc(c, stream);
  }
  [aaData appendString:@"\"\n"];
  //fputc('\"', stream);
  //fputc('\n', stream);

  dirty = YES;

  return self;
}

- writeNSString:(NSString *)string tag:(const char *)tag
{
  [self writeString:(char*)[string cString] tag:tag];
  return self;
}


- writeData:(void *)data type:(const char *)descriptor tag:(const char *)tag
{
  int i;

  if (mode!=AA_writeOnly)
    return nil;

  if(strlen(tag) > 0 && [self AAtypeSize:descriptor]<=0) // typeSize() returns -1 if bad descriptor
    return nil;
		
  for (i=0;i<nestingLevel;i++)
    [aaData appendString:@"\t"];
    //fputc('\t', stream);
  if (tag[0])
    [aaData appendFormat:@"%s :%s = ",tag,descriptor];
    //fprintf(stream,"%s :%s = ",tag,descriptor);
  switch (descriptor[0]) {
    case _C_INT:
      [aaData appendFormat:@"%d\n",*(int *)data];
      //fprintf(stream,"%d\n",*(int *)data);
      break;
    case _C_UINT:
      [aaData appendFormat:@"%u\n",*(unsigned int *)data];
      //fprintf(stream,"%u\n",*(unsigned int *)data);
      break;
    case _C_SHT:
      [aaData appendFormat:@"%hd\n",*(short *)data];
      //fprintf(stream,"%hd\n",*(short *)data);
      break;
    case _C_USHT:
      [aaData appendFormat:@"%hu\n",*(unsigned short *)data];
      //fprintf(stream,"%hu\n",*(unsigned short *)data);
      break;
    case _C_LNG:
      [aaData appendFormat:@"%ld\n",*(long *)data];
      //fprintf(stream,"%ld\n",*(long *)data);
      break;
    case _C_ULNG:
      [aaData appendFormat:@"%lu\n",*(unsigned long *)data];
      //fprintf(stream,"%lu\n",*(unsigned long *)data);
      break;
    case _C_FLT:
      [aaData appendFormat:@"%lx\n",*(unsigned long *)data];
      //fprintf(stream,"%lx\n",*(unsigned long *)data);
      break;
    case _C_DBL:
#ifdef i386
      [aaData appendFormat:@"%lx %lx\n",*(((unsigned long *)data)+1),*(unsigned long *)data];
      //fprintf(stream,"%lx %lx\n",*(((unsigned long *)data)+1),*(unsigned long *)data);
#else
      [aaData appendFormat:@"%lx %lx\n",*(unsigned long *)data,*(((unsigned long *)data)+1)];
      //fprintf(stream,"%lx %lx\n",*(unsigned long *)data,*(((unsigned long *)data)+1));
#endif
      break;
    case _C_CHR:
    case _C_UCHR:
      if (isgraph((int)(*(char *)data)))
        [aaData appendFormat:@"%c\n",*(char *)data];
        //fprintf(stream,"%c\n",*(char *)data);
      else
        [aaData appendFormat:@"\\%d\n",(int)(*(char *)data)];
        //fprintf(stream,"\\%d\n",(int)(*(char *)data));
      break;
    case _C_CHARPTR:
      return [self writeString:*(char **)data tag:""];
    case _C_ID:
      return [self writeObject:*(id *)data tag:""];
    case _C_ARY_B:
    {
      char arrdesc[MAXDESCLEN+1];
      int cnt;

      [self AAextractElementDescriptor:descriptor :arrdesc :&cnt];
      return [self writeArray:data size:cnt type:arrdesc tag:""];

    }
      break;
    case _C_STRUCT_B:
    {
      const char *d = descriptor+1;
      char locdesc[MAXDESCLEN+1];
      int align, offset=0, i; // offset is (hopefully) current offset into buffer
      int balance;

      [aaData appendString:@"{\n"];
      //fprintf(stream,"{\n");
      nestingLevel++;

      while (*d) {
        if (*d==_C_STRUCT_B) {
          i=0;
          balance = 1;
          locdesc[i++] = *d++;
          while (balance>0) {
            if (*d==_C_STRUCT_B) balance++;
            else if (*d==_C_STRUCT_E) balance--;
            locdesc[i++] = *d++;
          }
          locdesc[i] = '\0';
        } else if (*d==_C_ARY_B) {
          i=0;
          balance = 1;
          locdesc[i++] = *d++;
          while (balance>0) {
            if (*d==_C_ARY_B) balance++;
            else if (*d==_C_ARY_E) balance--;
            locdesc[i++] = *d++;
          }
          locdesc[i] = '\0';
        } else if (*d==_C_STRUCT_E) {
          d++;
          continue;
        } else {
          locdesc[0]=*d++;
          locdesc[1]='\0';
        }
        align = [self AAtypeAlign:locdesc];
        if (offset%align)
          offset+= (align-(offset%align));
        [self writeData:data+offset type:locdesc tag:""];
        offset+=[self AAtypeSize:locdesc];
      }
      nestingLevel--;
      for (i=0;i<nestingLevel;i++)
        [aaData appendString:@"\t"];
        //fputc('\t', stream);
      [aaData appendString:@"}\n"];
      //fprintf(stream,"}\n");				
    }
      break;
  }

  dirty = YES;

  return self;	
}

/******
*
* Dearchive/read from an AsciiArchiver representation
*
******/

- skipItem
{
  if (mode!=AA_readOnly)
    return nil;

  if (currentDesc[0]==_C_ARY_B ||
      currentDesc[0]==_C_STRUCT_B ||
      currentDesc[0]==_C_ID)
    [self AAreadDelimitedString:"{}" :YES];
  else
    [self AAreadToEOL];

  return self;
}

- getNextTag:(char *)tagBuf
{  
  if (mode!=AA_readOnly)
    return nil;

  if(!expectingTag)
    [self skipItem];
		
  if ([self AAlookahead]==_C_STRUCT_E)
    return nil; // end of object

  if (sscanf(readDataPtr,"%s :%s =",tagBuf,currentDesc)!=EOF) {
    while(*(readDataPtr++) != ':');
    while(*(readDataPtr++) != '=');
    expectingTag = NO;
    return self;
  } else
    return nil;

  return nil;
}

- readObject
{
  int oid, i;
  id newObject=nil, objectClass;
  char *className;
  char tag[MAXTAGLEN], buffer[64];
  NSException  *theException;

  [self AAlookahead];
  i=0;
  while(!isspace((int)(*(readDataPtr)))) buffer[i++]=*(readDataPtr++);
  buffer[i]='\0';
  sscanf(buffer,"%d",&oid);

  NS_DURING
    if (([knownObjects count] > 0) && (oid < [knownObjects count]))
      newObject = [knownObjects objectAtIndex:oid];
    else
      newObject = nil;
  NS_HANDLER
    if([[localException name] isEqualToString:NSRangeException]) newObject = nil;
    else NSLog(@"unknown exception during AsciiArchiver -readObject (knownObject check)\n");
  NS_ENDHANDLER
  if(newObject != nil)  return newObject;

  className = [self AAreadDelimitedString:"()" :NO];
  //if((objectClass=objc_lookUpClass(className))==nil) {
  if((objectClass=NSClassFromString([NSString stringWithCString:className]))==nil) {
    [self skipItem]; // class not loaded; skip entire object archive
    theException = [NSException
                      exceptionWithName:@"AA_classUnknown"
                                 reason:[NSString stringWithFormat:@"Object class '%s' is unknown", className]
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithCString:className], @"errorData",
                                 nil]];
    free(className);
    [theException raise];
    return nil;
  }
  free(className);

  if([self AAlookahead]!=_C_STRUCT_B) {
    theException = [NSException exceptionWithName:@"AA_syntaxError"
                                           reason:@"Syntax error"
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSString stringWithCString:"missing {"], @"errorData",
                                           nil]];
    [theException raise];
  }
		
  readDataPtr++; // consume the _C_STRUCT_B
		
  newObject = [[[objectClass alloc] init] autorelease];
  [newObject beginDearchiving:self];
  if (![knownObjects containsObject:newObject]) [knownObjects addObject:newObject];

  expectingTag = YES;

  while ([self getNextTag:tag]!=nil) {
    /* Assigning the return value to newObject each time gives it an opportunity
    * to replace itself with an instance of another class, if it wants to
    * Or it can just kill itself and return nil, which will cause the rest
    * of the tags for this object to be skipped
    */
    newObject = [newObject handleTag:tag fromArchiver:self];
    //[newObject handleTag:tag fromArchiver:self];
    if (newObject==nil)
      break;
    expectingTag = YES;
  }

  // Jump over any unconsumed tags/items
  while ([self getNextTag:tag]!=nil)
    [self skipItem];

  readDataPtr++; // consume the _C_STRUCT_E	

  return newObject;
}

- readObjectWithTag:(const char *)tag
{
  char myTag[MAXTAGLEN];

  //fseek(stream,0,NX_FROMSTART);
  //rewind(stream);
  readDataPtr = (char*)[aaData cString];  //resets pointer to beginning
  [self getNextTag:myTag];
  while (strcmp(tag,myTag)) {
    [self skipItem];
    [self getNextTag:myTag];
  }

  return [self readObject];
}

- (BOOL)findTag:(const char *)tag
{
  char myTag[MAXTAGLEN];
  id   tagReturn=nil;

  //fseek(stream,0,NX_FROMSTART);
  //rewind(stream);
  readDataPtr = (char*)[aaData cString];  //resets pointer to beginning
  tagReturn = [self getNextTag:myTag];
  while ((tagReturn != nil) && (strcmp(tag,myTag))) {
    [self skipItem];
    expectingTag = YES;
    tagReturn = [self getNextTag:myTag];
  }

  if(tagReturn == nil) return NO;
  return YES;;
}

- (void *)readData
{
  void *buf;
  int tsize = [self AAtypeSize:currentDesc];

  if (tsize < 0)
    return NULL;
		
  switch(currentDesc[0]) {
    case _C_ID: buf = [self readObject]; break;
    case _C_CHARPTR: buf = [self AAreadDelimitedString:"\"\"" :NO]; break;
    default:  buf = malloc(tsize);
      [self readData:buf];
      break;
  }

  expectingTag = YES;

  return buf;
}

- readArray:(void *)buf
{
  int cnt;
  char arrdesc[MAXDESCLEN];

  [self AAextractElementDescriptor:currentDesc :arrdesc :&cnt];

  return [self readArray:buf elementType:arrdesc count:cnt];
}

- readArray:(void *)buf elementType:(const char *)descriptor count:(int)cnt
{
  int i,ts=[self AAtypeSize:descriptor];

  if ([self AAlookahead]!=_C_STRUCT_B)
    return nil;
		
  readDataPtr++;

  for (i=0;i<cnt;i++) {
    expectingTag=NO;
    [self readData:(buf+(ts*i)) type:descriptor];
  }
		
  [self AAlookahead];
  readDataPtr++;
		
  return self;
}	

- (int)arraySize
{
  int cnt;
  char arrdesc[MAXDESCLEN];

  if (currentDesc[0]==_C_ARY_B)
    [self AAextractElementDescriptor:currentDesc :arrdesc :&cnt];
  else
    return 0;
		
  return cnt;
}

- readData:(void *)buf
{
  return [self readData:buf type:currentDesc];
}

- readString:(char *)buf maxLength:(int)len
{
  char *loc = [self AAreadDelimitedString:"\"\"" :NO];

  strncpy(buf,loc,len);
  buf[len]='\n';
  free(loc);
  return self;
}

- (NSString *)readNSString
{
  char *loc = [self AAreadDelimitedString:"\"\"" :NO];
  NSString *temp;

  temp = [NSString stringWithCString:loc];
  free(loc);
  return temp;
}


- readData:(void *)buf type:(const char *)descriptor
{
  char   localbuffer[256];

  if (mode!=AA_readOnly)
    return nil;

  if(expectingTag)
    return nil;

  switch(descriptor[0]) {
    case _C_INT:
      [self AAlookahead];
      sscanf(readDataPtr,"%d",(int*)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_UINT:
      [self AAlookahead];
      sscanf(readDataPtr,"%u",(unsigned*)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_SHT:
      [self AAlookahead];
      sscanf(readDataPtr,"%hd",(short*)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_USHT:
      [self AAlookahead];
      sscanf(readDataPtr,"%hu",(unsigned short*)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_LNG:
      [self AAlookahead];
      sscanf(readDataPtr,"%ld",(long *)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_ULNG:
      [self AAlookahead];
      sscanf(readDataPtr,"%lu",(unsigned long *)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_FLT:
      [self AAlookahead];
      sscanf(readDataPtr, "%s", localbuffer);
      sscanf(localbuffer,"%lx",(unsigned long *)buf);
      while(!isspace((int)*(readDataPtr++)));
      break;
    case _C_DBL:
      [self AAlookahead];
#ifdef i386
      sscanf(readDataPtr,"%lx",((unsigned long *)buf+1));
      while(!isspace((int)*(readDataPtr++)));
      sscanf(readDataPtr,"%lx",(unsigned long *)buf);
      while(!isspace((int)*(readDataPtr++)));
      //sscanf(stream,"%lx %lx",((unsigned long *)buf+1),(unsigned long *)buf);
      break;
#else
      sscanf(readDataPtr,"%lx",(unsigned long *)buf);
      while(!isspace((int)*(readDataPtr++)));
      sscanf(readDataPtr,"%lx",((unsigned long *)buf)+1);
      while(!isspace((int)*(readDataPtr++)));
      //fscanf(stream,"%lx %lx",(unsigned long *)buf,((unsigned long *)buf)+1);
      break;
#endif
    case _C_CHR:
    case _C_UCHR:
    {
      char c;
      int intbuf;

      [self AAlookahead]; // consume white space
      c = *(readDataPtr++);
      if (c!='\\')
        *(char *)buf = c;
      else {
        [self AAlookahead];
        sscanf(readDataPtr,"%i",&intbuf);
        while(!isspace((int)*(readDataPtr++)));
        *(char *)buf = (char)intbuf;
      }
      break;
    }
    case _C_CHARPTR: *(char **)buf = [self AAreadDelimitedString:"\"\"" :NO]; break;
    case _C_ID: *(id *)buf = [self readObject]; break;
    case _C_ARY_B:{
      int cnt;
      char arrdesc[MAXDESCLEN];

      [self AAextractElementDescriptor:descriptor :arrdesc :&cnt];

      [self readArray:buf elementType:arrdesc count:cnt];
    };
      break;
    case _C_STRUCT_B:
    {
      const char *d = descriptor+1;
      char locdesc[MAXDESCLEN+1];
      int align, offset=0, i; // offset is (hopefully) current offset into buffer
      int balance;

      if ([self AAlookahead]!=_C_STRUCT_B)
        return nil;
      readDataPtr++;

      while (*d) {
        expectingTag = NO;
        if (*d==_C_STRUCT_B) {
          i=0;
          balance = 1;
          locdesc[i++] = *d++;
          while (balance>0) {
            if (*d==_C_STRUCT_B) balance++;
            else if (*d==_C_STRUCT_E) balance--;
            locdesc[i++] = *d++;
          }
          locdesc[i] = '\0';
        } else if (*d==_C_ARY_B) {
          i=0;
          balance = 1;
          locdesc[i++] = *d++;
          while (balance>0) {
            if (*d==_C_ARY_B) balance++;
            else if (*d==_C_ARY_E) balance--;
            locdesc[i++] = *d++;
          }
          locdesc[i] = '\0';
        } else if (*d==_C_STRUCT_E) {
          d++;
          continue;
        } else {
          locdesc[0]=*d++;
          locdesc[1]='\0';
        }
        align = [self AAtypeAlign:locdesc];
        if (offset%align)
          offset+= (align-(offset%align));
        [self readData:buf+offset type:locdesc];
        offset+=[self AAtypeSize:locdesc];
      }
    }
      [self AAlookahead];
      readDataPtr++;
      break;		
  }

  expectingTag = YES;

  return self;		
}

@end


// Putting this here to make sure it gets linked in whenever AsciiArchiver is used.

@implementation NSObject (AAMethods)

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  return self;
}

- (void)writeAscii:archiver
{

}

- (void)beginDearchiving:archiver
{

}

@end

/*@implementation NSObject (AAMethods)

- (id)handleTag:(char *)tag fromArchiver:archiver
{
  return self;
}

- (void)writeAscii:archiver
{
}

- (void)beginDearchiving:archiver
{
}

@end*/
