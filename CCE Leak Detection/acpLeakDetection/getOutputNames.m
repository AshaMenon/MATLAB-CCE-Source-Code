function outNames = getOutputNames(tagName,configData,stage)

if strcmp(stage,"prep")

    tagName = strrep(tagName,"_","");
    tagName = strrep(tagName,"A:","");

    configNames = lower(configData.Feature);
    outNames = strings(size(tagName,1),1);

    uniqueTags = unique(tagName);

    for c = 1:size(uniqueTags,1)
        if strcmpi(uniqueTags(c),"run")
            tagNameIdx = contains(tagName,uniqueTags(c));
            outNames(tagNameIdx) = "run";
            %configIdx = contains(configNames,uniqueTags(c));
        else
            tagNameIdx = contains(tagName,uniqueTags(c));
            configIdx = contains(configNames,uniqueTags(c));
            outNames(tagNameIdx) = configData.Tag(configIdx);
        end
    end
else
    tagName = extractAfter(tagName,"A:");
    outNames = strrep(tagName,".","_");
end
end