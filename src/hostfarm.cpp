#include <iostream>
#include <vector>
#include <math.h>
#include <ff/pipeline.hpp>
#include <ff/farm.hpp>

#define HIGH 500.0f
#define LOW -500.0f

using namespace ff;

void initMat(float *MAT,int matN, int m, int n){
    for(int i=0;i<matN;++i)
        for(int r=0;r<m;++r) {
            for(int c=0;c<n;++c)
                MAT[(i*m*n) + (r*n) + c] = (i+c+r)/3.14;
        }
} 

void randomArray(float *x, int n){
    #ifndef MEASURES
            std::cout<<std::endl<< "X ARRAY: "<<std::endl;  
    #endif
    for(int i=0; i<n;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        #ifndef MEASURES
            std::cout<< x[i] << ", ";  
        #endif
    }
}

float* A = NULL;
float* B = NULL;
float* C = NULL;

void printMat(float * MAT,int N, int r, int c) {
   // int tsize=size*size;
    for(int k=0;k<N;++k) {
        for(int i=0;i<r;++i) {
            for(int j=0;j<c;++j) {
                std::cout << MAT[(k*r*c) + (i*c) + j] << " ";
            }
            std::cout << std::endl;
        }
        std::cout << std::endl << std::endl;
    }
}


/************************/
/*****MATMUL_FF_FARM****/
#ifdef HMMPAR
/* globals */
//double* A = NULL;
//double* B = NULL;
//double* C = NULL;



class Emitter: public ff_node {
public:
    Emitter(long ntasks):ntasks(ntasks) {}
    void* svc(void*) {
        for(long i=1;i<=ntasks;++i)
            ff_send_out((void*)i);
        return NULL;
    }
private:
    long ntasks;
};

class Worker: public ff_node {
public:
    Worker(long m,long k,long n):_m(m), _k(k), _n(n) {
    }
    
    void* svc(void* task) {
        long taskid = (long)(long*)task;
        --taskid;

        //std::cout<< std::endl << "TASK ID   : "<< taskid << std::endl;

        float* _A = &A[taskid*_m*_k];
        //printMat(_A,1,_m,_k);
        float* _B = &B[taskid*_k*_n];
        //printMat(_B,1,_k,_n);

        float* _C = &C[taskid*_m*_n];

        /*for (register int i = 0; i < _m; ++i)
            for (register int j = 0; j < _n; ++j) {
                float _Ctmp=0.0;
                for (register int c = 0; c < _k; ++c)
                    _Ctmp += _A[(i * _k) + r] * _B[(c * _n) + j];
                _C[(i * _n) + j] = _Ctmp;
            }*/
        for (register int c1 = 0; c1 < _k; ++c1) 
            for (register int r1 = 0; r1 < _m; ++r1) {
                //float _Ctmp=0.0;
                for (register int c2 = 0; c2 < _n; ++c2)
                    _C[(c2*_n)+r1] +=
                        _A[(r1 * _k) + c1] * _B[(c1 * _n) + c2];
               // _C[(i * _n) + j] = _Ctmp;
            }

        return GO_ON;
    }
public:
    long _m;
    long _k;
    long _n;
};
/*********************/
/*****COS_FF_FARM****/
#elif HCOSPAR
struct Worker: ff_node_t<float> {

    int M_itr;
    Worker(int m){
        M_itr=m;
    }

    float *svc(float *t) {  
        float res=cosf(*t);

        for(int j=0;j<M_itr-1;j+=1)
            res=cosf(res);

        return new float(res);         
    }
};

struct firstStage: ff_node_t<float> {
    long N_elements;
    
    firstStage(int n){
        N_elements=n;
    }

    firstStage(){
    }

    float *svc(float *) { 
        for(int i=0; i<N_elements;i+=1){
            float val=LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX; 
            #ifndef MEASURES  
            std::cout << "-Generated X: "<< val << std::endl;
            #endif
            ff_send_out(new float(val));
        }
        return EOS;
    }
} Emitter;

struct lastStage: ff_node_t<float> {
    float *svc(float *t) { 
        const float &task=*t;
        
        #ifndef MEASURES
        std::cout << "-COS result: " 
        << task << ", "<<std::endl;
        #endif

        delete t;
        return GO_ON;
    }
} Collector;
#endif

/**************/
/*****MAIN****/
int main(int argc, char *argv[]) {
    std::chrono::time_point<std::chrono::system_clock> start, end;
    std::chrono::time_point<std::chrono::system_clock> startTot, endTot;
    std::chrono::duration<double> elapsed, elapsedTot;

    int Nstr=atoi(argv[1]);

#ifdef HCOSSEQ
    assert(argc>1);
    //int nworkers = atoi(argv[1]);
    //int K_exec = atoi(argv[1]);
    int M_iter = atoi(argv[2]);
    int N_size = atoi(argv[3]);
    

    std::cout<<std::endl<<"#HCOSSEQ," ;
    std::cout<<Nstr<<","<<M_iter<<","<<N_size ;

    #ifndef MEASURES
    std::cout<<std::endl<<"##########################" <<std::endl;
    #else
    std::cout<<std::endl<<"*";
    #endif  
    
    startTot=std::chrono::system_clock::now();
    float *cosx=new float[N_size];
    float *x=new float[N_size];
    //for(int i=0; i<N_size;i+=1)
        //x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
    
     
    for (int r = 0; r < Nstr; ++r) { 
        start=std::chrono::system_clock::now();
        randomArray(x,N_size);
        
        for(int i=0;i<N_size;i+=1)   {
            cosx[i]=cos(x[i]);
            for(int j=0;j<M_iter;j+=1){                
                cosx[i]=cos(cosx[i]); 
            }
        } 
            
                                 
        end=std::chrono::system_clock::now();
        elapsed= end-start;
        #ifndef MEASURES
            std::cout << std::endl;
            std::cout << std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;  
            std::cout << "COSX array : " <<std::endl;  
            for(int j=0; j<N_size;j+=1) 
                std::cout << cosx[j] << ", ";    
            
            std::cout<<std::endl<< "Elapsed time: "<<elapsed.count()<<"ms"<< std::endl;
        #else
            std::cout <<elapsed.count()<<","; 
        #endif
            
    }
    endTot=std::chrono::system_clock::now();
    elapsedTot= endTot - startTot ;
    std::cout<<std::endl<< "$"<<elapsedTot.count()<< std::endl;
    /*auto m = std::minmax_element(timeVect.begin(), timeVect.end());
    auto min = m.first;
    auto max = m.second;
    float avg=std::accumulate( timeVect.begin(), timeVect.end(), 0.0)/timeVect.size(); 

    std::cout<<std::endl<<"----"<< *min<<","<<*max<<","<<avg<<std::endl; */

#elif HCOSPAR
    assert(argc>1);
    int nworkers = atoi(argv[2]);
    //int K = atoi(argv[3]);
    int M = atoi(argv[3]);
    int N = atoi(argv[4]);

    std::cout<<std::endl<<"#HCOSPAR," ;
    std::cout<<Nstr<<","<<nworkers<<","//<<K<<","
    <<M<<","<<N;

    #ifndef MEASURES
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<std::endl<< "Farm single elapsed worker time:"<<std::endl;
    #else
    std::cout<<std::endl<<"*";
    #endif 

    startTot = std::chrono::system_clock::now();  
    Emitter.N_elements=N;
    for (int r = 0; r < Nstr; ++r) {
        ff_Farm<float> farm([nworkers,M](){
                std::vector<std::unique_ptr<ff_node> > Workers;
                for(int i=0;i<nworkers;++i) 
                    Workers.push_back(std::unique_ptr<ff_node_t<float> >(new Worker(M)));
                return Workers;
            }(), Emitter, Collector);

        start = std::chrono::system_clock::now();  
        if (farm.run_and_wait_end()<0) error("running farm"); 
        end = std::chrono::system_clock::now();
        elapsed=end-start;
        std::cout<<elapsed.count()<<", ";
    }

    endTot = std::chrono::system_clock::now();      
    elapsedTot=endTot-startTot;

    #ifndef MEASURES
    std::cout<<std::endl<< "Farm Elapsed total time"<<std::endl;
    #endif
    std::cout<<std::endl<<"$"<<elapsedTot.count()<<std::endl;

/*****MATMUL*****/
#elif HMMSEQ
    if (argc<4) {
        std::cout<<"use: " << argv[0] << " matrix-size matrices-per-worker nworkers"<<std::endl;
        return -1;
    }

    int n = atoi(argv[2]);
    int k = atoi(argv[3]);
    int m = atoi(argv[4]);
    int matN = atoi(argv[5]);
    

    std::cout<<std::endl<<"#HMMSEQ," ;
    std::cout<<Nstr<<","<<n<<","<<k<<","<<m<<","<<matN;
    #ifndef MEASURES
    //std::cout<<std::endl<<"##########################" <<std::endl;
    //std::cout<<std::endl<< "Single matmul elapsed time:"<<std::endl;
    std::cout<<std::endl <<"-------------------" << std::endl;

    #else
    std::cout<<std::endl<<"*";
    #endif 

    startTot = std::chrono::system_clock::now();
    A = (float*)calloc(matN, m*k*sizeof(float));
    B = (float*)calloc(matN, k*n*sizeof(float));
    C = (float*)calloc(matN, m*n*sizeof(float));

    initMat(A, matN, m, k);
    initMat(B, matN, k, n);

	/*#ifndef MEASURES
        std::cout<<std::endl<< "Seq MatMul single elapsed: ";
    #endif  */

    for(int j=0;j<Nstr;++j)
    {
        for(int i=0;i<matN;++i)
        {
            start = std::chrono::system_clock::now();
            for (int r1 = 0; r1 < m; ++r1)
                for (int c1 = 0; c1 < k; ++c1) {
                    for (int c2 = 0; c2 < n; ++c2)
                    {
                        C[(i*m*n) +(r1 * n) + c2] += 
                            A[(i*m*k) + (r1*k) + c1] * B[(i*k*n)+(c1*n)+c2];
                    }
                }
            /*for (int r = 0; r < m; ++r)
                for (int c = 0; c < n; ++c) {
                    float sum=0.0;
                    for (int j = 0; j < k; ++j)
                        sum += A[(i*n*n) + (r*m) + j] * B[(i*n*n)+(j*k)+c];
                    C[(i*n*n) +(r * m) + c] = sum;
                }*/

            
            end = std::chrono::system_clock::now(); 
            elapsed=end-start;  
            #ifdef MEASURES  
            std::cout<<elapsed.count()<<",";
            #else
            std::cout<<std::endl<<"Seq MatMul single elapsed: "<< elapsed.count()<<std::endl;
            #endif



    }

    #ifndef MEASURES
        //std::cout<<std::endl;
            std::cout<<std::endl<<"----------------"<<std::endl;

        printMat(C,matN,m,n);
        //std::cout<<std::endl<< "Tot MatMul Elapsed: ";
    #else

    #endif
     





    }
    endTot = std::chrono::system_clock::now();
    elapsedTot=endTot-startTot;
    #ifndef MEASURES
    std::cout <<"-------------------" << std::endl;

    std::cout<< std::endl<<"Total Sequential MatMul elpsed time: "<<elapsedTot.count()<< std::endl;  
    #else
    std::cout<< std::endl<<"$"<<elapsedTot.count()<< std::endl;  
    #endif

#elif HMMPAR
    if (argc<1) {
        std::cout<<"use: " << argv[0] << " matrix-size matrices-per-worker nworkers"<<std::endl;
        return -1;
    }

    int n = atoi(argv[2]);
    int k = atoi(argv[3]);
    int m = atoi(argv[4]);
    int mxw = atoi(argv[5]);
    int nworkers = atoi(argv[6]);

    std::cout<<std::endl<<"#HMMPAR," ;
    std::cout<<Nstr<<","<<n<<","<<k<<","<<m<<","<<mxw<<","<<nworkers;
    #ifndef MEASURES
    std::cout<<std::endl<<"##########################" <<std::endl;
    
    #else
        std::cout<<std::endl<<"*";
    #endif 

    int matN = mxw * nworkers;

    startTot = std::chrono::system_clock::now();  
    A = (float*)calloc(matN, m*k*sizeof(float));
    B = (float*)calloc(matN, k*n*sizeof(float));
    C = (float*)calloc(matN, m*n*sizeof(float));

    initMat( A, matN,  m, k);
    initMat( B, matN, k, n);

    #ifndef MEASURES
    std::cout<<"A MATRIX " <<std::endl;
    printMat(A,matN,m,n);
    std::cout<<"B MATRIX "<< std::endl;
    printMat(B,matN,m,n);
    /*for(int i=0;i<matN;++i)
        for(int j=0;j<size;++j)
            for(int k=0;k<size;++k) {
                A[i*tsize + j*size + k] = (i+j+k)/3.14;
                B[i*tsize + j*size + k] = (i+j*k) + 3.14;
            }*/
    std::cout<<std::endl<<"##########################"<<std::endl<< "Single matmul elapsed time:"<<std::endl;
    #endif

    for(int j=0; j<Nstr; ++j){
        ff_farm<> farm;
        Emitter E(matN);
        farm.add_emitter(&E);
        std::vector<ff_node *> w;
        for(int i=0;i<nworkers;++i) 
            w.push_back(new Worker(m,k,n));
        farm.add_workers(w);    

        start = std::chrono::system_clock::now();  
        farm.run_and_wait_end();
        end = std::chrono::system_clock::now(); 

        elapsed=end-start;
        //std::cout<<elapsed.count()<<", ";



        #ifndef MEASURES
        

        for(int i=0;i<nworkers;++i)
        {
            std::cout << "Worker " << i << " mean task time "
                << diffmsec( ((Worker*)w[i])->getwstoptime(), ((Worker*)w[i])->getwstartime())/mxw<<std::endl; 

        }
        
        std::cout<<"Farm time "<< farm.ffTime() <<" (ms)" <<std::endl;
        std::cout<<"Measured time "<< elapsed.count() <<" (ms)" <<std::endl;

        std::cout <<"-------------------" << std::endl;
        printMat(C,matN,m,n);        
        //std::cout<<std::endl<< "Farm MatMul Elapsed: worker time, total time "<<std::endl;   

        memset(C,0,matN*m*n*sizeof(float));
        std::cout<<std::endl<<"Parallel Mat Mul CHECK"<<std::endl;
        for(int i=0;i<matN;++i)
        {
            //start = std::chrono::system_clock::now();
            for (int r1 = 0; r1 < m; ++r1)
                for (int c1 = 0; c1 < k; ++c1) {
                // float sum=0.0;
                
                    for (int c2 = 0; c2 < n; ++c2)
                    {
                        C[(i*m*n) +(r1 * n) + c2] += 
                            A[(i*m*k) + (r1*k) + c1] * B[(i*k*n)+(c1*n)+c2];

                    }
                        
                        //sum += A[(i*m*n) + (r*n) + j] * B[(i*matN)+(j*k)+c];
                    //C[(i*matN) +(r * m) + c] = sum;
                }
            //end = std::chrono::system_clock::now();     
            //std::cout<<(end-start).count()<<",";
        }
        //endTot = std::chrono::system_clock::now();
        //std::chrono::duration<double> elapsed=endTot-startTot;
        //#ifndef MEASURES
        printMat(C,matN,m,n);
    #else
        
        /*for(int i=0;i<nworkers;++i)
        {
            std::cout << diffmsec( ((Worker*)w[i])->getwstoptime(), ((Worker*)w[i])->getwstartime())<<",";
        }*/
        std::cout<<elapsed.count()<<", ";

        
    #endif
    }
    
    endTot = std::chrono::system_clock::now();  
    //elapsed=end-start;
    elapsedTot=endTot-startTot;

    #ifndef MEASURES
        std::cout<<"Total time "<< elapsedTot.count() <<" (ms)" <<std::endl;

       /* for(int i=0;i<nworkers;++i)
        {
            std::cout << "Worker " << i << " mean task time "
                << diffmsec( ((Worker*)w[i])->getwstoptime(), ((Worker*)w[i])->getwstartime())/mxw<<std::endl; 

        }
        std::cout <<"-------------------" << std::endl;
        printMat(C,matN,m,n);        
        std::cout<<std::endl<< "Farm MatMul Elapsed: worker time, total time "<<std::endl;   

        memset(C,0,matN*m*n*sizeof(float));
        std::cout<<std::endl<<"Par Mat Mul CHECK"<<std::endl;
        for(int i=0;i<matN;++i)
        {
            //start = std::chrono::system_clock::now();
            for (int r1 = 0; r1 < m; ++r1)
                for (int c1 = 0; c1 < k; ++c1) {
                // float sum=0.0;
                
                    for (int c2 = 0; c2 < n; ++c2)
                    {
                        C[(i*m*n) +(r1 * n) + c2] += 
                            A[(i*m*k) + (r1*k) + c1] * B[(i*k*n)+(c1*n)+c2];

                    }
                        
                        //sum += A[(i*m*n) + (r*n) + j] * B[(i*matN)+(j*k)+c];
                    //C[(i*matN) +(r * m) + c] = sum;
                }
            //end = std::chrono::system_clock::now();     
            //std::cout<<(end-start).count()<<",";
        }
        //endTot = std::chrono::system_clock::now();
        //std::chrono::duration<double> elapsed=endTot-startTot;
        //#ifndef MEASURES
        printMat(C,matN,m,n);*/
    #else
       /* std::cout <<std::endl<< "*";
        for(int i=0;i<nworkers;++i)
        {
            std::cout << diffmsec( ((Worker*)w[i])->getwstoptime(), ((Worker*)w[i])->getwstartime())<<",";
        }*/

        std::cout<<std::endl<<"$"<<elapsedTot.count()<< std::endl;
    #endif

#endif

    return 0;
}







