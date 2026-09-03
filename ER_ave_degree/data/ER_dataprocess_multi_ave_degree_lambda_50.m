clc;
clear;
close all;
networksize = 10000;
seed_count = 10;

A_a = 0.2;
A_c = 0.01;
B_a = A_a;
B_c = A_c;
disp(['A_a = ' num2str(A_a) ', A_c = ' num2str(A_c) ', B_a = ' num2str(B_a) ', B_c = ' num2str(B_c)]);

ave_degree_array = [5, 10, 20];

once_range = 101;
times = 1001;
color_array = {'c', 'b', 'r', 'g', 'm', 'k'};
marker_array = {'-', 'o', '^', 's', 'p', '+', '*', 'x', 'd', 'v', '>', '<', 'h'};

for index = 1:length(ave_degree_array)
    ave_degree = ave_degree_array(index);
    
    color = color_array{mod(index, length(color_array))+1};
    marker = marker_array{mod(index, length(marker_array))+1};

    baseDir = sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_avedg_%.2f', A_a, A_c, B_a, B_c, ave_degree);
    A_R_data = load(fullfile(baseDir, sprintf('ER_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');
    theoretical_data = load(fullfile(baseDir, sprintf('ER_theoretical_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_count_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');

    A_all_segs = zeros(times, once_range);
    for i=0:times-1
        A_all_segs(i+1, :) = A_R_data(i*once_range+1:(i+1)*once_range, 3)'/networksize;
    end

    [mean_A, square_variance, X_A] = modify_data(A_all_segs, times, 0);
    mean_result_variance = [0:0.01:1; mean_A; square_variance]';
    % save(fullfile(baseDir, sprintf('Mean_ER_Final_R_A_A_a_%.6f_A_b_%.6f_B_a_%.6f_c_%d_seed_%d.txt', T_A, T_B, seed_count, c)), 'mean_result_variance', '-ascii', '-double');
    X_A_result = [0:0.01:1; X_A]';
    % save(fullfile(baseDir, sprintf('ER_X_A_A_a_%.6f_A_b_%.6f_B_a_%.6f_c_%d_seed_%d.txt', T_A, T_B, seed_count, c)), 'X_A_result', '-ascii', '-double');

    subplot(2,1,1)
    errorbar(0:0.01:0.5,mean_A(1:51),square_variance(1:51), [marker color], 'DisplayName', ['\langlek\rangle=', num2str(ave_degree, '%d')]);
    hold on
    plot(0:0.01:0.5, theoretical_data(1:51,2), ['-' color], 'HandleVisibility','off');
    hold on
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13)
    xlim([0 0.5]);
    ylim([0 1]);
    xticks(0:0.1:0.5);
    yticks(0:0.2:1);
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)

    subplot(2,1,2)
    plot(0:0.01:0.5, X_A(1:51), ['-' color], 'DisplayName', ['\langlek\rangle=', num2str(ave_degree, '%d')]);
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('\chi', "FontName", "Times New Roman", "FontSize", 13)
    xlim([0 0.5]);
    xticks(0:0.1:0.5);
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)
    hold on
end

% 保存.fig格式图窗
savefig(sprintf('ER_ave_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.fig', A_a, A_c, B_a, B_c));
% 保存.jpg格式图
exportgraphics(gcf, sprintf('ER_ave_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.jpg', A_a, A_c, B_a, B_c), ...
    'Resolution',600);
% 保存.eps格式矢量图
exportgraphics(gcf, sprintf('ER_ave_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.eps', A_a, A_c, B_a, B_c), ...
    'Resolution',600,'ContentType','vector');