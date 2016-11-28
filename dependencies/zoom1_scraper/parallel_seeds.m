load('../GoogleMapsScraper/panoidAll.mat');

parfor_progress(length(panoidAll) - 500000);
parfor i = 500001:length(panoidAll)
    try
        bfs_download(panoidAll{i});
    catch
        disp(['Fail on: ' num2str(i)]);
    end
    parfor_progress;
end
parfor_progress(0);
