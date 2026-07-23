#ifndef CUSP_CONDITION_H
#define CUSP_CONDITION_H

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
double response_rate(double x, double alpha0, double beta0);

/**
 * cusp_condition - 条件判断（按概率返回是否采取防护行为）
 *
 * @param x   输入值，通常为 info_count / degree (局部感染比例)
 * @param alpha0   第一个区间的分界点，(0, 1)
 * @param beta0  第二个区间的分界点，(0, 1)
 * @return        true 表示采取防护行为
 */
bool cusp_condition(double x, double alpha0, double beta0);

#endif // CUSP_CONDITION_H
