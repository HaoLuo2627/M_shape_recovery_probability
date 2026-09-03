#define _USE_MATH_DEFINES
#include <cmath>
#include <cstdio>
#include <algorithm>
#include <stdexcept>
#include "recovery_probability.h"


/**
 * 恢复概率函数
 *
 * 函数形式:
 *   prob = 2 * (1 - c0) * x / a0 + c0,                           if 0 <= x < a0 / 2
 *   prob = -2 * (1 - c0) * x / a0 + 2 - c0,                      if a0 / 2 <= x < a0
 *   prob = (2 * (1 - c0) * x + c0 - a0 * (2 - c0)) / (1 - a0),   if a0 <= x < (1 + a0) / 2
 *   prob = (-2 * (1 - c0) * x + 2 - a0 * c0 - c0) / (1 - a0),    if (1 + a0) / 2 <= x <= 1
 *   最后裁剪到 [0, 1]
 *
 * @param x       输入值，通常为 info_count / degree (局部感染比例)
 * @param a0      参数，必须 大于0 小于1
 * @param c0      M形的最小值点，必须 大于0 小于等于1
 * @return        裁剪到 [0, 1] 的概率值
 */
double recovery_probability(double x, double a0, double c0) {
    if ((a0 <= 0) || (a0 >= 1)) {
        fprintf(stderr, "a0 必须在(0, 1)之间, a0 = %f 非法\n", a0);
        throw std::invalid_argument("a0 must be in (0, 1)");
    }
    if ((c0 <= 0) || (c0 > 1)) {
        fprintf(stderr, "c0 必须在(0, 1]之间, c0 = %f 非法\n", c0);
        throw std::invalid_argument("c0 must be in (0, 1]");
    }
    
    double prob = 0;

    // 第一个区间：[0, a0 / 2)
    if ((0 <= x) & (x < a0 / 2)) {
        prob = 2 * (1 - c0) * x / a0 + c0;
    }
    // 第二个区间：[a0 / 2, a0)
    else if ((a0 / 2 <= x) & (x < a0)) {
        prob = -2 * (1 - c0) * x / a0 + 2 - c0;
    }
    // 第三个区间：[a0, (1 + a0) / 2)
    else if ((a0 <= x) & (x < (1 + a0) / 2)) {
        prob = (2 * (1 - c0) * x + c0 - a0 * (2 - c0)) / (1 - a0);
    }
    // 第四个区间：[(1 + a0) / 2, 1]
    else if (((1 + a0) / 2 <= x) & (x <= 1)) {
        prob = (-2 * (1 - c0) * x + 2 - a0 * c0 - c0) / (1 - a0);
    }

    // 裁剪到 [0, 1]
    prob = std::max(0.0, std::min(1.0, prob));

    if(std::abs(prob) < 1e-6) {
        throw std::runtime_error("Recovery probability must be in (0, 1], but got prob = 0.\nThis may indicate that the input x is out of the expected range or that the parameters a0 and c0 are not set correctly.\n");
    }

    return prob;
}

// ============================================================
// 简单测试主函数 (编译: g++ -O2 -Wall recovery_probability.cpp -o recovery_probability)
// ============================================================
// #define FUNC_DESIGN_TEST
#ifdef FUNC_DESIGN_TEST
#include <cstdio>

int main() {
    double a0 = 0.5;
    double c0 = 0.8;

    printf("a0=%f, c0=%f\n", a0, c0);
    printf("x\tprob\n");
    for (int i = 0; i <= 100; ++i) {
        double x = i / 100.0;
        double p = recovery_probability(x, a0, c0);
        printf("%.3f\t%.6f\n", x, p);
    }
    return 0;
}
#endif
