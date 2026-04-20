function val = getCategoriesString(netObj)

catStr = string(netObj.CategoriesString);
if strlength(catStr)==0
    val = "";
else
    val = extractBefore(catStr, strlength(catStr));
end
