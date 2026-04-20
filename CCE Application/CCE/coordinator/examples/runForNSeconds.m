function complete = runForNSeconds(nSeconds)
    t0 = tic;
    while toc(t0) < nSeconds
    end
    complete = 'done';
end