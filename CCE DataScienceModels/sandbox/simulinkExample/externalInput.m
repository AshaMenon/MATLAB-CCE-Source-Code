 function extInp = externalInput(data)
            Tstop = data.StopTimeSpinnerValue;
            T0 = Tstop/20;
            F = data.InputForceMagnitudeSpinnerValue;
           
            
            switch (data.InputForceShapeDropDownValue)
                case 'Gate'
                    tv = [0 T0 T0 2*T0 2*T0 Tstop]';
                    uv = [0  0  F    F    0     0]';
                case 'Step'
                    tv = [0 T0 T0 Tstop]';
                    uv = [0  0  F     F]';
                case 'Ramp'
                    tv = [0 T0 Tstop]';
                    uv = [0  0     F]';
                case 'Bumpy'
                    tv = [0 linspace(T0,Tstop-T0,10) Tstop]';
                    uv = [0 2*F*(rand(1,10)-0.5) 0]';
                otherwise
                    error('invalid input signal type');
            end
            extInp = [tv uv];
        end % externalInput