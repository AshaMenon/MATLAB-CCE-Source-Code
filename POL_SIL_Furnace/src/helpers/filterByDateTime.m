function filteredTbl = filterByDateTime(tbl, startTime, endTime)
   filteredTbl = tbl(and(tbl.Timestamp > startTime, tbl.Timestamp <= endTime), :);
end