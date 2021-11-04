function simulate_data(lambda,rho,sampling_times,sampling_rate)
% % FUNCTION simulate_data
% % Author: Fabian Santiago 
% % Description: 
% %     Simulates data from the structured population model with linear
% %     aggregate replication dynamics. The data is generated by using
% %     rejection sampling on the multimodal distribution.

% % REJECTION SAMPLING PARAMETERS
% Number of points points to consider to determine the maximum height in
% the multimodal distribution for rejection sampling.
Npts  = 10^6; 

% Number of points (darts) to consider within the search window.
Npts_window = 10^6; 

% % MEAN AND STANDARD DEVIATION OF INITIAL DISTRIBUTION OF AGGREGATES
mu  = 10; % Mean number of aggregates
sig = 1;  % Standard deviation of aggregates

% Pre-allocate space to store aggregate counts
propagon_data = cell(1,length(sampling_times));

% Simulate aggregate counts per sampling times
parfor t = 1:length(sampling_times)
    % Load model solutions
    [Yn,~,cn,~,~] = load_model_solutions(mu,sig);
    
    % Select the next time at for generating simulated data
    T = sampling_times(t);
    
    % New observation
    new_samples = [];
    
    % Maximum number of aggregates to consider. Makes rejection sampling
    % more efficient as it narrows down the search space.
    a_max = (mu+4*sig)*exp(T*lambda); 
    %     a_min = (mu-4*sig)*exp(T*lambda)/(1/rho)^ceil(T*60/90);
    
    % Range of aggregates to consider
    a_rng = linspace(1,a_max,Npts);
    while numel(new_samples) < sampling_rate
        % We only consider up to maxDiv cell divisions since the beginning
        % of the experiment where cells divide every 90 minutes.
        maxD = ceil(T*60/90);
        minD = 0;
        gen_prob = cumsum([0 cn(minD:maxD,T)/sum(cn(minD:maxD,T))]);
        gen = sum(gen_prob < rand())-1;
        aggs_pdf = Yn(gen,T,a_rng,lambda,rho)/sum(cn(minD:maxD,T));

        % Create a rejection sampling window
        a_idx = aggs_pdf > 10^-6;
        a_idx = a_idx.*(1:Npts);
        a_idx(a_idx == 0)=[];
        a_tmp = linspace(a_rng(a_idx(1)),a_rng(a_idx(end)),Npts_window);
        rnd_pdf = max(Yn(gen,T,a_tmp,lambda,rho))...
                        /sum(cn(minD:maxD,T))*rand();
           
        % Select uniformly random number of aggregates within the search
        % window.
        rnd_agg = a_rng(a_idx(1))...
                  	+rand()*(a_rng(a_idx(end))-a_rng(a_idx(1)));
        
        % Accept points that lie below the distribution and reject those
        % that lie above.
        if rnd_pdf < Yn(gen,T,rnd_agg,lambda,rho)/sum(cn(minD:maxD,T))
            new_samples = [new_samples rnd_agg];
        end
    end
    propagon_data{t} = new_samples;
end
num2str2 =@(x,n) [num2str(round(floor(x),0)),'p',...
                num2str(round((x-round(floor(x),0))*10^n,0))];

f_str = ['./simulated_data/simdata_mu',num2str2(mu,2),...
         'sig',num2str2(sig,2),...
         'lambda',num2str2(lambda,2),...
         'rho',num2str2(rho,2),...
         'smph',num2str2(sampling_rate,2)];
save(f_str,'propagon_data','sampling_times','sampling_rate',...
                'mu','sig','lambda','rho')  