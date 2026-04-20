function [dVal] = convertEUsimple(expectedEU,value,eu,sg,comp)
%CONVERTEU Convert engineering units
%   [dVal] = convertEUsimple(expectedEU,value,eu,sg,comp) converts eu of value to expectedEU
%
%   Expected inputs: expectedEU, value, eu, sg, comp
% 
% G2 requirement for engineering unit conversion

dVal = [];
switch lower(expectedEU)
    case '%', dVal = value * 100;
    case 'fraction', dVal = value / 100;
    case 'float', dVal = value * 1.0;
    case 'quantity', dVal = value;
    case 'integer', dVal = round(value);
end
        
if isempty(dVal)
    switch eu
%         {---POWER UNITS}
        case 'W'
            switch expectedEU
                case 'kW', dVal = value / 1000;
                case 'MW', dVal = value / 1000000;
            end
        case 'kW'
            switch expectedEU
                case 'W', dVal = value * 1000;
                case 'MW' ,dVal = value / 1000;
            end
        case 'MW'
            switch expectedEU
                case 'W', dVal = value * 1000000;
                case 'kW', dVal = value * 1000;
            end
%         {--- PRESSURE UNITS}
        case 'atm'
            switch expectedEU
                case 'bar', dVal = value * 1.01325;
                case 'Pa', dVal = value * 101325;
                case 'kPa', dVal = value * 101.325;
                case 'psi', dVal = value * 14.696;
            end
        case 'bar'
            switch expectedEU
                case 'atm', dVal = value / 1.01325;
                case 'Pa', dVal = value * 100000;
                case 'kPa', dVal = value * 100;
                case 'psi', dVal = value * 14.504;
            end
        case 'Pa'
            switch expectedEU
                case 'atm', dVal = value / 101325;
                case 'bar', dVal = value / 100000;
                case 'kPa', dVal = value / 1000;
                case 'psi', dVal = value * 14.504 / 100000; 
            end
        case 'kPa'
            switch expectedEU
                case 'atm', dVal = value / 101.325;
                case 'bar', dVal = value / 100;
                case 'Pa', dVal = value * 1000;
                case 'psi', dVal = value * 0.14504;
            end
        case 'psi'
            switch expectedEU
                case 'atm', dVal = value / 14.696;
                case 'bar', dVal = value / 14.504;
                case 'Pa', dVal = value * 100000 / 14.504;
                case 'kPa', dVal = value / 0.14504; 
            end
%         {--- MASS/WEIGHT UNITS}
        case 'mg'
            switch expectedEU
                case 'g', dVal = value / 1000;
                case 'kg', dVal = value / 1000000;
                case 'ton', dVal = value / 1000000000;
                case 'lb', dVal = value * 2.205 / 1000000;
                case 'oz', dVal = value * 35.274 / 1000000;
            end
        case 'g'
            switch expectedEU
                case 'mg', dVal = value * 1000;
                case 'kg', dVal = value / 1000;
                case 'ton', dVal = value / 1000000;
                case 'lb', dVal = value * 2.205 / 1000; 
                case 'oz', dVal = value * 35.274 / 1000; 
            end
        case 'kg'
            switch expectedEU
                case 'mg', dVal = value * 1000000;
                case 'g', dVal = value * 1000;
                case 'ton', dVal = value / 1000;
                case 'lb', dVal = value * 2.205;
                case 'oz', dVal = value * 35.274; 
            end
        case 'ton'
            switch expectedEU
                case 'mg', dVal = value * 1000000000;
                case 'g', dVal = value * 1000000;
                case 'kg', dVal = value * 1000;
                case 'lb', dVal = value * 2205; 
            	case 'oz', dVal = value * 35274; 
            end
        case 'lb'
            switch expectedEU
                case 'mg', dVal = value / 2.205 * 1000000;
                case 'g', dVal = value / 2.205 * 1000;
                case 'kg', dVal = value / 2.205;
                case 'ton', dVal = value / 2205; 
                case 'oz', dVal = value * 16;
            end
        case 'oz'
            switch expectedEU
            	case 'mg', dVal = value / 35.274 * 1000000;
                case 'g', dVal = value / 35.274 * 1000;
                case 'kg', dVal = value / 35.274;
                case 'ton', dVal = value / 35274; 
                case 'lb', dVal = value / 16;
            end
%         {--- LENGTH UNITS}
        case 'um'
            switch expectedEU
            	case 'mm', dVal = value / 1000;
                case 'cm', dVal = value / 10000;
                case 'm', dVal = value/ 1000000;
                case 'in', dVal = value * 39.37 / 1000000;
                case 'ft', dVal = value * 3.281 / 1000000; 
            end
        case 'mm'
            switch expectedEU
                case 'um', dVal = value * 1000;
                case 'cm', dVal = value / 10;
                case 'm',  dVal = value / 1000;
                case 'in', dVal = value * 39.37 / 1000;
                case 'ft', dVal = value * 3.281 / 1000; 
            end
        case 'cm'
            switch expectedEU
                case 'um', dVal = value * 10000;
                case 'mm', dVal = value * 10;
                case 'm',  dVal = value / 100;
                case 'in', dVal = value * 39.37 / 100;
                case 'ft', dVal = value * 3.281 / 100; 
            end
        case 'm'
            switch expectedEU
                case 'um', dVal = value * 1000000;
                case 'mm', dVal = value * 1000;
                case 'cm', dVal = value * 100;
                case 'in', dVal = value * 39.37;
                case 'ft', dVal = value * 3.281;
            end
        case 'in'
            switch expectedEU
                case 'um', dVal = value / 39.37 * 1000000;
                case 'mm', dVal = value / 39.37 * 1000;
                case 'cm', dVal = value / 39.37 * 100;
                case 'm', dVal = value / 39.37;
                case 'ft', dVal = value / 12;
            end
        case 'ft'
            switch expectedEU
                case 'um', dVal = value / 3.281 * 1000000;
                case 'mm', dVal = value / 3.281 * 1000;
                case 'cm', dVal = value / 3.281 * 100;
                case 'm', dVal = value / 3.281;
                case 'in', dVal = value * 12;
            end
%         {--- VOLUMETRIC UNITS}
        case 'mm^3'
            switch expectedEU
                case 'l', dVal = value / 1000000;
                otherwise
                    if ~comp, dVal = convertEUComposite(value, eu, expectedEU, sg); end
            end
        case 'cm^3'
            switch expectedEU
                case 'l', dVal = value / 1000;
                otherwise
                    if ~comp, dVal = convertEUComposite(value, eu, expectedEU, sg); end
            end
        case 'l'
            switch expectedEU 
                case 'mm^3', dVal = value * 1000000;
                case 'cm^3', dVal = value * 1000;
                case 'm^3', dVal = value / 1000;
            end
        case 'm^3'
            switch expectedEU
                case 'l', dVal = value * 1000;
                otherwise
                    if ~comp, dVal = convertEUComposite(value, eu, expectedEU, sg); end
            end
%         {--- DENSITY UNITS}
        case 'sg'
            switch expectedEU
                case 'ton/m^3', dVal = value;
                case 'kg/l', dVal = value;
                case 'kg/m^3', dVal = value * 1000;
                case '%Sol', dVal = 100 * (value - 1)/(sg - 1);
                case 'fractionSol', dVal = (value - 1)/(sg - 1); 
            end
        case '%Sol'
            switch expectedEU
                case 'kg/m^3', dVal = 1000 * (value * (sg - 1) / 100 + 1);
                case 'ton/m^3', dVal = value * (sg - 1) / 100 + 1;
                case 'kg/l', dVal = value * (sg - 1) / 100 + 1;
                case 'sg', dVal = value * (sg - 1) / 100 + 1; 
                case 'fractionSol', dVal = value / 100;
            end
        case 'fractionSol'
            switch expectedEU
                case 'kg/m^3', dVal = 1000 * (value * (sg - 1) + 1);
                case 'ton/m^3', dVal = value * (sg - 1) + 1;
                case 'kg/l', dVal = value * (sg - 1) + 1;
                case 'sg', dVal = value * (sg - 1) + 1; 
                case '%Sol', dVal = value * 100;
            end
        case 'ton/m^3'
            switch expectedEU
                case 'sg', dVal = value;
                case 'kg/m^3', dVal = value * 1000; 
                case 'kg/l', dVal = value;
                case '%Sol', dVal = 100 * (value - 1)/(sg - 1); 
                case 'fractionSol', dVal = (value - 1)/(sg - 1); 
            end
        case 'kg/l'
            switch expectedEU
                case 'sg', dVal = value;
                case 'kg/m^3', dVal = value * 1000;
                case 'ton/m^3', dVal = value;
                case '%Sol', dVal = 100 * (value - 1)/(sg - 1); 
                case 'fractionSol', dVal = (value - 1)/(sg - 1); 
            end
        case 'kg/m^3'
            switch expectedEU
                case 'sg', dVal = value / 1000;
                case 'ton/m^3', dVal = value / 1000;
                case '%Sol', dVal = 100 * (value / 1000 - 1)/(sg - 1); 
                case 'fractionSol', dVal = (value / 1000 - 1)/(sg - 1); 
            end
%         {--- ELECTRICITY UNITS}
        case 'V'
            switch expectedEU
            	case 'kV', dVal = value / 1000;
            end
        case 'kV'
            switch expectedEU 
                case 'V', dVal = value * 1000;
            end
        case 'A'
            switch expectedEU 
                case 'kA', dVal = value / 1000;
            end
        case 'kA'
            switch expectedEU
                case 'A', dVal = value * 1000;
            end
        case 'J'
            switch expectedEU
                case 'kJ', dVal = value / 1000;
                case 'MJ', dVal = value / 1000000;
            end
        case 'kJ'
            switch expectedEU
                case 'J', dVal = value * 1000;
                case 'MJ', dVal = value / 1000;
            end
        case 'MJ'
            switch expectedEU
                case 'J', dVal = value * 1000000;
                case 'kJ', dVal = value * 1000;
            end
%         {---TEMPERATURE UNITS}
        if comp, a = 0; b = 0;
        else a = 32; b = 273; end
        case 'degC'
            switch expectedEU 
            	case 'degF', dVal = value*(9/5) + a;
                case 'degK', dVal = value + b;
                case 'WValT100', dVal = value * 32767 / 100; 
                case 'WValT150', dVal = value * 32767 / 150;   
                case 'WValT500', dVal = value * 32767 / 500; 
                case 'WValT800', dVal = value * 32767 / 800;
                case 'WValT1300', dVal = value * 32767 / 1300; 
            end
        case 'degF'
            switch expectedEU 
                case 'degC', dVal = (value - a)*(5/9);
                case 'degK', dVal = (value - a)*(5/9) + b;
            end
        case 'degK'
            switch expectedEU
                case 'degC', dVal = value - b; 
                case 'degF', dVal = (value - b)*(9/5) + a;
            end
        case 'WValT100'
            switch expectedEU
                case 'degC', dVal = value * 100 / 32767;
            end
        case 'WValT150'
            switch expectedEU
                case 'degC', dVal = value * 150 / 32767;
            end
        case 'WValT500'
            switch expectedEU
                case 'degC', dVal = value * 500 / 32767;
            end
        case 'WValT800'
            switch expectedEU
                case 'degC', dVal = value * 800 / 32767;
            end
        case 'WValT1300'
            switch expectedEU
                case 'degC', dVal = value * 1300 / 32767;
            end
%         {--- FORCE UNITS}
        case 'N'
            switch expectedEU 
                case 'kN', dVal = value / 1000;
            end
        case 'kN'
            switch expectedEU 
                case 'N', dVal = value * 1000;
            end
%         {--- TIME UNITS}
        case 'ms'
        	switch expectedEU
            	case 's', dVal = value / 1000;
                case 'min', dVal = value / 60000;
                case 'hr', dVal = value / 3600000;
                case 'shift', dVal = (value / 3600000) / 8;
                case 'day', dVal = (value / 3600000) / 24;
            end
        case 's'
            switch expectedEU
            	case 'ms', dVal = value * 1000;
                case 'min', dVal = value / 60;
                case 'hr', dVal = value / 3600;
                case 'shift', dVal = (value / 3600) / 8;
                case 'day', dVal = (value / 3600) / 24;
            end
        case 'min'
            switch expectedEU
            	case 'ms', dVal = value * 60 * 1000;
                case 's', dVal = value * 60;
                case 'hr', dVal = value / 60;
                case 'shift', dVal = (value / 60) / 8;
                case 'day', dVal = (value / 60) / 24;
            end
        case 'hr'
            switch expectedEU
                case 'ms', dVal = value * 3600 * 1000;
                case 's', dVal = value * 3600;
                case 'min', dVal = value * 60;
                case 'shift', dVal = value / 8;
                case 'day', dVal = value / 24;
            end
        case 'shift'
            switch expectedEU
            	case 'day', dVal = value / 3;
                case 'hour', dVal = value * 8;
                case 'min', dVal = value * 8 * 60;
                case 's', dVal = value * 8 * 3600;
                case 'ms', dVal = value * 8 * 3600 * 1000;
            end
        case 'day'
            switch expectedEU
                case 'ms', dVal = value * 24 * 3600 * 1000;
                case 's', dVal = value * 24 * 3600;
                case 'min', dVal = value * 24 * 60;
                case 'hr', dVal = value * 24;
                case 'shift', dVal = value * 3;
            end
%         {--- QUANTITY UNITS}
        case 'integer'
        	switch expectedEU 
            	case 'float', dVal = value * 1.0;
                case 'quantity', dVal = value;
            end
        case 'float'
        	switch expectedEU 
            	case 'integer', dVal = round(value);
                case 'quantity', dVal = value;
            end
        case 'quantity'
        	switch expectedEU 
            	case 'integer', dVal = round(value);
                case 'float', dVal = value;
            end
        case '%'
        	switch expectedEU
            	case 'integer', dVal = round(value / 100);
                case 'float', dVal = value / 100.0;
                case 'quantity', dVal = value / 100;
            end
        case 'fraction'
        	switch expectedEU 
            	case 'float', dVal = value;
                case 'quantiy', dVal = value;
            end
    end
end