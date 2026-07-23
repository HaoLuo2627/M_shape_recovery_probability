clc;
clear;

A_alpha=2.3333333333333333;
A_beta=0.3;
B_alpha=0.4285714285714286;
B_beta=0.7;

seed_count = 10;

baseDir = sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f', A_alpha, A_beta, B_alpha, B_beta);
S_time_file = fullfile(baseDir, sprintf('ER_S_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count));
A_time_file = fullfile(baseDir, sprintf('ER_A_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count));
R_time_file = fullfile(baseDir, sprintf('ER_R_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count));

S_time_data = load(S_time_file, '-ascii');
A_time_data = load(A_time_file, '-ascii');
R_time_data = load(R_time_file, '-ascii');

%计算平均时间序列
[x, y] = find(S_time_data(:,1)==0);
%后项减前项求时间序列长度
diff_array = diff(x);
%唯一化，看看时间序列长度有几种
unique_len_array = unique(diff_array);
%对每种长度求次数，看看哪种序列长度最多
number_of_types = size(unique_len_array, 1);
number_array = zeros(number_of_types, 2);
for i=1:number_of_types
    number_array(i, :) = [unique_len_array(i), sum(diff_array==unique_len_array(i))];
end

%计算出现次数最多的时间序列长度
[max_x, max_y] = max(number_array(:,2));
most_frequent_len = number_array(max_y, 1);

%抽取满足时间长度是序列
simulated_time_S_matrix = zeros(length(diff_array), most_frequent_len);
simulated_time_A_matrix = zeros(length(diff_array), most_frequent_len);
simulated_time_R_matrix = zeros(length(diff_array), most_frequent_len);
for i=1:length(diff_array)
    if diff_array(i) == most_frequent_len
        curr_start = x(i);
        curr_end = x(i) + most_frequent_len - 1;
        simulated_time_S_matrix(i, :) = S_time_data(curr_start:curr_end, 2)';
        simulated_time_A_matrix(i, :) = A_time_data(curr_start:curr_end, 2)';
        simulated_time_R_matrix(i, :) = R_time_data(curr_start:curr_end, 2)';
    end
end

averaged_S_time = sum(simulated_time_S_matrix)/max_x;
averaged_S_time = [0:most_frequent_len-1; averaged_S_time]';
averaged_A_time = sum(simulated_time_A_matrix)/max_x;
averaged_A_time = [0:most_frequent_len-1; averaged_A_time]';
averaged_R_time = sum(simulated_time_R_matrix)/max_x;
averaged_R_time_tmax = [(0:most_frequent_len-1)/(most_frequent_len-1); averaged_R_time]';
averaged_R_time = [0:most_frequent_len-1; averaged_R_time]';
save(fullfile(baseDir, sprintf('ER_Averaged_S_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), 'averaged_S_time', '-ascii', '-double');
save(fullfile(baseDir, sprintf('ER_Averaged_A_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), 'averaged_A_time', '-ascii', '-double');
save(fullfile(baseDir, sprintf('ER_Averaged_R_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), 'averaged_R_time', '-ascii', '-double');
save(fullfile(baseDir, sprintf('ER_Averaged_R_timeMax_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), 'averaged_R_time_tmax', '-ascii', '-double');

