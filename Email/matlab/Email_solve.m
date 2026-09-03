clear;
clc;

global lambda_A lambda_B h_A h_B A_a A_c B_a B_c rho_0 degree degree_A degree_B

%y是theta_w_A和theta_w_B的串联
tic;

% A和B两层网络的节点采纳概率均设置为常数1
h_A = 1;
h_B = 1;

v = 1.94;
seed_count = 5;
network_size = 1133;
rho_0 = seed_count / network_size;
lambda_A_array=0.01:0.01:1;

for A_a = [0.01, 0.2, 0.5, 0.8, 0.99]
    for A_c = [0.01, 0.2, 0.5, 0.8, 1]
        B_a = A_a;
        B_c = A_c;
        disp(['A_a = ' num2str(A_a) ', A_c = ' num2str(A_c) ', B_a = ' num2str(B_a) ', B_c = ' num2str(B_c)]);

        baseDir = fullfile('..', 'data', sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f', A_a, A_c, B_a, B_c));
        combined_file = fullfile(baseDir, sprintf('Email_combined_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt', A_a, A_c, B_a, B_c));
        degree_A_file = fullfile(baseDir, sprintf('Email_A_degree_distribution_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt', A_a, A_c, B_a, B_c));
        degree_B_file = fullfile(baseDir, sprintf('Email_B_degree_distribution_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt', A_a, A_c, B_a, B_c));

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
        degree(:,3) = degree(:,3) / sum(degree(:,3));  % 加载联合度分布后强制归一化
        len_degree = length(degree);

        avg_K_A = degree(:,1)' * degree(:,3);
        avg_K_B = degree(:,2)' * degree(:,3);

        R = zeros(1, length(lambda_A_array));
        for index=1:length(lambda_A_array)
            lambda_A = lambda_A_array(index);
            disp(['lambda_A is ' num2str(lambda_A)]);
            lambda_B=lambda_A;
            %初始值是theta_w_A和theta_w_B的两个列向量
            [TT,YY]=solve_to_steady_state(@thresholdModel, ones(len_degree+len_degree,1));
            theta_A_B_w=YY(end,:);  %%%%last line of YY (value in stable state)

            %计算theta_A
            theta_A = theta_A_B_w(1:len_degree) * (degree(:,1) .* degree(:,3) / avg_K_A);

            %计算theta_B
            theta_B = theta_A_B_w(len_degree+1:len_degree+len_degree) * (degree(:,2) .* degree(:,3) / avg_K_B);

            % 向量化计算所有度组合的易感率并做加权求和
            sus_vec = susceptible_K((1:len_degree)', theta_A, theta_B);
            s = degree(:,3)' * sus_vec;

            R(1, index) = 1-s;
            R(1, 1:index)    % 打印输出
        end

        Email_3D_temp = [0:0.01:1; [rho_0, R]]';
        file_name = fullfile(baseDir, sprintf('Email_theoretical_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_count_%d.txt', A_a, A_c, B_a, B_c, seed_count));
        save(file_name,'Email_3D_temp','-ascii','-double');
    end
end

toc;
