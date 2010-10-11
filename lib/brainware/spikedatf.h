/*
 * MATLAB Compiler: 2.0.1
 * Date: Wed Aug 16 12:54:41 2000
 * Arguments: "-x" "spikedatf" 
 */

#ifndef MLF_V2
#define MLF_V2 1
#endif

#ifndef __spikedatf_h
#define __spikedatf_h 1

#include "matlab.h"

extern mxArray * mlfSpikedatf(mxArray * fname);
extern void mlxSpikedatf(int nlhs,
                         mxArray * plhs[],
                         int nrhs,
                         mxArray * prhs[]);

#endif
