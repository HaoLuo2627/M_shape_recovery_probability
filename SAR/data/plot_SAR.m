clear;
clc;
close all;

A_alpha=2.3333333333333333;
A_beta=0.3;
B_alpha=0.4285714285714286;
B_beta=0.7;
seed_count = 10;

baseDir = sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f', A_alpha, A_beta, B_alpha, B_beta);
averaged_S_time = load(fullfile(baseDir, sprintf('ER_Averaged_S_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), '-ascii');
averaged_A_time = load(fullfile(baseDir, sprintf('ER_Averaged_A_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), '-ascii');
averaged_R_time = load(fullfile(baseDir, sprintf('ER_Averaged_R_time_A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f_seed_%d.txt', A_alpha, A_beta, B_alpha, B_beta, seed_count)), '-ascii');

plot(averaged_S_time(:,1), averaged_S_time(:,2), 'b-o', 'DisplayName', 'S(t)');
hold on
plot(averaged_A_time(:,1), averaged_A_time(:,2), 'r-^', 'DisplayName', 'A(t)');
hold on
plot(averaged_R_time(:,1), averaged_R_time(:,2), 'g-s', 'DisplayName', 'R(t)');
xlabel('t', "FontName", "Times New Roman", "FontSize", 13);
ylabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13);
xlim([0 max(averaged_S_time(:,1))]);
ylim([0 1]);
legend('Location', 'best', "FontName", "Times New Roman", "FontSize", 13);

% 保存.fig格式图窗
savefig(fullfile(baseDir, sprintf('SAR.fig')));
% 保存.jpg格式图
exportgraphics(gcf, fullfile(baseDir, sprintf('SAR.jpg')), ...
    'Resolution',600);
% 保存.eps格式矢量图
exportgraphics(gcf, fullfile(baseDir, sprintf('SAR.eps')), ...
    'Resolution',600,'ContentType','vector');
