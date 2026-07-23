clear;
clc;

global lambda_A lambda_B r_A r_B A_alpha A_beta B_alpha B_beta rho_0 degree degree_A degree_B

%y是theta_w_A和theta_w_B的串联
tic;
r_A=1;
r_B=1;
seed_count = 10;
network_size = 10000;
rho_0=seed_count / network_size;

A_alpha_ref=1;
A_beta_ref=0.5;
B_alpha=1;
B_beta=1;
v_list = [2, 4];

for vi = 1:length(v_list)
    v = v_list(vi);

    baseDir = fullfile('..','data',sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_v_%.2f', A_alpha_ref, A_beta_ref, B_alpha, B_beta, v));
    combined_file = fullfile(baseDir, sprintf('SF_combined_degree_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_v_%.2f.txt', A_alpha_ref, A_beta_ref, B_alpha, B_beta, v));
    degree_A_file = fullfile(baseDir, sprintf('SF_A_degree_distribution_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_v_%.2f.txt', A_alpha_ref, A_beta_ref, B_alpha, B_beta, v));
    degree_B_file = fullfile(baseDir, sprintf('SF_B_degree_distribution_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_v_%.2f.txt', A_alpha_ref, A_beta_ref, B_alpha, B_beta, v));
    
    data = load(combined_file);
    max_degree = max(data(:,1:2), [], "all");

    degree_A = load(degree_A_file);
    degree_B = load(degree_B_file);
    %len_degree_A = length(degree_A);
    %len_degree_B = length(degree_B);
    % 保留零度联合度类；为兼容 spconvert，度索引在构造矩阵时整体平移一位。
    % spconvert 不接受 0 下标；整体平移一位以保留 k_A=0 或 k_B=0 的度类。
    data(:,1:2) = data(:,1:2) + 1;
    combined_degree = spconvert(data);
    [nr, nc] = size(combined_degree);
    if nr < (max_degree + 1) || nc < (max_degree + 1)
        combined_degree(max_degree+1, max_degree+1) = 0;  % 仅在需要扩容时设置角元素
    end
    combined_degree = full(combined_degree);
    
    degree=zeros((max_degree+1).^2,3);
    for i=0:max_degree
        for j=0:max_degree
            degree(i*(max_degree+1)+j+1,:) = [i,j,combined_degree(i+1,j+1)];
        end
    end
    
    degree=degree(degree(:,3)>0,:);
    len_degree = length(degree);
    
    avg_K_A=degree_A(:,1)' * degree_A(:,2);
    avg_K_B=degree_B(:,1)' * degree_B(:,2);
    
    lambda_A_array = 0.01:0.01:1;
    A_beta_array = [0.001, 0.01:0.01:1];
    R = zeros(length(A_beta_array), length(lambda_A_array));
    all_data = zeros(length(A_beta_array)*(length(lambda_A_array)+1), 2);
    for index_A_beta = 1:length(A_beta_array)
        A_beta = A_beta_array(index_A_beta);
        if A_beta > 0
            A_alpha = (1 - A_beta) / A_beta;
        else
            A_alpha = 10000;
        end
    
        temp_R=zeros(1, length(lambda_A_array));
        for index_lambda_A = 1:length(lambda_A_array)
            lambda_A = lambda_A_array(index_lambda_A);
            disp(['A_alpha is ' num2str(A_alpha) ', A_beta is ' num2str(A_beta) ', lambda_A is ' num2str(lambda_A)]);
            lambda_B=lambda_A;
            %初始值是theta_w_A和theta_w_B的两个列向量
            [TT,YY]=solve_to_steady_state(@thresholdModel, ones(len_degree+len_degree,1));
            theta_A_B_w=YY(end,:);  %%%%last line of YY (value in stable state)
            %计算theta_A
            theta_A=theta_A_B_w(1:len_degree)*(degree(:,1).*degree(:,3)/avg_K_A);
    
            %计算theta_B
            theta_B=theta_A_B_w(len_degree+1:len_degree+len_degree)*(degree(:,2).*degree(:,3)/avg_K_B);
    
            % 向量化计算所有度组合的易感率并做加权求和
            sus_vec = susceptible_K((1:len_degree)', theta_A, theta_B);
            s = degree(:,3)' * sus_vec;
    
            temp_R(1, index_lambda_A) = 1-s;
            temp_R(1, 1:index_lambda_A)    % 打印输出
        end
        R(index_A_beta, :) = temp_R;
        SF_3D_temp = [0:0.01:1; [seed_count/network_size, temp_R]]';
        all_data((index_A_beta-1)*(length(lambda_A_array)+1)+1:index_A_beta*(length(lambda_A_array)+1),:) = SF_3D_temp;
    end
    file_name = fullfile(baseDir, sprintf('SF_all_theoretical_B_alpha_%.2f_B_beta_%.2f_v_%.2f_seed_count_%d.txt', B_alpha, B_beta, v, seed_count));
    save(file_name,'all_data','-ascii','-double');
end  % end for v loop
toc;
