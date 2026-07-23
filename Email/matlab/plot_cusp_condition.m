clear;
close all;
x = 0:0.001:1;
A_theta=0.001;
A_beta=(1 - A_theta) / A_theta;
B_beta=1;
B_theta=1;
h_A = cusp_condition(x, A_beta, A_theta);
h_B = cusp_condition(x, B_beta, B_theta);
plot(x, h_A, 'DisplayName', 'h_A');
hold on
plot(x, h_B, 'DisplayName', 'h_B');
xlabel('\lambda');
ylabel('h');
legend('Location','best');
xlim([0 1]);
ylim([0 1]);
axis square;

exportgraphics(gcf, sprintf('A_beta_%f_A_theta_%f_B_beta_%f_B_theta_%f.png', A_beta, A_theta, B_beta, B_theta), ...
    'Resolution',300);