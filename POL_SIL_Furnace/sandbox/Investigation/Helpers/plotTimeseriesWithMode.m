function  plotTimeseriesWithMode(tags, dataTbl, label, plotTitle)
    %UNTITLED5 Summary of this function goes here
    %   Detailed explanation goes here

    figure('WindowState','maximized')
    for i = 1:length(tags)
       p(i) = plot(dataTbl.Timestamp, dataTbl.(tags{i}));
       hold on
    end
    indices1 = dataTbl.mode == 'Off';
    indices2 = dataTbl.mode == 'Normal';
    indices3 = dataTbl.mode == 'Ramp';
    indices4 = dataTbl.mode == 'Lost Capacity';
    
    ymin = min( dataTbl{:,tags} ,[], "all" );
    ymax = max( dataTbl{:,tags} ,[], "all" );
   
    [p1, p2, p3, p4] = shadingClassification(indices1,indices2, indices3, indices4, dataTbl, ymin, ymax);


    ylabel(label)
    legend([p, p1, p2, p3, p4], {tags{:}, 'Off', 'Normal', 'Ramp', 'Lost Capacity'})
    title(plotTitle)

end