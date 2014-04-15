function [g,info] = comp_fourierwindow(g,L,callfun);
%COMP_FOURIERWINDOW  Compute the window from numeric, text or cell array.
%   Usage: [g,info] = comp_fourierwindow(g,a,M,L,wilson,callfun);
%
%   `[g,info]=comp_fourierwindow(g,L,callfun)` will compute the window
%   from a text description or a cell array containing additional
%   parameters.
%
%   See also: gabwin, wilwin

  
% Basic discovery: Some windows depend on L, and some windows help define
% L, so the calculation of L is window dependant.
  
% Default values.
info.gauss=0;
info.isfir=0;

% Manually get the list of window names
definput=arg_firwin(struct);
firwinnames =  definput.flags.wintype;

% Create window if string was given as input.
if ischar(g)
  winname=lower(g);
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    g=comp_pgauss(L,1,0,0);
    info.gauss=1;
    info.tfr=1;
   case {'psech','sech'}
    complain_L(L,callfun);
    g=psech(L,1);
    info.tfr=1;
   otherwise
    error('%s: Unknown window type: %s',callfun,winname);
  end;
end;

if iscell(g)
  if isempty(g) || ~ischar(g{1})
    error('First element of window cell array must be a character string.');
  end;
  
  winname=lower(g{1});
  
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    [g,info.tfr]=pgauss(L,g{2:end});
    info.gauss=1;
   case {'psech','sech'}
    complain_L(L,callfun);
    [g,info.tfr]=psech(L,g{2:end});    
   case firwinnames
    g=firwin(winname,g{2:end});
    info.isfir=1;
   otherwise
    error('Unsupported window type.');
  end;
end;

if isnumeric(g)
  if size(g,2)>1
    if size(g,1)>1
      error('%s: g must be a vector',callfun);
    else
      % g was a row vector.
      g=g(:);
    end;
  end;
  g_time=g;
  g=struct();
  g.h=fftshift(g_time);
  info.gl=numel(g_time);
  g.offset=-floor(info.gl/2);  
  g.fc=0;
  g.realonly=0;
  info.wasreal=isreal(g.h);
else

    if isstruct(g)
        if isfield(g,'h') && isnumeric(g.h) && isvector(g.h)
            info.wasreal=isreal(g.h);
            info.gl=length(g.h);
            info.isfir=1;
            
            % In case a filter lacks .offset, treat it as if it was
            % a zero delay FIR window.
            if ~isfield(g,'offset')
                g.h=fftshift(g.h);
                g.offset=-floor(info.gl/2); 
            end
        elseif isfield(g,'H')  && ... 
               ( isnumeric(g.H) && isvector(g.H) || isa(g.H,'function_handle') )
            info.wasreal=isfield(g,'realonly') && g.realonly;
            info.gl=[];
            
            % In case a filter lacks .foff, make a low-pass filter off it.
            if ~isfield(g,'foff')
                g.foff= @(L) 0; 
            end
            
            if ~isempty(L)
                if isa(g.H,'function_handle')
                    g.H=g.H(L);
                end;
                if isa(g.foff,'function_handle')
                    g.foff=g.foff(L);
                end
            end;
        else
            error(['%s: The struct. defining a filter must contain ',...
                   'either .h (numeric vector) or .H (numeric vector, ',...
                   'anonymous fcn) fields.'],callfun);
        end;
    else
        % Information to be determined post creation.
        info.wasreal = isreal(g);
        info.gl      = length(g);
        
        if (~isempty(L) && (info.gl<L))
            info.isfir=1;
        end;
            
    end;
    
end;
    
function complain_L(L,callfun)
  
  if isempty(L)
    error(['%s: You must specify a length L if a window is represented as a ' ...
           'text string or cell array.'],callfun);
  end;


