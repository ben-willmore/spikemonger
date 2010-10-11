function reposition_gcf(n)
  % reposition_gcf(n)
  %
  % computer-specific function for positioning the current window.
  % enter your computer specific details here if you want to use this.
  %
  % it is worthwhile storing a local copy of this function across updates
  
  
%% determine which computer you are on
% ======================================

  computer_name = get_current_computer_name;
    
    
%% reposition by which computer
% ==============================

switch computer_name
  case 'unknown'
    return;
    
  case 'macgyver'
    switch n
      case 1
        set(gcf,'position',[0 5 839 971]);
      case 2
        set(gcf,'position',[841 5 839 971]);
      case 3
        set(gcf,'position',[1681 5 839 971]);
      case 4
        set(gcf,'position',[2541 5 839 971]);
    end
    
  case 'rabbit'
    switch n
      case 1
        %set(gcf,'position',[400 450 520 450]);
        set(gcf,'position',[400 20 520 800]);
      case 2
        %set(gcf,'position',[920 450 520 450]);
        set(gcf,'position',[920 20 520 800]);
      case 3
        set(gcf,'position',[400 0 520 450]);
      case 4
        set(gcf,'position',[920 0 520 450]);
    end

    
end

end