#ifndef RECOVERY_PROBABILITY_H
#define RECOVERY_PROBABILITY_H

/**
 * 恢复概率函数
 *
 * 函数形式:
 *   prob = 2 * x / a0,                                           if 0 <= x < a0 / 2
 *   prob = - 2 * (1 - c0) * x / a0 + 2 - c0,                     if a0 / 2 <= x < a0
 *   prob = (2 * (1 - c0) * x + c0 - a0 * (2 - c0)) / (1 - a0),   if a0 <= x < (1 + a0) / 2
 *   prob = 2 * (1 - x) / (1 - a0),                               if (1 + a0) / 2 <= x <= 1
 *   最后裁剪到 [0, 1]
 *
 * @param x       输入值，通常为 info_count / degree (局部感染比例)
 * @param a0      参数，必须 大于0 小于1
 * @param c0      M形的谷值点，必须 大于等于0 小于等于1
 * @return        裁剪到 [0, 1] 的概率值
 */
double recovery_probability(double x, double a0, double c0);

#endif // RECOVERY_PROBABILITY_H
