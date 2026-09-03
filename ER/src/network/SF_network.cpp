/*
 * SF_network.cpp
 *
 *  Created on: 2017-7-16
 *      Author: Administrator
 */

#include "total.h"
#include "network/SF_network.h"
#include "network/network_basic_ops.h"
#include <stdexcept>
#include <unordered_set>

void degree_Seq(Node SF[], double lambda, int SF_NETWORK_SIZE)
{
	int K;
	int i,j;
	int u;
	double h;
	double zeta=0;   //
	double rd;
	double rd_1;
    double mean_k=0;
    int max_index = 0;
    K=100;
    vector<double> seqence(K+1, 0.0);
    vector<double> CDD(K+1, 0.0);
    vector<int> degree_distribution(SF_NETWORK_SIZE+1, 0);
    int min_degree = 4;
    int degree_sum = 0;

	printf("K=%d\n",K);

	for(i=min_degree; i<=K; i++)
	{//i=3
		seqence[i]=pow(i*1.0,-lambda);
	    zeta=zeta+seqence[i];
	}

/*	for(i=3;i<=K;i++)
	{
		printf("\nseqence[%d]=%f",i,seqence[i]);
	}*/

	printf("zeta=%f\n",zeta);
	mean_k=0;
	for(i=min_degree;i<=K;i++)
	{
		seqence[i]=(seqence[i])/zeta;
		mean_k += i*seqence[i];
	}

/*	for(i=3;i<=K;i++)
	{
		printf("\nseqence[%d]=%f",i,seqence[i]);
	}*/

	for(i=min_degree;i<=K;i++)
	{
		CDD[i]=CDD[i-1]+seqence[i];
	}

/*	for(i=3;i<=K;i++)
	{
		printf("\nCDD[%d]=%f",i,CDD[i]);
	}
*/
    printf("mean_k is %f\n", mean_k);
	//
	//srand((unsigned)time(NULL));//
	for(i=0;i<SF_NETWORK_SIZE;i++)
	{
		// Generate a value in [0, 1), so the upper CDF boundary is reachable
		// without leaving a node at its initialization degree of -1.
		rd=(double)rand()/((double)RAND_MAX + 1.0);
		int sampled_degree = K;
		for(j=min_degree;j<=K;j++)
		{
			if(rd<CDD[j])
			{
				sampled_degree = j;
				break;
			}
		}
		h=(((double)sampled_degree)/((double)mean_k))*((double)10);
		u=(int)h;
		rd_1=(double)rand()/((double)RAND_MAX + 1.0);
		if(rd_1<h-u)
		{
			SF[i].degree=u+1;
		}
		else
		{
			SF[i].degree=u;
		}
		if (max_index<SF[i].degree){
			max_index = SF[i].degree;
		}
		if (SF[i].degree >= (int)degree_distribution.size()) {
			degree_distribution.resize(SF[i].degree + 1, 0);
		}
		degree_distribution[SF[i].degree]++;
		degree_sum += SF[i].degree;
	}

	if (degree_sum % 2 == 1){
		int start = rand() % SF_NETWORK_SIZE;
		bool parity_fixed = false;
		for (int offset = 0; offset < SF_NETWORK_SIZE; offset++){
			int idx = (start + offset) % SF_NETWORK_SIZE;
			if (SF[idx].degree < 0 || SF[idx].degree >= SF_NETWORK_SIZE - 1){
				continue;
			}
			if (SF[idx].degree < (int)degree_distribution.size()){
				degree_distribution[SF[idx].degree]--;
			}
			SF[idx].degree++;
			degree_sum++;
			if (max_index < SF[idx].degree){
				max_index = SF[idx].degree;
			}
			if (SF[idx].degree >= (int)degree_distribution.size()) {
				degree_distribution.resize(SF[idx].degree + 1, 0);
			}
			degree_distribution[SF[idx].degree]++;
			parity_fixed = true;
			break;
		}
		if (!parity_fixed){
			throw std::runtime_error("cannot make the SF degree sum even");
		}
	}

//	sprintf(filename, "degree_sf_v_%.2f.txt",lambda);
//	fp=fopen(filename,"w");
//	for (i=1; i<=max_index; i++){
//	    degree_dis = (double)degree_distribution[i]/(double)10000;
//		fprintf(fp,"%f\n",degree_dis);
//	}
//	fclose(fp);
}

//
int SF_Model(Node SF[], int SF_NETWORK_SIZE)
{
	if (SF_NETWORK_SIZE <= 0){
		throw std::runtime_error("SF_NETWORK_SIZE must be positive, but actually is " + std::to_string(SF_NETWORK_SIZE));
	}

	vector<int> degree_stubs;
	long long stub_count = 0;
	for(int i=0; i<SF_NETWORK_SIZE; i++)
	{
		if (SF[i].degree < 0 || SF[i].degree >= SF_NETWORK_SIZE){
			throw std::runtime_error("invalid degree in SF degree sequence");
		}
		stub_count += SF[i].degree;
	}
	if (stub_count % 2 != 0){
		throw std::runtime_error("SF degree sum is odd");
	}
	degree_stubs.reserve((size_t)stub_count);
	for(int i=0; i<SF_NETWORK_SIZE; i++)
	{
		for(int d=0; d<SF[i].degree; d++)
		{
			degree_stubs.push_back(i);
		}
	}

	const int max_restarts = 100;
	for (int restart=0; restart<max_restarts; restart++)
	{
		vector<int> seq = degree_stubs;
		vector<unordered_set<int> > neighbors(SF_NETWORK_SIZE);
		vector<pair<int, int> > edges;
		edges.reserve(seq.size()/2);
		int remaining = (int)seq.size();
		bool complete = true;

		while(remaining > 1)
		{
			int m = -1;
			int n = -1;

			// Try random pairs first. The fixed bound avoids j*j integer
			// overflow; an exhaustive fallback below ensures that an
			// available pair is not missed merely by bad random draws.
			for(int attempt=0; attempt<256; attempt++)
			{
				int candidate_m = rand()%remaining;
				int candidate_n = rand()%remaining;
				int node_m = seq[candidate_m];
				int node_n = seq[candidate_n];
				if(candidate_m != candidate_n &&
				   node_m != node_n &&
				   neighbors[node_m].find(node_n) == neighbors[node_m].end())
				{
					m = candidate_m;
					n = candidate_n;
					break;
				}
			}

			if (m < 0)
			{
				for(int candidate_m=0; candidate_m<remaining && m<0; candidate_m++)
				{
					for(int candidate_n=candidate_m+1; candidate_n<remaining; candidate_n++)
					{
						int node_m = seq[candidate_m];
						int node_n = seq[candidate_n];
						if(node_m != node_n &&
						   neighbors[node_m].find(node_n) == neighbors[node_m].end())
						{
							m = candidate_m;
							n = candidate_n;
							break;
						}
					}
				}
			}

			if (m < 0)
			{
				complete = false;
				break;
			}

			int node_m = seq[m];
			int node_n = seq[n];
			neighbors[node_m].insert(node_n);
			neighbors[node_n].insert(node_m);
			edges.push_back(make_pair(node_m, node_n));

			if (m > n)
			{
				int temp = m;
				m = n;
				n = temp;
			}
			seq[n] = seq[remaining-1];
			remaining--;
			seq[m] = seq[remaining-1];
			remaining--;
		}

		if (complete && remaining == 0)
		{
			// Commit only a complete realization, so callers can never
			// observe a partially generated SF topology.
			for(size_t i=0; i<edges.size(); i++)
			{
				create(SF[edges[i].first].next, edges[i].second);
				create(SF[edges[i].second].next, edges[i].first);
			}
			return (int)edges.size();
		}
	}

	throw std::runtime_error("failed to realize the complete SF degree sequence after 100 restarts");
}
