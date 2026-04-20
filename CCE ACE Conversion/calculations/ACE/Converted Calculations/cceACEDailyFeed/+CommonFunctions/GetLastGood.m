function point = GetLastGood(Tag, CurTime) 

  if  ~isempty(CurTime)
        point = struct;
        idxTimes = abs(days(Tag.Timestamp - CurTime)) < 0.1;
        Times = Tag.Timestamp(idxTimes);
        Values = Tag.Value(idxTimes);

        try
            idx = Times <= CurTime; %|| seconds(Times-CurTime)<1;
            if ~isempty(idx)
                point.Value = Values(idx);
                point.TimeStamp = Times(idx);
            else
                 point.Value = [];
                 point.TimeStamp = [];
            end

        catch

            point.Value = [];
            point.TimeStamp = [];
        end 
  else 

              point.Value = [];
            point.TimeStamp = [];

  end

end