clear;
clc;
close all;

A_a = 0.2;
A_c = 0.2;
B_a = A_a;
B_c = A_c;
seed_count = 10;

baseDir = sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f', A_a, A_c, B_a, B_c);
averaged_S_time = load(fullfile(baseDir, sprintf('ER_Averaged_S_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');
averaged_A_time = load(fullfile(baseDir, sprintf('ER_Averaged_A_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');
averaged_R_time = load(fullfile(baseDir, sprintf('ER_Averaged_R_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, seed_count)), '-ascii');

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
