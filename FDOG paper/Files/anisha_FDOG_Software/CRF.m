clear all;
imsdir ='iccv09Data\images';
labdir = 'iccv09Data\labels';
nvals  = 8;
rez    = .2; % how much to reduce resolution
rho    = .5; % (1 = loopy belief propagation) (.5 = tree-reweighted belief propagation)

oldfolder=cd(imsdir);
ims_names = dir( '*.jpg');

cd(oldfolder);
oldfolder=cd(labdir);
lab_names = dir('*regions.txt');

cd(oldfolder);

N = length(ims_names);
ims    = cell(N,1);
labels = cell(N,1);


feat_params = {{'patches',0},{'position',1},{'fourier',1},{'hog',8}};




fprintf('loading data and computing feature maps...\n');
j=1;
for n=1:N
    % load data
    oldfolder=cd(labdir);
    lab = importdata( lab_names(n).name);
    
    cd(oldfolder);
    
    oldfolder=cd(imsdir);
   
    im  = im2double(imread(( ims_names(n).name)));
    
    cd(oldfolder);
    
    ims{n}  = im;
    labels0{n} = max(0,lab+1);

    % compute features
    feats{n}  = featurize_im(ims{n},feat_params);

    % reduce resolution for speed
    ims{n}    = imresize(ims{n}   ,rez,'bilinear');
    feats{n}  = imresize(feats{n} ,rez,'bilinear');
    labels{n} = imresize(labels0{n},rez,'nearest');

    % reshape features
    [ly lx lz] = size(feats{n});
    feats{n} = reshape(feats{n},ly*lx,lz);
    display(j)
    j=j+1;
end



model_hash = repmat({[]},1000,1000);
fprintf('building models...\n')
for n=1:N
    [ly lx lz] = size(ims{n});
    if isempty(model_hash{ly,lx});
        model_hash{ly,lx} = gridmodel(ly,lx,nvals);
    end
end

models = cell(N,1);

for n=1:N
    [ly lx lz] = size(ims{n});
    models{n} = model_hash{ly,lx};
end

edge_params = {{'const'},{'diffthresh'},{'pairtypes'}};
fprintf('computing edge features...\n')
efeats = cell(N,1);
parfor n=1:N
    efeats{n} = edgeify_im(ims{n},edge_params,models{n}.pairs,models{n}.pairtype);
end

fprintf('splitting data into a training and a test set...\n')
k = 1;
[who_train who_test] = kfold_sets(N,5,k);

ims_train     = ims(who_train);
feats_train   = feats(who_train);
efeats_train  = efeats(who_train);
labels_train  = labels(who_train);
labels0_train = labels0(who_train);
models_train  = models(who_train);

ims_test     = ims(who_test);
feats_test   = feats(who_test);
efeats_test  = efeats(who_test);
labels_test  = labels(who_test);
labels0_test = labels0(who_test);
models_test  = models(who_test);


loss_spec = 'trunc_cl_trwpll_5';


fprintf('training the model (this is slow!)...\n')
crf_type  = 'linear_linear';
%options.viz         = @viz;
options.print_times = 1; % since this is so slow, print stuff to screen
options.gradual     = 1; % use gradual fitting
options.maxiter     = 1000;
options.rho         = rho;
options.reg         = 1e-4;
options.opt_display = 0;
p = train_crf(feats_train,efeats_train,labels_train,models_train,loss_spec,crf_type,options)   %%%%%%----EDIT----------%%%%%




fprintf('get the marginals for test images...\n');
close all
for n=10
    [b_i b_ij] = eval_crf(p,feats_test{n},efeats_test{n},models_test{n},loss_spec,crf_type,rho);

    [ly lx lz] = size(labels_test{n});
    [~,x_pred] = max(b_i,[],1);
    x_pred = reshape(x_pred,ly,lx);

    [ly lx lz] = size(labels0_test{n});
    x       = labels0_test{n};
    % upsample predicted images to full resolution
    x_pred  = imresize(x_pred,size(x),'nearest');
    E(n)   = sum(x_pred(x(:)>0)~=x(x(:)>0));
    T(n)   = sum(x(:)>0);

    [ly lx lz] = size(ims_test{n});
    figure,
    subplot(1,3,3)
    miximshow(reshape(b_i',ly,lx,nvals),nvals);
%     subplot(1,3,2)
%     imagesc(ims_test{n})
%     subplot(1,3,2)
%     miximshow(reshape(labels_test{n},ly,lx),nvals);

    [ly lx lz] = size(labels0_test{n});
%     subplot(1,4,4)
% figure,
%     miximshow(reshape(x_pred,ly,lx),nvals);
   subplot(1,3,1)
   imshow(ims_test{n})
    subplot(1,3,2)
    miximshow(reshape(labels0_test{n},ly,lx),nvals);
    drawnow
end
fprintf('total pixelwise error on test data: %f \n', sum(E)/sum(T))

