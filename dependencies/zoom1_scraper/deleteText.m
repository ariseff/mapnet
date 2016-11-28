%% deleting txt depths

load('../GoogleMapsScraper/panoidAll.mat');

parfor i = 1:length(panoidAll)
  filename = ['/data/scraped_gsv/zoom1_panos/' panoidAll{i} '/' panoidAll{i} '.txt'];
  if(exist(filename, 'file'))
    delete(filename);
    disp(['Deleted: ' num2str(i)]);
  else
    disp(['Nonexistent: ' num2str(i)]);
  end
end
