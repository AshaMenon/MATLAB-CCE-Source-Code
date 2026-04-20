classdef (Abstract) ICalculationDbService < handle
    %ICalculationDbService Calculation Database interface class
    %   This is an abstract class that serves as an interface to the
    %   Calculation Record.
    
    methods (Static)
        [calcRecord, calcInput, calcParameter, calcOutput] = findCalculations(obj ,id); %Find calculations with specified id
        [calcRecord, calcInput, calcParameter, calcOutput] = findAllCalculations(obj); %Find all calculations in db
        [calcRecord, calcInput, calcParameter, calcOutput] = collectCalcItemsFromElement(obj, afElement); %Specify AF element of a given calculation, calculation items will be collected
    end
end

