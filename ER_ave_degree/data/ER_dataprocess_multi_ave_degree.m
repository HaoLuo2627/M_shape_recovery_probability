clc;
clear;
close all;
networksize = 10000;
seed_count = 10;

A_alpha=2.3333333333333333;
A_beta=0.3;
B_alpha=0.4285714285714286;
B_beta=0.7;

ave_degree_array = [5, 10, 20];

once_range = 101;
times = 1001;
color_array = {'c', 'b', 'r', 'g', 'k', 'm'};
marker_array = {'-', 'o', '^', 's', '+', '*', 'x', 'd', 'v', '>', '<', 'p', 'h'};

for index = 1:length(ave_degree_array)
    ave_degree = ave_degree_array(index);
    
    color = color_array{mod(index, length(color_array))+1};
    marker = marker_array{mod(index, length(marker_array))+1};

    baseDir = sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_avedg_%.2f', A_alpha, A_beta, B_alpha, B_beta, ave_degree);
    A_R_data = load(fullfile(baseDir, sprintf('ER_Final_R_A_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), '-ascii');
    theoretical_data = load(fullfile(baseDir, sprintf('ER_theoretical_R_A_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_count_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), '-ascii');

    A_all_segs = zeros(times, once_range);
    for i=0:times-1
        A_all_segs(i+1, :) = A_R_data(i*once_range+1:(i+1)*once_range, 3)'/networksize;
    end

    [mean_A, square_variance, X_A] = modify_data(A_all_segs, times, 0.5);
    mean_result_variance = [0:0.01:1; mean_A; square_variance]';
    % save(fullfile(baseDir, sprintf('Mean_ER_Final_R_A_A_a_%.6f_A_b_%.6f_B_a_%.6f_c_%d_seed_%d.txt', T_A, T_B, seed_count, c)), 'mean_result_variance', '-ascii', '-double');
    X_A_result = [0:0.01:1; X_A]';
    % save(fullfile(baseDir, sprintf('ER_X_A_A_a_%.6f_A_b_%.6f_B_a_%.6f_c_%d_seed_%d.txt', T_A, T_B, seed_count, c)), 'X_A_result', '-ascii', '-double');

    subplot(2,1,1)
    errorbar(0:0.01:1,mean_A,square_variance, [marker color], 'DisplayName', ['\langlek\rangle=', num2str(ave_degree, '%d')]);
    hold on
    plot(0:0.01:1, theoretical_data(:,2), ['-' color], 'HandleVisibility','off');
    hold on
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13)
    xlim([0 1]);
    ylim([0 1]);
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)

    subplot(2,1,2)
    plot(0:0.01:1, X_A, ['-' color], 'DisplayName', ['\langlek\rangle=', num2str(ave_degree, '%d')]);
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('\chi', "FontName", "Times New Roman", "FontSize", 13)
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)
    hold on
end

% 保存.fig格式图窗
savefig(sprintf('ER_ave_degree_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.fig', A_alpha, A_beta, B_alpha, B_beta));
% 保存.jpg格式图
exportgraphics(gcf, sprintf('ER_ave_degree_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.jpg', A_alpha, A_beta, B_alpha, B_beta), ...
    'Resolution',600);
% 保存.eps格式矢量图
exportgraphics(gcf, sprintf('ER_ave_degree_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f.eps', A_alpha, A_beta, B_alpha, B_beta), ...
    'Resolution',600,'ContentType','vector');