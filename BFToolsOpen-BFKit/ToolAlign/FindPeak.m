/*
 *  FindPeak.m
 *  
 *
 *  Created by Suzy Vasa on 12/22/05.
 *  Copyright 2005 Giddings Lab, UNC-Chapel Hill. All rights reserved.
 *
 *
 *  Integration of RNAfit created by Nicolas Guex.
 
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
 
#include "FindPeak.h"
/* ------------------------------------------------------------------------------------------------ */
/*static void AllocSpectra(SPECTRA *sp,int max)
{
	int i;
	sp->data = malloc(max*sizeof(float));
	sp->maxidx = malloc(max*sizeof(float));
	sp->fitted = malloc(max*sizeof(float));
	sp->score = malloc(max*sizeof(float));
	for (i = 0; i< max; i++)
	{	
		sp->data[i] = 0.0;
		sp->fitted[i] = 0.0;
		sp->score[i] = 0.0;
		sp->maxidx[i] = kNoPeak;
	}
	sp->mpcnt = 0;
//	sp->maxval = 0.0;
	sp->peakcnt = 0;
	sp->firstidx = 0;
	sp->lastidx = 0;
	
}*/ /* AllocSpectra */
/* ------------------------------------------------------------------------------------------------ */

void ResetFit(SPECTRA *sp,int max)
{
	int i;
	
		// reset fitted curve
		for (i= 0; i < max; i++)
			sp->fitted[i] = 0.0;

} /* ResetFit */
/* ------------------------------------------------------------------------------------------------ */
void FreeSpectra(SPECTRA *sp)
{
	if (sp->data)
	{
		free(sp->data);
		sp->data = NULL;
	}
	if (sp->fitted)
	{
		free(sp->fitted);
		sp->fitted = NULL;
	}
	if (sp->score)
	{
		free(sp->score);
		sp->score = NULL;
	}
	if (sp->maxidx)
	{
		free(sp->maxidx);
		sp->maxidx = NULL;
	}
  if (sp->peakPos) {
    free(sp->peakPos);
    sp->peakPos = NULL;
  }
	
} /* FreeSpectra */

/* ------------------------------------------------------------------------------------------------ */
void SmoothSpectra(SPECTRA *sp,int first, int last,int rounds)
{
	int i;
	
		for (i= first+1; i < last-1; i++)
			sp->score[i] = sp->data[i]; // save original

		for (i= first+1; i < last-1; i++)
			sp->fitted[i] = 0.3*(sp->data[i-1]+sp->data[i]+sp->data[i+1]);
		if (rounds == 2) // smooth it monce more
		{
			for (i= first+1; i < last-1; i++)
				sp->data[i] = 0.3*(sp->fitted[i-1]+sp->fitted[i]+sp->fitted[i+1]);
		}
		else // transfer smoothing results into data
		{
			for (i= first+1; i < last-1; i++)
				sp->data[i] = sp->fitted[i];
		}
} /* SmoothSpectra */
/* ------------------------------------------------------------------------------------------------ */
void UnsmoothSpectra(SPECTRA *sp,int first, int last)
{
	int i;
	
		for (i= first+1; i < last-1; i++)
			sp->data[i] = sp->score[i];
		
} /* UnsmoothSpectra */
/* ------------------------------------------------------------------------------------------------ */
/*static void PlotFitVsInput(char *fn,SPECTRA *nmia, SPECTRA *bg)
{
int i; 
FILE *of;

		of = fopen(fn,"w");
		if (!of)
		{
			printf("cannot open file '%s'\n",fn);
			return;
		}
//new		fprintf(of,"index\treagent_data\treagent_fit\tbackground_data\tbackground_fit\n");
		fprintf(of,"index\treagent_data\treagent_fit\tpercentdev\tbackground_data\tbackground_fit\n");
		for (i=nmia->firstidx; i<=nmia->lastidx; i++)
		{
// new		fprintf(of,"%6d\t%9.1f\t%9.1f\t%9.1f\t%9.1f\n",i,nmia->data[i],nmia->fitted[i],bg->data[i],bg->fitted[i]);		
			fprintf(of,"%6d\t%9.1f\t%9.1f\t%9.1f\t%9.1f\t%9.1f\n",i,nmia->data[i],nmia->fitted[i],nmia->score[i],bg->data[i],bg->fitted[i]);		
		}
		fclose(of);
		
}*/ /* PlotFitVsInput */

/* ------------------------------------------------------------------------------------------------ */
/*static void PlotMissingPeak(char *fn,SPECTRA *sp, int min, int max,int width,float scale,char * hdr)
{
int x,i; 
float pmax;
int cnt;
int nextcurve;
int prevx;
FILE *of;

		of = fopen(fn,"w");
		if (!of)
		{
			printf("cannot open file '%s'\n",fn);
			return;
		}
		fprintf(of,"%s\n",hdr);

		nextcurve = width+10;
		pmax = 0.0;
		for(x=min;x<max;x++)
		{
			if (sp->data[x] > pmax) pmax = sp->data[x];
		}

		prevx = 0;
		for(x=min;x<max;x++)
		{
			fprintf(of,"%5d ",x);
			cnt = (int)(scale*sp->data[x]*width/pmax);
			if (cnt > width)
				cnt = width;
			for (i=0;i<cnt;i++) { fprintf(of,"*"); }
			if (sp->maxidx[x] == kPeak)
			{
				fprintf(of," <-- %2d   ",(x-prevx));
				prevx = x;
			}
	//		if (sp->maxidx[x] == 2)
	//		{
	//			printf(" <---! %2d   ",(x-prevx));
	//			prevx = x;
	//		}
			if (sp->maxidx[x] == kInterpolatedPeak)
			{
				fprintf(of," <-! %2d ++",(x-prevx));
				prevx = x;
			}
			if (sp->maxidx[x] == kNoPeak)
			{
				fprintf(of,"          ");
			}


			for (i=cnt;i<nextcurve;i++) { fprintf(of," "); }
			fprintf(of,"|");
			fprintf(of,"\n");
		}
		fclose(of);
		
}*/ /* PlotMissingPeak */
/* ------------------------------------------------------------------------------------------------ */

void AddPeak(SPECTRA *sp, int peakpos, char *kind)
{

		printf("%s:ADDING %s PEAK at position %d\n",remark,kind,peakpos);
		sp->maxidx[peakpos] = kUserAddedPeak;
		
} /* AddPeak */

/* ------------------------------------------------------------------------------------------------ */

void DeletePeak(SPECTRA *sp, int peak, char *kind)
{

		int i;
		for (i = 0; i< sp->peakcnt; i++)
		{
			if (sp->peakPos[i].pos == peak)
			{
				printf("%s:DELETING %s PEAK %d (%d)\n",remark,kind,i,sp->peakPos[i].pos);
				sp->maxidx[sp->peakPos[i].pos] = kNoPeak;
				break;
			}
		}
		if (i == sp->peakcnt)
		{
			printf ("%s:CANNOT DELETE PEAK %d (no such peak)\n",remark,peak);
		}
				
} /* DeletePeak */

/* ------------------------------------------------------------------------------------------------ */
/* if 3 successive values are s times above the median, then we do have a potential peak. */
/* if their average is <= 20x the median, then accept it as a valid peak, else assume noise.*/
void IdentifyNT(SPECTRA *ddnt,float median,float s,char nt,char complement)
{
	int i;
	int pos;
	float sigma;
	
	for (i = 0; i< ddnt->peakcnt; i++)
	{
		pos = ddnt->peakPos[i].pos;
		if ((ddnt->peakPos[i].kind == kUserAddedPeak) || ((ddnt->data[pos] >= (s*median)) && (ddnt->data[pos-1] >= (s*median)) && (ddnt->data[pos+1] >= (s*median))))
		{
			ddnt->peakPos[i].nt = nt;
			sigma = (ddnt->data[pos]+ddnt->data[pos-1]+ddnt->data[pos+1])/(3.0*median); 
			if (verbose > 0)
				printf("%s:%c identified at peak %d (pos %d); sigma = %5.1f\n",remark,nt,i,pos,sigma);
			if (sigma > 20.0)
				printf("%s:unusually high dd%c peak %d (pos %d); sigma = %5.1f\n",remark,complement,i,pos,sigma);
		}
	}
	
} /* IdentifyNT */

/* ------------------------------------------------------------------------------------------------ */

void AttributeNT(SPECTRA *sp1,SPECTRA *sp2, SPECTRA *ddnt,SPECTRA *ddnt2)
{
	int i;
	int pos1,pos2;

	for (i = 0; i< sp1->peakcnt; i++)
	{
		if (sp1->peakLink[i] != -1)
		{	
			int j;
			int printed = 0;
			int printed2 = 0;
			char nt1 = 'N';
			char nt2 = 'N';
			
			pos1 = sp1->peakPos[i].pos;
			pos2 = sp2->peakPos[sp1->peakLink[i]].pos;
			for (j = 0; j< ddnt->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt->peakPos[j].pos;
					delta2 = pos2-ddnt->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						nt1 = ddnt->peakPos[j].nt;
						printed = 1;
						break;
					}
			}
			for (j = 0; j< ddnt2->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt2->peakPos[j].pos;
					delta2 = pos2-ddnt2->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						nt2 = ddnt2->peakPos[j].nt;
						printed2 = 1;
						break;
					}
			}
			if (printed || printed2)
			{
				if ((nt1 == 'N') && (nt2 == 'N'))
					sp1->peakPos[i].nt = sp2->peakPos[sp1->peakLink[i]].nt = 'N';
				else if ((nt1 != 'N') && (nt2 == 'N'))
					sp1->peakPos[i].nt = sp2->peakPos[sp1->peakLink[i]].nt = nt1;
				else if ((nt2 != 'N') && (nt1 == 'N'))
					sp1->peakPos[i].nt = sp2->peakPos[sp1->peakLink[i]].nt = nt2;
				else
				{
				/* conflict */
					sp1->peakPos[i].nt = sp2->peakPos[sp1->peakLink[i]].nt = 'X';
				}
			}
			else
			{
				sp1->peakPos[i].nt = sp2->peakPos[sp1->peakLink[i]].nt = 'N';
			}
		}
	}
}
/* ------------------------------------------------------------------------------------------------ */

void GetSeq(SPECTRA *sp1,char *seq)
{
	int i,j;
	
//	seq[0]='0';
	j = /*1*/0;
	for (i = 0; i< sp1->peakcnt; i++)
	{
		seq[j++] = sp1->peakPos[i].nt;
	}
	
} /* GetSeq */

/* ------------------------------------------------------------------------------------------------ */
//void MaskSeq(char *src, char *dst, int seqLen, char nt1,char nt2)
//{
//	int i, j;
	
//	dst[0] = '0';
//	j = 1;
//	for (i = 0; i< seqLen; i++)
//	{
//		if ((src[i] == nt1) || (src[i] == nt2))
//			dst[/*i*/j] = src[i];
//		else
//			dst[/*i*/j] = 'N';
//		j++;
//	}
	
//} /* MaskSeq */

/* ------------------------------------------------------------------------------------------------ */

/*static void FindAlignedBlocks(char *seq, int seqlen, char *ref,int reflen,int seql,int seqr,int refl,int refr)
{
	int i,j;
	int besti,bestj;
	int bestmatch,match;
	int starti,startj;

	bestmatch = 0;
	for (starti = seql; starti < seqr; starti++)
	{

		if (seq[starti] == 'N')
			continue;
		for (startj = refl; startj < refr; startj++)
		{
			if (ref[startj] == 'N')
				continue;
			i = starti; j= startj; match = 0;
			while (seq[i++] == ref[j++])  {match++; if ((i==seqlen) || (j==reflen)) break; }
			if (match > bestmatch) { besti = starti; bestj = startj; bestmatch = match; }
		}
	}
	if (bestmatch >= 4)
	{
		printf("%s:Longest fragment matching nt %d with reference nt %d len = %d\n",remark,besti,bestj,bestmatch);
		FindAlignedBlocks(seq, seqlen, ref, reflen, seql,            besti, refl,            bestj);
		FindAlignedBlocks(seq, seqlen, ref, reflen, besti+bestmatch, seqr,  bestj+bestmatch, refr);
	}

}*/ /* FindAlignedBlocks */
/* ------------------------------------------------------------------------------------------------ */
/*#ifdef USE_SIM
void DoAlign(char *seq, int seqlen, char *ref,int reflen)
{
 SimRslt *rslt;
 int i,j;
 
               rslt = calloc(5L,sizeof(SimRslt));

				for (i = 0; i< seqlen;i++)
				printf("%c",seq[i]);
				printf("\n");

				for (i = 0; i< reflen;i++)
				printf("%c",ref[i]);
				printf("\n");

                if (rslt)
				{
					if (SimGlue(seq,ref,seqlen,reflen, rslt) == 0)
					{                             
									for (j = 0; j<rslt[0].nbBlocks; j++)
									{
											printf("block %2d: from %4d to %4d\n",j,rslt[0].block[j].fromSeq1, rslt[0].block[j].toSeq1);
											printf("block      from %4d to %4d\n",rslt[0].block[j].fromSeq2, rslt[0].block[j].toSeq2);

											for (i = rslt[0].block[j].fromSeq1; i<= rslt[0].block[j].toSeq1;i++)
											printf("%c",seq[i]);
											printf("\n");

											for (i = rslt[0].block[j].fromSeq2; i<= rslt[0].block[j].toSeq2;i++)
											printf("%c",ref[i]);
											printf("\n");
									}                               

									for (j = 0; j<rslt[1].nbBlocks; j++)
									{
											printf("block %2d: from %4d to %4d\n",j,rslt[1].block[j].fromSeq1, rslt[1].block[j].toSeq1);
											printf("block      from %4d to %4d\n",rslt[1].block[j].fromSeq2, rslt[1].block[j].toSeq2);
											for (i = rslt[1].block[j].fromSeq1; i<= rslt[1].block[j].toSeq1;i++)
											printf("%c",seq[i]);
											printf("\n");

											for (i = rslt[1].block[j].fromSeq2; i<= rslt[1].block[j].toSeq2;i++)
											printf("%c",ref[i]);
											printf("\n");
									}                               
					}
					free(rslt);
				}
				else
					printf("error - no mem for alignment\n");
					
}*/ /* DoAlign */
//#endif
/* ------------------------------------------------------------------------------------------------ */
static void	ResetDoneFlag(SPECTRA *sp,int fromPeak,int toPeak)
{
	int i;
	PEAKPOS *p;

	p = sp->peakPos;
	for (i = fromPeak; i<= toPeak; i++)
	{
		p[i].done = 0;
	}

} /* ResetDoneFlag */
/* ------------------------------------------------------------------------------------------------ */
void RefinePeakPosition(SPECTRA *sp)
{
	int i;
	int dprev;
	int dnext;
	float f,minf;
	int shift;
	int shiftpeak = 0;
	int shiftdir = 0;
	
	ResetDoneFlag(sp, 1, sp->peakcnt-1);	
	
	do {
		minf = 1.0;
		for (i = 1; i< (sp->peakcnt-1); i++)
		{
			if (sp->peakPos[i].done == 0)
			{
				dprev = sp->peakPos[i].pos - sp->peakPos[i-1].pos; 
				dnext = sp->peakPos[i+1].pos - sp->peakPos[i].pos;
				if ((dnext == 0) || (dprev == 0))
					continue;
				if (dnext>dprev) 
				{
					f = (float)dprev/dnext;
					shift = 1;
				}
				else
				{
					f = (float)dnext/dprev;
					shift = -1;
				}

				if (f < minf)
				{
					/* test if moving peak would actually improve spread */
					float fnew;
					int dprevnew = (sp->peakPos[i].pos+shift) - sp->peakPos[i-1].pos; 
					int dnextnew = sp->peakPos[i+1].pos - (sp->peakPos[i].pos+shift);
					if ((dnextnew == 0) || (dprevnew == 0))
						continue;
					if (dprevnew>dnextnew) 
						fnew = (float)dprev/dnext;
					else
						fnew = (float)dnext/dprev;
					if (fnew > f)
					{
						minf = f;
						shiftdir = shift;
						shiftpeak = i;
					}
				}
			}
		}
	
		if (minf <= 0.75)
		{
			if (verbose >= 1)
				printf("%s:Shifting peak %d at pos %d by %d (ratio = %f)\n",remark,shiftpeak,sp->peakPos[shiftpeak].pos,shiftdir,minf);
			sp->maxidx[sp->peakPos[shiftpeak].pos+shiftdir] = sp->maxidx[sp->peakPos[shiftpeak].pos];
			sp->maxidx[sp->peakPos[shiftpeak].pos] = kNoPeak;
			sp->peakPos[shiftpeak].pos += shiftdir;
		}
	} while(minf <= 0.75);
	
} /* RefinePeakPosition */
/* ------------------------------------------------------------------------------------------------ */

void		AutoAddDeletePeaks(SPECTRA *sp1,SPECTRA *sp2)
{
int i;

	for (i = 0; i< (sp1->peakcnt); i++)
	{
		/* identify rx peaks with missing connection to background */
		if (sp1->peakLink[i] == -1)
		{
					if (verbose > 1)
						printf("%s:Should add background peak at pos %d\n",remark,sp1->peakPos[i].pos);
					AddPeak(sp2,sp1->peakPos[i].pos,"bg");			
		}
	}

	for (i = 0; i< (sp2->peakcnt); i++)
	{
		/* identify bg peaks with missing connection to rx */
		if (sp2->peakLink[i] == -1)
		{
					if (verbose > 1)
						printf("%s:Should delete background peak at pos %d\n",remark,sp2->peakPos[i].pos);
					DeletePeak(sp2,sp2->peakPos[i].pos,"bg");			
		}
	}


} /* AutoAddDeletePeaks */
/* ------------------------------------------------------------------------------------------------ */

void		HandleMissingPeakLink(SPECTRA *sp1,SPECTRA *sp2)
{
int i;

	for (i = 1; i< (sp1->peakcnt-1); i++)
	{
		/* identify peaks with missing connection to background */
		if ((sp1->peakLink[i] == -1) && (sp1->peakLink[i-1] != -1) && (sp1->peakLink[i+1] != -1))
		{
				if ((sp1->peakLink[i+1] - sp1->peakLink[i-1]) == 2) // -NMIA had exactly one peak
				{
					sp1->peakLink[i] = (sp1->peakLink[i-1])+1;
					sp2->peakLink[(sp1->peakLink[i-1])+1] = i;
					if (verbose > 0)
						printf("%s:Adding link from peak %dto %d\n",remark,i,(sp1->peakLink[i-1])+1);
				}
		}
	}

	for (i = 1; i< (sp1->peakcnt-2); i++)
	{
		/* identify 2 peaks in a row with missing connection to background */
		if ((sp1->peakLink[i] == -1) && (sp1->peakLink[i-1] != -1) && (sp1->peakLink[i+1] == -1) && (sp1->peakLink[i+2] != -1))
		{
				if ((sp1->peakLink[i+2] - sp1->peakLink[i-1]) == 3) // -NMIA had exactly two peaks
				{
					sp1->peakLink[i] = (sp1->peakLink[i-1])+1;
					sp2->peakLink[(sp1->peakLink[i-1])+1] = i;
					sp1->peakLink[i+1] = (sp1->peakLink[i])+1;
					sp2->peakLink[(sp1->peakLink[i])+1] = i+1;
					if (verbose > 0)
					{
						printf("%s:Adding link from peak %dto %d\n",remark,i,(sp1->peakLink[i-1])+1);
						printf("%s:   and link from peak %dto %d\n",remark,i+1,(sp1->peakLink[i])+1);
					}
				}
		}
	}

	for (i = 1; i< (sp1->peakcnt-3); i++)
	{
		/* identify 3 peaks in a row with missing connection to background */
		if ((sp1->peakLink[i] == -1) && (sp1->peakLink[i-1] != -1) && (sp1->peakLink[i+1] == -1) && (sp1->peakLink[i+2] == -1) && (sp1->peakLink[i+3] != -1))
		{
				if ((sp1->peakLink[i+3] - sp1->peakLink[i-1]) == 4) // -NMIA had exactly 3 peaks
				{
					sp1->peakLink[i] = (sp1->peakLink[i-1])+1;
					sp2->peakLink[(sp1->peakLink[i-1])+1] = i;
					sp1->peakLink[i+1] = (sp1->peakLink[i])+1;
					sp2->peakLink[(sp1->peakLink[i])+1] = i+1;
					sp1->peakLink[i+2] = (sp1->peakLink[i+1])+1;
					sp2->peakLink[(sp1->peakLink[i+1])+1] = i+2;
					if (verbose > 0)
					{
						printf("%s:Adding link from peak %dto %d\n",remark,i,(sp1->peakLink[i-1])+1);
						printf("%s:   and link from peak %dto %d\n",remark,i+1,(sp1->peakLink[i])+1);
						printf("%s:   and link from peak %dto %d\n",remark,i+2,(sp1->peakLink[i+1])+1);
					}
				}
		}
	}

	for (i = 1; i< (sp1->peakcnt-1); i++)
	{
		/* identify rx peaks with missing connection to background */
		if (sp1->peakLink[i] == -1)
		{
			if (verbose > 0)
				printf("%s:Should add background peak at pos %d\n",remark,sp1->peakPos[i].pos);			
		}
	}

/*1) check all +nmia peaks QC=1 but with no link
with previous and following peak with QC=1 linked to -nmia peaks
check if -nmia peak was present and only 1 peak.
check what would happen if the peak was removed wrt deltas.*/

} /* HandleMissingPeakLink */
/* ------------------------------------------------------------------------------------------------ */

/*static void PrintPeakLinkWithSeqTrace(SPECTRA *sp1,SPECTRA *sp2,SPECTRA *ddnt, SPECTRA *ddnt2,char *seq,int alignstart,int seqlen,int seqstart)
{
	int i;
	int offset;
	int pos1,pos2;
	int d1,d2;
	char c1,c2;
	FILE *outfile = NULL;

	if (outfn[0] != 0)
		outfile = fopen(outfn,"w");

	if (outfile)
	{
		fprintf(outfile,"peaknum,seq,ddNT,rxpos,rxQC,bgpos,bgQC\n");
	}
	
	printf("%s:# THE RELATIVE ddNT LANE OFFSET OF ONE PEAK COMPARED TO reagent LANE HAS *NOT* BEEN CORRECTED\n",remark);
	for (i = 0; i< sp1->peakcnt; i++)
	{
		pos2 = d2 = offset = 0;
		pos1 = sp1->peakPos[i].pos;
		d1 = pos1 - sp1->peakPos[i-1].pos;
		if (sp1->peakLink[i] != -1)
		{
			pos2 = sp2->peakPos[sp1->peakLink[i]].pos;
			offset = pos2 - sp1->peakPos[i].pos;
			if ((i!=0) && (sp1->peakLink[i-1] != -1))
				d2 = pos2 - sp2->peakPos[sp1->peakLink[i-1]].pos;
			else d2 = -1;
		}
		if (sp1->peakPos[i].nt != 'N') 
			c2 = sp1->peakPos[i].nt;
		else
			c2 = ' ';
	//	sp1->peakPos[i].seqnum = ((seqlen-i)-alignstart+seqstart);
	//	sp1->peakPos[i].nt = seq[i+alignstart];
		if (i+alignstart >= 0)
		{
			c1 = seq[i+alignstart];
			if (c1 == 0) c1 = '-';
		}
		else c1 = '-';
		printf("INFO  :%5d %c %c | peak %3d (%4d) QC=%1d delta=%2d  --> ",((seqlen-i)-alignstart+seqstart),c1,c2,i,pos1,sp1->maxidx[pos1],d1);
		if (outfile)
			fprintf(outfile,"%d,%c,%c,%d,%d",((seqlen-i)-alignstart+seqstart),c1,c2,pos1,sp1->maxidx[pos1]);
		if (sp1->peakLink[i] != -1)
		{	
			int j;
			int printed = 0;
			int printed2 = 0;
			char nt1 = 'N';
			char nt2 = 'N';
			printf("%3d (%4d) QC=%1d delta=%2d  | offset = %+2d",sp1->peakLink[i],pos2,sp2->maxidx[pos2],d2,offset);
			if (outfile)
				fprintf(outfile,",%d,%d\n",pos2,sp2->maxidx[pos2]);
			
			for (j = 0; j< ddnt->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt->peakPos[j].pos;
					delta2 = pos2-ddnt->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						printf("    %c at pos %4d",ddnt->peakPos[j].nt,ddnt->peakPos[j].pos);
						nt1 = ddnt->peakPos[j].nt;
						printed = 1;
						break;
					}
			}
			if (printed == 0)
				printf("                 ");
			for (j = 0; j< ddnt2->peakcnt; j++)
			{
					int delta1,delta2;
					delta1 = pos1-ddnt2->peakPos[j].pos;
					delta2 = pos2-ddnt2->peakPos[j].pos;
					if (delta1 < 0 ) delta1 = -delta1;
					if (delta2 < 0 ) delta2 = -delta2;
					if ((delta1 <= 2) || (delta2 <= 2))
					{
						printf("    %c at pos %4d",ddnt2->peakPos[j].nt,ddnt2->peakPos[j].pos);
						nt2 = ddnt2->peakPos[j].nt;
						printed2 = 1;
						break;
					}
			}
			if (printed2 == 0)
				printf("                 ");
			if (printed || printed2)
			{
				if ((nt1 != 'N') && (nt2 == 'N'))
					printf ("  %c",nt1);
				else if ((nt2 != 'N') && (nt1 == 'N'))
					printf ("  %c",nt2);
				//else
				//	printf("  N");
			}
		}
		else
		{
			if (outfile)
				fprintf(outfile,",,\n");
		}
		printf("\n");

		if (sp1->peakLink[i] == -1)
		{
	//		PlotMissingPeak(sp2, sp2->peakPos[sp1->peakLink[i-1]].pos-15, sp2->peakPos[sp1->peakLink[i-1]].pos + 35,80);
		}
		
	}
	if (outfile)
		fclose(outfile);
		
}*/ /* PrintPeakLinkWithSeqTrace */

/* ------------------------------------------------------------------------------------------------ */

void SetSeqIntoNMIA(SPECTRA *nmia,char *seq,int alignstart,int seqlen,int seqstart)
{
	int i;
//	int num;
	alignstart++; // because The corresponding sequencing lane is always 1 nucleotide longer than the SHAPE lanes. 
				// This means that the sequencing lane should be shifted one peak to the left 
				// (toward smaller index numbers) to exactly correspond with the SHAPE.
				// hence, for a given NMIA peak, we go fetch the sequence of the ddNT aligned with the next NMIA peak.
	for (i = 0; i< nmia->peakcnt; i++)
	{
		nmia->peakPos[i].seqnum = (seqlen-i)-alignstart+seqstart;
		nmia->peakPos[i].nt = seq[i+alignstart];
	}
} /* SetSeqIntoNMIA */

/* ------------------------------------------------------------------------------------------------ */

void ResetPeakLink(SPECTRA *sp)
{
	int i;
	for (i = 0; i< sp->peakcnt; i++)
	{
		sp->peakLink[i] = -1;
	}
} /* ResetPeakLink */

/* ------------------------------------------------------------------------------------------------ */

int PeakLink(SPECTRA *nmia,SPECTRA *bg,int desireddelta)
{
	int i,max,j;
	int delta;
	int cnt;
	int max2;
	
	max = nmia->peakcnt;
	max2 = bg->peakcnt;
//	if (bg->peakcnt < nmia->peakcnt)
//		max = bg->peakcnt;

	cnt = 0;
	for (i = 0; i< max; i++)
	{
		if (nmia->peakLink[i] == -1)
		{
			for (j = 0; j< max2; j++)
			{
				if (bg->peakLink[j] == -1)
				{
					delta = nmia->peakPos[i].pos-bg->peakPos[j].pos;
					if (delta == desireddelta)
					{
						bg->peakLink[j] = i;
						nmia->peakLink[i] = j;
						cnt++;
					}
				}
			}
		}
	}
	return(cnt);

} /* PeakLink */
/* ------------------------------------------------------------------------------------------------ */
void GatherPeaksPosition(SPECTRA *s)
{
	int pc;
	int i;
	
	pc = 0;
	for (i = s->firstidx; i< s->lastidx; i++)
	{
			if (s->maxidx[i] != kNoPeak)
			{
				/* prepare array for +NMIA lane */
				s->peakPos[pc].pos = i;
				s->peakPos[pc].width = 2.8;
				s->peakPos[pc].area = 0.0;
				s->peakPos[pc].score = 0.0;
				s->peakPos[pc].val = s->data[i];
				s->peakPos[pc].nt = 'N';
				s->peakPos[pc].seqnum = 0;
				s->peakPos[pc].kind = s->maxidx[i];
				pc++;
			}
	}
	s->peakcnt = pc;
	
} /* GatherPeaksPosition */
/* ------------------------------------------------------------------------------------------------ */

/*static void PrintIntegratedPeaks(SPECTRA *nmia,SPECTRA *bg,int firstnmia,int lastnmia,char *ifn)
{
	int i,j;
	float diff;
	FILE *of = NULL;
	
	if (ifn && (ifn[0]!=0))
		of = fopen(ifn,"w");
	if (!of)
	{
		printf("WARNING: cannot write to file '%s'\n",ifn);
	}
	printf("%s:# -- results of integration ---\n",remark);
	printf("%s:# THE RELATIVE ddNT LANE OFFSET OF ONE PEAK COMPARED TO reagent LANE HAS BEEN CORRECTED\n",remark);
	printf("RESULT:seqnum seq   RX.pos   RX.sigma   RX.area   RX.rms BG.pos BG.sigma BG.area BG.rms   (RX.area-BG.area)\n");
	if (of)
		fprintf(of,"seqnum\tseq\tRX.pos\tRX.sigma\tRX.area\tRX.rms\tBG.pos\tBG.sigma\tBG.area\tBG.rms\t(RX.area-BG.area)\n");
	for (i = lastnmia; i >= firstnmia; i--)
	{
		if (nmia->peakLink[i] != -1)
		{
			j = nmia->peakLink[i];
			diff = nmia->peakPos[i].area - bg->peakPos[j].area;
			printf("RESULT:%5d   %c   %4d %8.2f %10.1f %10.1f    %4d %6.2f %10.1f %10.1f %10.1f\n",
					nmia->peakPos[i].seqnum,nmia->peakPos[i].nt,
					nmia->peakPos[i].pos,nmia->peakPos[i].width,nmia->peakPos[i].area,nmia->peakPos[i].score,
					bg->peakPos[j].pos,bg->peakPos[j].width,bg->peakPos[j].area,bg->peakPos[j].score,
					diff);
			if (of) fprintf(of,"%5d\t%c\t%4d\t%8.2f\t%10.1f\t%10.1f\t%4d\t%6.2f\t%10.1f\t%10.1f\t%10.1f\n",
					nmia->peakPos[i].seqnum,nmia->peakPos[i].nt,
					nmia->peakPos[i].pos,nmia->peakPos[i].width,nmia->peakPos[i].area,nmia->peakPos[i].score,
					bg->peakPos[j].pos,bg->peakPos[j].width,bg->peakPos[j].area,bg->peakPos[j].score,
					diff);
		}
	}
	if (of) 
		fclose(of);
	
}*/ /* PrintIntegratedPeaks */
/* ------------------------------------------------------------------------------------------------ */

static void AddMissingPeaks(int start, int end,int median,int *smaxidx)
{
	int x,i;
	int prevx;
	int delta;
	int add;
	int pos;
	float offset;
		
		prevx = 0;
		for(x=start;x<end;x++)
		{
			if (smaxidx[x] == kPeak)
			{
				if (prevx > 0)
				{
					delta = x-prevx;
					add = (int)round((float)delta/median)-1;
					if (round > 0)
					{
						for (i = 0; i<round(add); i++)
						{
							offset = ((float)(i+1)*((float)delta/(add+1)));
							pos = prevx + round(offset);
							if (smaxidx[pos-1] > smaxidx[pos]) 
								pos--;
							smaxidx[pos] = kInterpolatedPeak;
						}
					}
				}
				prevx = x;
			}
		}
		
} /* AddMissingPeaks */
/* ------------------------------------------------------------------------------------------------ */

static void CheckPeakCount(int start, int end,int median,SPECTRA *sp)
{
	int x,i;
	int expectedlenfor10peaks;
	int cnt;
	#define kCheck 5
		
		expectedlenfor10peaks = kCheck*median;
		for(x=start;x<(end-expectedlenfor10peaks);x++)
		{
			cnt = 0;
			for (i = x; i<(x+expectedlenfor10peaks); i++)
			{
				if (sp->maxidx[i] != kNoPeak)
				{
					cnt++;
				}
			}
			if ((cnt != (kCheck-1)) && (cnt != kCheck) && (cnt != (kCheck+1)))
			{
				if ((sp->mpcnt > 0) && (x <= sp->missingpeak[sp->mpcnt-1].to))
				{
					sp->missingpeak[sp->mpcnt-1].to = (x+expectedlenfor10peaks-1);
				}
				else
				{
					sp->missingpeak[sp->mpcnt].from = x;
					sp->missingpeak[sp->mpcnt].to = (x+expectedlenfor10peaks-1);
					sp->mpcnt++;
				}
				//if (verbose > 0)
				//	printf("WARNING MISSING PEAK POSSIBLE IN REGION: [ %5d - %5d ] has %2d peaks\n",x,(x+expectedlenfor10peaks-1),cnt);
			}	
		}
		
} /* CheckPeakCount */
/* ------------------------------------------------------------------------------------------------ */

void MakeGaussianPeak(float *data,float width,float area,int center,int xmin,int xmax)
{
	int x;
	float A,B;
	float y;
	
		A = area / sqrt(2*3.14159265*width);
		for(x=xmin;x<xmax;x++)
		{
			B = (float)(x-center)/width;
			y = A * exp(-0.5*B*B);
			data[x] += y;
		}

} /* MakeGaussianPeak */
/* ------------------------------------------------------------------------------------------------ */
void NewGenerateFittedSpectra(SPECTRA *sp,int fromPeak,int toPeak,int offset)
{
	int i;
	PEAKPOS *p;
  int index;

	p = sp->peakPos;
	
		// reset fitted curve
    if (fromPeak == 0)
      index = 1;
    else
      index = fromPeak-1;
		for (i= (p[index].pos+offset); i < (p[toPeak].pos+offset); i++)
			sp->fitted[i] = 0.0;
			
		for (i = fromPeak; i<= toPeak; i++)
		{
			MakeGaussianPeak(sp->fitted,p[i].width,p[i].area,(p[i].pos+offset),(p[i-1].pos+offset),(p[i+1].pos+offset));
		}
		
} /* NewGenerateFittedSpectra */

/* ------------------------------------------------------------------------------------------------ */
static float NewGenerateFittedSpectraWithMinWidth(SPECTRA *sp,int fromPeak,int toPeak,int offset)
{
	int i;
	PEAKPOS *p;
	float w;

		p = sp->peakPos;
	
		// reset fitted curve
		for (i= (p[fromPeak-1].pos+offset); i < (p[toPeak].pos+offset); i++)
			sp->fitted[i] = 0.0;

		w=p[fromPeak+1].width;
		for (i = fromPeak+1; i<= toPeak-1; i++)
		{
			if (p[i].width<w) w=p[i].width;
		}
		for (i = fromPeak; i<= toPeak; i++)
		{
			MakeGaussianPeak(sp->fitted,w,p[i].area,(p[i].pos+offset),(p[i-1].pos+offset),(p[i+1].pos+offset));
		}
		return(w);
		
} /* NewGenerateFittedSpectraWithMinWidth */

/* ------------------------------------------------------------------------------------------------ */
static void	SaveGaussianParams(SPECTRA *sp,int fromPeak,int toPeak)
{
	int i;
	PEAKPOS *p;

	p = sp->peakPos;
	for (i = fromPeak; i<= toPeak; i++)
	{
		p[i].tmpwidth = p[i].width;
		p[i].tmparea = p[i].area;
	}

} /* SaveGaussianParams */
/* ------------------------------------------------------------------------------------------------ */
static void	SaveGaussianMaxWidth(SPECTRA *sp,int fromPeak,int toPeak)
{
	int i;
	PEAKPOS *p;

	p = sp->peakPos;
	for (i = fromPeak; i<= toPeak; i++)
	{
		p[i].maxwidth = p[i].width;
	}

} /* SaveGaussianMaxWidth */
/* ------------------------------------------------------------------------------------------------ */
static void	RestoreGaussianParams(SPECTRA *sp,int fromPeak,int toPeak)
{
	int i;
	PEAKPOS *p;

	p = sp->peakPos;
	for (i = fromPeak; i<= toPeak; i++)
	{
		p[i].width = p[i].tmpwidth;
		p[i].area = p[i].tmparea;
	}

} /* RestoreGaussianParams */
/* ------------------------------------------------------------------------------------------------ */

static float ComputeRMS(SPECTRA *sp,int fromPeak,int toPeak)
{
int i; 
float rms = 0.0;

		for (i=sp->peakPos[fromPeak].pos; i<=sp->peakPos[toPeak-1].pos; i++)
		{
			rms += (sp->data[i]-sp->fitted[i])*(sp->data[i]-sp->fitted[i]);
		}
		return(rms);
		
} /* FitScore */
/* ------------------------------------------------------------------------------------------------ */
static void FindLargestRMS(SPECTRA *sp,int fromPeak,int toPeak, int *worsepeak, float *rms)
{
int peak;
float r;
int i; 

		*rms = 0;
		*worsepeak = -1;
		for (peak=fromPeak+1; peak<=toPeak-1; peak++)
		{
			if (sp->peakPos[peak].done == 1)
				continue;
			r = 0.0;
			for (i=sp->peakPos[peak-1].pos; i<=sp->peakPos[peak+1].pos; i++)
			{
				r += (sp->data[i]-sp->fitted[i])*(sp->data[i]-sp->fitted[i]);
			}
			if (r > *rms) { *rms = r; *worsepeak = peak; }
		}
		
} /* FindLargestRMS */
/* ------------------------------------------------------------------------------------------------ */
static float CheckPeakSummitFit(SPECTRA *sp,int peak)
{
float r;
int i; 
float data,fit;

	data = fit = 0.0;
	r = 0.0;
	for (i=sp->peakPos[peak].pos-1; i<=sp->peakPos[peak].pos+1; i++)
	{
		data+=sp->data[i];
		fit+=sp->fitted[i];
	}
	if (data > 0.0)
		r = (100.0/data*fit)-100.0;

	return(r);
			
} /* CheckPeakSummitFit */
/* ------------------------------------------------------------------------------------------------ */
static void setPeakWidth(SPECTRA *sp,int fromPeak,int toPeak, float width)
{
int i; 
PEAKPOS *p;

		p = sp->peakPos;
		for (i = fromPeak+1; i<= toPeak-1; i++)
		{
			p[i].width = width;
		}
			
} /* setPeakWidth */
/* ------------------------------------------------------------------------------------------------ */

float GrowUnderPredictedPeaks(SPECTRA *sp,int fromPeak,int toPeak,float incrmultfactor)
{
	int i;
	PEAKPOS *p;
	float globalscore,newscore;
	float a2_from;
	float a2_to;
	float incr2;
	float a2;
	float minw;
	
	p = sp->peakPos;	

	printf("%s:Testing whether any peak from [%d - %d] need to grow\n",remark,fromPeak,toPeak);
	minw=NewGenerateFittedSpectraWithMinWidth(sp,fromPeak,toPeak,0);
	for(i=fromPeak+1;i<=toPeak-1;i++)
	{
		globalscore = CheckPeakSummitFit(sp,i);
		if (verbose>= 2)
			printf("%s: current score = %12.1f; peak=%2d (%4d)\n",remark,globalscore,i,p[i].pos);
		if (globalscore < 0.0)
		{
			float f;
			a2_from = p[i  ].area;
			a2_to = a2_from + 10.0*a2_from;
			if (globalscore <= -2.0)
				f = (0.5*log10(-globalscore)); /* the closer we are to optimal fit, the more we reduce incr factor */
			else
				f = (0.5*log10(2));
			incr2 = f*incrmultfactor*p[i  ].area;
			if (a2_from != 0) {
				for (a2 = a2_from; a2 <= a2_to; a2 += incr2)
				{
					p[i  ].area = a2;
					NewGenerateFittedSpectraWithMinWidth(sp,fromPeak,toPeak,0);
					newscore = CheckPeakSummitFit(sp,i);
					SaveGaussianParams(sp,fromPeak,toPeak);
					if (verbose>= 1)
						printf("%s: improved score for peak=%2d (%4d) from %12.1f to %12.1f using f=%5.3f;\n",remark,i,p[i].pos,globalscore,newscore,f);
					/*	break as soon as we are higher than data, and keep last improvement to ensure 
						we stay above data given that peak will be too narrow (widening peak will decrease max point) */
					if (newscore > 0.0)
						break; 
				}
			}
		}
	}
	SaveGaussianMaxWidth(sp,fromPeak,toPeak);
	setPeakWidth(sp,fromPeak+1,toPeak-1,minw);
	return(minw);

} /* GrowUnderPredictedPeaks */
/* ------------------------------------------------------------------------------------------------ */

void NewGlobalOptimize2(SPECTRA *sp,int fromPeak,int toPeak,float minw,float growthfactor)
{
	int i;
	int step,maxsteps;
	PEAKPOS *p;
	float globalrms,rms;
	float incr1,incr2,incr3;
	float w1,w1_from,w1_to;
	float w2_to,w3_to,w2,w3;
	float w2_from,w3_from;
	int improved;
	
	p = sp->peakPos;	

	maxsteps = 3*(toPeak-fromPeak); /* arbitrary but enough, just to put a cap on how much time to spend here. never observed need for > 1.5x(to-from) */
	printf("%s:Entering Global Optimization of peaks [%d - %d] using factor of %5.2f\n",remark,fromPeak+1,toPeak-1,growthfactor);
	ResetDoneFlag(sp,fromPeak,toPeak);
	for ( step=0; step< maxsteps; step++)
	{
		improved = 0;
//ngmay		FindLargestRMS(sp,fromPeak,toPeak,&i,&rms);
		FindLargestRMS(sp,fromPeak+1,toPeak-1,&i,&rms); // to prevent optimizing boundaries as the fit is not computed beyond boundaries
		if (i == -1)
		{
			if (verbose>= 2)
				printf("%s:PEAKS %d - %d fully optimized at step %d\n",remark,fromPeak,toPeak,step);
			break;
		}
		if (verbose>= 1)
			printf("%s:increase width step %d; largest rms for peak %4d (%5d) rms=%12f\n",remark,step,i,p[i].pos,rms);

		if (growthfactor == 0.0)
		{
			w1_from = w2_from = w3_from = minw;
			w1_to = p[i-1].maxwidth;
			w2_to = p[i  ].maxwidth;
			w3_to = p[i+1].maxwidth;
		}
		else
		{
			w1_from = p[i-1].width;
			w2_from = p[i ].width;
			w3_from = p[i+1].width;
			w1_to = w1_from+growthfactor*p[i-1].maxwidth; if (w1_to > p[i-1].maxwidth) w1_to = p[i-1].maxwidth;
			w2_to = w2_from+growthfactor*p[i  ].maxwidth; if (w2_to > p[i  ].maxwidth) w2_to = p[i  ].maxwidth;
			w3_to = w3_from+growthfactor*p[i+1].maxwidth; if (w3_to > p[i+1].maxwidth) w3_to = p[i+1].maxwidth;
		}
		
		incr1 = 0.05*(w1_to-w1_from);
		incr2 = 0.05*(w2_to-w2_from);
		incr3 = 0.05*(w3_to-w3_from);
		if (incr1 <= 0.005) incr1 = w1_to+0.01;
		if (incr2 <= 0.005) incr2 = w2_to+0.01;
		if (incr3 <= 0.005) incr3 = w3_to+0.01;
		if (verbose>= 2)
		{
			printf("%s:testing peak %4d (%5d) width [%5.2f-%5.2f] by %5.4f  (max=%5.2f)\n",remark,i-1,p[i-1].pos,w1_from,w1_to,incr1,p[i-1].maxwidth);
			printf("%s:testing peak %4d (%5d) width [%5.2f-%5.2f] by %5.4f  (max=%5.2f)\n",remark,i,p[i].pos,w2_from,w2_to,incr2,p[i].maxwidth);
			printf("%s:testing peak %4d (%5d) width [%5.2f-%5.2f] by %5.4f  (max=%5.2f)\n",remark,i+1,p[i+1].pos,w3_from,w3_to,incr3,p[i+1].maxwidth);
		}
		globalrms = ComputeRMS(sp,fromPeak,toPeak);
		for (w1 = w1_from; w1 <= w1_to; w1 += incr1)
		{
/*			if (verbose>= 2)
				printf("entering w1 = %5.2f\n",w1);*/
			for (w2 = w2_from; w2 <= w2_to; w2 += incr2)
			{
				for (w3 = w3_from; w3 <= w3_to; w3 += incr3)
				{
					p[i-1].width = w1;
					p[i  ].width = w2;
					p[i+1].width = w3;

					NewGenerateFittedSpectra(sp,fromPeak,toPeak,0);
					rms = ComputeRMS(sp,fromPeak,toPeak);
					if (rms < globalrms)
					{
						improved = 1;
						globalrms = rms;
						SaveGaussianParams(sp,fromPeak,toPeak);
/*						if (verbose>= 2)
							printf("%s:rms=%15.f w1=%5.2f w2=%5.2f w3=%5.2f\n",remark,rms,w1,w2,w3);*/
					}
				}
			}
		}
		RestoreGaussianParams(sp,fromPeak,toPeak);
		NewGenerateFittedSpectra(sp,fromPeak,toPeak,0);
/*		if (verbose>= 2)
			printf("improved peak %d = %d\n",i,improved);*/
		if (improved == 0)
		{
			p[i].done = 1;
		}
		else
		{
			if (verbose>= 2)
				printf("%s:improved of peak %d (%5d): rms=%15.f w1=%5.2f w2=%5.2f w3=%5.2f\n",remark,i,p[i].pos,rms,p[i-1].width,p[i].width,p[i+1].width);
		}
	}

} /* NewGlobalOptimize2 */
/* ------------------------------------------------------------------------------------------------ */

/*static int LoadSeq(char *fn,char *seq)
{
	FILE *f;
	int loaded = 0;
	char c;
	
		f = fopen(fn,"r");
		if (!f)
		{
			printf("cannot open file '%s'\n",fn);
			return(loaded);
		}
		printf("%s:Loading sequence from %s...",remark,fn);
		while(!feof(f))
		{
			c = toupper(fgetc(f));
			if ((c == 'T') || (c == 'C') || (c == 'G') || (c == 'A') || (c == 'U') || (c == 'N'))
			seq[loaded++] = c;
		}
		fclose(f);
		printf("done.\n");
		return(loaded);

}*/ /* LoadSeq */
/* ------------------------------------------------------------------------------------------------ */

/*static void ReverseSeq(char *seq,char *seqc, int len)
{

int i,j;

		j = len-1;
		for (i = 0; i< len; i++)
		{
			seqc[j] = seq[i];
			j--;
		}		

}*/ /* ReverseSeq */
/* ------------------------------------------------------------------------------------------------ */

/*static int LoadSpectra(char *fn,SPECTRA *nmia,SPECTRA *background,SPECTRA *ddnt,SPECTRA *ddnt2,int nmiacol,int bgcol,int nt1col,int nt2col)
{
	FILE *inpf;
	int idx;
	char linbuf[256];
	float highestnmia;
	int i;
	int neg;
	float f[4];
	
	highestnmia = 0.0;

		inpf = fopen(fn,"r");
		if (!inpf)
		{
			printf("ERROR:cannot open file '%s'\n",fn);
			return(0);
		}
		idx = 1; // start at i so as not to confuse user and avoid to offset all communications and input
		fgets(linbuf,128,inpf);
		printf("%s:Loading spectra...",remark);
		neg = 0;
		while(!feof(inpf))
		{

			if (idx >= kNbSpectraPeaks)
			{
				printf("WARNING: spectra not fully loaded. Index range beyond max allowed (%d)\n",kNbSpectraPeaks);
				break;
			}
			fgets(linbuf,128,inpf);
			sscanf(&linbuf[0],"%f %f %f %f", &f[0],&f[1],&f[2],&f[3]);
			for (i = 0; i<4; i++)
			{
				if (f[i] < 0.0) { f[i] = 0.0; neg++; }
			}

			nmia->data[idx] = f[nmiacol];
			background->data[idx] = f[bgcol];
			ddnt->data[idx] = f[nt1col];
			if (nt2col != -1)
				ddnt2->data[idx] = f[nt2col];

//			if (nmia->data[idx] > nmia->maxval) 
//				nmia->maxval = nmia->data[idx];
//			if (background->data[idx] > background->maxval) 
//				background->maxval = background->data[idx];
//			if (ddnt->data[idx] > ddnt->maxval) 
//				ddnt->maxval = ddnt->data[idx];
//			if (ddnt2->data[idx] > ddnt2->maxval) 
//				ddnt2->maxval = ddnt2->data[idx];
			idx++;
		}
		fclose(inpf);
		printf("done\n");

		nmia->firstidx = 1;
		nmia->lastidx = idx;

		background->firstidx = 1;
		background->lastidx = idx;

		ddnt->firstidx = 1;
		ddnt->lastidx = idx;

		ddnt2->firstidx = 1;
		ddnt2->lastidx = idx;
		
		if (neg)
			printf("%s:%d negative input values have been set to 0.0\n",remark,neg);
			
		return(idx);

}*/ /* LoadSpectra */

/* ------------------------------------------------------------------------------------------------ */


void IdentifyBestPeaks(SPECTRA *s,int fromidx,int toidx,float median)
{
	int idx;
	
		for(idx=fromidx+3;idx<(toidx-3);idx++)
		{
			if ((s->data[idx] >= median) &&
				(s->data[idx] > s->data[idx-1]) &&
				(s->data[idx] > s->data[idx-2]) &&
				(s->data[idx] > s->data[idx-3]) &&
				(s->data[idx] > s->data[idx+1]) &&
				(s->data[idx] > s->data[idx+2]) &&
				(s->data[idx] > s->data[idx+3])
				)
				{
					s->maxidx[idx] = kPeak;
				//	printf("peak at idx %4d top=%10.2f\n",idx,s->data[idx]);
				}
		}
		
} /* IdentifyBestPeaks */

/* ------------------------------------------------------------------------------------------------ */
int SetSpectraBoundaries(SPECTRA *nmia,SPECTRA *background,SPECTRA *ddnt,SPECTRA *ddnt2)
{
		int i;
		float highestnmia = 0.0;
		
			for (i= nmia->firstidx; i < nmia->lastidx; i++)
			{
				if (nmia->data[i] > highestnmia)
					highestnmia = nmia->data[i];
			}
			printf("%s:Skipping data in front of first peak higher that 50%% of max peak\n",remark);
			for (i= nmia->firstidx; i < nmia->lastidx; i++)
			{
				if (nmia->data[i] > (0.5*highestnmia))
					break;
			}
			while( ((i < nmia->lastidx) && (nmia->data[i] > (0.5*highestnmia))) ) {i++;}
			nmia->firstidx = i;

			printf("%s:Skipping data after last peak higher that 50%% of max peak\n",remark);
			for (i= nmia->lastidx-1; i > nmia->firstidx; i--)
			{
				if (nmia->data[i] > (0.5*highestnmia))
					break;
			}
			while( ((i > nmia->firstidx) && (nmia->data[i] > (0.5*highestnmia))) ) {i--;}
			nmia->lastidx = i;

		background->firstidx = nmia->firstidx;
		ddnt->firstidx = nmia->firstidx;
		ddnt2->firstidx = nmia->firstidx;

		background->lastidx = nmia->lastidx;
		ddnt->lastidx = nmia->lastidx;
		ddnt2->lastidx = nmia->lastidx;

		printf("%s:First row considered for integration = %d\n",remark,nmia->firstidx);
		printf("%s:Last  row considered for interaction = %d\n",remark,nmia->lastidx);
		
		return(nmia->lastidx-nmia->firstidx+1);

} /* SetSpectraBoundaries */
/* ------------------------------------------------------------------------------------------------ */

static int IdentifyMostFrequentInterval(int start,int end,int *smaxidx)
{
	int x,delta,maxcnt;
	int median;
	int peak[kNbSpectraPeaks];
	int intervalcnt[kNbSpectraPeaks];
	int peakcnt = 0;
	
		for(x=0;x<kNbSpectraPeaks;x++)
		{
			intervalcnt[x] = 0;
		}

		for(x=start;x<=end;x++)
		{
			if (smaxidx[x] == kPeak)
				peak[peakcnt++] = x;
		}
		for(x=1;x<peakcnt;x++)
		{
			delta = peak[x] - peak[x-1];
			intervalcnt[delta]++;
		}


		maxcnt = 0;
		median = 0;
		for(x=0;x<kNbSpectraPeaks;x++)
		{
			if (intervalcnt[x] > maxcnt)
			{ maxcnt = intervalcnt[x]; median = x; }
		}
		return(median);
		
} /* IdentifyMostFrequentInterval */
/* ------------------------------------------------------------------------------------------------ */

static void NewMakeThreeGaussian(int xmin,int xmax,int c1,int c2,int c3,float w1,float a1,float w2,float a2,float w3,float a3,float *g)
{
	int x;

		for (x = xmin; x< xmax; x++)
			g[x] = 0.0;
			
		MakeGaussianPeak(g,w1,a1,c1,xmin,xmax);
		MakeGaussianPeak(g,w2,a2,c2,xmin,xmax);
		MakeGaussianPeak(g,w3,a3,c3,xmin,xmax);
		
} /* NewMakeThreeGaussian */
/* ------------------------------------------------------------------------------------------------ */

static float NewEvaluateFit(int xmin,int xmax,float *fit,float *data)
{
	int x;
	float score,sq;

		score = 0;
		for (x = xmin; x< xmax; x++)
		{
			sq = (data[x]-fit[x]);
			score += (sq*sq);
		}
		return(score);
			
		
} /* NewEvaluateFit */
/* ------------------------------------------------------------------------------------------------ */
void NewPeakFit(int prev,int which, int next,SPECTRA *sp,float minw,float maxw,float stepw, int newpos, float newval)
{
	float score;
	float minscore,globalminscore;
	float a1,a2,a3;
//float w1,w2,w3;
	float best_a1,best_a2,best_a3;
	float incr1,incr2,incr3;
	float a1_from,a2_from,a3_from;
	float a1_to,a2_to,a3_to;
	float preval, nexval;
	int   prepos, nexpos;
	int dx;
	int round;
	float wd;
	float gaussian[kNbSpectraPeaks+10];
	#define kmulmax 10
	#define kmulmin 0.5
	#define kinterval 0.5

	PEAKPOS *p;
	float *data;


	p = sp->peakPos;
	data = sp->data;
	if (prev == which) {
		preval = newval;
		prepos = newpos;
	}
	else {
		preval = p[prev].val;
		prepos = p[prev].pos;
	}
	if (which == next) {
		nexval = newval;
		nexpos = newpos;
	}
	else {
		nexval = p[next].val;
		nexpos = p[next].pos;		
	}
	globalminscore = 1e25;	
	for (round = 0; round < 16; round++)
	{
	if (round == 0)
	{
		incr1 = kinterval*((kmulmax*preval)-(kmulmin*preval)); if (incr1 == 0.0) incr1 = 1.0;
		incr2 = kinterval*((kmulmax*p[which  ].val)-(kmulmin*p[which  ].val)); if (incr2 == 0.0) incr2 = 1.0;
		incr3 = kinterval*((kmulmax*nexval)-(kmulmin*nexval)); if (incr3 == 0.0) incr3 = 1.0;
		a1_from = kmulmin*preval;
		a2_from = kmulmin*p[which  ].val;
		a3_from = kmulmin*nexval;
		a1_to = kmulmax*preval;
		a2_to = kmulmax*p[which  ].val;
		a3_to = kmulmax*nexval;
	}
	else
	{
		incr1 = 0.75*best_a1; if (incr1 == 0.0) incr1 = 1.0;
		incr2 = 0.75*best_a2; if (incr2 == 0.0) incr2 = 1.0;
		incr3 = 0.75*best_a3; if (incr3 == 0.0) incr3 = 1.0;
		a1_from = best_a1-0.5*best_a1; // was .5
		a2_from = best_a2-0.5*best_a2;
		a3_from = best_a3-0.5*best_a3;
		a1_to = best_a1+0.5*best_a1;
		a2_to = best_a2+0.5*best_a2;
		a3_to = best_a3+0.5*best_a3;
	}
	minscore = 1e25;
	for(wd = minw; wd <= maxw; wd += stepw)
	{
		for (a1 = a1_from; a1 <= a1_to; a1 += incr1)
		{
			for (a2 = a2_from; a2 <= a2_to; a2 += incr2)
			{
				for (a3 = a3_from; a3 <= a3_to; a3 += incr3)
				{
					NewMakeThreeGaussian(prepos,nexpos,prepos,p[which].pos,nexpos,(wd), a1, (wd), a2, (wd), a3,gaussian);
					for(dx = 0; dx <=0; dx++)
					{
						score = NewEvaluateFit(prepos,nexpos,gaussian,data);
						//printf("%5.1f %5.1f %5.1f | %5.1f %5.1f %5.1f     %12.4f   p[prev].pos=%6d p[next].pos=%6d\n",incr1,incr2,incr3,a1,a2,a3,score,p[prev].pos,p[next].pos);
						if (score < minscore)
						{
							minscore = score;
							best_a1 = a1;
							best_a2 = a2;
							best_a3 = a3;
							if (score < globalminscore)
							{
								p[which].area = a2;
								p[which].width = (wd);
								p[which].score = score;
								globalminscore = score;
							}
						}
					}
				}
			}
		}
	}
	//printf("local...%8.0f %8.0f %8.0f | %10.0f %10.0f %12.0f\n",incr1,incr2,incr3,p[which].val,a2,minscore);
	}
	p[which].score = sqrt(p[which].score/(nexpos-prepos));
	//printf("peak %3d: %8.0f %8.0f %8.0f | %10.0f %10.0f %5.1f %12.0f\n",which,incr1,incr2,incr3,p[which].val,p[which].area,p[which].width,p[which].score);
	//printf("peak %3d: pos=%5d %10.0f a=%10.0f w=%5.1f %12.0f\n",which,p[which].pos,p[which].val,p[which].area,p[which].width,p[which].score);
} /* NewPeakFit */

/* ------------------------------------------------------------------------------------------------ */

int RefineAddedPeaksPosition(SPECTRA *sp)
{
int i;
int pos;
int shift;

	shift = 0;
	for (i = 1; i< (sp->peakcnt-1); i++)
	{
		if ((sp->peakPos[i].kind == kInterpolatedPeak) && 
			(sp->peakPos[i-1].kind == kPeak) && (sp->peakPos[i+1].kind == kPeak))
		{
			pos = sp->peakPos[i].pos;
			if (verbose>= 2)
				printf("%s:Checking Peak %3d (pos = %4d)\n",remark,i,sp->peakPos[i].pos);
			if ((sp->peakPos[i+1].pos - pos) > (pos - sp->peakPos[i-1].pos))
			{
				// check if moving the peak 1 pixel to the right would be closer to peak max better
				if (sp->data[pos+1] > sp->data[pos])
				{	
					sp->peakPos[i].pos++;
					sp->maxidx[pos+1] = sp->maxidx[pos];
					sp->maxidx[pos] = kNoPeak;
					if (verbose > 0)
						printf("%s:Shifting Peak %3d by +1 (new pos = %4d)\n",remark,i,sp->peakPos[i].pos);
					shift = 1;
				}
			}
			else if ((sp->peakPos[i+1].pos - pos) < (pos - sp->peakPos[i-1].pos))
			{
				// check if moving the peak 1 pixel to the left would be closer to peak max better
				if (sp->data[pos-1] > sp->data[pos])
				{
					sp->peakPos[i].pos--;
					sp->maxidx[pos-1] = sp->maxidx[pos];
					sp->maxidx[pos] = kNoPeak;
					if (verbose > 0)
						printf("%s:Shifting Peak %3d by -1 (new pos = %4d)\n",remark,i,sp->peakPos[i].pos);
					shift = 1;
				}
			}  
		}
	}
	return(shift);
	
} /* RefineAddedPeaksPosition */
/* ------------------------------------------------------------------------------------------------ */
static int sf(float *a,float*b)
{
	if (*a>*b) return(1);
	if (*a<*b) return(-1);
	return(0);
}
/* ------------------------------------------------------------------------------------------------ */
float ListPeakPos(SPECTRA *sp,int fromidx,int toidx)
{
int i,k;
float *a;
float median;

	a = malloc((toidx-fromidx+1)*sizeof(float));
	if (!a)
	{
		printf("not enough memory to compute median\n");
		exit(1);
	}	
	k = 0;
	for (i = fromidx; i< toidx; i++)
			a[k++] = sp->data[i];

	qsort(a, k, sizeof(float),(void*)sf);
	if ((k%2) == 1)
		median = a[k/2];
	else
		median = 0.5*(a[k/2] + a[k/2-1]);

	free(a);
	return(median);
	
} /* ListPeakPos */
/* ------------------------------------------------------------------------------------------------ */
int AnalyzeSpectra(SPECTRA *sp,int plotmissing)
{
int i;
int from,to;
int spectrarange;
int median;
int minmedian;
int largestmedianinterval;

		largestmedianinterval = minmedian = 0;
		for (i=0; i<4; i++)
		{
			spectrarange = sp->lastidx-sp->firstidx+1;
			
			from = sp->firstidx + (i*spectrarange/4/*-(10*median)*/);
			if (from < 0) from = 0;
			to = sp->firstidx + ((i+1)*spectrarange/4);

			median = ListPeakPos(sp,from,to); /* new in v0.82 use of median prevents detection of very small noise peaks that
		                              could persists despite smoothing */
			if (median < minmedian) 
				minmedian = median;
			
			if (verbose >= 1)
				printf("%s:median of signal for region %4d - %4d = %d\n",remark,from,to,median);
		}
		IdentifyBestPeaks(sp,sp->firstidx,sp->lastidx,0.25*minmedian);

		for (i=0; i<4; i++)
		{
			
			spectrarange = sp->lastidx-sp->firstidx+1;
			
			from = sp->firstidx + (i*spectrarange/4/*-(10*median)*/);
			if (from < 0) from = 0;
			to = sp->firstidx + ((i+1)*spectrarange/4);

			median = IdentifyMostFrequentInterval(from,to,sp->maxidx);
			if (median > largestmedianinterval) 
				largestmedianinterval = median;
			AddMissingPeaks(from,to,median,sp->maxidx);
			if (verbose >= 1)
				printf("%s:median for section %4d - %4d = %d\n",remark,from,to,median);
			CheckPeakCount(from,to,median,sp);
		}
		GatherPeaksPosition(sp);
		while(RefineAddedPeaksPosition(sp));
	//	RefineAddedPeaksPosition(sp);
	/*	if (plotmissing)
		{
			for (i= 0; i< sp->mpcnt; i++)
			{
				PlotMissingPeak(sp, sp->missingpeak[i].from, sp->missingpeak[i].to,80);
				printf("\n\n");
			}
		}*/
		
		return(largestmedianinterval);
		
} /* AnalyzeSpectra */
/* ------------------------------------------------------------------------------------------------ */



int Align(char *seq1,int len1, char *seq2, int len2)
{
	int i1,i2;
	int match,bestmatch,beststart;
	bestmatch = 0;
	beststart = -1;
	for (i2 = 0; i2<= (len2-len1); i2++)
	{
		match = 0;
		for (i1 = 0; i1<= len1; i1++)
		{
			if ((seq1[i1] == seq2[i2+i1])) {  match++;/* printf("%c",seq1[i1]);*/}
		//	else {if (match > 0) break;}
		}
		if (verbose >= 2)
			printf("%s:i2 = %d; match = %d\n",remark,i2,match);
		if (match > bestmatch) { bestmatch = match; beststart = i2; }
	}
	
	return(beststart); 
} /* Align */
/* ------------------------------------------------------------------------------------------------ */

void	FindLongestSyncStretch(SPECTRA *sp,int *firstpeak,int *lastpeak,int *firstbgpeak,int *lastbgpeak)
{
int i,k;
int cnt,maxcnt;

	maxcnt = -1;
	for (i = 0; i< (sp->peakcnt-1); i++)
	{
		cnt = 0;
		k = i;
		while (sp->peakLink[k] != -1) {cnt++;k++; if (k == sp->peakcnt) break; }
		if (cnt > maxcnt) 
		{ 
			maxcnt = cnt; 
			*firstpeak = i; 
			*lastpeak = k-1;
			*firstbgpeak = sp->peakLink[i]; 
			*lastbgpeak = sp->peakLink[k-1];
		}
	}

	
} /* FindLongestSyncStretch */
/* ------------------------------------------------------------------------------------------------ */
float GetPeakWidthMedian(int firstpeak,int lastpeak,SPECTRA *sp)
{
int i,k;
float *a;
float median;
PEAKPOS *p;

	a = malloc((lastpeak-firstpeak+1)*sizeof(float));
	if (!a)
	{
		printf("not enough memory to compute median\n");
		exit(1);
	}	

	p = sp->peakPos;
	k = 0;
	for (i = firstpeak; i<lastpeak; i++)
			a[k++] = p[i].width;

	qsort(a, k, sizeof(float),(void*)sf);
	if ((k%2) == 1)
		median = a[k/2];
	else
		median = 0.5*(a[k/2] + a[k/2-1]);

	free(a);
	return(median);
	
	
} /* GetPeakWidthMedian */
/* ------------------------------------------------------------------------------------------------ */
static int TestPeakWidth(SPECTRA *sp,int firstpeak, int lastpeak,float minw,float maxw)
{
int i,cnt;

	cnt = 0;
	for (i = firstpeak; i<lastpeak; i++)
	{
				if ((sp->peakPos[i].width <= minw) || (sp->peakPos[i].width >= maxw))
					cnt++;
	}
	return(cnt);
	
} /* TestPeakWidth */
/* ------------------------------------------------------------------------------------------------ */
void OptimizeFit(SPECTRA *sp, int firstpeak,int lastpeak)
{
	int i;
//	int section;
	int sectionlen;
	float peakwidthmedian;
	int badcnt;
	int section_fp,section_lp;

		sectionlen = 25;
		section_fp = firstpeak;
		while (section_fp < lastpeak)
		{
			section_lp = section_fp+sectionlen+2;
			if (section_lp > lastpeak) 
				section_lp = lastpeak;
			/* optimize peak fit using median */
			peakwidthmedian = GetPeakWidthMedian(section_fp,section_lp,sp); // works for 3peaks not 5 peaks
			if (verbose >= 2)
				printf("%s:will use peak width of %5.1f for peaks %d - %d\n",remark,peakwidthmedian,section_fp,section_lp);
			printf("%s:will use peak width of %5.1f for peaks %d - %d\n",remark,peakwidthmedian,section_fp,section_lp);
			if (verbose>= 2)
				printf("%s:**************** 0.5*peakwidthmedian=%f peakwidthmedian+0.6*peakwidthmedian=%f\n",remark,0.5*peakwidthmedian,peakwidthmedian+0.6*peakwidthmedian);
			for (i = section_fp; (i<= section_lp) && (i != lastpeak); i++)
			{
				if (verbose >= 2)
					printf("%s:fitting peak %d\n",remark,i);
				NewPeakFit(i-1,i,i+1,sp,0.4*peakwidthmedian,peakwidthmedian+0.5*peakwidthmedian,0.05,0,0);
			}
			if (badcnt=TestPeakWidth(sp,section_fp+3,section_lp-3,0.4*peakwidthmedian,peakwidthmedian+0.5*peakwidthmedian)!=0)
			{
				if (verbose>= 2)
					printf("%s:peak width used for fitting may be inaccurate for %d of the fitted peaks. You may obtain better integration results by splitting the data to analyze in two subsets\n",remark,badcnt);
			}
			section_fp += sectionlen;
		}
} /* OptimizeFit */

/* ------------------------------------------------------------------------------------------------ */
#ifdef DEBUGDUMPDATA
void DebugDumpIntegration(char *fn,SPECTRA *sp,int firstpeak,int lastpeak)
{ 
	int i;
	PEAKPOS *p;
	char pf[256];
	char s[256];
	char ifn[256];
	char iplotfile[256];

	FILE *oo;
	oo = fopen(fn,"w");

	p = sp->peakPos;
	for (i = firstpeak; i<= lastpeak; i++)
	{
		fprintf(oo,"%f,%f,%d\n",p[i].width,p[i].area,p[i].pos);
	}	
	fclose (oo);	

	sprintf(ifn,"%s.ifn",fn);
	sprintf(iplotfile,"%s.iplotfile.pdf",fn);
	sprintf(pf,"%s.dat",fn);

	PrintIntegratedPeaks(sp,sp,firstpeak,lastpeak,ifn);
	PlotFitVsInput(pf,sp,sp);
	sprintf(s,"R -q --vanilla --slave --args %s %s %d %d %s < Rplot.r > /dev/null",pf,ifn,sp->firstidx,sp->lastidx,iplotfile);
	printf("%s:plotting peak position with command '%s'\n","DEBUG",s);
	system(s);

} /* DebugDumpIntegration */ 
#endif
/* ------------------------------------------------------------------------------------------------ */
void IntegratePeaks(SPECTRA *sp,int firstpeak, int lastpeak,int gopt,char *s)
{
#ifdef DEBUGDUMPDATA
	char s2[96];
#endif
	int i;

			for (i = firstpeak+1; i< lastpeak; i++)
			{
				if (verbose >=2)
					printf("%s:exploring %s peak fitting %d\n",remark,s,i);
				NewPeakFit(i-1,i,i+1,sp,0.8,4.5,0.1,0,0);
			}


#ifdef DEBUGDUMPDATA
			NewGenerateFittedSpectra(sp,firstpeak+1,lastpeak,0);
			sprintf(s2,"rnafit-debug-dump-%s-step1.txt",s);
			DebugDumpIntegration(s2,sp,firstpeak,lastpeak);
#endif

			OptimizeFit(sp,firstpeak+1,lastpeak);

			printf("%s:Generating Fitted curve for background lane\n",remark);
			NewGenerateFittedSpectra(sp,firstpeak+1,lastpeak,0);
#ifdef DEBUGDUMPDATA
			sprintf(s2,"rnafit-debug-dump-%s-step2.txt",s);
			DebugDumpIntegration(s2,sp,firstpeak,lastpeak);
#endif
			if (gopt)
			{
				int section_lp;
				int section_fp = firstpeak+1;
				int sectionlen = 25;
				while (section_fp < lastpeak)
				{
					section_lp = section_fp+sectionlen; // ngmay +2
					if (section_lp > lastpeak) 
						section_lp = lastpeak;
					float minw = GrowUnderPredictedPeaks(sp,section_fp,section_lp,0.2);
					NewGlobalOptimize2(sp,section_fp,section_lp,minw,0.0);
					NewGlobalOptimize2(sp,section_fp,section_lp,minw,0.1);
					section_fp += (sectionlen-2);
				}
				NewGenerateFittedSpectra(sp,firstpeak+1,lastpeak,0);
#ifdef DEBUGDUMPDATA
				sprintf(s2,"rnafit-debug-dump-%s-step3.txt",s);
				DebugDumpIntegration(s2,sp,firstpeak,lastpeak);
#endif
			}
			
} /* IntegratePeaks */
/* ------------------------------------------------------------------------------------------------ */
