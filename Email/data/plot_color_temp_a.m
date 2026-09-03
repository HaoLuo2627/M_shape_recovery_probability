clear;
clc;
close all;

A_a_ref=0.2;
B_a_ref=0.2;
A_c=0.2;
B_c=0.2;
seed_count = 5;
threshold = 0.7;  % 一阶不连续区域的判定阈值

lambda_vec = 0:0.01:0.50;
round_scale = length(lambda_vec);  % 一次种子对应51个lambda
a_array = 0.01:0.01:0.99;
R_data = zeros(length(a_array), round_scale);
baseDir = sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f', A_a_ref, A_c, B_a_ref, B_c);
file_name = fullfile(baseDir, sprintf('Email_all_theoretical_A_c_%.2f_B_c_%.2f_seed_count_%d.txt', A_c, B_c, seed_count));
R_all_theoretical_data = load(file_name, '-ascii');
for seed_index = 0:length(a_array)-1
    range_data = seed_index*round_scale+(1:round_scale);
    R_data(seed_index+1, :) = R_all_theoretical_data(range_data,2)';
end

[x,y] = meshgrid(lambda_vec, a_array);
surf(x,y,R_data);
colorbar('location','EastOutside')
hold on
xticks(0:0.1:0.5);
yticks(0:0.1:1);

axis equal
% axis square

colormap(jet);  % 蓝->青->黄->红
clim([0 1]);    % 颜色范围固定
view(2);        % 俯视图（top view）

xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13);
ylabel('a', "FontName", "Times New Roman", "FontSize", 13);
zlabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13);
shading interp;  % 平滑颜色

% --- 求色温图二阶连续与一阶不连续区域的分界线 --- 
[Max_R_diff, Index_R_diff] = max(diff(R_data, 1, 2), [], 2)

% 找到第一个大于 threshold 的 Max_R_diff 对应的 A_a 索引
partition_idx_first = find(Max_R_diff > threshold, 1, 'first')
% 找到最后一个大于 threshold 的 Max_R_diff 对应的 A_a 索引
partition_idx_second = find(Max_R_diff > threshold, 1, 'last')
if ~isempty(partition_idx_first) || ~isempty(partition_idx_second)
    % 如果只有一条区域分界线
    if (partition_idx_first == partition_idx_second) || (partition_idx_first == 1)
        A_a_part = a_array(partition_idx_second);
        disp(['Region partition a = ', num2str(A_a_part), ...
              ',  index = ', num2str(partition_idx_second)]);
        lambda_part = lambda_vec(Index_R_diff(partition_idx_second)+1);  % 把 lambda 维度差分减掉的1个数加回来
        disp(['Corresponding lambda = ', num2str(lambda_part)]);
        disp(['Corresponding diff R(\infty) = ', num2str(Max_R_diff(partition_idx_second))]);
        % 绘制区域的分界线
        plot3(xlim, A_a_part * [1 1], [1 1], 'w--', 'LineWidth', 2);
        
        % 标记分界线的数值
        annotation_string = sprintf('$a^{*} = %.2f$', A_a_part);
        annotation('textarrow', [lambda_part, lambda_part], [A_a_part+0.08, A_a_part+0.02], ...
            'Interpreter', 'latex', 'String', annotation_string, ...
            "FontName", "Times New Roman", "FontSize", 13, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], "LineWidth", 1);
        annotation("textbox", [lambda_part/2 A_a_part/2 0.05 0.05], "String", "I", ...
            "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
            "EdgeColor", "none", "LineStyle", "none")
        annotation("textbox", [lambda_part/2 (A_a_part+1)/2 0.05 0.05], "String", "II", ...
            "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
            "EdgeColor", "none", "LineStyle", "none")
    % 如果有两条区域分界线
    else
        % 求解并画出区域I和II的分界线
        A_a_part_first = a_array(partition_idx_first);
        disp(['Region I and II partition a = ', num2str(A_a_part_first), ...
              ',  index = ', num2str(partition_idx_first)]);
        lambda_part_first = lambda_vec(Index_R_diff(partition_idx_first)+1);  % 把 lambda 维度差分减掉的1个数加回来
        disp(['Corresponding lambda = ', num2str(lambda_part_first)]);
        disp(['Corresponding diff R(\infty) = ', num2str(Max_R_diff(partition_idx_first))]);
        % 绘制区域的分界线
        plot3(xlim, A_a_part_first * [1 1], [1 1], 'w--', 'LineWidth', 2);
        
        % 标记分界线的数值
        annotation_string = sprintf('$a^{*} = %.2f$', A_a_part_first);
        annotation('textarrow', [lambda_part_first, lambda_part_first], [A_a_part_first+0.08, A_a_part_first+0.02], ...
            'Interpreter', 'latex', 'String', annotation_string, ...
            "FontName", "Times New Roman", "FontSize", 13, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], "LineWidth", 1);
        annotation("textbox", [lambda_part_first/2 A_a_part_first/2 0.05 0.05], "String", "I", ...
            "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
            "EdgeColor", "none", "LineStyle", "none")
        annotation("textbox", [lambda_part_first/2 (A_a_part_first+1)/2 0.05 0.05], "String", "II", ...
            "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
            "EdgeColor", "none", "LineStyle", "none")
        
        % 求解并画出区域II和III的分界线
        A_a_part_second = a_array(partition_idx_second);
        disp(['Region II and III partition a = ', num2str(A_a_part_second), ...
              ',  index = ', num2str(partition_idx_second)]);
        lambda_part_second = lambda_vec(Index_R_diff(partition_idx_second)+1);  % 把 lambda 维度差分减掉的1个数加回来
        disp(['Corresponding lambda = ', num2str(lambda_part_second)]);
        disp(['Corresponding diff R(\infty) = ', num2str(Max_R_diff(partition_idx_second))]);
        % 绘制区域的分界线
        plot3(xlim, A_a_part_second * [1 1], [1 1], 'w:', 'LineWidth', 2);
        
        % 标记分界线的数值
        annotation_string = sprintf('$a^{**} = %.2f$', A_a_part_second);
        annotation('textarrow', [lambda_part_second, lambda_part_second], [A_a_part_second+0.08, A_a_part_second+0.02], ...
            'Interpreter', 'latex', 'String', annotation_string, ...
            "FontName", "Times New Roman", "FontSize", 13, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], "LineWidth", 1);
        annotation("textbox", [lambda_part_second/2 (A_a_part_second+1)/2 0.05 0.05], "String", "III", ...
            "FontName", "Times New Roman", "FontSize", 15, "FontWeight", "bold", "Color", [1.0000, 1.0000, 1.0000], ...
            "EdgeColor", "none", "LineStyle", "none")
    end
else
    disp('No region partition found (no Max_R_diff exceeds threshold).');
end

color_temp_folder = 'color_temp_figures';
% 检查如果结果文件夹不存在则创建
if ~isfolder(color_temp_folder)
    mkdir(color_temp_folder);
end

% 保存.fig格式图窗
savefig([fullfile(baseDir, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.fig', A_c, B_c))]);
% 保存.jpg格式图
exportgraphics(gcf, [fullfile(baseDir, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.jpg', A_c, B_c))], ...
    'Resolution',600);
% 保存.pdf格式图
exportgraphics(gcf, [fullfile(baseDir, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.pdf', A_c, B_c))], ...
    'Resolution',600);
% 保存.fig格式图窗
savefig([fullfile(color_temp_folder, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.fig', A_c, B_c))]);
% 保存.jpg格式图
exportgraphics(gcf, [fullfile(color_temp_folder, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.jpg', A_c, B_c))], ...
    'Resolution',600);
% 保存.pdf格式图
exportgraphics(gcf, [fullfile(color_temp_folder, sprintf('Email_color_temp_figure_A_c_%.2f_B_c_%.2f.pdf', A_c, B_c))], ...
    'Resolution',600);
