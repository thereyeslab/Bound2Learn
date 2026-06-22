
function [BestModel, numComponents_BIC] = GMM_BIC_ML_log(data, GMM_models_tested, shared_cov)
%% Discription:
% This function fits the logarithm of the given data(variable) into a Gaussian mixture model.

%% inputs:
%   - data(vector): the data(variable) to be fitted into GMM
%   - GMM_models_tested(int): the number of models (with different number
%   of components) to be tested. ex: if GMM_models_tested = 3, then 3
%   models (with 1, 2, 3 components) will be fitted and the best fit (the
%   model with the lowest BIC)will be choosen.
%   - shared_cov(boolean): indicates whether the covariance matrices of the Gaussian distributions 
%     should be the same across all components or not 

%% outputs:
%   - BestModel (object (gmdistribution)): 
%   - numComponents_BIC (int): number of components (gaussian distribution) of the final model. 

%% Notes:
% - Bayesian Information Criterion(BIC)is a measure used for model selectionthat balances the goodness
% of fit of a model with its complexity. It takes into account both the likelihood of the data given
% the model and the number of parameters in the model. The goal is to choose a model that maximizes 
% the likelihood of the data while penalizing models with more parameters.
% In the context of fitgmdist, the BIC is used as a criterion for selecting the optimal number of 
% components (clusters) in the Gaussian mixture model.
% 
% - The best model at the end has two properties: 1)Mean 2)The mixing proportions: specify the relative contribution or weight of each component in the overall mixture.
% They represent the probabilities of belonging to each component for each data point. The mixing 
% proportions should sum up to 1.The mixing proportions indicate the relative contribution of each component to
% the overall distribution.

%%
% setting the options for the GMM fitting:
% Display = off :no iterative optimization information is shown in the command window or console 
% during the fitting process. 
% MaxIter: maximum number of iterations for the optimization. This helps prevent the algorithm 
% from running indefinitely or getting stuck in an infinite loop.
% UseParallel: allows you to enable or disable parallel computation during the fitting
options = statset('Display','off','MaxIter',10000,'UseParallel',true);

%%
data= log(data);
% gm = fitgmdist(intensities_final,2,'Options',options);
%GMM_models_tested = 5;

%% Perform GMM fitting on the data for different numbers of components.
% BIC: An array to store the BIC values for different GMM models:
BIC = zeros(1,GMM_models_tested);
% GMModels: A cell array to store the fitted GMM models:
GMModels = cell(1,GMM_models_tested);
for k = 1:GMM_models_tested
    % Fit a GMM to the data with 'k' components.
    GMModels{k} = fitgmdist(data,k,'Options',options,'Replicates',200,'SharedCovariance', shared_cov);
    % Compute the BIC value for the fitted model.
    BIC(k)= GMModels{k}.BIC;
end

% Find the best GMM model with the minimum BIC value:
[minBIC,numComponents_BIC] = min(BIC);

% Retrieve the best model based on the minimum BIC.
BestModel = GMModels{numComponents_BIC};
%% Plot the histogram of the data and the probability density function (PDF) of the best model.
figure, 
%[fi,xi]=ksdensity(data,'Support','positive');
histogram(data, 'BinMethod','fd','Normalization','pdf')
hold on
% Generate a range of values for x.
x= [min(data):0.01:max(data)];
x = x(:);
y = pdf(BestModel, x);

plot(x, y)
%plot(xi,fi)
hold off;
end
 
