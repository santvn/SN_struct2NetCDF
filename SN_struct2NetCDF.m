% SN_struct2NetCDF converts MATLAB Struct to netCDF file
%
% Usage: SN_struct2NetCDF(filename,structvar)
%
% If there are sub struct or cell items included, then different files will
% be created because netCDF doesn't support such structure really.
% The main netCDF file will be given a string under the variable name with
% a file name point to the sub structure or cell items
%
% Created: San Nguyen 2014 04 30
% Updated: San Nguyen 2014 05 03
%

function SN_struct2NetCDF(filename,myStruct)
if (exist(filename,'file'))
    delete(filename);
end
struct2NetCDF(filename,myStruct)
end
function struct2NetCDF(filename,myStruct,varname)
[p, f, e] = fileparts(filename);

if isstruct(myStruct) && (numel(myStruct) > 1 || (exist('varname','var') && (ischar(varname) && ~isempty(varname))))
    if (exist('varname','var') && (ischar(varname) && ~isempty(varname)))
        digits = ceil(log10(numel(myStruct)+1));
        sprintf_command = sprintf('%s0%d%s','%',digits,'d');
        
        % for each structure, write an netCDF file
        fname_array = char(zeros(numel(myStruct),numel([f '-' sprintf(sprintf_command,1) e])));
        for i = 1:numel(myStruct)
            tmp_fname = [p '/' f '-' sprintf(sprintf_command,i) e];
            fname_array(i,:) = [f '-' sprintf(sprintf_command,i) e];
            struct2NetCDF(tmp_fname,myStruct(i));
        end
        another_tmp_fname = sprintf('%s_%s',tmp_fname,datestr(now,'yyyymmddHHMMSSFFF'));
        while exist(another_tmp_fname,'file')
            another_tmp_fname = sprintf('%s_%s',tmp_fname,datestr(now+1,'yyyymmddHHMMSSFFF'));
        end
        nccreate(another_tmp_fname,varname,...
                         'Dimensions', {[varname '_dim1'],size(fname_array,1),[varname '_dim2'],size(fname_array,2)},...
                         'DeflateLevel', 9,...
                         'DataType','char',...
                         'Format','netcdf4_classic',...
                         'Shuffle',false);
        finfo = ncinfo(another_tmp_fname,varname);
        ncwriteschema(filename,finfo); 
        ncwrite(filename,varname,fname_array);
        delete(another_tmp_fname);
        return;
    end
    
    % if varname doesn't exist, we assume that it's just an array of
    % structure not part of any larger structure
    digits = ceil(log10(numel(myStruct)));
    sprintf_command = sprintf('%s0%d%s','%',digits,'d');
    % for each structure, write an netCDF file
    
    for i = 1:numel(myStruct)
        tmp_fname = [p '/' f '-' sprintf(sprintf_command,i) e];
        struct2NetCDF(tmp_fname,myStruct(i));
        another_tmp_fname = sprintf('%s_%s',tmp_fname,datestr(now,'yyyymmddHHMMSSFFF'));
        nccreate(another_tmp_fname,sprintf(sprintf_command,i),...
                         'Dimensions', {'dim1',1,'dim2',numel([f '-' sprintf(sprintf_command,i) e])},...
                         'DeflateLevel', 9,...
                         'DataType','char',...
                         'Format','netcdf4_classic',...
                         'Shuffle',false);
        finfo = ncinfo(another_tmp_fname,sprintf(sprintf_command,i));
        ncwriteschema(filename,finfo);
        ncwrite(filename,sprintf(sprintf_command,i),[f '-' sprintf(sprintf_command,i) e],[1 1]);
        ncwriteatt(filename,sprintf(sprintf_command,i),'class',class(myStruct(i)));
        delete(another_tmp_fname);
    end
    ncwriteatt(filename,'/','class',class(myStruct));
    return;
end

if isstruct(myStruct)
    % if varname doesn't exist, we assume that it's just an array of
    % structure not part of any larger structure
    varNames = fieldnames(myStruct);
    for i = 1:numel(varNames)
        
%         try
            tmp_fname = [p '/' f '.' varNames{i} e];
            struct2NetCDF(tmp_fname,myStruct.(varNames{i}),varNames{i});
            if iscell(myStruct.(varNames{i}))
                finfo.Name   = varNames{i};
                finfo.Format = 'netcdf4_classic';
                finfo.Dimensions(1).Name   = [varNames{i} '_dim1'];
                finfo.Dimensions(1).Length = 1;
                finfo.Dimensions(2).Name   = [varNames{i} '_dim2'];
                finfo.Dimensions(2).Length = numel([f '.' varNames{i} e]);
                finfo.Datatype = 'char';
                finfo.DeflateLevel = 9;
                finfo.Shuffle = false;
                finfo.ChunkSize=[1 numel([f '.' varNames{i} e])];
            else
                finfo = ncinfo(tmp_fname,varNames{i});
            end
            ncwriteschema(filename,finfo);
            if ~isempty(myStruct.(varNames{i}))
                if islogical(myStruct.(varNames{i}))
                    ncwrite(filename,varNames{i},uint8(myStruct.(varNames{i})));
                elseif isstruct(myStruct.(varNames{i}))
                    ncwrite(filename,varNames{i},ncread(tmp_fname,varNames{i}));
                elseif iscell(myStruct.(varNames{i}))
                    ncwrite(filename,varNames{i},[f '.' varNames{i} e]);
                else
                    ncwrite(filename,varNames{i},myStruct.(varNames{i}));
                end
            end
            if ~(iscell(myStruct.(varNames{i})))
                delete(tmp_fname);
            end
%         catch err
%             throw(err);
%         end
        ncwriteatt(filename,varNames{i},'class',class(myStruct.(varNames{i})));
    end
    ncwriteatt(filename,'/','class',class(myStruct));
    return;
end

if iscell(myStruct)
    if (exist('varname','var') && (ischar(varname) && ~isempty(varname)))
        digits = ceil(log10(numel(myStruct)+1));
        sprintf_command = sprintf('%s0%d%s','%',digits,'d');
        % for each structure, write an netCDF file
        fname_array = char(zeros(numel(myStruct),numel([f '-' sprintf(sprintf_command,1) e])));
        for i = 1:numel(myStruct)
            try
                tmp_fname = [p '/' f '-' sprintf(sprintf_command,i) e];
                fname_array(i,:) = [f '-' sprintf(sprintf_command,i) e];
                struct2NetCDF(tmp_fname,myStruct{i},sprintf(sprintf_command,i));
                finfo = ncinfo(tmp_fname,sprintf(sprintf_command,i));
                ncwriteschema(filename,finfo);
                if ~isempty(myStruct{i})
                    if islogical(myStruct{i})
                        ncwrite(filename,sprintf(sprintf_command,i),int8(myStruct{i}));
                        delete(tmp_fname);
                    elseif isstruct(myStruct{i}) || iscell(myStruct{i})
                        ncwrite(filename,sprintf(sprintf_command,i),ncread(tmp_fname,sprintf(sprintf_command,i)));
                    else
                        ncwrite(filename,sprintf(sprintf_command,i),myStruct{i});
                        delete(tmp_fname);
                    end
                end
                ncwriteatt(filename,sprintf(sprintf_command,i),'class',class(myStruct{i}));
            catch err
                throw(err);
            end
        end
        ncwriteatt(filename,'/','class',class(myStruct));
        return;
    end
    
    % if varname doesn't exist, we assume that it's just an array of
    % structure not part of any larger structure
    digits = ceil(log10(numel(myStruct)+1));
    sprintf_command = sprintf('%s0%d%s','%',digits,'d');
    % for each structure, write an netCDF file
    fname_array = char(zeros(numel(myStruct),numel([f '-' sprintf(sprintf_command,1) e])));
    for i = 1:numel(myStruct)
        try
            tmp_fname = [p '/' f '-' sprintf(sprintf_command,i) e];
            fname_array(i,:) = [f '-' sprintf(sprintf_command,i) e];
            struct2NetCDF(tmp_fname,myStruct{i},sprintf(sprintf_command,i));
            finfo = ncinfo(tmp_fname,sprintf(sprintf_command,i));
            ncwriteschema(filename,finfo);
            if ~isempty(myStruct{i})
                if islogical(myStruct{i})
                    ncwrite(filename,sprintf(sprintf_command,i),int8(myStruct{i}));
                elseif isstruct(myStruct{i}) || iscell(myStruct{i})
                    ncwrite(filename,sprintf(sprintf_command,i),ncread(tmp_fname,sprintf(sprintf_command,i)));
                else
                    ncwrite(filename,sprintf(sprintf_command,i),myStruct{i});
                end
            end
            if ~(iscell(myStruct{i}))
                delete(tmp_fname);
            end
        catch err
            throw(err);
        end
    end
    ncwriteatt(filename,'/','class',class(myStruct));
    return;
end

if (exist('varname','var') || (ischar(varname) && ~isempty(varname)))

    % regular array data
    if (numel(size(myStruct)) > 2)
        Dimensions = cell(1,numel(size(myStruct))*2);
        Dimensions(1,1:4) = {[varname '_dim1'], size(myStruct,1), [varname '_dim2'], size(myStruct,2)};
        for i = 3:numel(size(myStruct))
            Dimensions(1,i*2-1) = {sprintf('%s_dim%d',varname,i)};
            Dimensions(1,i*2) = {size(myStruct,i)};
        end
    else
        Dimensions = {[varname '_dim1'], size(myStruct,1), [varname '_dim2'], size(myStruct,2)};
    end
    try
        nccreate(filename,varname,...
                 'Dimensions', Dimensions,...
                 'DeflateLevel', 9,...
                 'DataType',getNetCTDDataType(myStruct),...
                 'Format','netcdf4_classic',...
                 'Shuffle',false);
    catch err
        error('struct2NetCDF:fileExists','The file already exists');
    end

    return;
end
error('struct2NetCDF:varnameInvalid','Not a valid variable name');

end

function NetCFDDataType = getNetCTDDataType(var)
if islogical(var)
    NetCFDDataType = 'int8';
else
    NetCFDDataType = class(var);
end
    
% switch class(var)
%     case 'double'
%         NetCTDDataType = 'NC_DOUBLE';
%     case 'single'
%         NetCTDDataType = 'NC_FLOAT';
%     case 'int64'
%         NetCTDDataType = 'NC_INT64';
%     case 'uint64'
%         NetCTDDataType = 'NC_UINT64';
%     case 'int32'
%         NetCTDDataType = 'NC_INT';
%     case 'uint32'
%         NetCTDDataType = 'NC_UINT';
%     case 'int16'
%         NetCTDDataType = 'NC_SHORT';
%     case 'uint16'
%         NetCTDDataType = 'NC_USHORT';
%     case 'int8'
%         NetCTDDataType = 'NC_BYTE';
%     case 'uint8'
%         NetCTDDataType = 'NC_UBYTE';
%     case 'char'
%         NetCTDDataType = 'NC_CHAR';
% end

end