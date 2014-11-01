/* "$Id: Sequence.m,v 1.8 2008/04/15 20:52:59 smvasa Exp $" */

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


//By Morgan Giddings
//Version 0.5

//#import "ConfMatch.h"
#import "Sequence.h"
#import <stdio.h>
#import <stdlib.h>
@implementation Sequence

+ (Sequence *)newWithCStringSeq:(char *)seq
{	
  id theptr;

  theptr = [[self alloc] init];
  [theptr setSeqFromCString:seq];
  return theptr;
}

+ (Sequence *)newWithString:(NSString *)string
{
  id theptr;

  theptr = [[self alloc] init];
  [theptr setSeqFromCString:(char*)[string cString]];
  return theptr;
}

+ (Sequence *)newWithString:(NSString *)string class:(Class)class
{
  id theptr;

  theptr = [[self alloc] init];
  [theptr setClass:class];
  [theptr setSeqFromCString:(char*)[string cString]];
  return theptr;
}

+ (Sequence *)newSequence
{
  return [[[self alloc] init] autorelease];
}

+ (Sequence *)sequenceWithString:(NSString *)string
{
  id theptr;

  theptr = [[self alloc] init];
  [theptr setSeqFromCString:(char*)[string cString]];
  return [theptr autorelease];
}

- init
{
  theSeq = [[NSMutableArray arrayWithCapacity:0] retain];
  BaseClass = [Base class];
	offset = 0;
	backForwards = FALSE;
  [super init];
  return self;
}

-initWithContentsOfFile:(NSString*)fname
{
	NSString  *tempString;
	char			*tempseq, c;
	int				i,starti,len;
	
	[self init];
	tempString = [NSString stringWithContentsOfFile:fname];
	if (tempString == nil) {
		return self;
	}
	tempString = [tempString uppercaseString];
	len = 0;
  tempseq = (char *)calloc(([tempString length]+1),sizeof(char));
	if ([tempString characterAtIndex:0] == '>') { //eat FASTA header
		starti=1;
		while ([tempString characterAtIndex:starti++]!='\n') {
		}
	}
	else
		starti=0;
	for (i=starti; i < [tempString length]; i++) {
		c = [tempString characterAtIndex:i];
		if ((c == 'T') || (c == 'C') || (c == 'G') || (c == 'A') || (c == 'U') || (c == 'N'))
			tempseq[len++] = c;
	}
	tempseq[len] = '\0';
	[self setSeqFromCString:tempseq];
	free(tempseq);
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  theSeq = [[coder decodeObject] retain];
  BaseClass = [Base class];
  return self;
}

- replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    if ([encoder isBycopy])
        return self;
    else
        return [super replacementObjectForPortCoder:encoder];
}

- (void) setOffset:(int)newset
{
	if (newset > 0)
		offset = newset;
}

- (int) getOffset
{
	return offset;
}

- (void) setbackForwards:(BOOL)flag
//forwards = FALSE
//Backwards = TRUE
//this will effect the display of the base positions
{
	backForwards = flag;
}

- (BOOL) getbackForwards
{
	return backForwards;
}


- (id <BaseProtocol>)baseAt:(unsigned)baseno
{
  return [theSeq objectAtIndex:baseno];
}

- (void)addBase:(id <BaseProtocol>)base
{
  [theSeq addObject:base];
}

- (void)insertBase:(id <BaseProtocol>)base At:(unsigned)baseno
{
  [theSeq insertObject:base atIndex:baseno];
}

- (void)removeBaseAt:(unsigned)index;
{
  if(index < [theSeq count])
    [theSeq removeObjectAtIndex:index];
}

- (char)charBaseAt:(unsigned)baseno
{
  return [[theSeq objectAtIndex:baseno] retBase];
}

- (void)addCharBase:(char)base
{
  [theSeq addObject:[BaseClass newWithChar:base]];
}

- (void)insertCharBase:(char)base At:(unsigned)baseno
{
  [theSeq insertObject:[BaseClass newWithChar:base]
               atIndex:baseno];
}

- (unsigned)positionOfBase:(id <BaseProtocol>)base
{
    return (unsigned)[theSeq indexOfObjectIdenticalTo:base];
}

- (int)indexOfBaseAssociatedWithPeak:(id)peak;
{
  int i,count=[theSeq count];
  for (i=0; i < count; i++)
    if ([[theSeq objectAtIndex:i] peak] == peak)
      return i;

  return -1;
}

- setSeqFromCString:(char *)theBases
{
  unsigned length, i;

  length = strlen(theBases);
  [theSeq release];
  theSeq = [[NSMutableArray arrayWithCapacity:length] retain];
  for (i = 0; i < length; i++)
    if ([BaseClass validBase:theBases[i]])
      [theSeq addObject:[BaseClass newWithChar:theBases[i]]];
  return self;
}

- (void)setClass:(Class)class
{
  BaseClass = class;
}


// theCBuf must be at least seqLength + 1 (for terminating null char).
- (void)getCStringSeqRep:(char *)theCBuf
{
  unsigned length, i;

  length = [theSeq count];
  for (i = 0; i < length; i++)
    theCBuf[i] = [[theSeq objectAtIndex:i] retBase];
  theCBuf[length] = '\0';  //Terminate with null
}

// Returns an NSString representing the base sequence
- (NSString *) seqString
{
  char *temp;
  NSString *theString;

  temp = malloc([theSeq count] + 1);
  [self getCStringSeqRep:temp];
  theString = [NSString stringWithCString:temp];
  free(temp);
  return theString;
}

- (unsigned)seqLength
{
  return [theSeq count];
}

- (unsigned)count
{
    return [theSeq count];
}

- (NSString *)description
{
  //return [[super description] stringByAppendingString:[self seqString]];
  return [self seqString];
}

//mask with N's nucleotides other then those specified.
- (void)maskSequence:(char *)theCs NT1:(char)nt1 NT2:(char)nt2
{
	int	 len, i, j;
	char c;
	
	len = [theSeq count];
	theCs[0]='0';
	j = 1;
	for (i = 0; i < len; i++) {
		c = [[theSeq objectAtIndex:i] retBase];
		if ((c == nt1) || (c == nt2))
			theCs[j] = c;
		else
			theCs[j] = 'N';
		j++;
	}
	theCs[j] = '\0';
}

- (void)reverseSequence:sender
{	
  id copy;
  int i, count;

  count = [[theSeq autorelease] count];
  copy = [[NSMutableArray arrayWithCapacity:count] retain];
  for (i = (count-1); i >=0; i--)
    [copy addObject:[theSeq objectAtIndex:i]];
  theSeq = copy;
}

-(void)partialSequenceFrom:(int)from to:(int)to
{
	int							count, i;
	NSMutableArray	*next;
	
	count = [theSeq count];
	if (((from-to) > count) || (from > count) || (from > to) || (to > count))
		return;
	next = [[NSMutableArray arrayWithCapacity:(to-from+1)] retain];
	for (i = from-1; i < to; i++) {
		[next addObject:[theSeq objectAtIndex:i]];
	}
	[theSeq release];
	theSeq = next;
}

- (Sequence*)reverseComplement
{
  Sequence   *newSeq;

  newSeq = [self copy];
  [newSeq complementSequence:self];
  [newSeq reverseSequence:self];
  return [newSeq autorelease];
}


- (void)complementSequence:sender
{
  int i, count;
  id basePtr;

  count = [theSeq count];
  //fprintf(stderr, "complementing sequence:");
  for (i = 0; i < count; i++) {
    basePtr = [theSeq objectAtIndex:i];
    //putc([basePtr base],stderr);
    switch ([basePtr base]) {
      case 'A':[basePtr setBase:'T'];
        break;
      case 'T':[basePtr setBase:'A'];
        break;
      case 'G':[basePtr setBase:'C'];
        break;
      case 'C':[basePtr setBase:'G'];
        break;
    }
  }
  //putc('\n',stderr);
}

- (Sequence*)unpaddedSequence
{	
  Sequence  *newSeq;
  int       i, count;

  count = [theSeq count];
  newSeq = [Sequence newSequence];
  for (i=0; i<count; i++) {
    if(([[theSeq objectAtIndex:i] base] != '.') && ([[theSeq objectAtIndex:i] base] != '*'))
      [newSeq addBase:[theSeq objectAtIndex:i]];
  }
  return newSeq;
}

- (void)dealloc
{
  if (theSeq != NULL)
    [theSeq release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  //[super encodeWithCoder:coder];
  [coder encodeBycopyObject:theSeq];
}

/*****
* NSCopying protocol
*****/

- (id)copyWithZone:(NSZone *)zone
{
  Sequence     *dupSelf;
  Base         *tempBase;
  unsigned     i;

  dupSelf = [[[self class] allocWithZone:zone] init];

  dupSelf->BaseClass = BaseClass;

  for(i=0; i<[theSeq count]; i++) {
    tempBase = [[theSeq objectAtIndex:i] copyWithZone:zone];
    [dupSelf->theSeq addObject:[tempBase autorelease]];
  }
  dupSelf->label = [label retain];
	dupSelf->offset = offset;
	dupSelf->backForwards = backForwards;
  return dupSelf;
}

/*****
* Labeling the sequence
******/
- (void)setLabel:(NSString*)aString
{
  if(label != nil) [label release];
  label = [aString retain];
}

- (NSString*)label
{
  return label;
}

- (void)sortByLocation
{
    [theSeq sortUsingSelector:@selector(comparePosition:)];
}    

/****
*
* Sequence alignment routines
*
****/
/*new alignment routine, smv*/
-(char) convertItoC:(int) value :(char) nt1 :(char) nt2
{
	char ch;
	
	ch = 'N';
	switch (value) {
		case 0:
			ch = nt1;
			break;
		case 1:
			ch = nt2;
			break;
		case 2:
			ch = 'N';
			break;
		case 3:
			ch = 'X';
			break;
	}
	return ch;
}

-(int) convertCtoI:(char) value :(char) nt1 :(char) nt2 
{
	int val;
	
	val = 2;
	switch(value) {
		case 'X':
			val = 3;
			break;
		case 'N':
			val = 2;
			break;
		default:
			if (value == nt1)
				val = 0;
			else if (value == nt2)
				val = 1;
				break;
	}
	return val;
}

//Overlap alignment
-(int) alignOverlapRNA:(char *)seq2 :(int)len2 :(char) nt1 :(char) nt2 :(char *)align1 :(char *)align2 :(int *)lenAlign
{
	//overlap alignment, global with overhanging ends
	//sequence 1 must be the original RNA sequence
	//sequence 2 must be the derived sequence from the trace data
	//assumes sequence starts at index 1!
	//may pass in score matrix and gap parameters at later date
	int		s[4][4] = {
		{ 2,-1,-1, 1},  /*nt1*/
		{-1, 2,-1, 1},  /*nt2*/
		{-1,-1, 2,-1},  /*N*/
		{ 1, 1,-1, 2}   /*X*/
	};
	int		i, j, k;
	int		**f, **ptr;
	int		gap1, gap2, score, extend;
	int		fmatch, finsert, fdelete;
	int		val, startx, starty, starti;
	int		len1;
	char	*seq1;
	BOOL	debugmode;
	
	//allocate memory
	len1 = [self seqLength];
	f = malloc((len1+1)*sizeof(int *));
	ptr = malloc((len1+1)*sizeof(int *));
	for (i = 0; i <= len1; i++) {
		f[i] = malloc((len2+1)*sizeof(int));
		ptr[i] = malloc((len2+1)*sizeof(int));
	}
	seq1 = (char *)calloc(len1+2, sizeof(char));
	[self maskSequence:seq1 NT1:nt1 NT2:nt2];	

	//initialize
	debugmode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"];
	gap1 = 50; gap2 = 2; extend = 2;
	if (debugmode) NSLog(@"length1=%d, length2=%d\n",len1,len2);
	for (i = 0; i <= len1; i++) {
		f[i][0] = 0.0;  //overlap and s-m
		ptr[i][0] = 1; //up
	}
	for (j = 0; j <= len2; j++) {
		f[0][j] = 0.0; //overlap and s-m
		ptr[0][j] = -1; //left
	}
	ptr[0][0] = 0; //diagonal
	f[0][0] = 0;
	//score & align
	val = startx = starty = 0;
	for (i = 1; i <= len1; i++) {
		for (j = 1; j <= len2; j++) {
			score = s[[self convertCtoI:seq1[i] :nt1 :nt2]][[self convertCtoI:seq2[j] :nt1 :nt2]];
			fmatch = f[i-1][j-1] + score;
			if (ptr[i-1][j] == 1)
				finsert = f[i-1][j] - extend;
			else
				finsert = f[i-1][j] - gap2;  //really delete
			fdelete = f[i][j-1] - gap1;  //really insert
			f[i][j] = fmatch;
			ptr[i][j] = 0;
			if (f[i][j] < finsert) { //up
				f[i][j] = finsert;
				ptr[i][j] = 1;	//x,-
			}
			if (f[i][j] < fdelete) { //left
				f[i][j] = fdelete;
				ptr[i][j] = -1;	//-,y
			}
			//keep track of Fmax
			if (j == len2) { //overlap
				if (f[i][j] > val) {
					val = f[i][j];
					startx = i;
					starty = j;
				}
			}
			else if (i == len1) {
				if (f[i][j] > val) {
					val = f[i][j];
					startx = i;
					starty = j;
				}
			}
		}		
	}
	//backtrace
	i = startx; //s-m and overlap
	j = starty;
	k = 0;
	while ((i > 0) && (j > 0)) {
		switch (ptr[i][j]) {
			case 0: //diagonal
				align1[k] = seq1[i];
				align2[k++] = seq2[j];
				i--;
				j--;
				break;
			case 1: //up
				align1[k] = seq1[i];
				align2[k++] = '_';
				i--;
				break;
			case -1: //left
				align1[k] = '_';
				align2[k++] = seq2[j];
				j--;
				break;
		} //switch
	} //while
	if (debugmode) NSLog(@" x1 = %d, y1 = %d, x2 = %d, y2 = %d\n",i,j,startx,starty);
	
	//need to reverse string and identify gaps, then finit
	//done by calling routine
	starti = i;
	*lenAlign = k;
	
	//free memory
	for (i = 0; i <= len1; i++) {
		free(f[i]);
		free(ptr[i]);
	}	
	free(f);
	free(ptr);
	return starti;
}

/*********
*  Search for oligo (identical match)
*********/

- (NSMutableArray*)locationsOfOligo:(Sequence*)oligo
{
  //searches all contigs (both directions) for oligo
  int                   index, oligoIndex, start, end, seqlen, oligolen;
  const char            *seqString, *oligoString;
  NSMutableDictionary   *oligoLocation;
  NSMutableArray        *allLocations = [NSMutableArray array];

  oligo = [oligo unpaddedSequence];
  oligoString = [[[oligo seqString] uppercaseString] cString];
  oligolen = strlen(oligoString);

  seqString = [[[self seqString] uppercaseString] cString];
  seqlen = strlen(seqString);
  
  index=oligoIndex=0;
  start=end=-1;
  while(index<seqlen) {
    if(seqString[index]!='.' && seqString[index]!='*') {
      if(seqString[index] == oligoString[oligoIndex]) {
        if(start<0) start=end=index;
        else end=index;
        //printf("oligo match s[%d]=%c  o[%d]=%c (%d,%d)       \r", index, seqString[index],
        //       oligoIndex, oligoString[oligoIndex], start, end);
        //fflush(stdout);
        oligoIndex++;
        if(oligoIndex >= oligolen) {
          //FOUND THE OLIGO
          oligoLocation = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            oligo, @"oligo",
            [NSNumber numberWithInt:start], @"start",
            [NSNumber numberWithInt:end], @"end",
            nil];
          [allLocations addObject:oligoLocation];

          index = start;
          //in case the oligo overlaps with self, step back to one base after the oligo was found
          //the index++ below will move past so it won't get stuck in an infinite loop
          oligoIndex = 0;
          start=end = -1;
        }
      }
      else {
        if(start>0) index = start;
        //in case the oligo overlaps with self, step back to one base after the oligo was found
        oligoIndex = 0;
        start=end = -1;
      }
    }
    index++;
  }
  
  //printf("%s\n", [[allLocations description] cString]);
  return allLocations;
}

@end
