#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <chrono>
#include <map>
#include "random.hpp"
using namespace std::chrono;
using namespace std;
#define MAX_STATIONS 4


// global variables
int N,M;
int document_recreation;
int logbook_entry;
int total_completed_operations = 0;
int reader_count = 0;

steady_clock::time_point start_time;

int get_time() {
    return duration_cast<seconds>(steady_clock::now() - start_time).count();
}


pthread_mutex_t station_lock[MAX_STATIONS];      
pthread_mutex_t reader_count_lock;
pthread_mutex_t rw_lock;
pthread_mutex_t output_lock;
pthread_mutex_t reader_output_lock;

map<int,int>mp;


void *reader_thread(void *arg) {
    int id = *(int*)arg;

    while (true) {
        sleep(get_random_number());  // Different random interval per staff

        pthread_mutex_lock(&reader_count_lock);
        reader_count++;
        if (reader_count == 1)
            pthread_mutex_lock(&rw_lock);  // first reader locks out writers
        pthread_mutex_unlock(&reader_count_lock);

        // Read logbook
        pthread_mutex_lock(&output_lock);
        cout << "Intelligence Staff " << id
            << " began reviewing logbook at time " << get_time()%1000
            << ". Operations completed = " << total_completed_operations << endl;
        pthread_mutex_unlock(&output_lock);

        pthread_mutex_lock(&reader_count_lock);
        reader_count--;
        if (reader_count == 0)
            pthread_mutex_unlock(&rw_lock);  
        pthread_mutex_unlock(&reader_count_lock);
    }
}


void *operative(void *arg){
    int id = *(int*)arg;
    int time = get_random_number();
    sleep(time);
    int unit_id = ceil(id*1.0/M);
    int station = id % MAX_STATIONS;
    pthread_mutex_lock(&output_lock);
    cout<<"Operative "<<id<<" "<<" has arrived at typewriting station  at time " <<get_time()%1000<<endl;
    pthread_mutex_unlock(&output_lock);

    pthread_mutex_lock(&station_lock[station]);
    cout<<"Operative "<<id<<" "<<" has started at typewriting station  at time " <<get_time()%1000<<endl;

    sleep(document_recreation);
    
    mp[unit_id]++;
    cout<<"Operative "<<id<<" has completed document recreation  at time "<<get_time()%1000<<endl;
    pthread_mutex_unlock(&station_lock[station]);

    if(mp[unit_id] == M)
    {
            pthread_mutex_lock(&output_lock);
            cout<<"Unit "<<unit_id<<" has completed document recreation phase at time "<<get_time()%1000<<endl;
            pthread_mutex_unlock(&output_lock);
            pthread_mutex_lock(&rw_lock);
            sleep(logbook_entry);
            total_completed_operations++;
            cout << "Unit "<<unit_id<<" has completed intelligence distribution at time " << get_time() << endl;
            pthread_mutex_unlock(&rw_lock);
    }
    return NULL;
}

int main(void){
        freopen("input.txt","r",stdin);
        freopen("output.txt","w",stdout);
        int x,y;
        cin>>N>>M>>x>>y;
        document_recreation = x;
        logbook_entry = y;
        pthread_mutex_init(&output_lock,NULL);
        pthread_mutex_init(&rw_lock,NULL);
        pthread_mutex_init(&reader_count_lock,NULL);
        pthread_mutex_init(&reader_output_lock,NULL);
        for (int i = 0; i < MAX_STATIONS; i++)
        {
            pthread_mutex_init(&station_lock[i], NULL);
        }

        pthread_t tid[N];
        pthread_t reader1, reader2;
        int id1 = 1, id2 = 2;
        pthread_create(&reader1, NULL, reader_thread, &id1);
        pthread_create(&reader2, NULL, reader_thread, &id2);

        for(int i=1;i<=N;i++)
        {
            int *id = new int(i);
            pthread_create(&tid[i-1],NULL,operative,id);
        }
        for(int i=0;i<N;i++)
        {
            pthread_join(tid[i],NULL);
        }
        pthread_join(reader1,NULL);
        pthread_join(reader2,NULL);
        for (int i = 0; i < MAX_STATIONS; i++) 
            {
                pthread_mutex_destroy(&station_lock[i]);
            }
        return 0;
}