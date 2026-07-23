% 设计系统模型时斜率是beta，分段点是theta，但是在推公式时发现theta已经被占用了，所以推导公式时斜率是alpha，分段点是beta。
% 画图与论文中符号一致，所以纵坐标theta改成beta。代码写完并且跑出很多数据，改文件名工作量太大，所以只能这么折衷了。
clear;
clc;
close all;

A_alpha=1.02;
A_beta=0.33;
B_alpha=1;
B_beta=1;
seed_count = 10;

lambda_vec = 0:0.01:1;
round_scale = length(lambda_vec);  % 一次种子对应101个lambda
theta_array = [0.001, 0.01:0.01:0.66];
R_data = zeros(length(theta_array), round_scale);
baseDir = fullfile('y_2_3_x_A_beta_0-0.66_B_alpha_1.00_B_beta_1.00', sprintf('A_alpha_%.2f_A_beta_%.2f_B_alpha_%.2f_B_beta_%.2f', A_alpha, A_beta, B_alpha, B_beta));
file_name = fullfile(baseDir, sprintf('ER_all_theoretical_B_alpha_%.2f_B_beta_%.2f_seed_count_%d.txt', B_alpha, B_beta, seed_count));
R_all_theoretical_data = load(file_name, '-ascii');
for seed_index = 0:length(theta_array)-1
    range_data = seed_index*round_scale+(1:round_scale);
    R_data(seed_index+1, :) = R_all_theoretical_data(range_data,2)';
end

[x,y] = meshgrid(lambda_vec, theta_array);
surf(x,y,R_data);
colorbar('location','EastOutside')
hold on

axis equal
% axis square

colormap(jet);  % 蓝->青->黄->红
clim([0 1]);    % 颜色范围固定
view(2);        % 俯视图（top view）

xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13);
ylabel('\beta^{A}', "FontName", "Times New Roman", "FontSize", 13);
zlabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13);
shading interp;  % 平滑颜色

% --- 求色温图二阶连续与一阶不连续区域的分界线 --- 
[Max_R_diff, Index_R_diff] = max(diff(R_data, 1, 2), [], 2)
threshold = 0.9;  % 一阶不连续区域的判定阈值

% 找到第一个大于 threshold 的 Max_R_diff 对应的 theta 索引
partition_idx = find(Max_R_diff > threshold, 1, 'first');
if ~isempty(partition_idx)
    theta_part = theta_array(partition_idx);
    disp(['Region partition theta = ', num2str(theta_part), ...
          ',  index = ', num2str(partition_idx)]);
    lambda_part = lambda_vec(Index_R_diff(partition_idx)+1);  % 把 lambda 维度差分减掉的1个数加回来
    disp(['Corresponding lambda = ', num2str(lambda_part)]);
    disp(['Corresponding diff R(\infty) = ', num2str(Max_R_diff(partition_idx))]);
    % 绘制区域的分界线
    plot3(xlim, theta_part * [1 1], [1 1], 'w--', 'LineWidth', 2);
    
    % 标记分界线的数值
    annotation_string = sprintf('$\\beta^{*} = %.2f$', theta_part);
    annotation('textarrow', [lambda_part-0.15, lambda_part-0.1], [theta_part+0.08, theta_part+0.02], ...
        'Interpreter', 'latex', 'String', annotation_string, ...
        "FontName", "Times New Roman", "FontSize", 13, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], "LineWidth", 1);
    annotation("textbox", [lambda_part/2 theta_part/2 0.05 0.05], "String", "I", ...
        "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
        "EdgeColor", "none", "LineStyle", "none")
    annotation("textbox", [lambda_part/2 (theta_part+1)/2 0.05 0.05], "String", "II", ...
        "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
        "EdgeColor", "none", "LineStyle", "none")
else
    disp('No region partition found (no Max_R_diff exceeds threshold).');
end

% 保存.fig格式图窗
savefig([fullfile(baseDir, sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.fig', B_alpha, B_beta))]);
% 保存.jpg格式图
exportgraphics(gcf, [fullfile(baseDir, sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.jpg', B_alpha, B_beta))], ...
    'Resolution',600);
% 保存.pdf格式图
exportgraphics(gcf, [fullfile(baseDir, sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.pdf', B_alpha, B_beta))], ...
    'Resolution',600);
% 保存.fig格式图窗
savefig([fullfile('color_temp_figures', sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.fig', B_alpha, B_beta))]);
% 保存.jpg格式图
exportgraphics(gcf, [fullfile('color_temp_figures', sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.jpg', B_alpha, B_beta))], ...
    'Resolution',600);
% 保存.pdf格式图
exportgraphics(gcf, [fullfile('color_temp_figures', sprintf('ER_A_beta_color_temp_figure_y_2_3_x_B_alpha_%.2f_B_beta_%.2f.pdf', B_alpha, B_beta))], ...
    'Resolution',600);
