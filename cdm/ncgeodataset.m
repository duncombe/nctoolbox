classdef ncgeodataset < cfdataset
    
    properties (SetAccess = private, GetAccess = private)
        ncvariables
    end
    
    methods
        
        %%
        function obj = ncgeodataset(url)
            % NCGEODATSET  Constructor. Instantiates a NetcdfDataset pointing to the
            % datasource specified by 'url' and uses that as the underlying
            % dataaccess API. When instantiated, the names of all variables
            % are fetched and stored in the 'variables' property. This can be
            % use to open local files, files stored on an HTTP server and
            % OpenDAP URLs.
            obj = obj@cfdataset(url);
            
            % Java hashTable doens't store matlab objects SO we'll use
            % poor man's hash of a n x 2 cell array
            obj.ncvariables = cell(length(obj.variables), 2);
            for i = 1:length(obj.variables)
                obj.ncvariables{i, 1} = obj.variables{i};
            end
        end
        
        %%
        function v = geovariable(obj, variableName)
            % NCGEODATASET.VARIABLE Returns an ncgeovariable object that provides
            % advanced access to the data contained within that variable based on geo-
            % graphically located data.
            %
            % Usage:
            %    v = ncgeodataset.variable(variableName)
            %
            % Arguments:
            %    variableName = A string name of the variable you want to
            %    retrieve. you can use cfdataset.variables to obtain a list
            %    of all variables available.
            %
            % Returns:
            %
            %    v = an instance of ncgeovariable
            %
            
            % Check to see if we've aready fetched the variable of interest
            v = value4key(obj.ncvariables, variableName);
            if isempty(v)
                
                % ---- Attempt to fetch the variables representing the axes
                % for the variable of interest. We'll try the CF
                % conventions first and if that's not available we'll try
                % COARDS.
                
                att = obj.attributes(variableName);
                coordinates = value4key(att, 'coordinates');
                
                if ~isempty(coordinates)
                    % ---- Look for CF 'coordinates' attribute
                    
                    % Parse the string into white space delimited parts
                    jls = java.lang.String(coordinates);
                    p = jls.split(' ');                   % java.lang.String[]
                    axesVariableNames = cell(size(p));    % cell version of p
                    for i = 1:length(p)
                        axesVariableNames{i} = char(p(i));
                    end
                    
                else
                    % ---- Look for COARDS conventions. If any coordinate
                    % dimensions are missing we don't bother looking any
                    % up.
                    axesVariableNames = obj.axes(variableName);
                    if ~isempty(axesVariableNames)
                        for i = 1:length(axesVariableNames)
                            if isempty(axesVariableNames{i})
                                axesVariableNames = {};
                                break;
                            end
                        end
                    end
                    
                end
                
                % Testing combining the axes from both the variable axes and dataset axes
                % maybe temporary stop gap...?
                for i = 1:length(axesVariableNames)
                  axesVariables{i,1} = axesVariableNames{i};
                end
                
                dsaxes = obj.axes(variableName);
                alreadythere = 0;
                for i = 1:length(dsaxes)
                  if ~isempty(dsaxes{i})
                    for j = 1:length(axesVariables)
                      if strcmp(axesVariables{j}, dsaxes{i})
                        alreadythere = 1;
                      end
                    end
                    if ~alreadythere
                      axesVariables{length(axesVariables)+1,1} = dsaxes{i};
                    end
                  end
                end
                
                v = ncgeovariable(obj, variableName, axesVariables);
                if ~isempty(v)
                    for i = 1:length(obj.variables)
                        if strcmp(obj.ncvariables{i, 1}, variableName)
                            obj.ncvariables{i, 2} = v;
                            break;
                        end
                    end
                end
                
            end
            
            
        end
        
%% Should be called as ncpoint(nc), etc.
%
%         function p = point(obj)
%             p = ncpoint(obj);       
%         end
%         
%         function r = rgrid(obj)
%             r = ncrgrid(obj);
%         end
%         
%         function c = cgrid(obj)
%             c = nccgrid(obj);
%         end
%         
%         function sg = sgrid(obj)
%             sg = ncsgrid(obj);
%         end
%         
%         function ug = ugrid(obj)
%             ug = ncugrid(obj);
%         end
        
    end  % methods end
    
    
end % class end