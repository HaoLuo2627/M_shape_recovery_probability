/*
 * infection.cpp
 *
 *  Created on: 2017-8-11
 *      Author: Administrator
 */
#include "total.h"
#include "network/network_basic_ops.h"
#include "network/ER_network.h"
#include "network/network_overlay_ops.h"
#include "utils/edge_weight.h"
#include "recovery_probability.h"
#include <iostream>
#include <exception>
#include <cerrno>
#include <stdint.h>
#ifdef _WIN32
#include <process.h>
#define GETPID _getpid
#else
#include <unistd.h>
#define GETPID getpid
#endif
#define filename_max_length 1024

int find_number_of_M_nodes(Node network[], Node * node){
	int count = 0;
	for (edge * pGuard=node->next->next; pGuard!=NULL; pGuard=pGuard->next){
//		printf("node number is %d\n",pGuard->data);
       if (network[pGuard->data].type=='M'){
    	   count++;
       }
	}
	return count;
}

int initialize_zero(int *array, int size){
	for(int i=0; i<size; i++){
		array[i] = 0;
	}
	return 0;
}

// 个体采纳条件函数
bool cusp_condition(double x, double prob) {
    double rd_accept_rate = static_cast<double>(rand()) / static_cast<double>(RAND_MAX);

	if (rd_accept_rate <= prob){
        return true;
	}else{
        return false;
	}
}

//传播感染过程
void double_layer_infection(Node A[], Node B[], double alpha_A, double h_A, double alpha_B, double h_B, double A_a, double A_c, double B_a, double B_c, int k_count, int seed[], int network_size, char *file_A, char *file_B, char *S_time_file, char *A_time_file, char *R_time_file)
{
	Infect Old[2*network_size];			//当前已经感染的节点数组，包括A网络和B网络的
	Infect New_A[network_size];			//A网络新感染的节点数组
	Infect New_B[network_size];			//B网络新感染的节点数组
	Infect New_AB[2*network_size];		//A网络和B网络新感染节点的混合数组
	//char file_dir_name[filename_max_length]; //文件路径名字符数组
	double rd_Infection_A;
	double rd_Recover_A;
	double rd_Infection_B;
	double rd_Recover_B;
	const double r_A = recovery_probability(alpha_A, A_a, A_c);  // A层个体的恢复概率
	const double r_B = recovery_probability(alpha_B, B_a, B_c);  // B层个体的恢复概率
	// printf("r_A = %f, r_B = %f\n", r_A, r_B);

	int ct_S_A=0;
    int ct_I_A=0;
	int ct_R_A=0;

	int ct_S_B=0;
	int ct_I_B=0;
	int ct_R_B=0;

	int rd_Add;
	int i;
	int count_Old=0;
	int count_New_A=0;
	int count_New_B=0;
	int count_New_AB=0;
	int count_Recover_A=0;
	int count_Recover_B=0;

    double inst_rate_A=0;
    double inst_rate_B=0;
    double inst_tre_A=0;
    double inst_tre_B=0;
	edge *p;
	FILE *fp = NULL;

	if (k_count == network_size){
		//保存最终A网络感染节点个数
		fp=fopen(file_A,"a");
		if (fp != NULL) {
			fprintf(fp,"%f %f %7d\n", alpha_A, alpha_B, network_size);
			fclose(fp);
		}
		//保存最终B网络感染节点个数
		fp=fopen(file_B,"a");
		if (fp != NULL) {
			fprintf(fp,"%f %f %7d\n", alpha_A, alpha_B, network_size);
			fclose(fp);
		}
		return;
	}

	for(i=0;i<network_size;i++)
	{
		New_A[i].data=-1;
		New_A[i].type='A';

		New_B[i].data=-1;
		New_B[i].type='B';
	}

	for(i=0;i<2*network_size;i++)
	{
		Old[i].data=-1;
		Old[i].type='U';
	}

	//初始设置种子感染节点
	for (i=0; i<k_count; i++){
		A[seed[i]].type='I';
		Old[count_Old].data=seed[i];
		Old[count_Old].type='A';
		count_Old++;

		B[seed[i]].type='I';
		Old[count_Old].data=seed[i];
		Old[count_Old].type='B';
		count_Old++;
	}

	//初始统计各个节点状态，只有S和A状态
	fp = fopen(S_time_file,"a");
	fprintf(fp,"0 %f\n", (double)(network_size-k_count)/(double)network_size);
	fclose(fp);

	fp = fopen(A_time_file,"a");
	fprintf(fp,"0 %f\n", (double)k_count/(double)network_size);
	fclose(fp);

	fp = fopen(R_time_file,"a");
	fprintf(fp,"0 %f\n", 0.0);
	fclose(fp);

	int t=0;
	while(count_Old>0)
	{
		//检查感染节点，开始感染周边
		for(i=0;i<count_Old;i++)
		{
			//如果感染节点来自A网络时
			if(Old[i].type=='A')
			{
				p=A[Old[i].data].next->next;
				while(p!=NULL)
				{
					rd_Infection_A=rand()/(double)(RAND_MAX);
					inst_rate_A = alpha_A;
					if(rd_Infection_A<inst_rate_A && A[p->data].type=='S' && p->transmit=='U')
					{
						p->transmit='T';
						A[p->data].info_count++;
						inst_tre_A = (A[p->data].degree > 0) ? (double)(A[p->data].info_count)/(double)(A[p->data].degree) : 0.0;  // 接收信息/节点度
						// 只有 A 层收到新信息：仅重新评估 A 层响应。
						// 任一层采纳后，下面的同步感染逻辑仍会令两层同时感染。
						if (cusp_condition(inst_tre_A, h_A)){
							A[p->data].type='I';
							New_A[count_New_A].data=p->data;
							New_A[count_New_A].type='A';
							count_New_A++;
							if(B[p->data].type=='S')
							{
								B[p->data].type='I';
								New_B[count_New_B].data=p->data;
								New_B[count_New_B].type='B';
								count_New_B++;
							}
						}
					}
					p=p->next;
				}
			}

			//如果感染节点来自B网络时
			if(Old[i].type=='B')
			{
				p=B[Old[i].data].next->next;
				while(p != NULL)
				{
					rd_Infection_B=rand()/(double)(RAND_MAX);
					inst_rate_B = alpha_B;
					if(rd_Infection_B<inst_rate_B && B[p->data].type=='S' && p->transmit=='U')
					{
						p->transmit='T';
						B[p->data].info_count++;
						inst_tre_B = (B[p->data].degree > 0) ? (double)(B[p->data].info_count)/(double)(B[p->data].degree) : 0.0;  // 接收信息/节点度
						// 只有 B 层收到新信息：仅重新评估 B 层响应。
						if (cusp_condition(inst_tre_B, h_B)){
							B[p->data].type='I';
							New_B[count_New_B].data=p->data;
							New_B[count_New_B].type='B';
							count_New_B++;
							if(A[p->data].type=='S')
							{
								A[p->data].type='I';
								New_A[count_New_A].data=p->data;
								New_A[count_New_A].type='A';
								count_New_A++;
							}
						}
					}
					p=p->next;
				}
			}
		}

		for(i=0;i<count_Old;)
		{
			if(Old[i].type=='A')
			{
				rd_Recover_A = static_cast<double>(rand()) / static_cast<double>(RAND_MAX);
				if(rd_Recover_A<r_A)
				{
					A[Old[i].data].type='R';
					Old[i].data=Old[count_Old-1].data;
					Old[i].type=Old[count_Old-1].type;
					Old[count_Old-1].data=-1;
					Old[count_Old-1].type='U';
					count_Recover_A++;
					count_Old--;
					// 末尾元素已交换到当前位置，下一轮继续处理当前位置。
					continue;
				}
			}

			else if(Old[i].type=='B')
			{
				rd_Recover_B = static_cast<double>(rand()) / static_cast<double>(RAND_MAX);
				if(rd_Recover_B<r_B)
				{
					B[Old[i].data].type='R';
					Old[i].data=Old[count_Old-1].data;
					Old[i].type=Old[count_Old-1].type;

					Old[count_Old-1].data=-1;
					Old[count_Old-1].type='U';

					count_Recover_B++;
					count_Old--;
					continue;
				}
			}

			i++;
		}

		t++;
		ct_S_A = 0;
		ct_I_A = 0;
		ct_R_A = 0;
		ct_S_B = 0;
		ct_I_B = 0;
		ct_R_B = 0;

		//统计每个时刻各个状态节点个数
		for(i=0;i<network_size;i++)
		{
			if(A[i].type=='S')
			{
				ct_S_A++;
			}
			if(A[i].type=='I')
			{
				ct_I_A++;
			}
			if(A[i].type=='R')
			{
				ct_R_A++;
			}

			if(B[i].type=='S')
			{
				ct_S_B++;
			}
			if(B[i].type=='I')
			{
				ct_I_B++;
			}
			if(B[i].type=='R')
			{
				ct_R_B++;
			}
		}
		fp = fopen(S_time_file,"a");
		fprintf(fp,"%d %f\n", t, (double)ct_S_A/(double)network_size);
		fclose(fp);

		fp = fopen(A_time_file,"a");
		fprintf(fp,"%d %f\n", t, (double)ct_I_A/(double)network_size);
		fclose(fp);

		fp = fopen(R_time_file,"a");
		fprintf(fp,"%d %f\n", t, (double)ct_R_A/(double)network_size);
		fclose(fp);

		for(i=0;i<count_New_A;i++)
		{
			New_AB[i].data=New_A[i].data;
			New_AB[i].type=New_A[i].type;
		}

		for(i=0;i<count_New_B;i++)
		{
			New_AB[count_New_A+i].data=New_B[i].data;
			New_AB[count_New_A+i].type=New_B[i].type;
		}

		count_New_AB=count_New_A+count_New_B;
		while(count_New_AB>0)
		{
			rd_Add=rand()%(count_New_AB);
			Old[count_Old].data=New_AB[rd_Add].data;
			Old[count_Old].type=New_AB[rd_Add].type;

			New_AB[rd_Add].data=New_AB[count_New_AB-1].data;
			New_AB[rd_Add].type=New_AB[count_New_AB-1].type;

			New_AB[count_New_AB-1].data=-1;
			New_AB[count_New_AB-1].type='U';

			count_New_AB--;
			count_Old++;
		}
		count_New_A=0;
		count_New_B=0;
	}
}

int select_seeds(int seed_count, int seed[], int network_size){
	int RandNum;
	int i, flag = 0, t=0;
	int MIN = 0;
	int MAX = network_size-1;
	if (seed_count <= 0 || seed_count > network_size){
		char error_msg[256];
		sprintf(error_msg, "seed_count must be in (0, %d], but actually is %d", network_size, seed_count);
		throw std::invalid_argument(error_msg);
	}
	if (seed_count == network_size){
        for(i=0; i<network_size; i++){
        	seed[i] = i;
        }
        return 0;
	}
	while(1)
	{
		flag = 0;
		if(t == seed_count)
			break;

		RandNum = (rand()%(MAX - MIN + 1)) + MIN;
		for(i = 0; i < t; i++)
		{
			if(seed[i] == RandNum)
				flag = 1;
		}
		if(flag != 1)
		{
			seed[t] = RandNum;
			t++;
		}
	}
	return 0;
}

void init_threshold(Node info_network[],  int network_size)
{
	int i;
	edge *eg;

	for(i=0;i<network_size;i++)
	{
		info_network[i].type='S';
		info_network[i].info_count = 0;
		eg=info_network[i].next->next;
		while(eg)
		{
			eg->transmit='U';
			eg=eg->next;
		}
	}
}

void calculate_combined_degree_distribution(Node network1[], Node network2[], int network_size, int max_degree, char *combined_degree_file){
    vector<vector<int> > combined_degree(max_degree+1, vector<int>(max_degree+1, 0));

	FILE *fp;
    char file_dir_name[filename_max_length];
    for (int i=0; i<network_size; i++){
		if (network1[i].degree >= 0 && network1[i].degree <= max_degree &&
    		network2[i].degree >= 0 && network2[i].degree <= max_degree) {
	    	combined_degree[network1[i].degree][network2[i].degree] += 1;
		}
    }

    memset(file_dir_name, 0, filename_max_length);
   	sprintf(file_dir_name, combined_degree_file);
   	fp=fopen(file_dir_name,"w");
	if (fp == NULL) {
  		fprintf(stderr, "ERROR: Cannot open file %s for writing.\n", file_dir_name);
  		return;
  	}

   	for (int i=0; i<=max_degree; i++){
   		for (int j=0; j<=max_degree; j++){
            if (combined_degree[i][j]!=0){
            	fprintf(fp,"%d %d %.17g\n", i, j, (double)combined_degree[i][j]/(double)network_size);
//            	printf("%d %d %.17g\n", i, j, (double)combined_degree[i][j]/(double)network_size);
            }
   		}
   	}
   	fclose(fp);
}

void save_degree_into_file(char *file, char *file_distribution, Node network[], int network_size)
{
	FILE *fp, *fp1;

	vector<int> distri(network_size+1, 0);
	if((fp=fopen(file,"w"))==NULL || (fp1=fopen(file_distribution,"w"))==NULL) {
		printf("weight distribution File cannot be opened\n");
		if (fp != NULL) fclose(fp);
		if (fp1 != NULL) fclose(fp1);
	}else{
		//写出每一条边的端点对
		//写入网络大小
		for (int i=0; i<network_size; i++){
			if (network[i].degree >= 0 && network[i].degree <= network_size) {
				distri[network[i].degree]++;
			}
			fprintf(fp, "%d\n", network[i].degree);
		}

		for (int i=0; i<=network_size; i++){
			if (distri[i]){
				fprintf(fp1, "%d %.17g\n", i, (double)distri[i]/(double)network_size);
			}
		}
		fclose(fp);
		fclose(fp1);
	}
}

// 递归创建目录（含中间目录），类似 mkdir -p
#include <sys/stat.h>
#include <string.h>
#ifdef _WIN32
#include <direct.h>
#define MKDIR_MODE 0  // Windows 忽略 mode
#else
#define MKDIR_MODE 0775
#endif

static int mkdir_one(const char *path) {
#ifdef _WIN32
    int rc = mkdir(path);
#else
    int rc = mkdir(path, MKDIR_MODE);
#endif
    if (rc == 0 || errno == EEXIST) {
        return 0;
    }
    return rc;
}

static int mkdir_p(const char *path) {
    char tmp[filename_max_length];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (len == 0) {
        return 0;
    }

    // 去掉末尾的 /
    if (tmp[len - 1] == '/' || tmp[len - 1] == '\\') {
        tmp[len - 1] = 0;
    }

    for (p = tmp + 1; *p; p++) {
        if (*p == '/' || *p == '\\') {
            *p = 0;
            mkdir_one(tmp);
            *p = '/';
        }
    }
    return mkdir_one(tmp);
}

//主函数
int main(int argc, char *argv[])
{
	FILE *fp;
	int network_size = 10000;//
	int total_edge_count1 = 0,  total_edge_count2 = 0; //

    int max_degree = 0;
    int ave_degree = 10;
    int flag = atoi(argv[1]);  //初始创建网络和度分布的标志，若是0表示新建，是1表示读取已存在的数据
    int seed_count = atoi(argv[2]);
	double A_a = atof(argv[3]);//a in network A
	double A_c = atof(argv[4]);//c in network A
	double B_a = atof(argv[5]);//a in network B
	double B_c = atof(argv[6]);//c in network B

	printf("A_a is %f, A_c is %f, B_a is %f, B_c is %f\n", A_a, A_c, B_a, B_c);

	double p = static_cast<double>(ave_degree) / static_cast<double>(network_size);

	char file_dir_name[filename_max_length];
	Node A_info_network[network_size]; //网络节点数组
	Node B_info_network[network_size]; //网络节点数组

	edge_element_t* A_info_edge_list = NULL;  //网络边链表
	edge_element_t* B_info_edge_list = NULL;  //网络边链表
	unsigned random_seed = (unsigned)time(NULL) ^ (unsigned)clock() ^ (unsigned)(uintptr_t)&random_seed ^ (unsigned)GETPID();
	srand(random_seed);//重设随机数；并发启动时也尽量保持不同

	init_Node(A_info_network, network_size);
	init_Node(B_info_network, network_size);
	int max_degree_1 = 0;
	int max_degree_2 = 0;
    //生成ER网络
	char filename[filename_max_length];
	char filename1[filename_max_length];
	char S_time_file[filename_max_length];
	char A_time_file[filename_max_length];
	char R_time_file[filename_max_length];

	sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f", A_a, A_c, B_a, B_c); //ER

	if (mkdir_p(file_dir_name) != 0)
	{
		printf("create dir failed!!!\n");
	}
	try
	{
		if (flag==0){
			total_edge_count1 = ER_Model(A_info_network, p, network_size, &A_info_edge_list); //ER
			printf("total_edge_count1 is %d\n", total_edge_count1);
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_info_network_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			save_network_into_file(A_info_network,  network_size, file_dir_name);
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_info_network_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			max_degree_1 = save_network_degree_distribution(A_info_network, network_size, file_dir_name);

			total_edge_count2 = ER_Model(B_info_network, p, network_size, &B_info_edge_list);//ER
			printf("total_edge_count2 is %d\n", total_edge_count2);
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_B_info_network_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			save_network_into_file(B_info_network, network_size, file_dir_name);
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_B_info_network_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			max_degree_2 = save_network_degree_distribution(B_info_network,  network_size, file_dir_name);

			sprintf(filename, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_degree_list_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			sprintf(filename1, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_degree_distribution_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			save_degree_into_file(filename,filename1,A_info_network, network_size);

			sprintf(filename, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_B_degree_list_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			sprintf(filename1, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_B_degree_distribution_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			save_degree_into_file(filename,filename1,B_info_network, network_size);

			if (max_degree_1 >= max_degree_2){
				max_degree = max_degree_1;
			}else{
				max_degree = max_degree_2;
			}
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_combined_degree_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER度分布
			calculate_combined_degree_distribution(A_info_network, B_info_network, network_size, max_degree, file_dir_name);
		}else{
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_info_network_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			total_edge_count1 = read_network_from_file(file_dir_name, A_info_network);
			printf("total_edge_count1 is %d\n", total_edge_count1);
			sprintf(file_dir_name, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_B_info_network_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c);//ER
			total_edge_count2 = read_network_from_file(file_dir_name, B_info_network);
			printf("total_edge_count2 is %d\n", total_edge_count2);
	}

	//	//种子数设置为10，即rho0=0.001
		printf("seed_count is %d\n", seed_count);
		int seed_array[seed_count] = {0};
		int index_a = 50;  // lambda_A = 0.5
		int index_b = 50;  // lambda_B = 0.5

		memset(filename, 0, filename_max_length);
		sprintf(filename, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_Final_R_A_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c, seed_count);//ER
		fp=fopen(filename,"w");
		if (fp == NULL) {
			fprintf(stderr, "ERROR: Cannot open file %s for writing. Check that parent directory exists.\n", filename);
			exit(EXIT_FAILURE);
		}
		fclose(fp);

		memset(filename1, 0, filename_max_length);
		sprintf(filename1,  "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_Final_R_B_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c, seed_count);//ER
		fp=fopen(filename1,"w");
		if (fp == NULL) {
			fprintf(stderr, "ERROR: Cannot open file %s for writing. Check that parent directory exists.\n", filename1);
			exit(EXIT_FAILURE);
		}
		fclose(fp);

		memset(S_time_file, 0, filename_max_length);
		memset(A_time_file, 0, filename_max_length);
		memset(R_time_file, 0, filename_max_length);
		
		sprintf(S_time_file, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_S_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c, seed_count);
		fp=fopen(S_time_file,"w");
		if (fp == NULL) {
			fprintf(stderr, "ERROR: Cannot open file %s for writing. Check that parent directory exists.\n", S_time_file);
			exit(EXIT_FAILURE);
		}
		fclose(fp);
		sprintf(A_time_file, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_A_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c, seed_count);
		fp=fopen(A_time_file,"w");
		if (fp == NULL) {
			fprintf(stderr, "ERROR: Cannot open file %s for writing. Check that parent directory exists.\n", A_time_file);
			exit(EXIT_FAILURE);
		}
		fclose(fp);
		sprintf(R_time_file, "data/A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f/ER_R_time_A_a_%.2f_A_c_%.2f_B_a_%.2f_B_c_%.2f_seed_%d.txt", A_a, A_c, B_a, B_c, A_a, A_c, B_a, B_c, seed_count);
		fp=fopen(R_time_file,"w");
		if (fp == NULL) {
			fprintf(stderr, "ERROR: Cannot open file %s for writing. Check that parent directory exists.\n", R_time_file);
			exit(EXIT_FAILURE);
		}
		fclose(fp);

		for(int i=0; i<=1000; i++)
		{
			printf("i is %d\n", i);
			init_threshold(A_info_network,  network_size);
			init_threshold(B_info_network,  network_size);
			select_seeds(seed_count, seed_array, network_size);
			double_layer_infection(A_info_network, B_info_network, (double)index_a/100., 1.0, (double)index_b/100., 1.0, A_a, A_c, B_a, B_c, seed_count, seed_array, network_size, filename, filename1, S_time_file, A_time_file, R_time_file);
		}
		printf("time is up!\n");
	}
	catch (std::out_of_range& e)
	{
		std::cerr << "[ERROR] Out of range: " << e.what() << std::endl;
	}
	catch (std::runtime_error& e)
	{
		std::cerr << "[ERROR] Runtime error: " << e.what() << std::endl;
	}
	catch (std::exception& e)
	{
		std::cerr << "[ERROR] " << e.what() << std::endl;
	}
	catch (...)
	{
		std::cerr << "[ERROR] Unknown exception" << std::endl;
	}
    return 0;
}
