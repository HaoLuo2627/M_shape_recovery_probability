/*
 * email_network.cpp
 *
 * Agent-based Email Network Model (ENM).  Edges are created only after two
 * nodes have exchanged email in both directions.
 */

#include "total.h"
#include "network/email_network.h"
#include "network/network_basic_ops.h"
#include <algorithm>
#include <queue>
#include <set>
#include <vector>

namespace {

const double MIN_ATTRACTIVENESS = 1.0e-6;
const double MIN_INVOLVEMENT = 1.0e-6;

enum EmailEventType {
	EMAIL_EVENT_SEND = 0,
	EMAIL_EVENT_REPLY = 1,
	EMAIL_EVENT_DELETE_CONTACT = 2
};

typedef struct EmailAgent {
	double attractiveness;
	double involvement;
	std::vector<int> contacts;
	bool active;
} EmailAgent;

typedef struct EmailEvent {
	double time;
	int type;
	int sender;
	std::vector<int> receivers;
	unsigned long sequence;
} EmailEvent;

struct EmailEventLater {
	bool operator()(const EmailEvent &left, const EmailEvent &right) const
	{
		if (left.time == right.time) {
			return left.sequence > right.sequence;
		}
		return left.time > right.time;
	}
};

double unit_rand()
{
	return ((double)rand() + 1.0) / ((double)RAND_MAX + 2.0);
}

double standard_normal_rand()
{
	static int has_cached = 0;
	static double cached = 0.0;

	if (has_cached) {
		has_cached = 0;
		return cached;
	}

	double u1 = unit_rand();
	double u2 = unit_rand();
	double radius = sqrt(-2.0 * log(u1));
	double angle = 2.0 * 3.14159265358979323846 * u2;
	cached = radius * sin(angle);
	has_cached = 1;
	return radius * cos(angle);
}

double lognormal_rand(double mu, double sigma)
{
	return exp(mu + sigma * standard_normal_rand());
}

double sample_involvement(double involvement_parameter)
{
	double z = pow(involvement_parameter + 1.0, unit_rand()) - 1.0;
	double involvement = z / involvement_parameter;
	if (involvement < MIN_INVOLVEMENT) {
		return MIN_INVOLVEMENT;
	}
	if (involvement > 1.0) {
		return 1.0;
	}
	return involvement;
}

double send_interval(const EmailAgent &agent, const EmailNetworkParams &params)
{
	double interval = lognormal_rand(params.lognormal_mu, params.lognormal_sigma);
	return interval / std::max(agent.involvement, MIN_INVOLVEMENT);
}

bool contains_node(const std::vector<int> &nodes, int value)
{
	return std::find(nodes.begin(), nodes.end(), value) != nodes.end();
}

void add_unique(std::vector<int> &nodes, int value)
{
	if (!contains_node(nodes, value)) {
		nodes.push_back(value);
	}
}

void add_contact(EmailAgent &agent, int contact)
{
	add_unique(agent.contacts, contact);
}

void schedule_event(
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	double time,
	int type,
	int sender,
	const std::vector<int> &receivers,
	unsigned long &sequence)
{
	EmailEvent event;
	event.time = time;
	event.type = type;
	event.sender = sender;
	event.receivers = receivers;
	event.sequence = sequence++;
	events.push(event);
}

void schedule_send(
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	const std::vector<EmailAgent> &agents,
	const EmailNetworkParams &params,
	double current_time,
	int sender,
	unsigned long &sequence)
{
	std::vector<int> empty_receivers;
	double next_time = current_time + send_interval(agents[sender], params);
	schedule_event(events, next_time, EMAIL_EVENT_SEND, sender, empty_receivers, sequence);
}

void schedule_delete(
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	const std::vector<EmailAgent> &agents,
	const EmailNetworkParams &params,
	double current_time,
	int node,
	unsigned long &sequence)
{
	std::vector<int> empty_receivers;
	double next_time = current_time + params.delete_interval_factor * send_interval(agents[node], params);
	schedule_event(events, next_time, EMAIL_EVENT_DELETE_CONTACT, node, empty_receivers, sequence);
}

int activate_node(
	std::vector<EmailAgent> &agents,
	Node network[],
	int network_size,
	int &active_count,
	double current_time,
	const EmailNetworkParams &params,
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	unsigned long &sequence)
{
	if (active_count >= network_size) {
		return -1;
	}

	int node = active_count;
	agents[node].active = true;
	network[node].active = 1;
	active_count++;

	schedule_send(events, agents, params, current_time, node, sequence);
	schedule_delete(events, agents, params, current_time, node, sequence);
	return node;
}

bool is_excluded(int candidate, int sender, const std::set<int> &excluded)
{
	if (candidate == sender) {
		return true;
	}
	return excluded.find(candidate) != excluded.end();
}

int weighted_pick_from_contacts(
	const std::vector<int> &contacts,
	const std::vector<EmailAgent> &agents,
	Node network[],
	int sender,
	const std::set<int> &excluded)
{
	std::vector<int> candidates;
	double degree_sum = 0.0;
	double attractiveness_sum = 0.0;

	for (size_t i = 0; i < contacts.size(); i++) {
		int candidate = contacts[i];
		if (candidate < 0 || candidate >= (int)agents.size()) {
			continue;
		}
		if (!agents[candidate].active || is_excluded(candidate, sender, excluded)) {
			continue;
		}
		candidates.push_back(candidate);
		degree_sum += std::max(network[candidate].degree, 0);
		attractiveness_sum += agents[candidate].attractiveness;
	}

	if (candidates.empty()) {
		return -1;
	}

	std::vector<double> weights(candidates.size(), 0.0);
	double weight_sum = 0.0;
	for (size_t i = 0; i < candidates.size(); i++) {
		int candidate = candidates[i];
		double degree_weight = degree_sum > 0.0 ?
			(double)std::max(network[candidate].degree, 0) / degree_sum :
			1.0 / (double)candidates.size();
		double attractiveness_weight = attractiveness_sum > 0.0 ?
			agents[candidate].attractiveness / attractiveness_sum :
			1.0 / (double)candidates.size();
		weights[i] = 0.5 * (degree_weight + attractiveness_weight);
		weight_sum += weights[i];
	}

	double threshold = unit_rand() * weight_sum;
	double cumulative = 0.0;
	for (size_t i = 0; i < candidates.size(); i++) {
		cumulative += weights[i];
		if (threshold <= cumulative) {
			return candidates[i];
		}
	}
	return candidates.back();
}

int weighted_pick_unknown_existing(
	const std::vector<EmailAgent> &agents,
	int active_count,
	int sender,
	const std::set<int> &excluded)
{
	std::vector<int> candidates;
	double attractiveness_sum = 0.0;

	for (int i = 0; i < active_count; i++) {
		if (!agents[i].active || is_excluded(i, sender, excluded)) {
			continue;
		}
		if (contains_node(agents[sender].contacts, i)) {
			continue;
		}
		candidates.push_back(i);
		attractiveness_sum += agents[i].attractiveness;
	}

	if (candidates.empty()) {
		return -1;
	}

	double threshold = unit_rand() * attractiveness_sum;
	double cumulative = 0.0;
	for (size_t i = 0; i < candidates.size(); i++) {
		cumulative += agents[candidates[i]].attractiveness;
		if (threshold <= cumulative) {
			return candidates[i];
		}
	}
	return candidates.back();
}

int select_unknown_receiver(
	std::vector<EmailAgent> &agents,
	Node network[],
	int network_size,
	int &active_count,
	double current_time,
	int sender,
	const std::set<int> &excluded,
	const EmailNetworkParams &params,
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	unsigned long &sequence)
{
	double p_new = 1.0 - ((double)active_count / (double)params.estimated_network_size);
	if (p_new < 0.0) {
		p_new = 0.0;
	}

	if (active_count < network_size && unit_rand() < p_new) {
		return activate_node(agents, network, network_size, active_count, current_time, params, events, sequence);
	}

	int receiver = weighted_pick_unknown_existing(agents, active_count, sender, excluded);
	if (receiver >= 0) {
		return receiver;
	}

	if (active_count < network_size) {
		return activate_node(agents, network, network_size, active_count, current_time, params, events, sequence);
	}

	return -1;
}

std::vector<int> choose_receivers(
	std::vector<EmailAgent> &agents,
	Node network[],
	int network_size,
	int &active_count,
	double current_time,
	int sender,
	const EmailNetworkParams &params,
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	unsigned long &sequence)
{
	std::vector<int> receivers;
	int contact_count = (int)agents[sender].contacts.size();
	int receiver_count = contact_count > 0 ? (rand() % contact_count) + 1 : 1;
	int max_attempts = 100 + receiver_count * 20;

	for (int attempt = 0; attempt < max_attempts && (int)receivers.size() < receiver_count; attempt++) {
		std::set<int> excluded(receivers.begin(), receivers.end());
		int receiver = -1;

		if (contact_count == 0 || unit_rand() < params.p_un) {
			receiver = select_unknown_receiver(
				agents, network, network_size, active_count, current_time, sender,
				excluded, params, events, sequence);
		} else if (!receivers.empty() && unit_rand() < params.p_sel) {
			int selected = receivers[rand() % receivers.size()];
			receiver = weighted_pick_from_contacts(agents[selected].contacts, agents, network, sender, excluded);
			if (receiver < 0) {
				receiver = weighted_pick_from_contacts(agents[sender].contacts, agents, network, sender, excluded);
			}
		} else {
			receiver = weighted_pick_from_contacts(agents[sender].contacts, agents, network, sender, excluded);
		}

		if (receiver >= 0 && receiver != sender && !contains_node(receivers, receiver)) {
			receivers.push_back(receiver);
		}
	}

	if (receivers.empty()) {
		std::set<int> excluded;
		int receiver = select_unknown_receiver(
			agents, network, network_size, active_count, current_time, sender,
			excluded, params, events, sequence);
		if (receiver >= 0 && receiver != sender) {
			receivers.push_back(receiver);
		}
	}

	return receivers;
}

void delete_contact(std::vector<EmailAgent> &agents, int node)
{
	if (agents[node].contacts.empty()) {
		return;
	}

	double weight_sum = 0.0;
	for (size_t i = 0; i < agents[node].contacts.size(); i++) {
		int contact = agents[node].contacts[i];
		weight_sum += 1.0 / std::max(agents[contact].attractiveness, MIN_ATTRACTIVENESS);
	}

	double threshold = unit_rand() * weight_sum;
	double cumulative = 0.0;
	for (size_t i = 0; i < agents[node].contacts.size(); i++) {
		int contact = agents[node].contacts[i];
		cumulative += 1.0 / std::max(agents[contact].attractiveness, MIN_ATTRACTIVENESS);
		if (threshold <= cumulative) {
			agents[node].contacts.erase(agents[node].contacts.begin() + i);
			return;
		}
	}

	agents[node].contacts.pop_back();
}

bool add_social_edge(
	Node network[],
	std::vector<std::vector<unsigned char> > &social_edge,
	int from,
	int to)
{
	if (from == to || social_edge[from][to]) {
		return false;
	}

	create(network[from].next, to);
	create(network[to].next, from);
	social_edge[from][to] = 1;
	social_edge[to][from] = 1;
	network[from].degree++;
	network[to].degree++;
	return true;
}

void process_email(
	std::vector<EmailAgent> &agents,
	Node network[],
	int network_size,
	int &active_count,
	std::vector<std::vector<unsigned char> > &sent_mail,
	std::vector<std::vector<unsigned char> > &social_edge,
	double current_time,
	int sender,
	const std::vector<int> &input_receivers,
	const EmailNetworkParams &params,
	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> &events,
	unsigned long &sequence,
	int &mail_count,
	int &edge_count)
{
	if (sender < 0 || sender >= network_size || !agents[sender].active) {
		return;
	}

	std::vector<int> receivers;
	for (size_t i = 0; i < input_receivers.size(); i++) {
		int receiver = input_receivers[i];
		if (receiver >= 0 && receiver < network_size && receiver != sender && agents[receiver].active) {
			add_unique(receivers, receiver);
		}
	}

	if (receivers.empty()) {
		return;
	}

	mail_count++;

	for (size_t i = 0; i < receivers.size(); i++) {
		int receiver = receivers[i];
		add_contact(agents[sender], receiver);
		sent_mail[sender][receiver] = 1;
		if (sent_mail[receiver][sender]) {
			if (add_social_edge(network, social_edge, sender, receiver)) {
				edge_count++;
			}
		}
	}

	for (size_t i = 0; i < receivers.size(); i++) {
		int receiver = receivers[i];
		double p_reply = params.p_answer * agents[sender].attractiveness;
		if (unit_rand() >= p_reply) {
			continue;
		}

		std::vector<int> reply_receivers;
		add_unique(reply_receivers, sender);
		for (size_t j = 0; j < receivers.size(); j++) {
			int other = receivers[j];
			if (other == receiver) {
				continue;
			}
			if (unit_rand() < agents[other].attractiveness) {
				add_unique(reply_receivers, other);
			}
		}

		double reply_time = current_time + send_interval(agents[receiver], params);
		schedule_event(events, reply_time, EMAIL_EVENT_REPLY, receiver, reply_receivers, sequence);
	}
}

void initialize_agents(std::vector<EmailAgent> &agents, const EmailNetworkParams &params)
{
	for (size_t i = 0; i < agents.size(); i++) {
		agents[i].attractiveness = std::max(unit_rand(), MIN_ATTRACTIVENESS);
		agents[i].involvement = sample_involvement(params.involvement_parameter);
		agents[i].contacts.clear();
		agents[i].active = false;
	}
}

} // namespace

EmailNetworkParams default_email_network_params(int estimated_network_size)
{
	EmailNetworkParams params;
	params.estimated_network_size = estimated_network_size;
	params.seed_size = 1;
	params.simulation_time = 3.0 * 365.0 * 24.0;
	params.involvement_parameter = 200.0;
	params.lognormal_mu = 3.35;
	params.lognormal_sigma = 3.6;
	params.p_un = 0.20;
	params.p_sel = 0.35;
	params.p_answer = 0.45;
	params.delete_interval_factor = 8.0;
	params.max_events = 2000000;
	return params;
}

int ENM_Model(Node network[], int network_size, edge_element_t **edge_list, const EmailNetworkParams &params)
{
	if (edge_list != NULL) {
		*edge_list = NULL;
	}

	for (int i = 0; i < network_size; i++) {
		network[i].degree = 0;
		network[i].active = 0;
	}

	std::vector<EmailAgent> agents(network_size);
	initialize_agents(agents, params);

	std::vector<std::vector<unsigned char> > sent_mail(
		network_size, std::vector<unsigned char>(network_size, 0));
	std::vector<std::vector<unsigned char> > social_edge(
		network_size, std::vector<unsigned char>(network_size, 0));

	std::priority_queue<EmailEvent, std::vector<EmailEvent>, EmailEventLater> events;
	unsigned long sequence = 0;
	int active_count = 0;
	int seed_size = std::max(1, std::min(params.seed_size, network_size));

	for (int i = 0; i < seed_size; i++) {
		activate_node(agents, network, network_size, active_count, 0.0, params, events, sequence);
	}

	int mail_count = 0;
	int edge_count = 0;
	int processed_events = 0;

	while (!events.empty() && processed_events < params.max_events) {
		EmailEvent event = events.top();
		events.pop();

		if (event.time > params.simulation_time) {
			break;
		}
		if (event.sender < 0 || event.sender >= network_size || !agents[event.sender].active) {
			continue;
		}

		processed_events++;

		if (event.type == EMAIL_EVENT_DELETE_CONTACT) {
			delete_contact(agents, event.sender);
			schedule_delete(events, agents, params, event.time, event.sender, sequence);
			continue;
		}

		std::vector<int> receivers = event.receivers;
		if (event.type == EMAIL_EVENT_SEND) {
			receivers = choose_receivers(
				agents, network, network_size, active_count, event.time,
				event.sender, params, events, sequence);
			schedule_send(events, agents, params, event.time, event.sender, sequence);
		}

		process_email(
			agents, network, network_size, active_count, sent_mail, social_edge,
			event.time, event.sender, receivers, params, events, sequence,
			mail_count, edge_count);
	}

	printf("ENM summary: active nodes=%d/%d, emails=%d, mutual edges=%d, events=%d\n",
		active_count, network_size, mail_count, edge_count, processed_events);

	return edge_count;
}
