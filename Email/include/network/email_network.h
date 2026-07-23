/*
 * email_network.h
 *
 * Agent-based Email Network Model (ENM).
 */

#ifndef EMAIL_NETWORK_H_
#define EMAIL_NETWORK_H_

#include "network/network_total.h"

typedef struct EmailNetworkParams {
	int estimated_network_size;
	int seed_size;
	double simulation_time;
	double involvement_parameter;
	double lognormal_mu;
	double lognormal_sigma;
	double p_un;
	double p_sel;
	double p_answer;
	double delete_interval_factor;
	int max_events;
} EmailNetworkParams;

EmailNetworkParams default_email_network_params(int estimated_network_size);

int ENM_Model(Node network[], int network_size, edge_element_t **edge_list, const EmailNetworkParams &params);

#endif /* EMAIL_NETWORK_H_ */
