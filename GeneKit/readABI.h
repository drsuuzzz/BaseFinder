/* "$Id: readABI.h,v 1.2 2006/08/04 20:31:58 svasa Exp $" */
/* Many thanks to LaDenia Hillier and Clark Tibbetts for deciphering the ABI file format */

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

/* ReadABI.h  
	 This is the unit meant for reading (and someday writing?) ABI format
	 files.  Based on version ** of the ABI software.
	 Many thanks to LaDenia Hillier for deciphering the ABI file format
*/
void readABISeq(char *fname, id pointsLists, id rawLists, id baseList);
