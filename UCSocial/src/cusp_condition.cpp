#define _USE_MATH_DEFINES
#include <cmath>
#include <cstdio>
#include <algorithm>
#include <stdexcept>
#include "cusp_condition.h"


/**
 * cusp_condition - Cusp条件函数
 *
 * 函数形式:
 *   prob = 1 - x / alpha0,                                if 0 <= x <= alpha0
 *   prob = 0,                                            if alpha0 < x <= beta0
 *   prob = (x - beta0) / (1 - beta0),                       if beta0 < x <= 1
 *   最后裁剪到 [0, 1]
 *
 * @param x   输入值，通常为 info_count / degree (局部感染比例)
 * @param alpha0   第一个区间的分界点，(0, 1)
 * @param beta0  第二个区间的分界点，(0, 1)
 * @return    裁剪到 [0, 1] 的概率值
 */
double response_rate(double x, double alpha0, double beta0) {
    if ((alpha0 <= 0) || (alpha0 >= 1)) {
        fprintf(stderr, "alpha0 必须在(0, 1)之间, alpha0 = %f 非法\n", alpha0);
        throw std::invalid_argument("alpha0 must be in (0, 1)");
    }
    if ((beta0 <= 0) || (beta0 >= 1)) {
        fprintf(stderr, "beta0 必须在(0, 1)之间, beta0 = %f 非法\n", beta0);
        throw std::invalid_argument("beta0 must be in (0, 1)");
    }
    if (alpha0 >= beta0) {
        fprintf(stderr, "alpha0 必须小于 beta0, alpha0 = %f, beta0 = %f 非法\n", alpha0, beta0);
        throw std::invalid_argument("alpha0 must be less than beta0");
    }
    double prob = 0;
    double eps = 1e-16; // 防止除以零的极小值

    // 第一个区间：[0, alpha0]
    if ((0 <= x) && (x <= alpha0)) {
        prob = 1 - x / alpha0;
    }
    // 第二个区间：(alpha0, beta0]
    else if ((alpha0 < x) && (x <= beta0)) {
        prob = 0;
    }
    // 第三个区间：(beta0, 1]
    else if ((beta0 < x) && (x <= 1)) {
        prob = (x - beta0) / (1 - beta0 + eps);
    }

    // 裁剪到 [0, 1]
    prob = std::max(0.0, std::min(1.0, prob));

    return prob;
}

/**
 * cusp_condition - 条件判断（按概率返回是否采取防护行为）
 *
 * @param x   输入值，通常为 info_count / degree (局部感染比例)
 * @param alpha0   第一个区间的分界点，(0, 1)
 * @param beta0  第二个区间的分界点，(0, 1)
 * @return        true 表示采取防护行为
 */
bool cusp_condition(double x, double alpha0, double beta0) {
    double prob = response_rate(x, alpha0, beta0);
    double rd_accept_rate = static_cast<double>(rand()) / static_cast<double>(RAND_MAX);

	if (rd_accept_rate <= prob){
        return true;
	}else{
        return false;
	}
}

// ============================================================
// 简单测试主函数 (编译: g++ -O2 -Wall cusp_condition.cpp -o cusp_condition)
// ============================================================
// #define FUNC_DESIGN_TEST
#ifdef FUNC_DESIGN_TEST
#include <cstdio>

int main() {
    double alpha0 = 0.5;
    double beta0 = 0.8;

    printf("alpha0=%f, beta0=%f\n", alpha0, beta0);
    printf("x\tprob\n");
    for (int i = 0; i <= 100; ++i) {
        double x = i / 100.0;
        double p = response_rate(x, alpha0, beta0);
        printf("%.3f\t%.6f\n", x, p);
    }
    return 0;
}
#endif
