/*
 *  FindPeak.h
 *  rnafitnew
 *
 *  Created by Suzy Vasa on 12/22/05.
 *  Copyright 2005 Suzy Vasa 
 
 All rights reserved.
 
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
 NIH Center for AIDS Research
 
 
 ******************************************************************/

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

//#define DEBUGDUMPDATA
//#define USE_SIM    broken do not enable
#ifdef USE_SIM
#include "Sim200.h"
#endif
/* --------------------------------------------------------------------------------------------- */

#define kNbSpectraPeaks 25000
#define kNoPeak 0
#define kPeak   1
#define kInterpolatedPeak   3
// for now, keep same value for user added peak.
#define kUserAddedPeak   3

static char remark[]="REMARK";
int verbose;

typedef struct  PEAKPOS_struct                        PEAKPOS;
struct PEAKPOS_struct
  {
	int pos;		// refer to original data
	float val;		// value of peak summit (from input data)
	float width;	// Gaussian
	float area;		// Gaussian
	float maxwidth;	// used to cap the peak width so as not to exceed first crude approximaiton
	float tmpwidth;	// Gaussian
	float tmparea;	// Gaussian
	float done;		// flag recording whether peak fitting has been optimized
	float score;	// Gaussian fit quality
	char nt;		// Sequence
	int seqnum;		// Sequence number (as loaded sequence may not start at 1)
	int kind;		// Observed, interpolated, etc...
  };

typedef struct  MISSINGPEAK_struct                        MISSINGPEAK;
struct MISSINGPEAK_struct
  {
	int from;
	int to;
  };

typedef struct  SPECTRA_struct                        SPECTRA;
struct SPECTRA_struct
  {
	float		*data;				// original curve
	float		*fitted;			// computed curve
	float		*score;				// fitted %deviation from original curve
	int			*maxidx;			// peak, no peak, etc..
//	PEAKPOS		peakPos[3000];		// list position and characteristics of peaks recognized
  PEAKPOS *peakPos;
	int			peakLink[3000];		// link toward other data curve
	MISSINGPEAK missingpeak[3000];	// used by CheckPeakCount() which is currently not doing anything useful.
	int			mpcnt;				// number of missing peaks
//	float		maxval;				
	int			peakcnt;			// number of peaks detected
	int			firstidx;			// first "valid" data point
	int			lastidx;			// last "valid" data point
  };
	
int SetSpectraBoundaries(SPECTRA *nmia,SPECTRA *background,SPECTRA *ddnt,SPECTRA *ddnt2);
void FreeSpectra(SPECTRA *sp);
void IdentifyNT(SPECTRA *ddnt,float median,float s,char nt,char complement);
void AttributeNT(SPECTRA *sp1,SPECTRA *sp2, SPECTRA *ddnt,SPECTRA *ddnt2);
void GetSeq(SPECTRA *sp1,char *seq);
//void MaskSeq(char *src, char *dst, int seqLen, char nt1,char nt2);
//	#ifdef USE_SIM
//void DoAlign(char *seq, int seqlen, char *ref,int reflen);
//	#endif
void		HandleMissingPeakLink(SPECTRA *sp1,SPECTRA *sp2);
int AnalyzeSpectra(SPECTRA *sp,int plotmissing);
void GatherPeaksPosition(SPECTRA *s);
void IdentifyBestPeaks(SPECTRA *s,int fromidx,int toidx,float median);
float ListPeakPos(SPECTRA *sp,int fromidx,int toidx);
void ResetPeakLink(SPECTRA *sp);
int PeakLink(SPECTRA *nmia,SPECTRA *bg,int desireddelta);
int Align(char *seq1,int len1, char *seq2, int len2);
void SmoothSpectra(SPECTRA *sp,int first, int last,int rounds);
void UnsmoothSpectra(SPECTRA *sp,int first, int last);
void RefinePeakPosition(SPECTRA *sp);

//add delete peaks
void DeletePeak(SPECTRA *sp, int peak, char *kind);
int RefineAddedPeaksPosition(SPECTRA *sp);
void AddPeak(SPECTRA *sp, int peakpos, char *kind);
void AutoAddDeletePeaks(SPECTRA *sp1,SPECTRA *sp2);

//integrate
void	FindLongestSyncStretch(SPECTRA *sp,int *firstpeak,int *lastpeak,int *firstbgpeak,int *lastbgpeak);
void SetSeqIntoNMIA(SPECTRA *nmia,char *seq,int alignstart,int seqlen,int seqstart);
//void NewPeakFit(int prev,int which, int next,SPECTRA *sp,float minw,float maxw,float stepw);
void NewPeakFit(int prev,int which, int next,SPECTRA *sp,float minw,float maxw,float stepw, int newpos, float newval);
float GetPeakWidthMedian(int firstpeak,int lastpeak,SPECTRA *sp);
void NewGenerateFittedSpectra(SPECTRA *sp,int fromPeak,int toPeak,int offset);
void MakeGaussianPeak(float *data,float width,float area,int center,int xmin,int xmax);

void ResetFit(SPECTRA *sp,int max);
void OptimizeFit(SPECTRA *sp, int firstpeak,int lastpeak);
float GrowUnderPredictedPeaks(SPECTRA *sp,int fromPeak,int toPeak,float incrmultfactor);
void NewGlobalOptimize2(SPECTRA *sp,int fromPeak,int toPeak,float minw,float growthfactor);




	





/* ------------------------------------------------------------------------------------------------ */
