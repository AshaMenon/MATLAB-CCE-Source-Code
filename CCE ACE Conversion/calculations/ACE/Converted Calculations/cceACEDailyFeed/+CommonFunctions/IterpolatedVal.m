function Val = IterpolatedVal(Tag, CurTime) 

        Val = struct;

        try
            Ev1 = CommonFunctions.GetLastGood(Tag, CurTime); % Incase there is a value at the current time
            Ev2 = CommonFunctions.GetNextGood(Tag, CurTime);

            if ~isnan(Ev1.Value) 
                if round(Ev1.TimeStamp, 3) == round(CurTime, 3) % There was a value at the requested timestamp

                    Val = Ev1;
                else
                    Val.Value = string((Ev1.Value) + ((Ev2.Value) - (Ev1.Value)) / (Ev2.TimeStamp - Ev1.TimeStamp) * (CurTime - Ev1.TimeStamp));

                    Val.TimeStamp = CurTime;

                    if ~isnumeric(Val.Value) 
                        ME = MException("Not numeric");
                        throw(ME)
                    end
                end 
            end 
        catch 
            Val = [];
        end 

end