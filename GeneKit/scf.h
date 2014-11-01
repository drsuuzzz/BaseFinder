/*
 * File: scf.h
 * Version:
 *
 * Author: Simon Dear
 *         MRC Laboratory of Molecular Biology
 *	   Hills Road
 *	   Cambridge CB2 2QH
 *	   United Kingdom
 *
 * Description: file structure definitions for SCF file
 *
 * Created: 19 November 1992
 * Updated:
 *
 */

#ifndef _SCF_H_
#define _SCF_H_

#define SCF_MAGIC (((((((unsigned int)'.'<<8)+(unsigned int)'s')<<8)+(unsigned int)'c')<<8)+(unsigned int)'f')

#define VERSION 2.00

/*
 * Type definition for the Header structure
 */
 
typedef struct {
    unsigned int magic_number;       // SCF_MAGIC
    unsigned int samples;            // Number of elements in Samples matrix
    unsigned int samples_offset;     // Byte offset from start of file
    unsigned int bases;              // Number of bases in Bases matrix
    unsigned int bases_left_clip;    // Number of bases in left clip (vector)
    unsigned int bases_right_clip;   // Number of bases in right clip (unreliable)
    unsigned int bases_offset;       // Byte offset from start of file
    unsigned int comments_size;      // Number of bytes in Comment section
    unsigned int comments_offset;    // Byte offset from start of file
    char version[4];	     	     // "version.revision"
    unsigned int sample_size;	     // precision of samples (in bytes)
    unsigned int code_set;	     // uncertainty codes used
    unsigned int private_size;       /* No. of bytes of Private data, 0 if none (added scf version 3) */
    unsigned int private_offset;     /* Byte offset from start of file */

    unsigned int spare[18];          // Unused
} SCFHeader;


#define CSET_DEFAULT 0  /* {A,C,G,T,-} */
#define CSET_STADEN  1
#define CSET_NC_IUB  2
#define CSET_ALF     3  /* extended NC_IUB */
#define CSET_ABI     4  /* {A,C,G,T,N} */

/*
 * Type definition for the Sample data
 */

#ifndef MACOSX
typedef unsigned char Byte;
#endif
typedef struct {
  Byte sample_A;           // Sample for A trace
  Byte sample_C;           // Sample for C trace
  Byte sample_G;           // Sample for G trace
  Byte sample_T;           // Sample for T trace
} SCFSamples1;
typedef struct {
    unsigned short sample_A;           // Sample for A trace
    unsigned short sample_C;           // Sample for C trace
    unsigned short sample_G;           // Sample for G trace
    unsigned short sample_T;           // Sample for T trace
} SCFSamples2;


/*
 * Type definition for the sequence data
 */

typedef struct {
    unsigned int peak_index;  // Index into Samples matrix for base position
    Byte prob_A;              // Probability of it being an A
    Byte prob_C;              // Probability of it being an C
    Byte prob_G;              // Probability of it being an G
    Byte prob_T;              // Probability of it being an T
    char base;                // Base called
    Byte spare[3];            // Spare
} SCFBase;


/*
 * Type definition for the comments
 */
typedef char SCFComments;            /* Zero terminated list of \n separated entries */


/*
 * Type definition of the UW Smith Group exension to use the private
 * data section for additional info like raw data, script, tracking info,
 * processing details ...
 */
typedef struct {
    char         magic_number[4];    // MAGIC string = 'UWBF'
    unsigned int raw_samples;        // Number of raw data time samples
    unsigned int raw_channel_count;  // no. of wavelength channels in raw data
    unsigned int raw_samples_offset; // Byte offset from start of private section
                                     // (raw block size = raw_samples*raw_channel_count*4)
    unsigned int script_size;        // no. of bytes used by script (ASCII representation)
    unsigned int script_offset;      // Byte offset from start of private section
    unsigned int taggedInfo_size;    // An OpenStep Property List
    unsigned int taggedInfo_offset;  //
    unsigned int spare[24];          // Unused (gives 128byte total)
} UWBFPrivateSCFHeader;


#endif /*_SCF_H_*/
