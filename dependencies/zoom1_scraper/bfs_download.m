function bfs_download()

% Options
seed_panoid = 'uLEMD8veNzg46zPxY2P-ZA'; % random SF panoid
city = 'San Francisco';
outfolder = 'sf_panos';
download_number = 1000; % number of panoramas you want to download
zoom = 1;


setenv('PATH', '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/texbin'); % for wget


if ~exist(outfolder,'dir')
    mkdir(outfolder)
end

% in case this bfs was previously initiated
% files = dir([outfolder '/*.xml']);
% files = {files.name}';
% for i = 1:length(files)
%     files{i} = files{i}(1:end-4);
% end

cnt = 0;

panoidAll = {seed_panoid};
downloadAll = false(1);
neighborAll = true(1);

failed_panoids = {};

while cnt < download_number
    tic;
    try
        %for i=length(downloadAll):-1:1 % dfs
        for i=1:length(downloadAll) % bfs
            if downloadAll(i)==false
                break;
            end
        end
        if downloadAll(i)==true
            break;
        end
        cnt = cnt + 1;
        
        skip = false;
        %check previously downloaded
%         if(ismember(panoidAll{i}, files))
%             skip = true;
%             disp('skipping');
%         end
        
        panoids = downloadPano(panoidAll{i}, outfolder, zoom, skip);
        
        %     figure(1)
        %     subplot(2,1,1);
        %     %imshow(imread(fullfile(panoidAll{i},[panoidAll{i} '.jpg'])));
        %     imshow(imread(fullfile(outfolder, [panoidAll{i} '.jpg'])));
        %     title('image');
        %     subplot(2,1,2);
        %     %imagesc(imread(fullfile(panoidAll{i},[panoidAll{i} '.png'])));
        %     imagesc(imread(fullfile(outfolder, [panoidAll{i} '.png'])));
        %     axis equal;
        %     axis tight;
        %     axis off;
        %     title('depth');
        
        downloadAll(i)=true;
        
        mainIdx = i;
        
        for i=1:length(panoids)
            Idx = find(ismember(panoidAll,panoids{i})==1);
            if isempty(Idx) && length(panoidAll)<download_number
                panoidAll{end+1} = panoids{i};
                downloadAll(end+1) = false;
                Idx = length(downloadAll);
            end
            % the following is slow
            %         if ~isempty(Idx)
            %             neighborAll(Idx,Idx) = true;
            %             neighborAll(mainIdx,Idx) = true;
            %             neighborAll(Idx,mainIdx) = true;
            %         end
        end
        disp([city ' image ' num2str(cnt) ' took ' num2str(toc) ' seconds']);
    catch error
        disp(['Fail on image ' num2str(cnt)]);
        disp(error);
        failed_panoids{end+1,1} = panoidAll{i};
        downloadAll(i) = true; % skipping this failure
        save(['failed_panoids.mat'], 'failed_panoids');       
    end
end
end

% figure(2)
% imagesc(neighborAll);
% axis equal
% axis tight
% set(gca,'YTick',[1:length(panoidAll)])
% set(gca,'YTickLabel',panoidAll)
% title('connectivity graph')
