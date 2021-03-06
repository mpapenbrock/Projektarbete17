
% Trains a neural network in the task of classifying which final state
% particle belongs to a given track candidate.

clear;

%% INITIALIZATION

% Load data
load('../../mat/dataClass.mat');

% Number of training and testing points
Ntrain = 10000000;
Ntest = 10000;

% Load and save flags
load_flag = 0;
save_flag = 1;

% Learning rate
gamma_min = 0.0001;
gamma_max = 0.001;

% Dropout parameter
pkeep = 0.7;

% Standard deviation for the initial random weights
st_dev = 0.12;

% Batch size
batchSize = 1000;
Nb = Ntrain/batchSize; % Nr of batches

% Number of neurons
n = NtubesSTT;   % Number of input neurons
s1 = 200;        % 1:st hidden layer
s2 = 100;        % 2:nd hidden layer
s3 = 50;         % 3:rd hidden layer
s4 = 20;         % 4:th hidden layer
m = 3;           % Number of output neurons

% Activation functions
sigma1  = @relu;
sigma1g = @relu_grad;
sigma2  = @relu;
sigma2g = @relu_grad;
sigma3  = @relu;
sigma3g = @relu_grad;
sigma4  = @relu;
sigma4g = @relu_grad;
sigmay  = @softmax;
sigmayg = @softmax_grad;

% Loss function
loss  = @crossEntropyLoss;
lossg = @crossEntropyLoss_grad;

% Transform data (balance classes)
A = A(:, [1,4,5]);
minClass = min(sum(A));
idx_1 = randsample(find(A(:, 1) == 1), minClass);
idx_2 = randsample(find(A(:, 2) == 1), minClass);
idx_3 = randsample(find(A(:, 3) == 1), minClass);
idx = sort([idx_1; idx_2; idx_3]);
T = Tstt(idx, :);
A = A(idx, :);

% Divide into training and testing indices
Ntest = min(Npoints/2, Ntest);
idx_keep = find(sum(A, 2) ~= 0)';
Npoints = length(idx_keep);
idx_test = idx_keep(1:Ntest);%randsample(idx_keep, Ntest);
idx_train = setdiff(idx_keep, idx_test);

% Initial weights and biases
W1 = st_dev*randn(s1, n);    % Weights to 1:st hidden layer
W2 = st_dev*randn(s2, s1);   % Weights to 2:nd hidden layer
W3 = st_dev*randn(s3, s2);   % Weights to 3:rd hidden layer
W4 = st_dev*randn(s4, s3);   % Weights to 4:th hidden layer
Wy = st_dev*randn(m, s4);    % Weights to output layer
B1 = st_dev*ones(s1, 1);     % Biases to 1:st hidden layer
B2 = st_dev*ones(s2, 1);     % Biases to 2:nd hidden layer
B3 = st_dev*ones(s3, 1);     % Biases to 3:rd hidden layer
B4 = st_dev*ones(s4, 1);     % Biases to 4:th hidden layer
By = st_dev*ones(m, 1);      % Biases to output layer

% Parameters for the Adam Optimizer
beta1 = 0.9;
beta2 = 0.999;
epsilon = 1e-8;
mW1 = zeros(s1, n);   vW1 = zeros(s1, n);
mW2 = zeros(s2, s1);  vW2 = zeros(s2, s1);
mW3 = zeros(s3, s2);  vW3 = zeros(s3, s2);
mW4 = zeros(s4, s3);  vW4 = zeros(s4, s3);
mWy = zeros(m, s4);   vWy = zeros(m, s4);
mB1 = zeros(s1, 1);   vB1 = zeros(s1, 1);
mB2 = zeros(s2, 1);   vB2 = zeros(s2, 1);
mB3 = zeros(s3, 1);   vB3 = zeros(s3, 1);
mB4 = zeros(s4, 1);   vB4 = zeros(s4, 1);
mBy = zeros(m, 1);    vBy = zeros(m, 1);


%% TRAINING

% Train the network
C_train = zeros(Nb, 1);
C_test = zeros(Nb, 1);
predAcc_test = zeros(Nb, 1);
predAcc_train = zeros(Nb, 1);
predAccMax = 0;
ep_start = 1;
if load_flag == 1
    load('../../mat/weights5.mat');
    ep_start = ep + 1;
end

% Loop through each batch
figure;
h = waitbar(0, 'Training the neurual network...');
for ep = ep_start:Nb
    
    % Initialize the weight and bias changes
    dW1 = zeros(s1, n);
    dW2 = zeros(s2, s1);
    dW3 = zeros(s3, s2);
    dW4 = zeros(s4, s3);
    dWy = zeros(m, s4);
    dB1 = zeros(s1, 1);
    dB2 = zeros(s2, 1);
    dB3 = zeros(s3, 1);
    dB4 = zeros(s4, 1);
    dBy = zeros(m, 1);
    
    % Loop through each data point in the batch
    confusion_train = zeros(3, 3);
    im_train = randsample(idx_train, batchSize);
    for im = im_train
        
        % Dropout vectors
        doZ1 = 1*(rand(s1, 1) < pkeep);
        doZ2 = 1*(rand(s2, 1) < pkeep);
        doZ3 = 1*(rand(s3, 1) < pkeep);
        doZ4 = 1*(rand(s4, 1) < pkeep);
        
        % Forward propagation (with dropout)
        X = T(im, :)';
        Z1tilde = (W1*X + B1).*doZ1;
        Z1 = sigma1(Z1tilde).*doZ1;
        Z2tilde = (W2*Z1 + B2).*doZ2;
        Z2 = sigma2(Z2tilde).*doZ2;
        Z3tilde = (W3*Z2 + B3).*doZ3;
        Z3 = sigma3(Z3tilde).*doZ3;
        Z4tilde = (W4*Z3 + B4).*doZ4;
        Z4 = sigma4(Z4tilde).*doZ4;
        Yp = Wy*Z4 + By;
        Yh = sigmay(Yp);
        
        % Compute the training loss
        Y = A(im, :)';
        C_train(ep) = C_train(ep) + loss(Yh, Y)/batchSize;
        
        % Compute the training prediction accuracy
        [~, pred] = max(Yh);
        [~, correct] = max(Y);
        predAcc_train(ep) = predAcc_train(ep) + 100*(pred == correct)/batchSize;
        
        % Update training confusion matrix
        confusion_train(pred, correct) = confusion_train(pred, correct) + 1;
        
        % Backpropagate
        delta_y = sigmayg(Yp)*lossg(Yh, Y);
        delta_4 = sigma4g(Z4tilde)*(Wy'*delta_y);
        delta_3 = sigma3g(Z3tilde)*(W4'*delta_4);
        delta_2 = sigma2g(Z2tilde)*(W3'*delta_3);
        delta_1 = sigma1g(Z1tilde)*(W2'*delta_2);
        dW1 = dW1 + delta_1*X';
        dW2 = dW2 + delta_2*Z1';
        dW3 = dW3 + delta_3*Z2';
        dW4 = dW4 + delta_4*Z3';
        dWy = dWy + delta_y*Z4';
        dB1 = dB1 + delta_1;
        dB2 = dB2 + delta_2;
        dB3 = dB3 + delta_3;
        dB4 = dB4 + delta_4;
        dBy = dBy + delta_y;
    end
    
    % Step size
    gamma = gamma_max*((gamma_min/gamma_max)^(ep/Nb));
    
    % Partial derivatives
    dW1 = dW1/batchSize;
    dW2 = dW2/batchSize;
    dW3 = dW3/batchSize;
    dW4 = dW4/batchSize;
    dWy = dWy/batchSize;
    dB1 = dB1/batchSize;
    dB2 = dB2/batchSize;
    dB3 = dB3/batchSize;
    dB4 = dB4/batchSize;
    dBy = dBy/batchSize;
    
    % Adam Optimizer
    mW1 = (beta1*mW1 + (1 - beta1)*dW1);%/(1 - beta1^ep);
    mW2 = (beta1*mW2 + (1 - beta1)*dW2);%/(1 - beta1^ep);
    mW3 = (beta1*mW3 + (1 - beta1)*dW3);%/(1 - beta1^ep);
    mW4 = (beta1*mW4 + (1 - beta1)*dW4);%/(1 - beta1^ep);
    mWy = (beta1*mWy + (1 - beta1)*dWy);%/(1 - beta1^ep);
    mB1 = (beta1*mB1 + (1 - beta1)*dB1);%/(1 - beta1^ep);
    mB2 = (beta1*mB2 + (1 - beta1)*dB2);%/(1 - beta1^ep);
    mB3 = (beta1*mB3 + (1 - beta1)*dB3);%/(1 - beta1^ep);
    mB4 = (beta1*mB4 + (1 - beta1)*dB4);%/(1 - beta1^ep);
    mBy = (beta1*mBy + (1 - beta1)*dBy);%/(1 - beta1^ep);
    vW1 = (beta2*vW1 + (1 - beta2)*dW1.*dW1);%/(1 - beta2^ep);
    vW2 = (beta2*vW2 + (1 - beta2)*dW2.*dW2);%/(1 - beta2^ep);
    vW3 = (beta2*vW3 + (1 - beta2)*dW3.*dW3);%/(1 - beta2^ep);
    vW4 = (beta2*vW4 + (1 - beta2)*dW4.*dW4);%/(1 - beta2^ep);
    vWy = (beta2*vWy + (1 - beta2)*dWy.*dWy);%/(1 - beta2^ep);
    vB1 = (beta2*vB1 + (1 - beta2)*dB1.*dB1);%/(1 - beta2^ep);
    vB2 = (beta2*vB2 + (1 - beta2)*dB2.*dB2);%/(1 - beta2^ep);
    vB3 = (beta2*vB3 + (1 - beta2)*dB3.*dB3);%/(1 - beta2^ep);
    vB4 = (beta2*vB4 + (1 - beta2)*dB4.*dB4);%/(1 - beta2^ep);
    vBy = (beta2*vBy + (1 - beta2)*dBy.*dBy);%/(1 - beta2^ep);
    dW1 = mW1./(sqrt(vW1) + epsilon);
    dW2 = mW2./(sqrt(vW2) + epsilon);
    dW3 = mW3./(sqrt(vW3) + epsilon);
    dW4 = mW4./(sqrt(vW4) + epsilon);
    dWy = mWy./(sqrt(vWy) + epsilon);
    dB1 = mB1./(sqrt(vB1) + epsilon);
    dB2 = mB2./(sqrt(vB2) + epsilon);
    dB3 = mB3./(sqrt(vB3) + epsilon);
    dB4 = mB4./(sqrt(vB4) + epsilon);
    dBy = mBy./(sqrt(vBy) + epsilon);
    
    % Update the weights
    W1 = W1 - gamma*dW1;
    W2 = W2 - gamma*dW2;
    W3 = W3 - gamma*dW3;
    W4 = W4 - gamma*dW4;
    Wy = Wy - gamma*dWy;
    B1 = B1 - gamma*dB1;
    B2 = B2 - gamma*dB2;
    B3 = B3 - gamma*dB3;
    B4 = B4 - gamma*dB4;
    By = By - gamma*dBy;
    
    % Compute the test loss, prediction accuracy and confusion matrix
    confusion_test = zeros(3, 3);
    im_test = randsample(idx_test, batchSize);
    for k = im_test
        X = T(k, :)';
        Z1tilde = (W1*X + B1)*pkeep;
        Z1 = sigma1(Z1tilde);
        Z2tilde = (W2*Z1 + B2)*pkeep;
        Z2 = sigma2(Z2tilde);
        Z3tilde = (W3*Z2 + B3)*pkeep;
        Z3 = sigma3(Z3tilde);
        Z4tilde = (W4*Z3 + B4)*pkeep;
        Z4 = sigma4(Z4tilde);
        Yp = Wy*Z4 + By;
        Yh = sigmay(Yp);
        Y = A(k, :)';
        C_test(ep) = C_test(ep) + loss(Yh, Y)/batchSize;
        [~, pred] = max(Yh);
        [~, correct] = max(Y);
        predAcc_test(ep) = predAcc_test(ep) + 100*(pred == correct)/batchSize;
        confusion_test(pred, correct) = confusion_test(pred, correct) + 1;
    end
    
    % Update predAccMax and save the weights
    if predAcc_test(ep) > predAccMax
        predAccMax = predAcc_test(ep);
    end
    if save_flag == 1
        save('../../mat/weights5.mat', ...
            'n', 's1', 's2', 's3', 's4', 'm', ...
            'W1', 'W2', 'W3', 'W4', 'Wy', ...
            'B1', 'B2', 'B3', 'B4', 'By', ...
            'mW1', 'mW2', 'mW3', 'mW4', 'mWy', ...
            'mB1', 'mB2', 'mB3', 'mB4', 'mBy', ...
            'vW1', 'vW2', 'vW3', 'vW4', 'vWy', ...
            'vB1', 'vB2', 'vB3', 'vB4', 'vBy', ...
            'predAccMax', 'idx_train', 'idx_test', 'pkeep', ...
            'confusion_train', 'confusion_test', ...
            'ep', 'C_train', 'C_test', 'predAcc_test', 'predAcc_train');
    end
    
    % Compute the largest partial derivative
    maxWeight = max(abs(min(min(dW1))), max(max(dW1))) + ...
        max(abs(min(min(dW2))), max(max(dW2))) + ...
        max(abs(min(min(dW3))), max(max(dW3))) + ...
        max(abs(min(min(dW4))), max(max(dW4))) + ...
        max(abs(min(min(dWy))), max(max(dWy))) + ...
        max(abs(min(min(dB1))), max(max(dB1))) + ...
        max(abs(min(min(dB2))), max(max(dB2))) + ...
        max(abs(min(min(dB3))), max(max(dB3))) + ...
        max(abs(min(min(dB4))), max(max(dB4))) + ...
        max(abs(min(min(dBy))), max(max(dBy)));
    
    % Display information
    fprintf('Batch %d: C = %.3f \t acc = %.2f %%\t max(dW) = %.2e \t sum(Yh) = %.4f (%.4f) \n', ...
        ep, C_train(ep), predAcc_test(ep), maxWeight, sum(full(Yh)), sum(full(Y)));
    
    % Plot the error and prediction accuracy
    subplot(1, 2, 1);
    plot(0:(ep-1), C_train(1:ep), '-b', 1:ep, C_test(1:ep), '-r');
    title('Loss');
    xlabel('Batch number');
    if strcmp(func2str(loss), 'crossEntropyLoss')
        ylabel('Cross-entropy loss');
    elseif strcmp(func2str(loss), 'crossEntropyLoss2')
        ylabel('Cross-entropy loss (alternate)');
    elseif strcmp(func2str(loss), 'quadraticLoss')
        ylabel('Quadratic loss');
    else
        ylabel('Loss');
    end
    legend('training loss', 'test loss', 'Location', 'northwest');
    grid on;
    subplot(1, 2, 2);
    plot(0:(ep-1), predAcc_train(1:ep), '-b', 1:ep, predAcc_test(1:ep), '-r');
    title('Prediction accuracy');
    xlabel('Batch number');
    ylabel('Accuracy in %');
    legend('training accuracy', 'test accuracy', 'Location', 'northwest');
    grid on;
    
    % Display progress
    waitbar(ep/Nb, h);
end
close(h);


%% TESTING

% Plot the error and prediction accuracy
figure;
subplot(1, 2, 1);
plot(0:(ep-1), C_train(1:ep), '-b', 1:ep, C_test(1:ep), '-r');
title('Loss');
xlabel('Batch number');
if strcmp(func2str(loss), 'crossEntropyLoss')
    ylabel('Cross-entropy loss');
elseif strcmp(func2str(loss), 'crossEntropyLoss2')
    ylabel('Cross-entropy loss (alternate)');
elseif strcmp(func2str(loss), 'quadraticLoss')
    ylabel('Quadratic loss');
else
    ylabel('Loss');
end
legend('training loss', 'test loss', 'Location', 'northwest');
grid on;
subplot(1, 2, 2);
plot(0:(ep-1), predAcc_train(1:ep), '-b', 1:ep, predAcc_test(1:ep), '-r');
title('Prediction accuracy');
xlabel('Batch number');
ylabel('Accuracy in %');
legend('training accuracy', 'test accuracy', 'Location', 'northwest');
grid on;

% Display the best prediction accuracy
disp(' ');
disp(['Highest accuracy: ' num2str(predAccMax) ' %']);


