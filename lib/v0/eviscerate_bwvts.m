directory = '/data/experiments/data.awake/all/P01.L.contrast.2/';
files = getfilelist(directory,'bwvt');

%% filter and downsample

% construct filter
    fs = 48828.125;
    Wp = [300 3000];
    n = 6;
    [z,p,k] = ellip(n, 0.01, 80, Wp/(fs/2));
    [sos,g] = zp2sos(z,p,k);
    Hd = dfilt.df2tsos(sos,g);  

    
    
n.files = 10; %L(files);
bwvt = cell(1,n.files);

for aa = 1:n.files
  fprintf_numbered(files(aa).name,aa,n.files);
  bt = readBWVTfile(files(aa).fullname);

  maxt = L(bt(1).signal);
  tt = 1:25:maxt;

  for ii=1:L(bt)
    bt(ii).signal = filtfilthd(Hd,bt(ii).signal);
    %bt(ii).signal = bt(ii).signal(tt) - mean(bt(ii).signal);
  end

  bwvt{aa} = bt;
  if aa==1
    bwvt = mat2cell(repmat(bt,n.files,1),ones(1,n.files),L(bt));
  end

end
bwvt = cell2mat(bwvt);

%% plot

maxs = nan(1,n.files);
medians = nan(1,n.files);
for ii=1:n.files
  fprintf_numbered(n2s(ii),ii,n.files);
  s = abs(reach(bwvt(ii,:),'signal'''));
  maxs(ii) = max(s);
  medians(ii) = median(s);
end

%%
n.bwvt = size(bwvt,2);
for aa = 1:n.files
  fprintf_numbered(['site ' n2s(aa)],aa,n.files);
med = medians(aa)*4;
for ii=1:n.bwvt
  s = bwvt(aa,ii).signal;
  tocontinue = true;
  while tocontinue
    pos = find(abs(s)>med,1);
    if isempty(pos)
      tocontinue = false;
    else
      startpos = max(pos-2*25,1);
      endpos   = min(pos+500*25,L(s));
      s(startpos:endpos) = nan;
    end
  end
  bwvt(aa,ii).signal2 = s;
end
end

%%
ylims = min([medians*10; maxs]);

n.cols = 4;
n.rows = ceil(n.files/n.cols);
w = 1/(n.cols+1);
h = 1/(n.rows+1);

p = struct;
p.fig = figure(1); clf;
set_fig_size(1000,800);

for ii=1:n.bwvt
  fprintf_numbered(['trial ' n2s(ii)],ii,n.bwvt);
  
  clf;
  for aa=1:n.files
    p.ax(aa) = axatpos(w,h,n.rows,n.cols,aa);
    hold on;
    plot(bwvt(aa,ii).signal2);
    xlim([1 L(tt)]);
    plot(xlim,medians(aa)*[1 1],'r--');
    plot(xlim,-medians(aa)*[1 1],'r--');
    ylim(ylims(aa) * [-1 1]);
    noticks;
    ylabel(n2s(aa));
    
    
    
  end
  pause;
end
