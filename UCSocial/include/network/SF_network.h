/*
 * SF_network.h
 *
 *  Created on: 2017-7-16
 *      Author: Administrator
 */

#ifndef SF_NETWORK_H_
#define SF_NETWORK_H_

#include "network/network_total.h"
/*****
 * 建立SF网络的度序列
 */
void degree_Seq(Node SF[], double lambda, int SF_NETWORK_SIZE);
/*******
 * 根据度序列建立SF网络
 */
int SF_Model(Node SF[], int SF_NETWORK_SIZE);
#endif /* SF_NETWORK_H_ */
