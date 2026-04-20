function pathStr = makePath(element)
%makePath  Construct the full path of an element using parents
current = element;
pathStr = string(current.Name);
while ~isempty(current.Parent)
    parentName = string(current.Parent.Name);
    pathStr = parentName + "\" + pathStr;
    current = current.Parent;
end
pathStr = "\\" + pathStr;
end