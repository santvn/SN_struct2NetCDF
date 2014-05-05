SN_struct2NetCDF
================
% SN_struct2NetCDF converts MATLAB Struct to netCDF file<br/>
%<br/>
% Usage: SN_struct2NetCDF(filename,structvar)<br/>
%<br/>
% If there are sub struct or cell items included, then different files will<br/>
% be created because netCDF doesn't support such structure really.<br/>
% The main netCDF file will be given a string under the variable name with<br/>
% a file name point to the sub structure or cell items<br/>
%<br/>
% Created: San Nguyen 2014 04 30<br/>
% Updated: San Nguyen 2014 05 03<br/>
%
