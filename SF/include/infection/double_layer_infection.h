/*
 * double_layer_infection.h
 *
 *  Created on: 2017-8-11
 *      Author: Administrator
 */

#ifndef DOUBLE_LAYER_INFECTION_H_
#define DOUBLE_LAYER_INFECTION_H_

#include "total.h"
#include "network/network_total.h"
#include "network/network_basic_ops.h"

void double_layer_infection(Node A[], Node B[], double alpha_A, double r_A, double alpha_B, double r_B, double A_beta, double A_theta, double B_beta, double B_theta, int k_count, int seed[], int network_size, char *file_A, char *file_B);

#endif /* DOUBLE_LAYER_INFECTION_H_ */

