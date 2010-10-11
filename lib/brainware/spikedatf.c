/*
 * MATLAB Compiler: 2.0.1
 * Date: Wed Aug 16 12:54:41 2000
 * Arguments: "-x" "spikedatf" 
 */
#include "spikedatf.h"

/*
 * The function "Mspikedatf" is the implementation version of the "spikedatf"
 * M-function from file "C:\jan\wphysio6\BWmfiles\spikedatf.m" (lines 1-43). It
 * contains the actual compiled code for that M-function. It is a static
 * function and must only be called from one of the interface functions,
 * appearing below.
 */
/*
 * function data=spikedatf(fname);
 */
static mxArray * Mspikedatf(int nargout_, mxArray * fname) {
    mxArray * data = mclGetUninitializedArray();
    mxArray * ans = mclInitializeAns();
    mxArray * f = mclGetUninitializedArray();
    mxArray * i = mclGetUninitializedArray();
    mxArray * numparams = mclGetUninitializedArray();
    mxArray * numsets = mclGetUninitializedArray();
    mxArray * numsweeps = mclGetUninitializedArray();
    mxArray * totalspikes = mclGetUninitializedArray();
    mxArray * totalsweeps = mclGetUninitializedArray();
    mclValidateInputs("spikedatf", 1, &fname);
    /*
     * % reads binary spike data file "fname" generated with
     * % BrainWare 6.1 "File | Save As | Spike Times as Binary"
     * % (c) Jan Schnupp, Feb 1999
     * %
     * f=fopen(fname, 'r');
     */
    mlfAssign(&f, mlfFopen(NULL, NULL, fname, mxCreateString("r"), NULL));
    /*
     * 
     * numsets=0;
     */
    mlfAssign(&numsets, mlfScalar(0.0));
    /*
     * numsweeps=0;
     */
    mlfAssign(&numsweeps, mlfScalar(0.0));
    /*
     * totalsweeps=0;
     */
    mlfAssign(&totalsweeps, mlfScalar(0.0));
    /*
     * totalspikes=0;
     */
    mlfAssign(&totalspikes, mlfScalar(0.0));
    /*
     * i=fread(f,1,'float32');
     */
    mlfAssign(
      &i, mlfFread(NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
    /*
     * while ~isempty(i);
     */
    while (mlfTobool(mlfNot(mlfIsempty(i)))) {
        if (mclSwitchCompare(i, mlfScalar(-2.0))) {
            /*
             * 
             * switch i
             * case (-2) % new dataset
             * numsets=numsets+1; 
             */
            mlfAssign(&numsets, mlfPlus(numsets, mlfScalar(1.0)));
            /*
             * numsweeps=0;
             */
            mlfAssign(&numsweeps, mlfScalar(0.0));
            /*
             * % read sweeplength
             * data(numsets).sweeplength=fread(f,1,'float32');
             */
            mlfIndexAssign(
              &data,
              "(?).sweeplength",
              numsets,
              mlfFread(
                NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
            /*
             * % read stimulus parameters
             * numparams=fread(f,1,'float32');
             */
            mlfAssign(
              &numparams,
              mlfFread(
                NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
            /*
             * 
             * data(numsets).stim=fread(f,numparams,'float32');
             */
            mlfIndexAssign(
              &data,
              "(?).stim",
              numsets,
              mlfFread(NULL, f, numparams, mxCreateString("float32"), NULL));
        /*
         * 
         * case (-1) % new sweep
         */
        } else if (mclSwitchCompare(i, mlfScalar(-1.0))) {
            /*
             * numsweeps=numsweeps+1;
             */
            mlfAssign(&numsweeps, mlfPlus(numsweeps, mlfScalar(1.0)));
            /*
             * 
             * totalsweeps=totalsweeps+1;
             */
            mlfAssign(&totalsweeps, mlfPlus(totalsweeps, mlfScalar(1.0)));
            /*
             * data(numsets).sweep(numsweeps).spikes=[];
             */
            mlfIndexAssign(
              &data,
              "(?).sweep(?).spikes",
              numsets,
              numsweeps,
              mclCreateEmptyArray());
        /*
         * 
         * otherwise % read spike time for next spike in current sweep
         */
        } else {
            /*
             * data(numsets).sweep(numsweeps).spikes=...
             */
            mlfIndexAssign(
              &data,
              "(?).sweep(?).spikes",
              numsets,
              numsweeps,
              mlfHorzcat(
                mlfIndexRef(data, "(?).sweep(?).spikes", numsets, numsweeps),
                i,
                NULL));
            /*
             * [data(numsets).sweep(numsweeps).spikes i];
             * totalspikes=totalspikes+1;
             */
            mlfAssign(&totalspikes, mlfPlus(totalspikes, mlfScalar(1.0)));
        /*
         * end;
         */
        }
        /*
         * 
         * i=fread(f,1,'float32');
         */
        mlfAssign(
          &i,
          mlfFread(NULL, f, mlfScalar(1.0), mxCreateString("float32"), NULL));
    /*
     * 
     * end;
     */
    }
    /*
     * fclose(f);
     */
    mclAssignAns(&ans, mlfFclose(f));
    /*
     * disp(sprintf('read %d sets, %d sweeps, %d spikes',...
     */
    mlfDisp(
      mlfSprintf(
        NULL,
        mxCreateString("read %d sets, %d sweeps, %d spikes"),
        numsets,
        totalsweeps,
        totalspikes,
        NULL));
    mclValidateOutputs("spikedatf", 1, nargout_, &data);
    mxDestroyArray(ans);
    mxDestroyArray(f);
    mxDestroyArray(i);
    mxDestroyArray(numparams);
    mxDestroyArray(numsets);
    mxDestroyArray(numsweeps);
    mxDestroyArray(totalspikes);
    mxDestroyArray(totalsweeps);
    /*
     * numsets,totalsweeps, totalspikes))
     */
    return data;
}

/*
 * The function "mlfSpikedatf" contains the normal interface for the
 * "spikedatf" M-function from file "C:\jan\wphysio6\BWmfiles\spikedatf.m"
 * (lines 1-43). This function processes any input arguments and passes them to
 * the implementation version of the function, appearing above.
 */
mxArray * mlfSpikedatf(mxArray * fname) {
    int nargout = 1;
    mxArray * data = mclGetUninitializedArray();
    mlfEnterNewContext(0, 1, fname);
    data = Mspikedatf(nargout, fname);
    mlfRestorePreviousContext(0, 1, fname);
    return mlfReturnValue(data);
}

/*
 * The function "mlxSpikedatf" contains the feval interface for the "spikedatf"
 * M-function from file "C:\jan\wphysio6\BWmfiles\spikedatf.m" (lines 1-43).
 * The feval function calls the implementation version of spikedatf through
 * this function. This function processes any input arguments and passes them
 * to the implementation version of the function, appearing above.
 */
void mlxSpikedatf(int nlhs, mxArray * plhs[], int nrhs, mxArray * prhs[]) {
    mxArray * mprhs[1];
    mxArray * mplhs[1];
    int i;
    if (nlhs > 1) {
        mlfError(
          mxCreateString(
            "Run-time Error: File: spikedatf Line: 1 Column:"
            " 0 The function \"spikedatf\" was called with m"
            "ore than the declared number of outputs (1)"));
    }
    if (nrhs > 1) {
        mlfError(
          mxCreateString(
            "Run-time Error: File: spikedatf Line: 1 Column:"
            " 0 The function \"spikedatf\" was called with m"
            "ore than the declared number of inputs (1)"));
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
    mplhs[0] = Mspikedatf(nlhs, mprhs[0]);
    mlfRestorePreviousContext(0, 1, mprhs[0]);
    plhs[0] = mplhs[0];
}
