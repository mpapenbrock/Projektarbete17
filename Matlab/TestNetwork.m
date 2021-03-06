
clear;

%% Load stuff

% Load weights
load('../../mat/weights3.mat');

% Load event data
load('../../mat/dataPat.mat');

%% Plot stuff

% Choose subset (train or test data)
idx = idx_test;

% Activation functions
sigma1  = @relu;
sigma1g = @relu_grad;
sigma2  = @relu;
sigma2g = @relu_grad;
sigma3  = @relu;
sigma3g = @relu_grad;
sigma4  = @relu;
sigma4g = @relu_grad;
sigmay  = @sigmoid;
sigmayg = @sigmoid_grad2;

% Transform data (not currently relevant)
T = Tstt;

%
% Loop over threshold values
thresholds = 0.99;
pred_acc = zeros(length(thresholds), 1);
efficiency = zeros(length(thresholds), 1);
purity = zeros(length(thresholds), 1);
Nx_miss = 0;
Ny_miss = 0;
Nyh_miss = zeros(length(thresholds), 1);
for k = idx
    if mod(k, 100) == 0
        disp(['k = ' num2str(k) '/' num2str(idx(end))]);
    end
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
    
    for i = 1:length(thresholds)
        th = thresholds(i);
        Yh_th = zeros(size(Yh));
        Yh_th(Yh > th & X == 1) = 1;
        if sum(X(1:NtubesSTT)) ~= 0
            pred_acc(i) = pred_acc(i) + 100*(sum(Yh_th == Y & X(1:NtubesSTT) == 1)/sum(X(1:NtubesSTT)));
        else
            Nx_miss = Nx_miss + 1;
        end
        if sum(Y) ~= 0
            efficiency(i) = efficiency(i) + 100*(sum(Yh_th == Y & Y == 1)/sum(Y));
        else
            Ny_miss = Ny_miss + 1;
        end
        if sum(Yh_th) ~= 0
            purity(i) = purity(i) + 100*(sum(Yh_th == Y & Y == 1)/sum(Yh_th));
        else
            Nyh_miss(i) = Nyh_miss(i) + 1;
        end
    end
end

% Adjust for data points that are missing X, Y or Yh vector
Nx_miss = Nx_miss/length(thresholds);
Ny_miss = Ny_miss/length(thresholds);
pred_acc = pred_acc/(length(idx) - Nx_miss);
efficiency = efficiency/(length(idx) - Ny_miss);
purity = purity./(length(idx) - Nyh_miss);

% Plot
plot(thresholds, pred_acc, '-b', thresholds, efficiency, '-r', thresholds, purity, '-g');
xlabel('Threshold');
ylabel('Performance value');
legend('accuracy', 'efficiency', 'purity');
%}


%{
% Filter out events with too many hits
cluster_sizes = 0:10:100;
pred_acc = zeros(length(cluster_sizes), 1);
for i = 1:length(cluster_sizes)
    disp(['i = ' num2str(i)]);
    N = 0;
    for k = idx
        X = T(k, :)';
        if sum(X(1:NtubesSTT)) > cluster_sizes(i)
            continue;
        end
        N = N + 1;
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
        Yh_th = zeros(size(Yh));
        Yh_th(Yh > 0.99) = 1;
        Y = A(k, :)';
        if sum(X(1:NtubesSTT)) ~= 0
            pred_acc(i) = pred_acc(i) + 100*(sum(Yh_th == Y & X(1:NtubesSTT) == 1)/sum(X(1:NtubesSTT)));
        end
    end
    pred_acc(i) = pred_acc(i)/N;
    disp(['N = ' num2str(N)]);
end

% Plot
plot(cluster_sizes, pred_acc);
%}


%{
N1 = 0;
N2 = 0;
h1 = 0;
h2 = 0;
for k = idx
    X = T(k, :)';
    Y = A(k, :)';
    if sum(X(1:NtubesSTT)) <= 100
        N1 = N1 + 1;
        h1 = h1 + 1*(sum(Y) ~= 0);
    else
        N2 = N2 + 1;
        h2 = h2 + 1*(sum(Y) ~= 0);
    end
end
%}








