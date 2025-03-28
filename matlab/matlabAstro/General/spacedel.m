function TrimStr=spacedel(Str)
%---------------------------------------------------------------------------
% spacedel function                                                 General
% Description: Given a string, recursively delete all spaces.
% Input  : - A string, or a cell array of strings.
% Output : - A trimmed string.
% Tested : Matlab 7.13
%     By : Eran O. Ofek                    Apr 2013
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% See also: spacetrim.m
% Example: spacedel('a   a ');
%          spacedel({'a   a ';' bbbaj   a'});
% Reliable: 2
%---------------------------------------------------------------------------


TrimStr = regexprep(Str,' ','');
if (iscell(TrimStr)),
   If = find(isempty_cell(strfind(TrimStr,' '))==0);
else
   If = strfind(TrimStr,' ');
end
if (~isempty(If)),
   TrimStr=spacetrim(TrimStr);
end



