function point = GetNextGood(Tag, CurTime) 
        
        point = struct;

        idxTimes = abs(seconds(Tag.Timestamp - CurTime) )< 1 ;
        Times = Tag.Timestamp(idxTimes);
        Values = Tag.Value(idxTimes);

        try
            idx = Times > CurTime;
            if ~isempty(idx)
                point.Value = Values(idx);
                point.TimeStamp = Times(idx);
            else
                point.Value = [];
                point.TimeStamp  = [];
            end

        catch

            point.Value = [];
            point.TimeStamp  = [];

        end 


end