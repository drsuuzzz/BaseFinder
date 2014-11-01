/* "$Id: dspfft.h,v 1.1.1.1 2005/09/07 22:21:58 giddings Exp $" */

// include file for dspfft


void dspfft (float *input, float *output, int complex, int number_of_blocks,int dspfft_size);

// #define DSPFFT_SIZE 256
#define EXPANSION_MEMORY 0