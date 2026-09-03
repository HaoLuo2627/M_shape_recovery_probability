clc;
clear;
close all;
networksize = 10000;
seed_count = 10;

for A_a = [0.01, 0.2, 0.5, 0.8, 0.99]
    for A_c = [0.01, 0.2, 0.5, 0.8, 1]
		for v = [2, 4]
			try
			B_a = A_a;
			B_c = A_c;
			disp(['A_a = ' num2str(A_a) ', A_c = ' num2str(A_c) ', B_a = ' num2str(B_a) ', B_c = ' num2str(B_c) ', v = ' num2str(v)]);

			baseDir = sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f', A_a, A_c, B_a, B_c, v);
			A_R_data = load(fullfile(baseDir, sprintf('SF_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, v, seed_count)), '-ascii');
			theoretical_data = load(fullfile(baseDir, sprintf('SF_theoretical_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_count_%d.txt', A_a, A_c, B_a, B_c, v, seed_count)), '-ascii');
			once_range = 101;

			times = 1001;

			A_all_segs = zeros(times, once_range);
			for i=0:times-1
				A_all_segs(i+1, :) = A_R_data(i*once_range+1:(i+1)*once_range, 3)'/networksize;
			end

			[mean_A, square_variance, X_A] = modify_data(A_all_segs, times, 0);
			mean_result_variance = [0:0.01:1; mean_A; square_variance]';
			save(fullfile(baseDir, sprintf('Mean_SF_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, v, seed_count)), 'mean_result_variance', '-ascii', '-double');
			X_A_result = [0:0.01:1; X_A]';
			save(fullfile(baseDir, sprintf('SF_X_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.txt', A_a, A_c, B_a, B_c, v, seed_count)), 'X_A_result', '-ascii', '-double');

			subplot(2,1,1)
			errorbar(0:0.01:1,mean_A,square_variance,'ob');
			hold on
			plot(0:0.01:1, theoretical_data(:,2),  'k--');
			hold on
			xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
			ylabel('R(\infty)', "FontName", "Times New Roman", "FontSize", 13)
			xlim([0 1])
			ylim([0 1])

			subplot(2,1,2)
			plot(0:0.01:1, X_A, 'k');
			xlabel('\lambda', "FontName", "Times New Roman", "FontSize", 13)
			ylabel('\chi', "FontName", "Times New Roman", "FontSize", 13)
			hold on

			% 保存.fig格式图窗
			savefig([fullfile(baseDir, sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.fig', A_a, A_c, B_a, B_c, v, seed_count))]);
			% 保存.png格式图
			exportgraphics(gcf, [fullfile(baseDir, sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.png', A_a, A_c, B_a, B_c, v, seed_count))], ...
				'Resolution',300);
			% 保存.eps格式矢量图
			% exportgraphics(gcf, [fullfile(baseDir, sprintf('A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_v_%.2f_seed_%d.eps', A_a, A_c, B_a, B_c, v, seed_count))], ...
			%     'Resolution',300);
			close(gcf);
			catch ME
				fprintf(2, ['A_a = ' num2str(A_a) ', A_c = ' num2str(A_c) ', B_a = ' num2str(B_a) ', B_c = ' num2str(B_c) 'failed: %s\n'], ME.message);
				currentFig = get(groot, 'CurrentFigure');
				if ~isempty(currentFig)
					close(currentFig);
				end
				continue;
			end
		end
    end
end
