classdef BasicClass
   %BasicClass Used to test wrapping classes for MLProdServer deployement
   
   properties
      Value {mustBeNumeric}
   end
   
   methods
      function obj = BasicClass(val)
            if nargin == 1
                obj.Value = val;
            end
      end
        
      function r = roundOff(obj)
         r = round([obj.Value],2);
      end
      
      function r = multiplyBy(obj,n)
         r = [obj.Value] * n;
      end
   end
end