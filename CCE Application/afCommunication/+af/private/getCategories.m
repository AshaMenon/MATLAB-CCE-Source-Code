function val = getCategories(netObj)

catStr = string(netObj.CategoriesString);
if strlength(catStr)==0
    val = "";
else
    val = strsplit(extractBefore(catStr, strlength(catStr)), ";");
end
