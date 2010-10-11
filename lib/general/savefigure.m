function savefigure(directory, filename, varargin)
    % SAVEFIGURE
    %   saveFigure(directory,filename) saves the figure as a png, jpg, eps,
    %   pdf and fig all at once ***
    %
    % ***: check current file: some saving formats may be commented out
    %
    
%% parse varargin

  make_png = 0;
  make_eps = 0;
  make_fig = 0;
  make_pdf = 0;
  make_jpg = 0;

  if nargin==2
    make_png = 1;
    make_eps = 0;
    make_fig = 0;
    make_pdf = 0;
    make_jpg = 0;
  elseif nargin>=3
    for ii=1:L(varargin)
      switch varargin{ii}
        case 'png'
          make_png = 1;
        case 'eps'
          make_eps = 1;
        case 'fig'
          make_fig = 1;
        case 'pdf'
          make_pdf = 1;
        case 'jpg'
          make_jpg = 1;
      end
    end
  end

%% parse directory
    
    directory = fixpath(directory);
    
    % if the directory doesn't exist, ask for it to be created
    dircontents = dir(directory);
    if L(dircontents)==0
        fprintf(['Directory: ' directory ' does not exist \n']);
        fprintf('Do you want to:\n');
        fprintf('   - 1: create it\n');
        fprintf('   - 2: reenter it\n');
        fprintf('   - 3: cancel?\n');
        aa = input('                  >> ');
        if aa==1
            mkdir(directory);
        elseif aa==2
            newdir = input('enter new directory:  ','s');
            savefigure(newdir,filename);
            return;
        elseif aa==3
            return;
        else
            fprintf('invalid input. try again\n\n\n');
            savefigure(directory,filename);
            return;
        end
    end
    
    
%% save

  if make_png
    print('-dpng','-r300',[directory filename '.png']);
  end
  if make_jpg
    print('-djpeg','-r125',[directory filename ' - PREVIEW.jpg']);
  end
  if make_eps
    print('-depsc',[directory filename '.eps']);
  end
  if make_pdf
    print('-dpdf',[directory filename '.pdf']);
  end
  if make_fig
    hgsave([directory filename '.fig']);
  end


end