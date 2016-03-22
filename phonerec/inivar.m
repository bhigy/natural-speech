%Modify input and output dir before starting

% file containing acoustic and articulatory data
datafile = 'nmngu0_dataRecognition_bsil_melfilt_htk_ma_noMAVG.mat';

% file for training and testing splitting.
splitfile = 'nmngu0_splitRecognition_bsil_melfilt_htk_ma_noMAVG.mat';

%probabilities of phone and state unigrams and bigrams 
p_unifile{1} = 'mngu_1gram.arpa';
p_bifile{1} = 'mngu_2gram.arpa';
s_unifile{1} = 'mngu_state1gram.arpa';
s_bifile{1} = 'mngu_state2gram.arpa';

load(splitfile);

% remove silences
removeSil = 1;
% No. of acoustic coefficients
NoAuF = 60;
%No. of raw artiulatory features
NoMF = 36; %relative
%No. of state per phone
state = 3;
% type of feature normalization
normtype = 3;

%% type of acoustic features used for classification
% caudioType = 0; % no audio
caudioType = 1; % raw audio
% caudioType = 2; % encoded audio
% caudioType = 3; % raw + encoded audio

%% type of articulatory features used for classification
% cmotorType = 0; % no motor
% cmotorType = 1; % raw motor
% cmotorType = 2; % encoded motor
% cmotorType = 3; % raw reconstructed motor
cmotorType = 4; % encoded reconstructed motor
% cmotorType = 5; % encoded (using classification) motor
% cmotorType = 6; % encoded (using classification) reconstructed motor

%% type of articulatory reconstruction (i.e. inversion)
% bReconstruct = 0;   % no reconstruction
% bReconstruct = 1;   % reconstruct raw motor from raw audio (either with linear regressor a regularized MLP regressor or a pretrained MLP regressor. same thing for some of the reconstructions below)
% bReconstruct = 2;   % reconstruct encoded motor from encoded audio
bReconstruct = 3;   % reconstruct encoded motor from raw audio
% bReconstruct = 4;   % reconstruct encoded motor (using classification) from encoded audio
% bReconstruct = 5;   % reconstruct encoded motor (using classification) from raw audio
% bReconstruct = 6;   % (Not working yet, only available in the old version) reconstruct raw motor from raw audio through shared representation

blinregr = 0;   % a neural network is used
% blinregr = 1;   % a linear regressor is used

mixtype = 1;

nfae_audio = 1; % number of context frames for the audio AE

% struct of hyperparameters of the autoencoder that extract acoustic features 
parae_audio = struct(...
    'units',[NoAuF*nfae_audio 300 36],...   % input + hidden (last is the encoding layer)
    'activations',{{'sigm','sigm'}},... % hidden
    'pretrain','rbm',...    % rbm/ae/rand
    'preae_maxepoch',50,... % for 'ae' pretraining, number of epochs for each layer
    'vgaus',1,...   % for 'rbm' pretraining, gaussian visible units
    'hgaus',0,...   % for 'rbm' pretraining, gaussian hidden units
    'shid',0,...    % SCAE
    'pairsim',0,... % SAE
    'noisy',0,...   % DAE
    'forceBin',0,...    % force binarization: 1) add noise to encoding layer input; 2) additional entropy cost term
    'binarize',0,...    % binarize encodings in the fwd pass: 1) threshold 0.5; 2) threshold stochastically
    'sparsepen',0,...   % sparsity penalty (beta)
    'batchsize',1000,...
    'maxepoch',50,...
    'optimization','cgd',...    % cgd/sgd
    'cost','mse',...    % cost functions are: 'mse' (Mean Square Error), 'ce_logistic' (Cross-Entropy for sigmoid output), 'ce_softmax' (Cross-Entropy for softmax output)
    'dropout',0,... % dropout probability
    'learningRate',0.1,...          % SGD parameters
    'learningRateDecay',0.99,...    %%
    'momentum',0.9,...              %%
    'weightDecay',0.0001,...
    'rbmparam',struct(...           
        'vgaus',0,...   % this must be kept fixed
        'hgaus',0,...   % this must be kept fixed
        'batchsize',50,...
        'maxepoch',75,...
        'epsilonw',0.1,...
        'epsilonvb',0.1,...
        'epsilonhb',0.1,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmhgausparam',struct(...
        'vgaus',0,...   % this must be kept fixed
        'hgaus',1,...   % this must be kept fixed
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmvgausparam',struct(...
        'vgaus',1,...   % this must be kept fixed
        'hgaus',0,...   % this must be kept fixed
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        )...
    );

nfae_motor = 1; % number of context frames for the motor AE
% struct of hyperparameters of the autoencoder that extract articulatory features
parae_motor = struct(...
    'units',[NoMF*nfae_motor 300 36],...
    'activations',{{'sigm','sigm'}},...
    'pretrain','rbm',...
    'preae_maxepoch',50,...
    'vgaus',1,...
    'hgaus',0,...
    'shid',0,...
    'pairsim',0,...
    'noisy',0,...
    'forceBin',0,...
    'binarize',0,...
    'sparsepen',0,...
    'batchsize',1000,...
    'maxepoch',50,...
    'optimization','cgd',...
    'cost','mse',...
    'dropout',0,...
    'learningRate',0.1,...
    'learningRateDecay',0.99,...
    'momentum',0.9,...
    'weightDecay',0.0001,...
    'rbmparam',struct(...
        'vgaus',0,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',75,...
        'epsilonw',0.1,...
        'epsilonvb',0.1,...
        'epsilonhb',0.1,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmhgausparam',struct(...
        'vgaus',0,...
        'hgaus',1,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmvgausparam',struct(...
        'vgaus',1,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        )...
    );

nf_audio = 5;   % number of audio context frames for reconstruction
nf_motor = 1;   % number of motor context frames for reconstruction
dimIn=0;
dimOut=0;
switch bReconstruct
    case 1
        dimIn=NoAuF;
        dimOut=NoMF;
    case {2,4}
        dimIn=parae_audio.units(end);
        dimOut=parae_motor.units(end);
    case {3,5}
        dimIn=NoAuF;
        dimOut=parae_motor.units(end);
end

% struct of hyperparameters of the DNN that performs the
% acoustic-to-articulatory mapping
parnet_regress = struct(...
    'units',[dimIn*nf_audio 300 300 300 dimOut],... % input + hidden + output
    'activations',{{'relu','relu','relu','linear'}},... % hidden + output
    'pretrain','rand',...   % rbm/rand
    'outputInit_maxepoch',10,...    % if 'rbm' pretraining, number of epochs to initialize last layer weights before running backprop
    'vgaus',1,...
    'hgaus',0,...
    'batchsize',1000,...
    'maxepoch',50,...
    'optimization','sgd',...
    'cost','mse',...
    'dropout',0,...
    'learningRate',0.1,...
    'learningRateDecay',0.99,...
    'momentum',0.9,...
    'weightDecay',0.0001,...
    'rbmparam',struct(...
        'vgaus',0,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',75,...
        'epsilonw',0.1,...
        'epsilonvb',0.1,...
        'epsilonhb',0.1,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmhgausparam',struct(...
        'vgaus',0,...
        'hgaus',1,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmvgausparam',struct(...
        'vgaus',1,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        )...
    );

Nframes4class = 9;  % number of context frames for classification
dim = 0;
switch caudioType
    case 1
        dim = NoAuF;
    case 2
        dim = parae_audio.units(end);
    case 3
        dim = NoAuF + parae_audio.units(end);
end
switch cmotorType
    case {1,3,5,6}
        dim = dim + NoMF;
    case {2,4}
        dim = dim + parae_motor.units(end);
end

% struct hyperparameters of the dnn that computes the phone state
% posteriors
parnet_classifier=struct(...
    'units',[dim*Nframes4class 1500 1500 1500 147],...
    'activations',{{'relu','relu','relu','softmax'}},...
    'pretrain','rand',...   % 'aam' for Acoustic to Articulatory Mapping - based pretraining
    'outputInit_maxepoch',5,... %  if 'rbm'/'aam' pretraining, number of epochs to initialize last layer weights
    'vgaus',1,...
    'hgaus',0,...
    'batchsize',1000,...
    'maxepoch',50,...
    'optimization','sgd',...
    'cost','ce_softmax',...
    'dropout',0,...
    'learningRate',0.1,...
    'learningRateDecay',0.99,...
    'momentum',0.9,...
    'weightDecay',0.0001,...
    'rbmparam',struct(...
        'vgaus',0,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',75,...
        'epsilonw',0.1,...
        'epsilonvb',0.1,...
        'epsilonhb',0.1,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmhgausparam',struct(...
        'vgaus',0,...
        'hgaus',1,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        ),...
    'rbmvgausparam',struct(...
        'vgaus',1,...
        'hgaus',0,...
        'batchsize',50,...
        'maxepoch',225,...
        'epsilonw',0.001,...
        'epsilonvb',0.001,...
        'epsilonhb',0.001,...
        'weightcost',0.0002,...
        'initialmomentum',0.5,...
        'finalmomentum',0.9...
        )...
    );

% parjnet = struct(...
%     'rbmgaus_maxepoch',1,...
%     'rbm_maxepoch',1,...
%     'hlayers',[300],...
%     'vgaus','',...
%     'hgaus',0,...
%     'bpmaxepoch',1,...
%     'mmode','',...
%     'agaus',[],...
%     'addtraindata',0,...
%     'usennmatlab',0,...
%     'finetune',1,...
%     'dynamicweigths',0 ...
%     );
% parsrbm = struct(...
%     'rbmgaus_maxepoch',1,...
%     'rbm_maxepoch',1,...
%     'hnodes',[300],...
%     'vgaus',0,...
%     'ogaus',0,...
%     'bpmaxepoch',1,...
%     'mmode','',...
%     'finetune',0,...
%     'translate',1,...
%     'agaus',[],...
%     'optimization','cgd',...
%     'labrbm',0,...
%     'labauto',0,...
%     'labautotype','short',...
%     'noisy',0,...
%     'dropout',0,...
%     'bsparse',0,...
%     'sparsepen',0.1,...
%     'sparsepar',0.1,...
%     'shid',0,...
%     'wshid',0 ...
%     );

rframes = 2;

% inizialitation of cells where results will be saved
rseq = cell(1,numSplits);
srseq = cell(1,numSplits);
testseq = cell(1,numSplits);
predseq = cell(1,numSplits);
totdels = cell(1,numSplits);
totins = cell(1,numSplits);
totsubs = cell(1,numSplits);
moperations = cell(1,numSplits);
cpred = cell(1,numSplits);
post = cell(1,numSplits);
rectrainerr = cell(1,numSplits);
rectesterr = cell(1,numSplits);
rectrainerr_each_phoneme=cell(1,numSplits);
rectesterr_each_phoneme=cell(1,numSplits);
traincerr=cell(1,numSplits);
testcerr=cell(1,numSplits);
trainber=cell(1,numSplits);
testber=cell(1,numSplits);
confmatrix=cell(1,numSplits);
rconfmatrix=cell(1,numSplits);
cacc=cell(1,numSplits);
rcacc=cell(1,numSplits);
rerr=cell(1,numSplits);
rsubstitution=cell(1,numSplits);
serr=cell(1,numSplits);
spredseq=cell(1,numSplits);
stotdels=cell(1,numSplits);
stotins=cell(1,numSplits);
stotsubs=cell(1,numSplits);
smoperations=cell(1,numSplits);
ssubstitution=cell(1,numSplits);

%output folder
folderName = [datestr(now,'yyyy-mm-dd_HH-MM-SS') '_audio' int2str(caudioType) '_motor' int2str(cmotorType) '_rec' int2str(bReconstruct)];