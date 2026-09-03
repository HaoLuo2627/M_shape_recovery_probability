clc;
clear;
close all;
networksize = 10000;
seed_count = 10;

A_a = 0.2;
B_a = A_a;

A_c_array = [0.01, 0.2, 0.5, 1];

once_range = 101;
times = 1001;
color_array = {'c', 'b', 'r', 'g', 'm', 'k'};
marker_array = {'-', 'o', '^', 's', 'p', '+', '*', 'x', 'd', 'v', '>', '<', 'h'};

for index = 1:length(A_c_array)
    A_c = A_c_array(index);
    B_c = A_c;
    color = color_array{mod(index, length(color_array))+1};
    marker = marker_array{mod(index, length(marker_array))+1};

    baseDir = sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f', A_a, A_c, B_a, B_c);
    A_R_data = load(fullfile(baseDir, sprintf('ER_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');
    theoretical_data = load(fullfile(baseDir, sprintf('ER_theoretical_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_count_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');

    A_all_segs = zeros(times, once_range);
    for i=0:times-1
        A_all_segs(i+1, :) = A_R_data(i*once_range+1:(i+1)*once_range, 3)'/networksize;
    end

    [mean_A, square_variance, X_A] = modify_data(A_all_segs, times, 0);
    mean_result_variance = [0:0.01:1; mean_A; square_variance]';
    % save(fullfile(baseDir, sprintf('Mean_ER_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), 'mean_result_variance', '-ascii', '-double');
    X_A_result = [0:0.01:1; X_A]';
    % save(fullfile(baseDir, sprintf('ER_X_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), 'X_A_result', '-ascii', '-double');

    subplot(2,1,1)
    errorbar(0:0.01:1,mean_A,square_variance, [marker color], 'DisplayName', ['c=', num2str(A_c, '%.2f')]);
    hold on
    plot(0:0.01:1, theoretical_data(:,2), ['-' color], 'HandleVisibility','off');
    hold on
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13)
    xlim([0 1]);
    ylim([0 1]);
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)

    subplot(2,1,2)
    plot(0:0.01:1, X_A, ['-' color], 'DisplayName', ['c=', num2str(A_c, '%.2f')]);
    xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
    ylabel('\chi', "FontName", "Times New Roman", "FontSize", 13)
    legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13)
    hold on
end

% 检查如果结果文件夹不存在则创建
if ~isfolder('trend_figures')
    mkdir('trend_figures');
end

% 保存.fig格式图窗
savefig([fullfile('trend_figures', sprintf('ER_trend_figure_A_a_%.2f_B_a_%.2f.fig', A_a, B_a))]);
% 保存.jpg格式图
exportgraphics(gcf, [fullfile('trend_figures', sprintf('ER_trend_figure_A_a_%.2f_B_a_%.2f.jpg', A_a, B_a))], ...
    'Resolution',600);
% 保存.eps格式矢量图
exportgraphics(gcf, [fullfile('trend_figures', sprintf('ER_trend_figure_A_a_%.2f_B_a_%.2f.eps', A_a, B_a))], ...
    'Resolution',600,'ContentType','vector');
