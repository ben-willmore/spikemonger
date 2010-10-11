/*
 * MATLAB Compiler: 2.0.1
 * Date: Wed Aug 16 12:56:13 2000
 * Arguments: "-x" "spikecountsf" 
 */
#include "spikecountsf.h"

/*
 * The function "Mspikecountsf" is the implementation version of the
 * "spikecountsf" M-function from file
 * "C:\jan\wphysio6\BWmfiles\spikeCountsF.m" (lines 1-19). It contains the
 * actual compiled code for that M-function. It is a static function and must
 * only be called from one of the interface functions, appearing below.
 */
/*
 * function data=spikeCountsF(fname);
 */
static mxArray * Mspikecountsf(int nargout_, mxArray * fname) {
    mxArray * data = mclGetUninitializedArray();
    mxArray * f = mclGetUninitializedArray();
    mxArray * i = mclGetUninitializedArray();
    mxArray * stim = mclGetUninitializedArray();
    mxArray * swps = mclGetUninitializedArray();
    mclValidateInputs("spikecountsf", 1, &fname);
    /*
     * % function data=spikeCountsF(fname);
     * %    reads a BrainWare spike data file exported with "save spike counts as 32-bit binary" 
     * %    and export option set to detailed
     * 
     * data=[];
     */
    mlfAssign(&data, mclCreateEmptyArray());
    /*
     * 
     * f=fopen(fname,'r');
     */
    mlfAssign(&f, mlfFopen(NULL, NULL, fname, mxCreateString("r"), NULL));
    /*
     * swps=fread(f,1,'float32');
     */
    mlfAssign(
      &swps,
      mlfFread(NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
    /*
     * i=0;
     */
    mlfAssign(&i, mlfScalar(0.0));
    /*
     * while ~isempty(swps);
     */
    while (mlfTobool(mlfNot(mlfIsempty(swps)))) {
        /*
         * i=i+1;
         */
        mlfAssign(&i, mlfPlus(i, mlfScalar(1.0)));
        /*
         * data(i).counts=fread(f,[2,round(swps)],'float32');
         */
        mlfIndexAssign(
          &data,
          "(?).counts",
          i,
          mlfFread(
            NULL,
            f,
            mlfHorzcat(mlfScalar(2.0), mlfRound(swps), NULL),
            mxCreateString("float32"),
            NULL));
        /*
         * stim=fread(f,1,'float32');
         */
        mlfAssign(
          &stim,
          mlfFread(NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
        /*
         * data(i).stim=fread(f,round(stim),'float32');
         */
        mlfIndexAssign(
          &data,
          "(?).stim",
          i,
          mlfFread(NULL, f, mlfRound(stim), mxCreateString("float32"), NULL));
        /*
         * swps=fread(f,1,'float32');
         */
        mlfAssign(
          &swps,
          mlfFread(NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
    /*
     * end;
     */
    }
    mclValidateOutputs("spikecountsf", 1, nargout_, &data);
    mxDestroyArray(f);
    mxDestroyArray(i);
    mxDestroyArray(stim);
    mxDestroyArray(swps);
    /*
     * % disp(['Read data for ' int2str(i) ' sets']);
     */
    return data;
}

/*
 * The function "mlfSpikecountsf" contains the normal interface for the
 * "spikecountsf" M-function from file
 * "C:\jan\wphysio6\BWmfiles\spikeCountsF.m" (lines 1-19). This function
 * processes any input arguments and passes them to the implementation version
 * of the function, appearing above.
 */
mxArray * mlfSpikecountsf(mxArray * fname) {
    int nargout = 1;
    mxArray * data = mclGetUninitializedArray();
    mlfEnterNewContext(0, 1, fname);
    data = Mspikecountsf(nargout, fname);
    mlfRestorePreviousContext(0, 1, fname);
    return mlfReturnValue(data);
}

/*
 * The function "mlxSpikecountsf" contains the feval interface for the
 * "spikecountsf" M-function from file
 * "C:\jan\wphysio6\BWmfiles\spikeCountsF.m" (lines 1-19). The feval function
 * calls the implementation version of spikecountsf through this function. This
 * function processes any input arguments and passes them to the implementation
 * version of the function, appearing above.
 */
void mlxSpikecountsf(int nlhs, mxArray * plhs[], int nrhs, mxArray * prhs[]) {
    mxArray * mprhs[1];
    mxArray * mplhs[1];
    int i;
    if (nlhs > 1) {
        mlfError(
          mxCreateString(
            "Run-time Error: File: spikecountsf Line: 1 Column"
            ": 0 The function \"spikecountsf\" was called with"
            " more than the declared number of outputs (1)"));
    }
    if (nrhs > 1) {
        mlfError(
          mxCreateString(
            "Run-time Error: File: spikecountsf Line: 1 Column"
            ": 0 The function \"spikecountsf\" was called with"
            " more than the declared number of inputs (1)"));
    }
    for (i = 0; i < 1; ++i) {
        mplhs[i] = NULL;
    }
    for (i = 0; i < 1 && i < nrhs; ++i) {
        mprhs[i] = prhs[i];
    }
    for (; i < 1; ++i) {
        mprhs[i] = NULL;
    }
    mlfEnterNewContext(0, 1, mprhs[0]);
    mplhs[0] = Mspikecountsf(nlhs, mprhs[0]);
    mlfRestorePreviousContext(0, 1, mprhs[0]);
    plhs[0] = mplhs[0];
}
