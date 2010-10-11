/*
 * MATLAB Compiler: 2.0.1
 * Date: Wed Aug 16 12:56:13 2000
 * Arguments: "-x" "spikecountsf" 
 */

#ifndef MLF_V2
#define MLF_V2 1
#endif

#ifndef __spikecountsf_h
#define __spikecountsf_h 1

#include "matlab.h"

extern mxArray * mlfSpikecountsf(mxArray * fname);
extern void mlxSpikecountsf(int nlhs,
                            mxArray * plhs[],
                            int nrhs,
                            mxArray * prhs[]);

#endif
