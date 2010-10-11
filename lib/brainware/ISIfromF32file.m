function isi=ISIfromF32file(fname,bins);
%function isi=ISIfromF32file(fname,bins);
%  opens an F32 spike data file "fname" (exported from BrainWare)
%  and calculates a first order inter-spike interval histogram (isi)
%  using the optional bin boundaries "bins". I.e. the first bin will be
%  bins(1) <= x < bins(2)
%  If not specified, "bins"
%  defaults to 0:20
% 

data=spikedatf(fname);
if ~exist('bins'), bins=0:20; end;
intervals=[];
for dd=1:length(data),
    for ss=1:length(data(dd).sweep)
        for kk=2:length(data(dd).sweep(ss).spikes)
            intervals=[intervals data(dd).sweep(ss).spikes(kk)-data(dd).sweep(ss).spikes(kk-1)];
        end;
    end;
end;
isi=histc(intervals, bins);