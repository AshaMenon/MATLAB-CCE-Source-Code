classdef ControllerPlot < ap.AnalysisTechnique
    % Class provides specialised support to ap.controllerPlotFcn
    % Class is derived of ap.AnalysisTechnique and adds support for
    % exporting the result table to CSV
    %
    % Copyright Anglo American Platinum 2013
    
    methods
       
        function this = ControllerPlot(varargin)
            % Constructor
            this = this@ap.AnalysisTechnique(varargin{:});
            
        end
        
        % TO DO: REMOVE THIS TEMPORARY OVERRIDE ONCE PERMANENT SOLUTION HAS
        % BEEN FOUND TO PRESET SEQUENCE OF TABLES AND FIGURES IN TECHNIQUE
        % FUNCTIONS
        function rptString = report(this,description,result,unit,rptDir)
            % Report the results of an analysis technique function.
            % RPTSTRING = report(this,DESCRIPTION,RESULT,UNIT,RPTDIR)
            % The results can be image files and tables.
            
            % Heading: H3
            htmlFmt = '<H3>%s</H3>\n';
            if isempty(result) || isempty(result.Description)
                s = sprintf(htmlFmt, description);
            else
                s = sprintf(htmlFmt, result.Description); % override DESCRIPTION, received from caller
            end
            
            if ~isempty(result)
                if ~isempty(result.TimeSpan)
                % For controllerPlot all reporting results are stored in results.Timespan(1)
                    for tsResult = result.TimeSpan(1)' % result.TimeSpan(:)'
                        % iterate through array of result table objects
                        if ~isempty(tsResult)
                            for kk = 1:numel(tsResult.Result)
                                tableObj = tsResult.Result(kk);
                                % convert any figure objects to image files
                                if ~isempty(tableObj.ImageH)
                                    if ~isempty(tableObj.FigureTitle)
                                        s = sprintf('%s<P><B>%s</B></p>\n', s, tableObj.FigureTitle);
                                    end
                                    if isempty(tableObj.ImgName)
                                        [tableObj.ImgName{1:numel(tableObj.ImageH)}] = '';
                                    end
                                    for k = 1:numel(tableObj.ImageH)
                                        fig = tableObj.ImageH(k);
                                        if ishandle(fig) % Checks whether current figure has been deleted (implies isOptimiseMem == true)
                                            % Create unique ID
                                            figTitle = get(fig,'Children');
                                            figTitle = get(figTitle(end),'Title');
                                            figTitle = figTitle.String;
                                            if iscell(figTitle), figTitle = figTitle{1}; end
                                            strID = dec2bin([figTitle this.ArgumentsToString]); % Use description as unique identifier
                                            for i = 1:size(strID,1)
                                                numID(i) = str2double(strID(i,:));
                                            end
                                            tableObj.ImgName{k} = this.pOPMgrabfigure(fig,sum(numID)+k+kk,rptDir,tableObj.ImgName{k});
                                            drawnow
                                        end
                                        s = sprintf('%s%s\n', s, opm.htmlimage(sprintf('./%s', tableObj.ImgName{k})));
                                    end
                                end
                            end
                        end
                    end
                end
                for tsResult = result.TimeSpan(:)'
                    % iterate through array of result table objects
                    % report tables
                    if ~isempty(tsResult)
                        for kk = 1:numel(tsResult.Result)
                            tableObj = tsResult.Result(kk);
                            if isempty(strfind(lower(tableObj.Name),'treemap'))
                                if ~isempty(tableObj.ReportTitle)
                                    % add table title
                                    tblTitle = tableObj.ReportTitle;
                                elseif kk == 1
                                    tblTitle = '';
                                elseif kk > 1
                                    tblTitle = ' ';
                                end

                                if ~isempty(tableObj.Table)
                                    s = sprintf('%s%s\n', s, opm.htmltable(tableObj.Table, tblTitle, true, '%g', tableObj.IsStaticTable));
                                end
                            end
                            
                        end
                    end
                end                
            end
            
            % Always end with a blank line
            rptString = sprintf('%s\n', s);
        end
        
    end
    
end
