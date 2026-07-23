function yy=susceptible_K(kk,theta_A,theta_B)

global A_alpha A_beta B_alpha B_beta rho_0 degree

% 支持向量化 kk（标量或索引向量）
kk = kk(:);

deg_sub = degree(kk, :); % CPU array
n = size(deg_sub,1);
temp_A = zeros(n,1);
temp_B = zeros(n,1);

kA_list = deg_sub(:,1);
kB_list = deg_sub(:,2);

uniqueA = unique(kA_list);
for ii = 1:length(uniqueA)
    d = uniqueA(ii);
    idx = (kA_list == d);
    if d <= 0
        % 零度层不会收到信息，因此该层保持未采纳的概率为 1。
        val = 1;
    else
        m = 0:d;
        pVec = 1 - cusp_condition((1:d)/d, A_alpha, A_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d+1) - gammaln(d - m + 1) - gammaln(m + 1));
        terms = comb .* (theta_A.^(d - m)) .* ((1 - theta_A).^m) .* condVec;
        val = sum(terms);
    end
    temp_A(idx) = val;
end

uniqueB = unique(kB_list);
for ii = 1:length(uniqueB)
    d = uniqueB(ii);
    idx = (kB_list == d);
    if d <= 0
        val = 1;
    else
        m = 0:d;
        pVec = 1 - cusp_condition((1:d)/d, B_alpha, B_beta);
        condVec = [1, cumprod(pVec)];
        comb = exp(gammaln(d+1) - gammaln(d - m + 1) - gammaln(m + 1));
        terms = comb .* (theta_B.^(d - m)) .* ((1 - theta_B).^m) .* condVec;
        val = sum(terms);
    end
    temp_B(idx) = val;
end

conservative = temp_A .* temp_B;
yy = conservative .* (1 - rho_0);
end
