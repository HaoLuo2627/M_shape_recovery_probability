clear;
clc;

global lambda_A lambda_B r_A r_B A_alpha A_beta B_alpha B_beta rho_0 degree degree_A degree_B

%y是theta_w_A和theta_w_B的串联
tic;

r_A=1;
r_B=1;

B_alpha=1;
B_beta=1;
v = 3.81;

seed_count = 5;
network_size = 1893;
rho_0=seed_count / network_size;

for A_beta = [0.001, 0.01:0.01:0.66]
    A_alpha = -1 + 2 / (3 * A_beta);
    disp(['A_beta = ' num2str(A_beta) ', A_alpha = ' num2str(A_alpha)])

    baseDir = fullfile('..','data',sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f', A_alpha, A_beta, B_alpha, B_beta));
    combined_file = fullfile(baseDir, sprintf('UCSocial_combined_degree_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.txt', A_alpha, A_beta, B_alpha, B_beta));
    degree_A_file = fullfile(baseDir, sprintf('UCSocial_A_degree_distribution_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.txt', A_alpha, A_beta, B_alpha, B_beta));
    degree_B_file = fullfile(baseDir, sprintf('UCSocial_B_degree_distribution_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.txt', A_alpha, A_beta, B_alpha, B_beta));

    data = load(combined_file);
    max_degree = max(data(:,1:2), [], "all");

    degree_A = load(degree_A_file);
    degree_B = load(degree_B_file);

    % 保留零度联合度类；为兼容 spconvert，度索引在构造矩阵时整体平移一位。
    %len_degree_A = length(degree_A);
    %len_degree_B = length(degree_B);
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

    lambda_A_array=0.01:0.01:1;
    R = zeros(1, length(lambda_A_array));
    for index=1:length(lambda_A_array)
        lambda_A = lambda_A_array(index);
        disp(['lambda_A is ' num2str(lambda_A)]);
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

        R(1, index) = 1-s;
        R(1, 1:index)    % 打印输出
    end

    UCSocial_3D_temp = [0:0.01:1; [seed_count/network_size, R]]';
    file_name = fullfile(baseDir, sprintf('UCSocial_theoretical_R_A_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_count_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count));
    save(file_name,'UCSocial_3D_temp','-ascii','-double');
end  % for A_beta loop

% plot(UCSocial_3D_temp(:,1), UCSocial_3D_temp(:,2), 'ob')
% hold on

% xlabel('\beta')
% ylabel('R(\infty)')

% savefig(fullfile(baseDir, sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.fig', A_alpha, A_beta, B_alpha, B_beta)));

% exportgraphics(gcf, ...
%     fullfile(baseDir, sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.png', A_alpha, A_beta, B_alpha, B_beta)), ...
%     'Resolution', 300);
toc;
