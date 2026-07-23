function dy=thresholdModel(t,y)

global lambda_A lambda_B r_A r_B A_alpha A_beta B_alpha B_beta rho_0 degree degree_A degree_B
%   lambda_A为传播率，r_A为恢复概率，T为节点的固有阈值

%   y: theta_w_A(t)与theta_w_B(t)串连的向量

%网络A和网络B的平均度
avg_K_A = degree_A(:,1)' * degree_A(:,2);
avg_K_B = degree_B(:,1)' * degree_B(:,2);

len_degree = size(degree,1);
dy = zeros(len_degree+len_degree,1);

%计算theta_A和theta_B
theta_A = y(1:len_degree)' * (degree(:,1) .* degree(:,3) / avg_K_A);
theta_B = y(len_degree+1:len_degree+len_degree)' * (degree(:,2) .* degree(:,3) / avg_K_B);

%%计算每条边的感染概率
% lambda_w_A = 1 - (1 - lambda_A) .^ weight_A(1:len_weight_A,1);
% lambda_w_B = 1 - (1 - lambda_B) .^ weight_B(1:len_weight_B,1);

inf_w_A = lambda_A;
inf_w_B = lambda_B;

%计算 xi_S_w_A
degA_list = degree(:,1);
degB_list = degree(:,2);

uniqueA = unique(degA_list);
uniqueB = unique(degB_list);
tempA1 = zeros(len_degree,1);
tempB1 = zeros(len_degree,1);
tempA2 = zeros(len_degree,1);
tempB2 = zeros(len_degree,1);

% block 1: tempA1 使用 degree(:,1) 的组合（nchoosek(d-1,a)），tempB1 使用 degree(:,2) 的组合（nchoosek(d,b)）
for ii = 1:length(uniqueA)
    d = uniqueA(ii);
    idx = (degA_list == d);
    if d <= 0
        val = 1;
    else
        m = 0:(d-1);
        pVec = 1 - cusp_condition((1:(d-1))/d, A_alpha, A_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d) - gammaln(d - m) - gammaln(m + 1)); % nchoosek(d-1,m)
        terms = comb .* (theta_A.^(d - m - 1)) .* ((1 - theta_A).^m) .* condVec;
        val = sum(terms);
    end
    tempA1(idx) = val;
end

for ii = 1:length(uniqueB)
    d = uniqueB(ii);
    idx = (degB_list == d);
    if d <= 0
        val = 1;
    else
        m = 0:d;
        pVec = 1 - cusp_condition((1:d)/d, B_alpha, B_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d+1) - gammaln(d - m + 1) - gammaln(m + 1)); % nchoosek(d,m)
        terms = comb .* (theta_B.^(d - m)) .* ((1 - theta_B).^m) .* condVec;
        val = sum(terms);
    end
    tempB1(idx) = val;
end

xi_S_w_A = tempA1 .* tempB1 .* (1 - rho_0);

% block 2: 计算 xi_S_w_B 的两个分量（注意组合形式有所不同）
for ii = 1:length(uniqueB)
    d = uniqueB(ii);
    idx = (degB_list == d);
    if d <= 0
        val = 1;
    else
        m = 0:(d-1);
        pVec = 1 - cusp_condition((1:(d-1))/d, B_alpha, B_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d) - gammaln(d - m) - gammaln(m + 1)); % nchoosek(d-1,m)
        terms = comb .* (theta_B.^(d - m - 1)) .* ((1 - theta_B).^m) .* condVec;
        val = sum(terms);
    end
    tempB2(idx) = val;
end

for ii = 1:length(uniqueA)
    d = uniqueA(ii);
    idx = (degA_list == d);
    if d <= 0
        val = 1;
    else
        m = 0:d;
        pVec = 1 - cusp_condition((1:d)/d, A_alpha, A_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d+1) - gammaln(d - m + 1) - gammaln(m + 1)); % nchoosek(d,m)
        terms = comb .* (theta_A.^(d - m)) .* ((1 - theta_A).^m) .* condVec;
        val = sum(terms);
    end
    tempA2(idx) = val;
end

xi_S_w_B = tempA2 .* tempB2 .* (1 - rho_0);

%计算xi_R_w_A
xi_R_w_A = r_A .* (1 - y(1:len_degree)) .* (1 - inf_w_A) ./ inf_w_A;
%计算xi_R_w_B
xi_R_w_B = r_B .* (1 - y(len_degree+1:len_degree+len_degree)) .* (1 - inf_w_B) ./ inf_w_B;
%计算 xi_I_W_A
xi_I_W_A = y(1:len_degree) - xi_S_w_A - xi_R_w_A;
%计算 xi_I_W_B
xi_I_W_B = y(len_degree+1:len_degree+len_degree) - xi_S_w_B - xi_R_w_B;

%写出微分方程
%计算dtheta_w_A_t
dy(1:len_degree) = -inf_w_A .* xi_I_W_A;
%计算dtheta_w_B_t
dy(len_degree+1:len_degree+len_degree) = -inf_w_B .* xi_I_W_B;
end
