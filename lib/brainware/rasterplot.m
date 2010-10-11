function rasterplot(sweeps)
% makes a raster plot of data imported with spikedatf
%   example:
%   d=spikedatf(fname);
%   rasterplot(d(1).sweep)
clf;
hold on;
for ii=1:length(sweeps),
    spk=sweeps(ii).spikes;
    plot(spk,ones(size(spk))*ii,'k.');
end;
hold off;
xlabel('time (ms)');
ylabel('sweep #');