function [W,M,V] = EM_GM_compiled(X,k)
  % [W,M,V] = EM_GM_compiled(X,k)
  %
  % expectation maximisation for gaussian mixtures
  % interfacing with compiled C code
  %
  % this runs about 10x faster than the matlab version, EM_GM
  %
  % source code for clust obtained from:
  % https://engineering.purdue.edu/~bouman/software/cluster/
  %
  % Citation:
  % ---------
  % @UNPUBLISHED{Bouman97,
  %    author = "C. A. Bouman",
  %    title = "Cluster: {A}n unsupervised algorithm for modeling {G}aussian mixtures",
  %    note = "Available from http://www.ece.purdue.edu/\string~bouman",
  %    month = "April",
  %    year = "1997"
  %  }
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
%% prelims
  D = size(X,2);
  N = size(X,1);

%% write X to file
  save clustertemp_X X -ASCII;
  
%% make info file

  fid = fopen('clustertemp_info','w');
  
  fprintf(fid,'%s\n%s\n%s %s',...
    '1'               ,...
    num2str(D)        ,...
    'clustertemp_X'   ,...
    num2str(N)         ...
    );
  
  fclose(fid);

  
%% call script
  if isunix
    eval(['!./clust ' num2str(k) ' clustertemp_info clustertemp_output full ' num2str(k) ' > clustertemp_stdout']);
  elseif ismac
    eval(['!./clust ' num2str(k) ' clustertemp_info clustertemp_output full ' num2str(k) ' > clustertemp_stdout']);
  elseif ispc
    eval(['!clust.exe ' num2str(k) ' clustertemp_info clustertemp_output full ' num2str(k)]);
  end
  
%% read and parse output

  W = nan * zeros(1,k);
  M = nan * zeros( D, k );
  V = nan * zeros( D, D, k );

  fid = fopen('clustertemp_output','rt');
  C = textscan(fid,'%s'); C = C{1};

  posn.subclass.start = find(strcmp(C,'subclass:'))'+1;
  posn.subclass.end   = find(strcmp(C,'endsubclass:'))'-1;
  n.clusters = L(posn.subclass.start);
  
  if ~(n.clusters == k)
    error('processing:error','somehow, the number of clusters has fucked up inside the .c file!');
  end
  
  for ii=1:n.clusters
    Ct = C(posn.subclass.start(ii):posn.subclass.end(ii))';
    posn.pi   = find(strcmp(Ct,'pi:'));
    posn.mean = find(strcmp(Ct,'means:'));
    posn.covar = find(strcmp(Ct,'covar:'));
    W(ii) = str2num( Ct{posn.pi+1} );
    for jj=1:D
      M(jj,ii) = str2num( Ct{posn.mean + jj} );
      for kk=1:D
        V(jj,kk,ii) = str2num( Ct{posn.covar + (jj-1)*D + kk} );
      end
    end
  end
  
%% delete files
  warning off MATLAB:DELETE:FileNotFound;
  warning off MATLAB:DELETE:Permission;
  
  delete clustertemp_info;
  delete clustertemp_output;
  delete clustertemp_X;
  delete clustertemp_stdout;
  
  warning on MATLAB:DELETE:Permission;
  warning on MATLAB:DELETE:FileNotFound;
  
end
