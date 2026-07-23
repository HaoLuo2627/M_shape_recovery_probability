/*
 * SF_network.cpp
 *
 *  Created on: 2017-7-16
 *      Author: Administrator
 */

#include "total.h"
#include "network/SF_network.h"
#include "network/network_basic_ops.h"

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
    char filename[100];
    K=100;
    vector<double> seqence(K+1, 0.0);
    vector<double> CDD(K+1, 0.0);
    vector<int> degree_distribution(SF_NETWORK_SIZE+1, 0);
    double degree_dis = 0;
   	FILE *fp;
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
		rd=(double)rand()/(RAND_MAX);
		for(j=min_degree;j<=K;j++)
		{
			if(rd<CDD[j])
			{
				h=(((double)j)/((double)mean_k))*((double)10);
				u=(int)h;
				rd_1=(double)rand()/(RAND_MAX);
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
				break;
			}
		}
	}

	if (degree_sum % 2 == 1){
		int idx = rand() % SF_NETWORK_SIZE;
		if (SF[idx].degree >= 0 && SF[idx].degree < SF_NETWORK_SIZE - 1){
			if (SF[idx].degree < (int)degree_distribution.size()){
				degree_distribution[SF[idx].degree]--;
			}
			SF[idx].degree++;
			if (SF[idx].degree >= (int)degree_distribution.size()) {
				degree_distribution.resize(SF[idx].degree + 1, 0);
			}
			degree_distribution[SF[idx].degree]++;
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
	int count=0;	//
	int total_edge_count = 0; //
	int i,j;

//	int ct1,ct2;

	int m,n;

	int temp;
	vector<int> seq;
	seq.reserve(SF_NETWORK_SIZE*10);

//	ct1=0;
//	ct2=0;

	for(i=0;i<SF_NETWORK_SIZE;i++)
	{
		for(j=0;j<SF[i].degree;j++)
		{
			seq.push_back(i);
			count++;
		}
	}
	for(i=0;i<count;i++)
	{
	//	printf("%4d",seq[i]);
	}
	//printf("count=%d,seq[count]=%d",count,seq[count-1]);

	j=count;

	while(j>1)
	{
		int attempts = 0;
		int max_attempts = j*j*4;
		bool found_pair = false;
		while(attempts < max_attempts)
		{
			m=rand()%j;
			n=rand()%j;
			if(!(m==n || find_Data(SF[seq[m]].next,seq[n]) || find_Data(SF[seq[n]].next,seq[m]) || seq[m]==seq[n]))
			{
				found_pair = true;
				break;
			}
			attempts++;
		}
		if (!found_pair)
		{
			fprintf(stderr, "WARNING: SF_Model stopped with %d unmatched stubs.\n", j);
			break;
		}
//				printf("\nj=%d",j);

		create(SF[seq[m]].next,seq[n]);
		create(SF[seq[n]].next,seq[m]);
		total_edge_count++;
		if (m > n)
		{
			temp = m;
			m = n;
			n = temp;
		}
		seq[n]=seq[j-1];
		j--;
		seq[m]=seq[j-1];
		j--;
	}
	//printf("\nj=%d\n",j);
//	for(i=0;i<SF_NETWORK_SIZE;i++)
//	{
//		print(SF[i].next,type);
//	}
	return total_edge_count;
}
